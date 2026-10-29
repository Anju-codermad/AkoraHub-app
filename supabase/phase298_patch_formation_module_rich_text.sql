-- ============================================================
-- AkoraHub - Patch Phase 298 : texte enrichi (gras, listes, titres)
-- pour le contenu des modules de formation
--
-- Demande explicite (29/10) : une vraie barre d'outils de mise en
-- forme (comme un traitement de texte), où l'auteur choisit le style
-- au moment d'écrire plutôt qu'une syntaxe à apprendre. Utilise
-- flutter_quill (déjà présent dans pubspec.yaml mais jamais câblé
-- jusqu'ici — voir lib/core/utils/linkify_text.dart).
--
-- Nouvelle colonne `content_delta` (jsonb) : stocke le contenu au
-- format Quill Delta (mise en forme réelle). `content_text` (texte
-- brut) est CONSERVÉE comme repli — utilisée tant qu'un module n'a
-- pas encore été réenregistré avec le nouvel éditeur, et continue
-- d'être mise à jour en parallèle (extraction texte brut du contenu
-- enrichi) pour rester lisible partout ailleurs dans l'app sans tout
-- changer d'un coup.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.formation_course_modules
  add column if not exists content_delta jsonb;
