-- ============================================================
-- AkoraHub - Patch Phase 143 : ajout de nouveaux produits au
-- catalogue "Tensioactifs" (anioniques, cationiques, amphotères,
-- non ioniques).
--
-- Diligence doublon inter-catégories : vérifié qu'aucun de ces
-- produits (Polysorbate, Poloxamer, Sorbitan, Cetrimonium,
-- Behentrimonium, savons Sodium/Potassium Cocoate/Stearate/Palmate,
-- PEG-40/PEG-7) n'apparaît dans une catégorie déjà terminée
-- (grep PROJECT_CONTEXT.md : aucune occurrence).
-- Aucune exclusion sécurité : tous les produits sont des
-- tensioactifs légaux et couramment utilisés en cosmétique/
-- détergence artisanale.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Tensioactifs'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Tensioactifs".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    -- Anioniques
    (v_business_unit_id, 'Tensioactifs', 'Sodium Cocoyl Isethionate (SCI)', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Disodium Laureth Sulfosuccinate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Disodium Lauryl Sulfosuccinate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sodium Methyl Cocoyl Taurate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sodium Cocoyl Glycinate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Potassium Cocoate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sodium Cocoate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sodium Stearate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sodium Palmate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Ammonium Lauryl Sulfate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Magnesium Laureth Sulfate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sodium Lauryl Glucose Carboxylate', 'rupture', null),
    -- Cationiques
    (v_business_unit_id, 'Tensioactifs', 'Cetrimonium Chloride', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Behentrimonium Methosulfate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Distearyldimonium Chloride', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Stearamidopropyl Dimethylamine', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Dicetyldimonium Chloride', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Quaternium-87', 'rupture', null),
    -- Amphotères / Zwitterioniques
    (v_business_unit_id, 'Tensioactifs', 'Disodium Cocoamphodiacetate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sodium Cocoamphoacetate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Lauramidopropyl Betaine', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Coco-Betaine', 'rupture', null),
    -- Non ioniques
    (v_business_unit_id, 'Tensioactifs', 'Cocamide MEA', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Cocamide MIPA', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Polysorbate 20', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Polysorbate 80', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sorbitan Oleate (Span 80)', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sorbitan Stearate (Span 60)', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Sorbitan Laurate (Span 20)', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Laureth-4', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Laureth-7', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Ceteareth-20', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Ceteareth-25', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'PEG-40 Hydrogenated Castor Oil', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'PEG-7 Glyceryl Cocoate', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Poloxamer 407', 'rupture', null),
    (v_business_unit_id, 'Tensioactifs', 'Poloxamer 188', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
