-- ============================================================
-- AkoraHub - Patch Phase 275 : bucket de stockage PRIVÉ pour les
-- vidéos/photos de formation Académie (upload direct depuis l'app)
--
-- Demande explicite (28/10) : pouvoir uploader plusieurs vidéos par
-- formation directement depuis le téléphone, sans dépendre d'un
-- hébergement externe (YouTube/Drive) — voir le bouton "Uploader une
-- vidéo depuis le téléphone" dans formation_course_modules_management.dart.
--
-- Révisé le même jour (protection maximale demandée explicitement,
-- "sans donner beaucoup de temps") : bucket PRIVÉ, pas public comme la
-- première version. Chaque lecture passe par le SDK Supabase
-- authentifié (`storage.from(...).download(path)`, voir
-- course_content_screen.dart) — jamais par une URL publique ou signée
-- à durée de vie. Un lien intercepté ne sert donc à RIEN : il faut la
-- session authentifiée ET l'achat validé du cours à CHAQUE requête,
-- pas seulement dans une fenêtre de temps.
--
-- Astuce du chemin de fichier : chaque fichier est uploadé sous
-- `<course_id>/<horodatage>.<ext>` (voir formation_course_modules_management.dart)
-- — `(storage.foldername(name))[1]` donne donc directement l'id du
-- cours concerné, ce qui permet de vérifier l'achat au niveau du
-- bucket lui-même, sans jamais exposer les fichiers en public.
-- `video_url`/`photo_urls` stockent maintenant ce CHEMIN (pas une URL
-- complète) — voir course_content_screen.dart et
-- formation_course_modules_management.dart.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

insert into storage.buckets (id, name, public)
values ('formation-videos', 'formation-videos', false)
on conflict (id) do update set public = false;

drop policy if exists "formation_videos_bucket_public_read" on storage.objects;

drop policy if exists "formation_videos_bucket_read_purchased_or_staff" on storage.objects;
create policy "formation_videos_bucket_read_purchased_or_staff" on storage.objects
  for select using (
    bucket_id = 'formation-videos'
    and (
      public.current_role_is_staff()
      or exists (
        select 1 from public.course_purchases cp
        where cp.course_id::text = (storage.foldername(name))[1]
          and cp.customer_id = auth.uid()
          and cp.status = 'validee'
      )
    )
  );

drop policy if exists "formation_videos_bucket_staff_write" on storage.objects;
create policy "formation_videos_bucket_staff_write" on storage.objects
  for insert with check (bucket_id = 'formation-videos' and public.current_role_is_staff());

drop policy if exists "formation_videos_bucket_staff_update" on storage.objects;
create policy "formation_videos_bucket_staff_update" on storage.objects
  for update using (bucket_id = 'formation-videos' and public.current_role_is_staff());

drop policy if exists "formation_videos_bucket_staff_delete" on storage.objects;
create policy "formation_videos_bucket_staff_delete" on storage.objects
  for delete using (bucket_id = 'formation-videos' and public.current_role_is_staff());
