-- ============================================================
-- AkoraHub - Patch Phase 217 : tarification sécurisée + paiement réel
-- de l'acompte pour le diagnostic qualité de l'eau (site web)
--
-- Contexte (05/09) : le formulaire "Demander un diagnostic de votre
-- eau" (site web, services.html) calcule `estimated_total`/
-- `deposit_amount` ENTIÈREMENT côté navigateur (constantes JS
-- CATEGORIES/PACK_PRICES) et les envoie tels quels vers
-- `website_service_requests` (phase214/215), dont la policy d'insertion
-- est ouverte à tout le monde (`insert with check (true)`) — rien
-- n'empêche un visiteur d'appeler l'API REST directement avec un
-- `estimated_total`/`deposit_amount` falsifiés. Même classe de faille
-- que phase154 (order_items.unit_price). De plus, "Acompte à régler en
-- ligne (50%)" n'était jusqu'ici que du texte : aucun paiement n'était
-- réellement déclenché.
--
-- Ce patch :
--   1) Migre la grille de prix (tests à la carte + forfaits) dans deux
--      tables, seule source de vérité désormais (le site pourra les lire
--      par SELECT public pour l'affichage, au lieu de dupliquer les prix
--      en dur dans son JS comme c'est le cas ailleurs — voir
--      SITE_APP_SYNC.md sur les risques de duplication).
--   2) Ajoute un trigger BEFORE INSERT/UPDATE qui recalcule
--      `estimated_total`/`deposit_amount` server-side à partir de
--      `selected_pack`/`requested_analyses` — même principe que
--      `enforce_order_item_price` (phase154), avec le même
--      contournement pour le staff (ajustement manuel possible, requis
--      pour le forfait "ong_communaute" qui reste "sur devis").
--   3) Ajoute les colonnes de suivi de paiement (mêmes noms que sur
--      `orders`, phase38/59, pour réutiliser telles quelles les mêmes
--      conventions côté Edge Functions) + `claimed_by` : le formulaire
--      reste anonyme à la soumission, mais payer l'acompte exige que le
--      client (désormais avec un compte, voir le tunnel d'achat en
--      cours de construction) associe sa demande à son compte via la
--      fonction `claim_water_diagnostic_request` ci-dessous (vérifie le
--      téléphone saisi au formulaire — évite qu'un compte quelconque ne
--      s'approprie la demande de quelqu'un d'autre).
--
-- Comme papi-payment-notification/fiveonepay-payment-notification
-- (Edge Functions) doivent aussi être patchées pour reconnaître une
-- référence `website_service_requests` en plus de `orders` — voir les
-- fichiers correspondants dans supabase/functions/, patchés
-- séparément dans la même phase.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New
-- query. Idempotent (create if not exists / on conflict do update).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Grille de prix — migration des constantes JS actuelles de
-- services.html (CATEGORIES/PACK_PRICES), inchangées.
-- ------------------------------------------------------------
create table if not exists public.water_analysis_tests (
  slug text primary key,
  category text not null
    check (category in ('organoleptique','chimique','toxique','microbiologie','autres')),
  label text not null,
  price numeric not null
);

alter table public.water_analysis_tests enable row level security;

drop policy if exists "water_analysis_tests_select_all" on public.water_analysis_tests;
create policy "water_analysis_tests_select_all" on public.water_analysis_tests
  for select using (true);

drop policy if exists "water_analysis_tests_write_staff" on public.water_analysis_tests;
create policy "water_analysis_tests_write_staff" on public.water_analysis_tests
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

insert into public.water_analysis_tests (slug, category, label, price) values
  ('ph', 'organoleptique', 'pH', 33808),
  ('temperature', 'organoleptique', 'Température', 12690),
  ('turbidite', 'organoleptique', 'Turbidité', 35298),
  ('conductivite', 'organoleptique', 'Conductivité', 21808),
  ('couleur', 'organoleptique', 'Couleur', 34290),
  ('odeur', 'organoleptique', 'Odeur', 34290),
  ('mes', 'organoleptique', 'MES (matières en suspension)', 44820),
  ('calcium', 'chimique', 'Calcium', 61520),
  ('magnesium', 'chimique', 'Magnésium', 65640),
  ('sulfates', 'chimique', 'Sulfates', 50760),
  ('saturation_oxygene_dissous', 'chimique', 'Saturation oxygène dissous (%)', 33808),
  ('durete_totale', 'chimique', 'Dureté totale', 65920),
  ('chlore_libre', 'chimique', 'Chlore libre', 46624),
  ('ammonium', 'chimique', 'Ammonium', 71940),
  ('nitrite', 'chimique', 'Nitrite', 48600),
  ('azote_ammoniacale', 'chimique', 'Azote ammoniacale', 71940),
  ('manganese', 'chimique', 'Manganèse', 58770),
  ('fer_total', 'chimique', 'Fer total', 44786),
  ('phosphore', 'chimique', 'Phosphore', 53100),
  ('zinc', 'chimique', 'Zinc', 53280),
  ('cuivre', 'chimique', 'Cuivre', 49140),
  ('aluminium', 'chimique', 'Aluminium', 71540),
  ('nitrate', 'chimique', 'Nitrate', 53460),
  ('arsenic', 'toxique', 'Arsenic', 164000),
  ('chrome_total', 'toxique', 'Chrome total', 92480),
  ('cyanure', 'toxique', 'Cyanure', 75400),
  ('nickel', 'toxique', 'Nickel', 61260),
  ('test_3germes', 'microbiologie',
    'TEST 3GERMES — E.Coli, Entérocoques, Coliformes fécaux et totaux (avec quantification)', 377400),
  ('oxygene_dissous', 'autres', 'Oxygène dissous', 33808),
  ('tds', 'autres', 'Solides dissous totaux (TDS)', 42372),
  ('orp', 'autres', 'Potentiel oxydo-réduction (ORP)', 14220),
  ('salinite', 'autres', 'Salinité', 42372),
  ('chlore_total', 'autres', 'Chlore total', 46304),
  ('ferreux', 'autres', 'Ferreux', 44586),
  ('ferrique', 'autres', 'Ferrique', 44586),
  ('fluorures', 'autres', 'Fluorures', 103200),
  ('mineralisation_globale', 'autres', 'Minéralisation globale', 33808)
on conflict (slug) do update set
  category = excluded.category, label = excluded.label, price = excluded.price;

create table if not exists public.water_analysis_packs (
  slug text primary key,
  label text not null,
  price numeric -- null = "sur devis" (ong_communaute)
);

alter table public.water_analysis_packs enable row level security;

drop policy if exists "water_analysis_packs_select_all" on public.water_analysis_packs;
create policy "water_analysis_packs_select_all" on public.water_analysis_packs
  for select using (true);

drop policy if exists "water_analysis_packs_write_staff" on public.water_analysis_packs;
create policy "water_analysis_packs_write_staff" on public.water_analysis_packs
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

insert into public.water_analysis_packs (slug, label, price) values
  ('eau_de_boisson', 'Pack Eau de boisson', 609706),
  ('forage_complet', 'Pack Forage complet', 1013024),
  ('ong_communaute', 'Pack ONG / Communauté', null)
on conflict (slug) do update set label = excluded.label, price = excluded.price;

-- ------------------------------------------------------------
-- 2) Colonnes de suivi de l'acompte + rattachement à un compte —
-- mêmes noms que sur `orders` (phase38/phase59) pour réutiliser telles
-- quelles les mêmes conventions Edge Function.
-- ------------------------------------------------------------
alter table public.website_service_requests
  add column if not exists claimed_by uuid references auth.users(id),
  add column if not exists payment_method text
    check (payment_method is null or payment_method in ('mvola','orange_money','airtel_money')),
  add column if not exists payment_status text not null default 'en_attente'
    check (payment_status in ('en_attente','paye','echoue')),
  add column if not exists papi_notification_token text,
  add column if not exists papi_payment_link text,
  add column if not exists fiveonepay_reference text,
  add column if not exists fiveonepay_payment_url text;

