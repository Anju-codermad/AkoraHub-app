-- ============================================================
-- AkoraHub - Patch Phase 253 : médias enrichis (messagerie)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (29/09/2026) : "Médias enrichis" (items 15 à 21 de la
-- comparaison messagerie AkoraHub vs WhatsApp/Messenger) :
--   15. Vitesse de lecture des notes vocales (1x/1.5x/2x)
--   16. Forme d'onde visuelle + barre de progression cliquable
--   17. Prise de photo directe (caméra)
--   18. Sélection multiple de fichiers/photos
--   19. Barre de progression pendant l'envoi
--   20. Limite de taille de fichier avec message clair
--   21. Aperçu automatique des liens partagés
--
-- Seule 16 (forme d'onde) touche au schéma : il faut un endroit où
-- stocker les échantillons d'amplitude capturés PENDANT
-- l'enregistrement (impossible à recalculer après coup sans
-- redécoder tout le fichier audio côté client). Les items 15/17/18/
-- 19/20/21 sont purement client (packages déjà présents :
-- image_picker, file_picker, audioplayers, http — voir
-- PROJECT_CONTEXT.md), aucune colonne nécessaire.
-- ============================================================

alter table public.messages
  add column if not exists attachment_waveform text;

-- Pas de nouvelle policy : déjà couvert par `messages_insert_own_or_staff`
-- (phase8), cette colonne est renseignée uniquement à l'insertion (au
-- moment de l'envoi de la note vocale), jamais modifiée après coup.
