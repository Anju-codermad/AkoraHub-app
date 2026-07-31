-- ============================================================
-- AkoraHub - Patch Phase 36 : Abonnement aux notifications par catégorie
-- de produit
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande (31/07) : un client peut s'abonner à une catégorie précise d'un
-- pilier (ex: "Anti-nuisibles" -> "Insecticides") et recevoir une
-- notification push quand un nouveau produit y est ajouté. Distinct du
-- système de sons par catégorie de NOTIFICATION (message/devis/commande,
-- phase24) : ici on ajoute une 4e catégorie de notification ("produit")
-- pour la partie son/canal, ET une nouvelle table d'abonnements pour
-- savoir QUI doit recevoir CETTE notification précise (contrairement à
-- message/devis/commande qui ciblent toujours un destinataire déjà connu
-- - l'auteur d'une commande, l'autre partie d'une conversation).
--
-- ⚠️ Avant d'exécuter ce script : remplace `<WEBHOOK_SECRET>` ci-dessous
-- par la même valeur secrète déjà utilisée pour les triggers messages/
-- commandes/devis (phase17/phase18) — c'est le secret configuré dans
-- Edge Functions -> send-push-notification -> Manage secrets ->
-- WEBHOOK_SECRET. Sans la bonne valeur, la fonction Edge rejettera l'appel
-- (401) et aucune notification ne partira, mais rien d'autre ne casse.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Table des abonnements : qui suit quelle catégorie de quel pilier.
-- ------------------------------------------------------------
create table if not exists public.product_category_subscriptions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  business_unit_id uuid not null references public.business_units(id) on delete cascade,
  category_name text not null,
  created_at timestamptz not null default now(),
  unique (customer_id, business_unit_id, category_name)
);

create index if not exists product_category_subscriptions_lookup_idx
  on public.product_category_subscriptions (business_unit_id, category_name);

alter table public.product_category_subscriptions enable row level security;

drop policy if exists "product_category_subscriptions_own_select" on public.product_category_subscriptions;
create policy "product_category_subscriptions_own_select" on public.product_category_subscriptions
  for select using (auth.uid() = customer_id);

drop policy if exists "product_category_subscriptions_own_insert" on public.product_category_subscriptions;
create policy "product_category_subscriptions_own_insert" on public.product_category_subscriptions
  for insert with check (auth.uid() = customer_id);

drop policy if exists "product_category_subscriptions_own_delete" on public.product_category_subscriptions;
create policy "product_category_subscriptions_own_delete" on public.product_category_subscriptions
  for delete using (auth.uid() = customer_id);

-- ------------------------------------------------------------
-- 2) 4e catégorie de notification ("produit") : même plomberie que
-- message/devis/commande (phase24 + phase32) pour le choix du son.
-- ------------------------------------------------------------
alter table public.profiles
  add column if not exists notification_sound_produit text not null default 'notif_bulle_eau';

alter table public.notification_sound_catalog
  drop constraint if exists notification_sound_catalog_category_check;
alter table public.notification_sound_catalog
  add constraint notification_sound_catalog_category_check
  check (category in ('message','devis','commande','produit'));

insert into public.notification_sound_catalog (category, sound_id, sort_order, enabled)
select 'produit', snd.id, snd.ord, true
from (
  values
    ('notif_message_classique', 0),
    ('notif_message_bulle', 1),
    ('notif_message_brillant', 2),
    ('notif_message_doux', 3),
    ('notif_message_fun', 4),
    ('notif_devis_classique', 5),
    ('notif_devis_chaleureux', 6),
    ('notif_devis_serieux', 7),
    ('notif_devis_discret', 8),
    ('notif_devis_fun', 9),
    ('notif_commande_classique', 10),
    ('notif_commande_rapide', 11),
    ('notif_commande_festif', 12),
    ('notif_commande_doux', 13),
    ('notif_commande_fun', 14),
    ('notif_bulle_eau', 15),
    ('notif_bulle_savon', 16),
    ('notif_bulle_liquide', 17),
    ('notif_bulles_profondes', 18),
    ('notif_radar', 19)
) as snd(id, ord)
on conflict (category, sound_id) do nothing;

-- ------------------------------------------------------------
-- 3) Trigger : notifie à chaque nouveau produit visible (même modèle que
-- phase17/phase18 — un seul appel réseau vers l'Edge Function existante,
-- qui décide ensuite qui prévenir en lisant la table ci-dessus).
-- ------------------------------------------------------------
create or replace function public.notify_push_on_new_product()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', TG_TABLE_NAME,
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_new_product_push on public.products;
create trigger on_new_product_push
  after insert on public.products
  for each row
  when (NEW.visibility = true)
  execute procedure public.notify_push_on_new_product();
