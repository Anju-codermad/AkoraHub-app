-- ============================================================
-- AkoraHub - Patch Phase 209 : retire "Ethanol (alcool ethylique)"
-- du lien vers Akora NutriLab — demande explicite de la propriétaire
-- le 04/09/2026, suite à vérification.
--
-- Diagnostic (session) : ni "Ethanol (alcool ethylique)" (Solvants) ni
-- "Éthanol 96° (alcool éthylique)" (Désinfectants) — les deux seules
-- références existantes — n'ont "alimentaire" dans leur nom. Sa fiche
-- mentionne qu'un grade alimentaire/pharmaceutique existe, mais aucune
-- référence catalogue dédiée ne le confirme explicitement. Par
-- précaution (même logique que la phase 207 pour l'acide
-- phosphorique technique), on retire ce lien plutôt que de risquer
-- une confusion pour un client agroalimentaire.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (delete simple, ne fait rien si déjà retiré).
-- ============================================================

delete from public.product_extra_business_units peb
using public.products p, public.business_units bu
where peb.product_id = p.id
  and peb.business_unit_id = bu.id
  and bu.slug = 'akora-nutrilab'
  and p.name = 'Ethanol (alcool ethylique)';

-- Vérification : total de produits liés à Akora NutriLab (doit être 118)
select count(*) as total_lies
from public.product_extra_business_units
where business_unit_id = (select id from public.business_units where slug = 'akora-nutrilab');
