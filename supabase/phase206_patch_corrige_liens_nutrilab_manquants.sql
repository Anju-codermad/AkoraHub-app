-- ============================================================
-- AkoraHub - Patch Phase 206 : corrige 2 liens manquants de la
-- phase 205 vers Akora NutriLab — demande explicite de la
-- propriétaire le 04/09/2026, suite à vérification post-exécution.
--
-- La phase 205 visait "Acide phosphorique" et "Sorbate de potassium"
-- (noms génériques repérés dans le diagnostic), mais ces libellés
-- exacts n'existent pas au catalogue — les vrais produits sont :
--   - "Acide phosphorique H₃PO₄ (Grade Technique/Industriel)"
--   - "Sorbate de potassium (E202)"
-- (les versions "(E338)" / "alimentaire (E338)" de l'acide
-- phosphorique, elles, ont bien été basculées vers NutriLab par la
-- phase 205 — seule la version technique/industrielle manquait le
-- lien supplémentaire).
--
-- Mêmes deux produits combo repérés lors de la vérification
-- ("Acide citrique + Sorbate K — combo conservateur standard",
-- "Benzoate de sodium + Sorbate de K (combo conserves)") laissés de
-- côté volontairement — pas demandés explicitement, la propriétaire
-- pourra les ajouter séparément si besoin.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing).
-- ============================================================

insert into public.product_extra_business_units (product_id, business_unit_id)
select p.id, bu.id
from public.products p
join public.business_units bu on bu.slug = 'akora-nutrilab'
where p.name in (
  'Acide phosphorique H₃PO₄ (Grade Technique/Industriel)',
  'Sorbate de potassium (E202)'
)
on conflict (product_id, business_unit_id) do nothing;

-- Vérification : les 17 produits liés en plus à Akora NutriLab
select p.name as produit, bu.name as pilier_principal
from public.product_extra_business_units peb
join public.products p on p.id = peb.product_id
join public.business_units bu on bu.id = p.business_unit_id
where peb.business_unit_id = (select id from public.business_units where slug = 'akora-nutrilab')
order by p.name;
