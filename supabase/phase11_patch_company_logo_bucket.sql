-- ============================================================
-- Akora Fanadiovana - Patch Phase 11 : bucket Storage pour le logo entreprise
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : l'utilisateur a signalé que l'écran "Profil entreprise" ne
-- fonctionnait pas. En vérifiant le code, le bouton "changer le logo"
-- ouvrait bien un sélecteur de photo, mais la photo choisie n'était
-- jamais réellement sauvegardée (commentaire trouvé dans le code :
-- "In real implementation, upload image and update businessData" —
-- un reste de scaffolding jamais terminé). Ce script crée le bucket
-- nécessaire ; le code Flutter est corrigé séparément pour uploader
-- réellement le fichier choisi.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('company', 'company', true)
on conflict (id) do nothing;

drop policy if exists "company_bucket_public_read" on storage.objects;
create policy "company_bucket_public_read" on storage.objects
  for select using (bucket_id = 'company');

drop policy if exists "company_bucket_staff_write" on storage.objects;
create policy "company_bucket_staff_write" on storage.objects
  for insert with check (bucket_id = 'company' and public.current_role_is_staff());

drop policy if exists "company_bucket_staff_update" on storage.objects;
create policy "company_bucket_staff_update" on storage.objects
  for update using (bucket_id = 'company' and public.current_role_is_staff());
