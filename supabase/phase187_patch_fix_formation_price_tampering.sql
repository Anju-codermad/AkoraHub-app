-- ============================================================
-- AkoraHub - Patch Phase 187 : CORRECTIF CRITIQUE — falsification du
-- prix des achats Formation (formation_purchases.amount /
-- course_purchases.amount)
--
-- Trouvé le 03/09/2026 depuis la conversation du dépôt du site web
-- (groupe-akora-site), en miroir du correctif Phase 154 (falsification
-- du prix des commandes) : `formation_purchases_insert_own` (phase45)
-- et `course_purchases_insert_own` (phase50) vérifient seulement que
-- customer_id = auth.uid() et status = 'en_attente', jamais que
-- `amount` correspond au vrai prix. Confirmé dans le code du site
-- (site/formation.html) : le prix (dégressif par palier pour les
-- matières premières, fixe pour les cours) est calculé côté CLIENT et
-- envoyé tel quel — un client authentifié pouvait donc soumettre une
-- vraie demande d'achat à n'importe quel montant en appelant l'API
-- directement. Risque atténué en pratique par la vérification humaine
-- du staff avant validation (status 'en_attente' -> 'validee'), mais le
-- prix doit être recalculé côté serveur plutôt que fait confiance au
-- client, mêmes principes que Phase 154.
--
-- Complexité propre aux matières premières (contrairement à Phase 154 /
-- order_items) : le palier de prix dépend du nombre TOTAL de produits
-- de l'achat EN COURS (voir Phase 45 : "le palier atteint... s'applique
-- à TOUS les produits de l'achat en cours"), pas du produit ligne par
-- ligne. Un trigger BEFORE INSERT FOR EACH ROW classique (comme
-- enforce_order_item_price en Phase 154) ne peut pas voir les autres
-- lignes du même lot au moment où il s'exécute pour la première d'entre
-- elles — il faut un trigger AFTER INSERT/UPDATE FOR EACH STATEMENT
-- avec table de transition (REFERENCING NEW TABLE, dispo depuis PG10)
-- pour voir le lot complet une fois inséré, puis corriger `amount` sur
-- tout le lot d'un coup.
--
-- ⚠️ INSERT ... ON CONFLICT DO UPDATE (utilisé par le site pour la
-- re-soumission après refus, `on_conflict=customer_id,raw_material_id`
-- avec `Prefer: resolution=merge-duplicates`) déclenche le trigger
-- UPDATE pour les lignes en conflit, PAS le trigger INSERT — d'où les
-- DEUX triggers ci-dessous (un par événement) plutôt qu'un seul.
--
-- ⚠️ Les fonctions AFTER STATEMENT ci-dessous font elles-mêmes un UPDATE
-- sur la table qui les a déclenchées : la garde `amount is distinct
-- from` limite la récursion à une correction ininterrompue (l'appel
-- suivant du trigger constate que amount est déjà correct, ne fait
-- aucune ligne, la boucle interne ne trouve rien à traiter et
-- s'arrête) — pas de boucle infinie, comportement standard pour ce
-- genre de trigger auto-correcteur.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (create or replace, drop trigger if exists).
-- ============================================================

-- ------------------------------------------------------------
-- 1) course_purchases : prix fixe par cours, pas de logique de palier
-- —  même principe que enforce_order_item_price (Phase 154), un simple
-- trigger BEFORE INSERT OR UPDATE FOR EACH ROW suffit (fonctionne aussi
-- bien pour un vrai INSERT que pour la branche ON CONFLICT DO UPDATE).
-- ------------------------------------------------------------
create or replace function public.enforce_course_purchase_price()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price numeric;
begin
  if public.current_role_is_staff() then
    return new;
  end if;
  select price into v_price
    from public.formation_courses
    where id = new.course_id;
  new.amount := coalesce(v_price, 0);
  return new;
end;
$$;

drop trigger if exists enforce_course_purchase_price_trigger on public.course_purchases;
create trigger enforce_course_purchase_price_trigger
  before insert or update on public.course_purchases
  for each row execute function public.enforce_course_purchase_price();

