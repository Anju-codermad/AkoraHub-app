-- ============================================================
-- AkoraHub - Patch Phase 65 : nouveau menu "Services" côté client —
-- demande de service (installation, intervention, consultation...),
-- distinct d'une commande de produit ou d'un devis.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  business_unit_id uuid references public.business_units(id),
  title text not null,
  description text not null,
  preferred_date date,
  address text,
  status text not null default 'nouvelle'
    check (status in ('nouvelle','en_cours','traitee','refusee')),
  staff_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists service_requests_customer_idx
  on public.service_requests (customer_id);
create index if not exists service_requests_status_idx
  on public.service_requests (status);

alter table public.service_requests enable row level security;

drop policy if exists "service_requests_insert_own" on public.service_requests;
create policy "service_requests_insert_own" on public.service_requests
  for insert with check (customer_id = auth.uid());

drop policy if exists "service_requests_select_own_or_staff" on public.service_requests;
create policy "service_requests_select_own_or_staff" on public.service_requests
  for select using (customer_id = auth.uid() or public.current_role_is_staff());

-- Le client ne peut pas modifier sa demande après envoi (pas de bouton
-- "annuler" pour ce premier lot, contrairement aux commandes) — seul le
-- staff met à jour le statut / ajoute des notes internes.
drop policy if exists "service_requests_update_staff" on public.service_requests;
create policy "service_requests_update_staff" on public.service_requests
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- Notifie le staff (Admin/Commercial) dès qu'une demande arrive —
-- réutilise la fonction générique déjà en place (Phase 17), voir
-- supabase/functions/send-push-notification/index.ts pour le cas
-- "service_requests" ajouté côté Edge Function.
drop trigger if exists on_new_service_request_push on public.service_requests;
create trigger on_new_service_request_push
  after insert on public.service_requests
  for each row execute procedure public.notify_push_on_new_message();
