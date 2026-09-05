-- ============================================================
-- AkoraHub - Patch Phase 207 : retire un produit à tort lié à Akora
-- NutriLab — erreur commise en phase 206, signalée par la
-- propriétaire le 04/09/2026 ("il faut bien vérifier chaque
-- référence pour éviter la confusion entre le produit technique
-- (non alimentaire) et alimentaire").
--
-- La phase 206 a lié "Acide phosphorique H₃PO₄ (Grade
-- Technique/Industriel)" à Akora NutriLab pour faire correspondre le
-- nombre de produits attendu, sans revérifier que ce produit précis
-- était pertinent. Son nom dit explicitement "Grade
-- Technique/Industriel" — CE N'EST PAS un produit alimentaire, il
-- n'a rien à faire visible sous un pilier d'ingrédients
-- agroalimentaires. Les vraies variantes alimentaires de l'acide
-- phosphorique ("H₃PO₄ (E338)" et "H₃PO₄ alimentaire (E338)") ont,
-- elles, bien été basculées vers NutriLab par la phase 205 — rien à
-- changer de ce côté.
--
-- Ce script retire uniquement ce lien erroné (le produit reste
-- inchangé sous Akora Pro, seul le lien supplémentaire vers
-- NutriLab est supprimé), puis vérifie qu'aucun autre produit dont
-- le nom contient "Technique" ou "Industriel" n'est visible sous
-- Akora NutriLab (pilier principal ou lien supplémentaire) — pour
-- s'assurer qu'aucune autre confusion similaire ne s'est glissée.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (delete simple, ne fait rien si déjà retiré).
-- ============================================================

delete from public.product_extra_business_units peb
using public.products p, public.business_units bu
where peb.product_id = p.id
  and peb.business_unit_id = bu.id
  and bu.slug = 'akora-nutrilab'
  and p.name = 'Acide phosphorique H₃PO₄ (Grade Technique/Industriel)';

-- ------------------------------------------------------------
-- Audit : tout produit "technique/industriel" encore visible sous
-- Akora NutriLab, par pilier principal OU lien supplémentaire.
-- Ne devrait renvoyer AUCUNE ligne après ce correctif.
-- ------------------------------------------------------------
select p.name as produit, 'pilier principal' as via
from public.products p
join public.business_units bu on bu.id = p.business_unit_id
where bu.slug = 'akora-nutrilab'
  and (p.name ilike '%technique%' or p.name ilike '%industriel%')
union all
select p.name as produit, 'lien supplémentaire' as via
from public.product_extra_business_units peb
join public.products p on p.id = peb.product_id
join public.business_units bu on bu.id = peb.business_unit_id
where bu.slug = 'akora-nutrilab'
  and (p.name ilike '%technique%' or p.name ilike '%industriel%');

-- Vérification : les 16 produits qui doivent rester liés en plus à
-- Akora NutriLab (17 moins celui retiré)
select p.name as produit, bu.name as pilier_principal
from public.product_extra_business_units peb
join public.products p on p.id = peb.product_id
join public.business_units bu on bu.id = p.business_unit_id
where peb.business_unit_id = (select id from public.business_units where slug = 'akora-nutrilab')
order by p.name;