create index if not exists website_service_requests_claimed_by_idx
  on public.website_service_requests (claimed_by);

-- ------------------------------------------------------------
-- 3) Trigger anti-falsification — même principe que
-- enforce_order_item_price (phase154) : recalcule le prix server-side
-- pour tout appelant non-staff, staff garde la main (nécessaire pour le
-- forfait "ong_communaute", qui reste "sur devis").
-- ------------------------------------------------------------
create or replace function public.enforce_water_diagnostic_pricing()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pack_price numeric;
  v_tests_sum numeric;
  v_has_micro boolean;
  v_flacon_price constant numeric := 24000;
begin
  if new.service_slug is distinct from 'diagnostic-eau' then
    return new;
  end if;
  if public.current_role_is_staff() then
    return new;
  end if;

  if new.selected_pack is not null then
    select price into v_pack_price
      from public.water_analysis_packs where slug = new.selected_pack;
    new.estimated_total := v_pack_price;
  else
    select coalesce(sum(price), 0) into v_tests_sum
      from public.water_analysis_tests
      where slug = any(coalesce(new.requested_analyses, array[]::text[]));
    select exists (
      select 1 from public.water_analysis_tests
      where slug = any(coalesce(new.requested_analyses, array[]::text[]))
        and category = 'microbiologie'
    ) into v_has_micro;
    if v_has_micro then
      v_tests_sum := v_tests_sum + v_flacon_price;
    end if;
    new.estimated_total := v_tests_sum;
  end if;

  new.deposit_amount := case
    when new.estimated_total is null then null
    else round(new.estimated_total / 2)
  end;

  return new;
end;
$$;

drop trigger if exists enforce_water_diagnostic_pricing_trigger on public.website_service_requests;
create trigger enforce_water_diagnostic_pricing_trigger
  before insert or update on public.website_service_requests
  for each row execute function public.enforce_water_diagnostic_pricing();

-- ------------------------------------------------------------
-- 4) Rattachement d'une demande anonyme à un compte client — fonction
-- SECURITY DEFINER plutôt qu'une policy UPDATE ouverte : la seule
-- action permise est de poser `claimed_by` sur SA PROPRE demande, et
-- seulement si le téléphone fourni correspond à celui du formulaire
-- d'origine (empêche un compte quelconque de s'approprier la demande
-- de quelqu'un d'autre juste en devinant/énumérant des uuid).
-- ------------------------------------------------------------
create or replace function public.claim_water_diagnostic_request(
  p_request_id uuid, p_phone text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Authentification requise';
  end if;

  update public.website_service_requests
    set claimed_by = v_uid
    where id = p_request_id
      and service_slug = 'diagnostic-eau'
      and claimed_by is null
      and phone = p_phone;

  if not found then
    raise exception 'Demande introuvable, déjà associée à un compte, ou téléphone incorrect';
  end if;
end;
$$;

grant execute on function public.claim_water_diagnostic_request(uuid, text) to authenticated;
