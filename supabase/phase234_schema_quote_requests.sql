-- ============================================================
-- AkoraHub - Patch Phase 234 : demandes de devis produit ("Prix sur
-- devis") pour les piliers B2B/matières premières du site web —
-- demande explicite de la propriétaire (10/09) : plutôt que d'afficher
-- un prix fixe pour Akora Pro / Akora Coatings / Akora NutriSource
-- (prix souvent lié au volume/à la négociation), le client clique
-- "Demander un devis" sur la fiche produit et la demande arrive ici.
--
-- Distincte de `website_service_requests` (phase214, anonyme, un
-- service générique type diagnostic-eau) : une demande de devis est
-- liée à un produit précis ET à un compte client connecté (le site et
-- l'app partagent déjà la même base Supabase — demande explicite que
-- le suivi apparaisse dans le compte AkoraHub du client), donc
-- `customer_id` est obligatoire (auth.uid()), pas anonyme.
--
-- Pas de colonnes nom/téléphone/e-mail dénormalisées : comme `orders`,
-- on rejoint `profiles`/`auth.users` via `customer_id` pour les
-- coordonnées du client au moment du traitement par le staff.
--
-- Script idempotent (create table if not exists, on conflict do
-- nothing). À exécuter une seule fois : Supabase Dashboard -> SQL
-- Editor -> New query.
-- ============================================================

create table if not exists public.quote_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  product_name text not null, -- snapshot : le produit peut être renommé/retiré ensuite
  business_unit_id uuid references public.business_units(id),
  quantity numeric,
  quantity_unit text,
  message text,
  status text not null default 'nouveau'
    check (status in ('nouveau','traite','envoye')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists quote_requests_customer_idx
  on public.quote_requests (customer_id);
create index if not exists quote_requests_status_idx
  on public.quote_requests (status);

alter table public.quote_requests enable row level security;

drop policy if exists "quote_requests_select_own_or_staff" on public.quote_requests;
create policy "quote_requests_select_own_or_staff" on public.quote_requests
  for select using (auth.uid() = customer_id or public.current_role_is_staff());

drop policy if exists "quote_requests_insert_own" on public.quote_requests;
create policy "quote_requests_insert_own" on public.quote_requests
  for insert with check (auth.uid() = customer_id);

drop policy if exists "quote_requests_update_staff" on public.quote_requests;
create policy "quote_requests_update_staff" on public.quote_requests
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- updated_at : trigger dédié, même pattern que touch_cart_snapshot_updated_at
-- (Phase 232) — pas de fonction générique dans ce projet.
create or replace function public.touch_quote_request_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists set_quote_requests_updated_at on public.quote_requests;
create trigger set_quote_requests_updated_at
  before update on public.quote_requests
  for each row execute procedure public.touch_quote_request_updated_at();

-- Notification push au staff dès qu'une demande arrive — même
-- fonction générique que Phase 216/17/78/176 (envoie juste TG_TABLE_NAME
-- + la ligne insérée à l'Edge Function send-push-notification, qui gère
-- le cas "quote_requests" — voir le patch associé de ce fichier).
drop trigger if exists on_new_quote_request_push on public.quote_requests;
create trigger on_new_quote_request_push
  after insert on public.quote_requests
  for each row execute procedure public.notify_push_on_new_message();

-- Garde-fou : prévenir si la fonction generique attendue n'existe pas
-- (ex. exécuté sur une base qui n'a jamais eu les phases 17/78/176).
do $$
begin
  if not exists (
    select 1 from pg_proc where proname = 'notify_push_on_new_message'
  ) then
    raise notice 'Fonction notify_push_on_new_message() introuvable — le trigger de notification a été créé mais ne fonctionnera pas tant qu''elle n''existe pas (voir phase17_schema.sql).';
  end if;
end $$;

-- Vérification
select table_name from information_schema.tables
where table_schema = 'public' and table_name = 'quote_requests';
