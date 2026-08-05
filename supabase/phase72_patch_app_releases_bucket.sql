-- ============================================================
-- AkoraHub - Patch Phase 72 : bucket public pour l'APK (lien stable)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (05/08) : la popup "Mise à jour disponible" (phase70) pointait
-- jusqu'ici vers la page Release GitHub — mais le dépôt est PRIVÉ, donc
-- ce lien renvoie une erreur pour un vrai client (même piège que pour
-- partager l'APK sur Facebook). Solution : la CI dépose désormais l'APK
-- ici, sous TOUJOURS le même nom de fichier (réécrit à chaque build,
-- x-upsert), ce qui donne un lien de téléchargement stable qui ne change
-- jamais d'un build à l'autre — utilisable aussi bien par la popup de
-- mise à jour que pour un post Facebook one-shot.
--
-- Écriture réservée à la CI (clé service_role, contourne RLS) : aucune
-- policy d'insertion/mise à jour ouverte aux clients n'est nécessaire ici.
-- ============================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'app-releases',
  'app-releases',
  true,
  524288000, -- 500 Mo de marge (l'APK actuel pèse environ 300 Mo)
  array['application/vnd.android.package-archive']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "app_releases_public_read" on storage.objects;
create policy "app_releases_public_read" on storage.objects
  for select using (bucket_id = 'app-releases');
