-- ============================================================
-- AkoraHub - Patch Phase 186 : demandes de contact depuis le site web
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (27/08, demande explicite) : le site web n'a pas de compte
-- client ni de panier (ce n'est pas son rôle, voir SITE_APP_SYNC.md) —
-- mais un visiteur intéressé n'a aujourd'hui aucun moyen de laisser ses
-- coordonnées sans passer par Messenger. Un petit formulaire "Demander
-- un devis / être rappelé" (nom + téléphone + message, sans compte)
-- capture ces contacts sans avoir à reconstruire tout un système de
-- commande côté site.
-- ============================================================

create table if not exists public.website_leads (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  message text,
  source_page text,
  status text not null default 'nouveau'
    check (status in ('nouveau', 'contacte', 'traite')),
  created_at timestamptz not null default now()
);

alter table public.website_leads enable row level security;

-- Le site web n'a pas de compte connecté (visiteur anonyme) : la
-- soumission du formulaire doit pouvoir insérer sans authentification.
drop policy if exists "website_leads_insert_public" on public.website_leads;
create policy "website_leads_insert_public" on public.website_leads
  for insert with check (true);

drop policy if exists "website_leads_select_staff" on public.website_leads;
create policy "website_leads_select_staff" on public.website_leads
  for select using (public.current_role_is_staff());

drop policy if exists "website_leads_update_staff" on public.website_leads;
create policy "website_leads_update_staff" on public.website_leads
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
