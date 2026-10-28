-- ============================================================
-- AkoraHub - Patch Phase 277 : description + page publique
-- partageable par formation (lien promo, pas vers le contenu payant)
--
-- Demande explicite (28/10) : "pas de lien pour partager le vidéo mais
-- juste le lien pour les publications vers nos formations" — chaque
-- formation doit avoir un lien public partageable (WhatsApp, réseaux
-- sociaux) qui ouvre une page de présentation (titre, catégorie, prix,
-- description), JAMAIS le contenu payant lui-même. Même principe que
-- `produit.html?id=...` pour les produits (groupe-akora-site).
--
-- `description` manquait sur formation_courses (seulement
-- catégorie/titre/statut/prix jusqu'ici) — nécessaire pour une vraie
-- page de présentation. Toujours lisible publiquement (policy
-- `formation_courses_select_all`, phase43, inchangée : `using (true)`,
-- déjà compatible avec un visiteur non connecté du site web).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.formation_courses
  add column if not exists description text;
