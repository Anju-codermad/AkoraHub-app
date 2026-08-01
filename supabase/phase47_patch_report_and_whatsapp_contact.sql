-- ============================================================
-- AkoraHub - Patch Phase 47 : signaler une publication + numéro
-- WhatsApp visible en option (Communauté)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01/08) : deux améliorations de la Communauté (ex-Mur) mises
-- de côté lors d'une discussion précédente, construites maintenant.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Signalements de publications — un signalement par (client, post),
-- lecture/traitement réservés au staff. Best-effort : un client ne peut
-- jamais lire les signalements (les siens ou ceux des autres), pour ne
-- pas transformer ça en outil de harcèlement ("untel a signalé mon
-- post").
-- ------------------------------------------------------------
create table if not exists public.post_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  status text not null default 'en_attente' check (status in ('en_attente','traite')),
  created_at timestamptz not null default now(),
  unique (post_id, reporter_id)
);

create index if not exists post_reports_status_idx
  on public.post_reports (status);

alter table public.post_reports enable row level security;

drop policy if exists "post_reports_insert_own" on public.post_reports;
create policy "post_reports_insert_own" on public.post_reports
  for insert with check (reporter_id = auth.uid());

drop policy if exists "post_reports_select_staff" on public.post_reports;
create policy "post_reports_select_staff" on public.post_reports
  for select using (public.current_role_is_staff());

drop policy if exists "post_reports_update_staff" on public.post_reports;
create policy "post_reports_update_staff" on public.post_reports
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- Notifie le staff (Admin/Commercial) dès qu'un signalement arrive —
-- réutilise la fonction générique déjà en place (Phase 17).
drop trigger if exists on_new_post_report_push on public.post_reports;
create trigger on_new_post_report_push
  after insert on public.post_reports
  for each row execute procedure public.notify_push_on_new_message();

-- ------------------------------------------------------------
-- 2) Numéro visible dans la Communauté (opt-in, désactivé par défaut).
-- Le profil public (phase9_patch_public_profiles.sql) exposait
-- volontairement AUCUNE info de contact — on ajoute le téléphone,
-- uniquement pour les clients qui l'ont explicitement activé eux-mêmes
-- (réglage dans Confidentialité et sécurité).
-- ------------------------------------------------------------
alter table public.profiles
  add column if not exists share_phone_publicly boolean not null default false;

create or replace view public.public_profiles as
select
  id,
  full_name,
  company_name,
  client_type,
  avatar_url,
  case when share_phone_publicly then phone else null end as phone
from public.profiles;

grant select on public.public_profiles to authenticated, anon;
