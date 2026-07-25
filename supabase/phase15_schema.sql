-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 15
-- Stockage réel du logo entreprise (jusqu'ici, le sélecteur de logo
-- dans "Profil entreprise" choisissait une image mais ne l'uploadait
-- jamais nulle part — commentaire "In real implementation, upload
-- image..." trouvé dans le code, jamais implémenté).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

insert into storage.buckets (id, name, public)
values ('company-logo', 'company-logo', true)
on conflict (id) do nothing;

drop policy if exists "company_logo_public_read" on storage.objects;
create policy "company_logo_public_read" on storage.objects
  for select using (bucket_id = 'company-logo');

drop policy if exists "company_logo_staff_write" on storage.objects;
create policy "company_logo_staff_write" on storage.objects
  for insert with check (
    bucket_id = 'company-logo' and public.current_role_is_staff()
  );

drop policy if exists "company_logo_staff_update" on storage.objects;
create policy "company_logo_staff_update" on storage.objects
  for update using (
    bucket_id = 'company-logo' and public.current_role_is_staff()
  );
