-- ============================================================
-- AkoraHub - Patch Phase 306 : texte enrichi (gras, italique,
-- couleur...) pour le contenu MALGACHE des modules aussi
--
-- Demande explicite (29/10) : "Tout le champ de texte de module"
-- doit avoir la barre d'outils de mise en forme, pas seulement le
-- texte français (phase298). Même principe : `content_delta_mg`
-- (jsonb, format Quill Delta) stocke la mise en forme réelle,
-- `content_text_mg` (texte brut, déjà existante) reste le repli pour
-- tout endroit de l'app qui ne lit pas encore le Delta.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.formation_course_modules
  add column if not exists content_delta_mg jsonb;
