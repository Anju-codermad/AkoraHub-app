-- ============================================================
-- AkoraHub - Patch Phase 214 : demandes de service structurées depuis
-- le site web — premier cas d'usage "Diagnostic qualité de l'eau"
-- (demande explicite de la propriétaire le 05/09/2026).
--
-- Distincte de `website_leads` (phase186, contact générique
-- nom+téléphone+message) : ici on capture des champs structurés
-- propres à un service précis (type d'eau, mode de prélèvement,
-- analyses souhaitées...). Le champ `service_slug` permet de
-- réutiliser cette même table pour de futurs services du site (ex.
-- future demande "Puits") sans nouvelle migration à chaque fois —
-- les champs non pertinents pour un service donné restent null.
--
-- Anonyme comme website_leads : le site n'a pas de compte client,
-- l'insertion doit fonctionner sans authentification.
-- ============================================================

create table if not exists public.website_service_requests (
  id uuid primary key default gen_random_uuid(),
  service_slug text not null,
  name text not null,
  phone text not null,
  email text,
  water_type text
    check (water_type is null or water_type in ('puits','forage','reseau')),
  sampling_method text
    check (sampling_method is null or sampling_method in ('descente','apport')),
  address text,
  requested_analyses text[],
  message text,
  source_page text,
  status text not null default 'nouveau'
    check (status in ('nouveau','contacte','traite')),
  created_at timestamptz not null default now()
);

create index if not exists website_service_requests_slug_idx
  on public.website_service_requests (service_slug);
create index if not exists website_service_requests_status_idx
  on public.website_service_requests (status);

alter table public.website_service_requests enable row level security;

drop policy if exists "website_service_requests_insert_public" on public.website_service_requests;
create policy "website_service_requests_insert_public" on public.website_service_requests
  for insert with check (true);

drop policy if exists "website_service_requests_select_staff" on public.website_service_requests;
create policy "website_service_requests_select_staff" on public.website_service_requests
  for select using (public.current_role_is_staff());

drop policy if exists "website_service_requests_update_staff" on public.website_service_requests;
create policy "website_service_requests_update_staff" on public.website_service_requests
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
