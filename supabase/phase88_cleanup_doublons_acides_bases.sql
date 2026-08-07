-- ============================================================
-- AkoraHub - Patch Phase 88 : nettoyage doublons "Acides & Bases"
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (07/08) : le catalogue "Acides & Bases" a été importé en
-- masse (tout créé à la même seconde) avec plusieurs noms différents
-- pour un même produit (ex : "Acide tartrique" et "Acide tartrique
-- L(+) (E334)"). Suppression UNIQUEMENT des doublons vérifiés sans
-- aucun achat existant (formation_purchases) — les autres doublons
-- potentiels (Acide acetique, Acide citrique, Acide citrique
-- alimentaire, Acide phosphorique) ont déjà des achats clients réels
-- et NE DOIVENT PAS être supprimés.
--
-- - "Acide tartrique" (895c26fb...) → doublon de "Acide tartrique
--   L(+) (E334)" (5966f22c...), qui reste.
-- - "Bicarbonate de soude" (0cbe524e...) → doublon de "Bicarbonate de
--   sodium NaHCO₃ (E500ii)" (09a5e4e8...), qui reste.
-- ============================================================

delete from public.raw_materials
where id in (
  '895c26fb-90df-4379-b948-329a8a41e0c6', -- Acide tartrique
  '0cbe524e-cd09-4507-8a1b-46ef05594127'  -- Bicarbonate de soude
);
