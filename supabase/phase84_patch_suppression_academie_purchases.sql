-- ============================================================
-- AkoraHub - Patch Phase 84 : suppression définitive de l'ancien achat
-- Académie séparé
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ⚠️ Prérequis : phase83_patch_fusion_academie_matieres.sql doit déjà
-- avoir été exécuté (sinon l'accès à la fiche Académie sera cassé).
--
-- Contexte (06/08) : après la fusion (phase83), plus rien dans l'app
-- ne lit/écrit `academie_purchases` ou `academie_pricing_tiers` — sur
-- demande explicite, on les supprime au lieu de les laisser inertes.
-- ============================================================

drop table if exists public.academie_purchases cascade;
drop table if exists public.academie_pricing_tiers cascade;
drop function if exists public.has_purchased_academie_access(uuid, uuid);
