-- ============================================================
-- AkoraHub - Patch Phase 157 : réparer le lien de mise à jour in-app
-- suite à la panne Netlify (quota gratuit dépassé, 10/08) — bascule
-- temporairement sur une GitHub Release publiée manuellement.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Le lien /releases/latest/download/<nom-fichier> reste stable tant que
-- l'utilisatrice republie une nouvelle GitHub Release en gardant le même
-- nom de fichier ("app-arm64-v8a-release.apk") et l'étiquette "Latest" —
-- pas besoin de rejouer ce script à chaque nouvel upload manuel.
-- ============================================================

update public.app_latest_version
set
  version_name = '1.0.0',
  build_number = 50,
  download_url = 'https://github.com/Anju-codermad/AkoraHub-app/releases/latest/download/app-arm64-v8a-release.apk',
  updated_at = now()
where id = 1;
