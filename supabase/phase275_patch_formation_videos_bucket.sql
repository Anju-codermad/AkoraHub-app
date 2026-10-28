-- ============================================================
-- AkoraHub - Patch Phase 275 : bucket de stockage pour les vidéos
-- de formation Académie (upload direct depuis l'app)
--
-- Demande explicite (28/10) : pouvoir uploader plusieurs vidéos par
-- formation directement depuis le téléphone, sans dépendre d'un
-- hébergement externe (YouTube/Drive) — voir le nouveau bouton
-- "Uploader une vidéo depuis le téléphone" dans
-- formation_course_modules_management.dart.
--
-- Même principe que le bucket `raw-materials` (phase40) : public en
-- lecture (nécessaire pour que VideoPlayerController.networkUrl lise
-- l'URL directement, sans URL signée), écriture réservée au staff. La
-- vraie protection du contenu payant reste la RLS de
-- `formation_course_modules` (un client qui n'a pas acheté le cours
-- ne voit jamais la ligne contenant cette URL, donc ne peut pas la
-- découvrir) — cohérent avec `document_url`, qui n'était déjà pas
-- protégé autrement.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

insert into storage.buckets (id, name, public)
values ('formation-videos', 'formation-videos', true)
on conflict (id) do nothing;

drop policy if exists "formation_videos_bucket_public_read" on storage.objects;
create policy "formation_videos_bucket_public_read" on storage.objects
  for select using (bucket_id = 'formation-videos');

drop policy if exists "formation_videos_bucket_staff_write" on storage.objects;
create policy "formation_videos_bucket_staff_write" on storage.objects
  for insert with check (bucket_id = 'formation-videos' and public.current_role_is_staff());

drop policy if exists "formation_videos_bucket_staff_update" on storage.objects;
create policy "formation_videos_bucket_staff_update" on storage.objects
  for update using (bucket_id = 'formation-videos' and public.current_role_is_staff());

drop policy if exists "formation_videos_bucket_staff_delete" on storage.objects;
create policy "formation_videos_bucket_staff_delete" on storage.objects
  for delete using (bucket_id = 'formation-videos' and public.current_role_is_staff());
