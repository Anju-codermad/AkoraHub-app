-- ============================================================
-- AkoraHub - Patch Phase 240 : recrée un produit "Bicarbonate de
-- sodium technique" (grade industriel) distinct des grades
-- alimentaires — demande explicite de la propriétaire le 11/09/2026.
--
-- Contexte (découvert en essayant d'exécuter la phase236) : la fiche
-- "Bicarbonate de soude" (grade technique) avait été SUPPRIMÉE en
-- phase88 (07/08), à l'époque considérée à tort comme un doublon de
-- "Bicarbonate de sodium NaHCO₃ (E500ii)" (grade alimentaire, qui est
-- resté seul au catalogue depuis). Les phases 235/236/238/239 de cette
-- conversation supposaient à tort que "Bicarbonate de soude" existait
-- encore — elles ont été corrigées pour utiliser ce nouveau nom.
--
-- La propriétaire a explicitement demandé de le recréer comme produit
-- SÉPARÉ du grade alimentaire (nom recommandé par elle :
-- "Bicarbonate de sodium technique"), pour l'usage traitement de
-- l'eau/piscine/industriel (Akor'Eau + Akora Pro), sans toucher aux
-- fiches alimentaires existantes (Akora NutriSource).
--
-- Insère dans raw_materials -> le trigger sync_product_from_raw_material
-- (phase159) crée automatiquement un produit brouillon (visibility=false)
-- -> ce script le publie ensuite.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing grâce à la contrainte unique
-- (business_unit_id, category_name, name) de phase40).
-- ============================================================

insert into public.raw_materials
  (business_unit_id, category_name, name, description, safety_note, stock_status)
select bu.id, 'Acides & Bases', 'Bicarbonate de sodium technique',
  'Bicarbonate de sodium (NaHCO₃) grade technique/industriel, distinct du grade alimentaire (E500ii). Utilisé pour le traitement de l''eau et des piscines (correction et stabilisation du pH, augmentation de l''alcalinité/TAC, amélioration de l''efficacité du chlore), l''entretien/nettoyage industriel (désodorisation, abrasif doux), les formulations de détergents (agent tampon, régulateur de pH) et divers usages industriels/agricoles (neutralisation d''acides, correction de pH de solutions).',
  null, 'en_stock'
from public.business_units bu
where bu.slug = 'matieres-premieres'
on conflict do nothing;

do $$
declare
  v_product_id uuid;
begin
  select id into v_product_id from public.products
  where name = 'Bicarbonate de sodium technique';

  if v_product_id is not null then
    update public.products
    set visibility = true
    where id = v_product_id;
  else
    raise notice 'Produit "Bicarbonate de sodium technique" pas encore créé automatiquement — vérifier que le trigger sync_product_from_raw_material (phase159) est bien actif.';
  end if;
end $$;

-- Vérification :
-- select id, name, category, visibility from public.products
-- where name = 'Bicarbonate de sodium technique';
