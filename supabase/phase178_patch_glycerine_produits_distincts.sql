-- ============================================================
-- AkoraHub - Patch Phase 178 : séparer les grades de Glycérine
-- en fiches produit distinctes
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (24/08, sur demande) : le catalogue Produits ne contenait
-- qu'UNE fiche "Glycérine / Glycérol alimentaire (E422)" (grade
-- alimentaire/végétale), alors qu'il existe 3 grades commercialement
-- distincts : Glycérine 99,5% USP, Glycérine végétale (déjà couverte par
-- la fiche E422 existante — non touchée ici), Glycérine technique
-- (absente du catalogue).
--
-- Ajoute 2 nouvelles fiches produit en BROUILLON (comme
-- "Éthylhexylglycérine" déjà dans le catalogue) :
--   - "Glycérine technique" : contenu technique réel repris d'une fiche
--     déjà rédigée dans le projet (jamais utilisée côté catalogue produit).
--   - "Glycérine 99,5% USP" : fiche vide (prix/stock à 0), à compléter
--     manuellement — aucune donnée technique existante pour ce grade
--     précis dans le projet, pas de valeurs inventées.
-- Chaque insertion reprend le business_unit_id/catégorie de la fiche
-- "Glycérine / Glycérol alimentaire (E422)" existante pour rester
-- cohérent, et ne s'exécute que si la fiche n'existe pas déjà (sûr à
-- ré-exécuter).
-- ============================================================

insert into public.products (business_unit_id, category, name, description, visibility)
select p.business_unit_id, p.category, 'Glycérine technique',
  'Pureté variable (80-95 %), peut contenir des impuretés, des sels, '
  || 'des traces de méthanol ou d''acides gras. Non conforme aux normes '
  || 'alimentaires. Utilisée pour des applications techniques : antigel, '
  || 'fluides hydrauliques, plastifiants industriels, fabrication de '
  || 'résines. Ne doit en aucun cas être utilisée en alimentaire ou en '
  || 'cosmétique. Coût généralement inférieur à la glycérine alimentaire.',
  false
from public.products p
where p.name = 'Glycérine / Glycérol alimentaire (E422)'
  and not exists (select 1 from public.products where name = 'Glycérine technique')
limit 1;

insert into public.products (business_unit_id, category, name, description, visibility)
select p.business_unit_id, p.category, 'Glycérine 99,5% USP', null, false
from public.products p
where p.name = 'Glycérine / Glycérol alimentaire (E422)'
  and not exists (select 1 from public.products where name = 'Glycérine 99,5% USP')
limit 1;
