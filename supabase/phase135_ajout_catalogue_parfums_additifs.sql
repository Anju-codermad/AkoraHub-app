-- ============================================================
-- AkoraHub - Patch Phase 135 : ajout de nouveaux produits au
-- catalogue "Parfums & Additifs" (édulcorants, arômes, exhausteurs
-- de goût, fixateurs de parfum, additifs fonctionnels).
--
-- Diligence doublon inter-catégories : Cire de carnauba/Cire d'abeille/
-- Lécithine/Glycérol (Huiles & Beurres Cosmétiques), Gomme laque
-- (Polymères & Résines), Mono-/diglycérides E471/Gomme xanthane E415/
-- Pectine E440 (Épaississants), Dioxyde de silicium/Silice colloïdale
-- E551 (Charges Minérales), Propylène glycol E1520 (Solvants),
-- Oxyde de magnésium E530 (déjà au catalogue Charges Minérales),
-- Phosphates de calcium/sodium/Polyphosphates (famille Phosphates
-- déjà couverte par Charges Minérales), Carbonate de sodium E500
-- (déjà documenté dans Acides & Bases) exclus.
-- Vanilline/Éthylvanilline E426 exclu (doublon de "Vanilline de
-- synthèse (éthylvanilline)" déjà au catalogue) ; Tartrate de
-- potassium E336 exclu (doublon de "Crème de tartre" déjà au
-- catalogue). Doublons internes fusionnés : Polyglycitol E964
-- (poudre/sirop), Carbonate acide d'ammonium/Bicarbonate d'ammonium
-- E503 (même composé).
-- Diligence sécurité : Azodicarbonamide E927a (interdit comme
-- additif alimentaire en UE) et Musc cétone (nitro-musc restreint
-- IFRA) inclus avec avertissements renforcés sur décision de
-- l'utilisatrice.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Parfums & Additifs'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Parfums & Additifs".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    -- Édulcorants & polyols
    (v_business_unit_id, 'Parfums & Additifs', 'Érythritol (E968)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Isomalt (E953)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Lactitol (E966)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Maltitol (E965) — sirop et poudre', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Mannitol (E421)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Polyglycitol (E964) — poudre et sirop', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Sel d''aspartame-acésulfame (E962)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Thaumatine (E957)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Xylitol (E967)', 'rupture', null),
    -- Arômes spécifiques de synthèse ou identiques nature
    (v_business_unit_id, 'Parfums & Additifs', 'Acétate d''éthyle (arôme fruité)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Acétoïne (arôme beurre)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Aldéhyde C14 (gamma-undécalactone, arôme pêche)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Aldéhyde C16 (éthyl-méthyl-phénylglycidate, arôme fraise)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Aldéhyde C18 (gamma-nonalactone, arôme coco)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Anéthol (arôme anis)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Benzaldéhyde (arôme amande amère)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Citral (arôme citron)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Diacétyle (arôme beurre)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Éthylmaltol (E637)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Eucalyptol (1,8-cinéole)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Eugénol (arôme clou de girofle)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Furfuryl mercaptan (arôme café)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Isobutyrate d''éthyle (arôme fruits rouges)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Limonène D (d-limonène, arôme agrume)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Linalol (arôme fleuri/lavande)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Maltol (E636)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Menthol (arôme menthe)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Pipéronal (héliotropine, arôme vanille/amande)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Vératraldéhyde (arôme vanillé boisé)', 'rupture', null),
    -- Exhausteurs de goût
    (v_business_unit_id, 'Parfums & Additifs', 'Guanylate disodique / Acide guanylique (E626/E627)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Inosinate disodique / Acide inosinique (E630/E631)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Protéine végétale hydrolysée (HVP)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Extrait de levure (autolysat de levure)', 'rupture', null),
    -- Fixateurs de parfum spécifiques
    (v_business_unit_id, 'Parfums & Additifs', 'Ambre gris (ambroxide synthétique)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Benjoin (résine)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Civettone (musc synthétique macrocyclique)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Galaxolide (musc polycyclique)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Iso E Super (tétraméthyl-acétyl-octahydronaphtalènes)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Musc cétone', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Myrrhe (résine)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Oliban (encens, résine)', 'rupture', null),
    -- Additifs fonctionnels alimentaires
    (v_business_unit_id, 'Parfums & Additifs', 'Azodicarbonamide (E927a)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Carbonate acide d''ammonium / Bicarbonate d''ammonium (E503)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'L-cystéine (E920)', 'rupture', null),
    -- Additifs divers
    (v_business_unit_id, 'Parfums & Additifs', 'Alun de potassium (E522)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Chlorure de magnésium (E511)', 'rupture', null),
    (v_business_unit_id, 'Parfums & Additifs', 'Chlorure de potassium (E508)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