-- ------------------------------------------------------------
-- 2) formation_purchases (matières premières) : prix dégressif par
-- palier de quantité CUMULÉE (déjà validé + tout le lot en cours) — voir
-- l'explication en tête de fichier sur pourquoi ceci doit être un
-- trigger AFTER STATEMENT plutôt que BEFORE ROW.
-- ------------------------------------------------------------

-- 2a) Après un vrai INSERT (nouveaux produits, jamais achetés avant)
create or replace function public.enforce_formation_purchase_batch_price_ins()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_batch record;
  v_owned_count int;
  v_cumulative int;
  v_price numeric;
begin
  if public.current_role_is_staff() then
    return null;
  end if;

  for v_batch in
    select customer_id, batch_id, count(*) as batch_count
    from new_rows
    group by customer_id, batch_id
  loop
    select count(*) into v_owned_count
      from public.formation_purchases
      where customer_id = v_batch.customer_id and status = 'validee';

    v_cumulative := v_owned_count + v_batch.batch_count;

    select price into v_price
      from public.formation_pricing_tiers
      where min_quantity <= v_cumulative
      order by min_quantity desc
      limit 1;

    if v_price is not null then
      update public.formation_purchases
        set amount = v_price
        where customer_id = v_batch.customer_id
          and batch_id = v_batch.batch_id
          and amount is distinct from v_price;
    end if;
  end loop;
  return null;
end;
$$;

drop trigger if exists enforce_formation_purchase_batch_price_ins_trigger on public.formation_purchases;
create trigger enforce_formation_purchase_batch_price_ins_trigger
  after insert on public.formation_purchases
  referencing new table as new_rows
  for each statement
  execute function public.enforce_formation_purchase_batch_price_ins();

-- 2b) Après un UPDATE (re-soumission après refus, via ON CONFLICT DO
-- UPDATE — voir avertissement en tête de fichier). Restreint aux lignes
-- redevenues 'en_attente' (re-soumission client) : une validation/refus
-- par le staff passe aussi par UPDATE mais avec un autre statut, donc
-- ignorée par le filtre `where status = 'en_attente'` en plus de la
-- garde current_role_is_staff() ci-dessus.
create or replace function public.enforce_formation_purchase_batch_price_upd()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_batch record;
  v_owned_count int;
  v_cumulative int;
  v_price numeric;
begin
  if public.current_role_is_staff() then
    return null;
  end if;

  for v_batch in
    select customer_id, batch_id, count(*) as batch_count
    from new_rows
    where status = 'en_attente'
    group by customer_id, batch_id
  loop
    select count(*) into v_owned_count
      from public.formation_purchases
      where customer_id = v_batch.customer_id and status = 'validee';

    v_cumulative := v_owned_count + v_batch.batch_count;

    select price into v_price
      from public.formation_pricing_tiers
      where min_quantity <= v_cumulative
      order by min_quantity desc
      limit 1;

    if v_price is not null then
      update public.formation_purchases
        set amount = v_price
        where customer_id = v_batch.customer_id
          and batch_id = v_batch.batch_id
          and status = 'en_attente'
          and amount is distinct from v_price;
    end if;
  end loop;
  return null;
end;
$$;

drop trigger if exists enforce_formation_purchase_batch_price_upd_trigger on public.formation_purchases;
create trigger enforce_formation_purchase_batch_price_upd_trigger
  after update on public.formation_purchases
  referencing new table as new_rows
  for each statement
  execute function public.enforce_formation_purchase_batch_price_upd();

-- ------------------------------------------------------------
-- Non couvert par ce patch (résiduel, à surveiller) :
-- - Si un client soumet volontairement plusieurs petits lots successifs
--   au lieu d'un seul gros lot, chaque lot est facturé au palier
--   correspondant à sa propre taille cumulée au moment de l'achat — ce
--   n'est pas un contournement du prix (le total payé pour atteindre un
--   palier donné reste cohérent dans le temps), juste le comportement
--   déjà voulu par Phase 45 pour un achat étalé dans le temps.
-- - Aucun changement requis côté site (site/formation.html) ni côté app
--   Flutter : les deux continuent d'envoyer `amount` comme avant, ce
--   trigger le corrige silencieusement si besoin, exactement comme
--   Phase 154 pour les commandes.
-- ============================================================
