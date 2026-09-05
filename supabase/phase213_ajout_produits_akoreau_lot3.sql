-- ============================================================
-- AkoraHub - Patch Phase 213 : complète Akor'Eau avec 11 nouveaux
-- produits + relie 4 produits déjà existants — demande explicite de la
-- propriétaire le 05/09/2026, suite à une liste de suggestions
-- (produite par un autre outil) passée au crible pour éviter les
-- doublons déjà rencontrés plusieurs fois dans cette conversation.
--
-- Relie (aucune duplication, comme Hypochlorite de calcium/Charbon
-- actif/STPP) :
--   - PHMB (polyhexaméthylène biguanide) -> Désinfection
--   - BCDMH (brome piscine/SPA) -> Désinfection
--   - Chlorure de didecyldiméthylammonium (DDAC) -> Désinfection (fait
--     office d'algicide, ammonium quaternaire)
--   - Sulfate de cuivre -> Désinfection (déjà catalogué comme algicide
--     bassins/plans d'eau sous Akora Protect)
--
-- Nouveaux produits (vérifiés absents du catalogue) :
--   Coagulants     : Chlorure d'aluminium, Aluminate de sodium
--   Désinfection   : SDIC (Dichloroisocyanurate de sodium),
--                    Acide cyanurique (stabilisant, ne désinfecte pas)
--   Oxydation      : Permanganate de potassium (nouvelle catégorie —
--                    aucune des 7 existantes ne convient pour un
--                    oxydant fer/manganèse)
--   Filtration     : Sable siliceux filtrant, Anthracite filtrant,
--                    Zéolite, Gravier support filtrant
--   Adoucissement  : Résine échangeuse d'anions, Sel régénérant
--                    (NaCl haute pureté)
--
-- Écartés (voir discussion) : "Chlore choc/lent", "Régulateur pH+/-",
-- "Clarifiant piscine" (renommages marketing de produits déjà au
-- catalogue), PAM anionique/cationique/non-ionique séparés (déjà
-- décrits comme variantes dans une seule fiche), Testeurs pH/chlore
-- (instruments de mesure, pas des produits chimiques), Ozone (généré
-- sur place, non stockable), EDTA disodique (existe déjà).
--
-- Contenu rédigé à partir de connaissances générales de chimie (CAS,
-- propriétés, dangers GHS), À VÉRIFIER PAR LA PROPRIÉTAIRE avant
-- diffusion (statut_verification = 'a_valider').
--
-- Comme les phases 190/195 : les nouveaux produits sont créés par le
-- trigger phase159 avec le business_unit_id d'Akora Pro (celui de leur
-- fiche raw_materials) — ce script bascule ensuite explicitement
-- products.business_unit_id vers Akor'Eau, en assignant directement la
-- catégorie finale (via raw_materials.category_name) plutôt qu'un
-- passage par la catégorie générique "Akor'Eau".
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing sur raw_materials,
-- on conflict do update sur l'academie par matiere_premiere_id).
-- ============================================================

do $$
declare
  v_akora_pro_id uuid;
  v_akoreau_id uuid;
  v_material_id uuid;
  v_academie_id uuid;
  v_product_id uuid;
begin
  select id into v_akora_pro_id from public.business_units where slug = 'matieres-premieres';
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';
  if v_akora_pro_id is null then
    raise exception 'Aucun pilier avec le slug "matieres-premieres" trouvé — arrêt.';
  end if;
  if v_akoreau_id is null then
    raise exception 'Aucun pilier avec le slug "akor-eau" trouvé — arrêt.';
  end if;

  -- ============================================================
  -- 0) Nouvelle catégorie "Oxydation" pour Akor'Eau
  -- ============================================================
  insert into public.categories (business_unit_id, name)
  values (v_akoreau_id, 'Oxydation')
  on conflict (business_unit_id, name) do nothing;

  -- ============================================================
  -- 1) Relie 4 produits déjà existants (aucune duplication)
  -- ============================================================
  select id into v_product_id from public.products where name = 'PHMB (polyhexaméthylène biguanide)';
  if v_product_id is not null then
    insert into public.product_extra_business_units (product_id, business_unit_id, category)
    values (v_product_id, v_akoreau_id, 'Désinfection')
    on conflict (product_id, business_unit_id) do update set category = excluded.category;
  else
    raise notice '"PHMB (polyhexaméthylène biguanide)" introuvable — rien relié.';
  end if;

  select id into v_product_id from public.products where name = 'BCDMH (brome piscine/SPA)';
  if v_product_id is not null then
    insert into public.product_extra_business_units (product_id, business_unit_id, category)
    values (v_product_id, v_akoreau_id, 'Désinfection')
    on conflict (product_id, business_unit_id) do update set category = excluded.category;
  else
    raise notice '"BCDMH (brome piscine/SPA)" introuvable — rien relié.';
  end if;

  select id into v_product_id from public.products where name = 'Chlorure de didecyldiméthylammonium (DDAC)';
  if v_product_id is not null then
    insert into public.product_extra_business_units (product_id, business_unit_id, category)
    values (v_product_id, v_akoreau_id, 'Désinfection')
    on conflict (product_id, business_unit_id) do update set category = excluded.category;
  else
    raise notice '"Chlorure de didecyldiméthylammonium (DDAC)" introuvable — rien relié.';
  end if;

  select id into v_product_id from public.products where name = 'Sulfate de cuivre';
  if v_product_id is not null then
    insert into public.product_extra_business_units (product_id, business_unit_id, category)
    values (v_product_id, v_akoreau_id, 'Désinfection')
    on conflict (product_id, business_unit_id) do update set category = excluded.category;
  else
    raise notice '"Sulfate de cuivre" introuvable — rien relié.';
  end if;

  -- ============================================================
  -- 2) Chlorure d'aluminium hexahydraté (AlCl₃·6H₂O)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Coagulants', 'Chlorure d''aluminium hexahydraté', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Chlorure d''aluminium hexahydraté';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Chlorure d''aluminium hexahydraté (AlCl₃·6H₂O), CAS 7784-13-6',
    'Chlorure d''aluminium hexahydraté, aluminum chloride hexahydrate',
    'Technique',
    'Cristaux ou poudre blanche à jaunâtre très hygroscopique, ou solution jaune pâle',
    '1-3 (solution commerciale, acide par hydrolyse)',
    'Très soluble dans l''eau (dissolution exothermique)',
    2.4, null,
    'Coagulant très concentré en aluminium actif — dose efficace plus faible que le sulfate d''aluminium, mais plus corrosif pour les métaux et nécessite un ajustement de pH plus important après traitement. La forme hexahydratée est plus stable et manipulable que la forme anhydre (qui fume au contact de l''air humide).',
    'Comparé au sulfate d''aluminium/PAC, coagulant plus concentré donc dosé plus finement ; comparé au chlorure ferrique, ne colore pas l''eau traitée.',
    'Corrosif',
    array['gants','lunettes','ventilation','tablier'],
    'Gants en caoutchouc ou nitrile épais, lunettes étanches, tablier résistant aux acides.',
    'Peau : rincer 15 min, retirer vêtements souillés. Yeux : rincer 15 min, consulter. Ingestion : rincer la bouche, boire de l''eau, consulter.',
    'Bases fortes (réaction violente), métaux (corrosion, dégagement d''hydrogène), oxydants forts.',
    'Récipients en plastique (PEHD/PVC) ou verre, jamais de métal non protégé. Local frais, à l''écart de l''humidité excessive.',
    5, 30, true, false, 12, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H314', 'H318')
  on conflict (academie_id, phrase_h_id) do nothing;
  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P264', 'P280', 'P301+P330+P331', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coagulation eau potable / eau industrielle',
   'Injecter dans l''eau brute avant décantation, agitation rapide puis floculation lente.',
   'plage', 5, 50, 'mg/L de produit commercial, selon turbidité', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Coagulants'
      and name = 'Chlorure d''aluminium hexahydraté';

  -- ============================================================
  -- 3) Aluminate de sodium (NaAlO₂)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Coagulants', 'Aluminate de sodium', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Aluminate de sodium';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Aluminate de sodium (NaAlO₂), CAS 1302-42-7',
    'Aluminate de soude, sodium aluminate',
    'Technique',
    'Solution alcaline incolore à jaune pâle, ou poudre/granulés blancs',
    '12-13,5 (fortement alcalin)',
    'Soluble dans l''eau',
    1.5, null,
    'Coagulant alcalin — contrairement aux coagulants acides (sulfate/chlorure d''aluminium, PAC), il augmente le pH et l''alcalinité de l''eau traitée. Souvent utilisé en complément d''un coagulant acide pour équilibrer le pH final, ou seul sur des eaux à faible alcalinité naturelle.',
    'Contrairement au PAC/sulfate d''aluminium (acides), l''aluminate de sodium est basique — permet de coaguler sans acidifier l''eau, utile quand l''alcalinité naturelle de l''eau est déjà faible.',
    'Corrosif',
    array['gants','lunettes','tablier'],
    'Solution fortement alcaline — gants et lunettes étanches, tablier, éviter tout contact cutané.',
    'Yeux : rincer 15 min, consulter. Peau : rincer abondamment. Ingestion : rincer la bouche, boire de l''eau, ne pas faire vomir, consulter.',
    'Acides forts (neutralisation violente), métaux amphotères (aluminium, zinc — dégagement d''hydrogène).',
    'Récipient en plastique, local frais, à l''écart des acides.',
    5, 30, true, false, 12, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H318')
  on conflict (academie_id, phrase_h_id) do nothing;
  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P264', 'P280', 'P301+P330+P331', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coagulation (eaux à faible alcalinité, ou en complément d''un coagulant acide)',
   'Injecter dans l''eau brute avant décantation, agitation rapide puis floculation lente ; ajuster le dosage avec le coagulant acide associé si utilisé en tandem.',
   'plage', 2, 20, 'mg/L de produit commercial', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Coagulants'
      and name = 'Aluminate de sodium';

  -- ============================================================
  -- 4) SDIC (Dichloroisocyanurate de sodium)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Désinfection', 'SDIC (Dichloroisocyanurate de sodium)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'SDIC (Dichloroisocyanurate de sodium)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Dichloroisocyanurate de sodium (NaDCC), CAS 2893-78-9',
    'SDIC, dichlor, NaDCC, troclosène sodique',
    'Technique',
    'Poudre, granulés ou pastilles effervescentes blanches, odeur de chlore',
    '5,5-6,5 (solution à 1 %, quasi neutre)',
    'Très soluble dans l''eau, dissolution rapide',
    2.0, null,
    'Contient environ 55-60 % de chlore actif disponible. Se dissout beaucoup plus vite que le TCCA — pratique pour un traitement choc rapide ou la désinfection d''urgence de l''eau potable (comprimés).',
    'Contrairement au TCCA (dissolution lente, effet prolongé en doseur flottant), le SDIC se dissout rapidement — mieux adapté aux traitements ponctuels/chocs et à la désinfection d''urgence qu''à un dosage continu.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en caoutchouc, lunettes de sécurité, masque anti-poussière et anti-chlore, manipuler dans un endroit bien ventilé.',
    'Peau : rincer 15 min. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, médecin. Inhalation : air frais.',
    'Acides forts (dégagement de chlore gazeux), ammoniaque, matières organiques.',
    'Récipient étanche, local frais, sec et bien ventilé, à l''écart de tout acide.',
    5, 30, true, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H314', 'H335', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;
  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P220', 'P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Désinfection choc de l''eau de piscine',
   'Dissoudre les granulés dans un seau d''eau, verser dans le bassin, filtration en marche.',
   'plage', 15, 25, 'g de produit par 10 m³ d''eau (traitement choc)', true, 0);

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Potabilisation de l''eau (urgence, comprimés)',
   'Dissoudre un comprimé dosé dans le volume d''eau indiqué par le fabricant, laisser agir avant consommation.',
   'texte_libre', 'Dosage fixé par le fabricant selon le comprimé (généralement pour 1 L ou 20 L d''eau) — ne pas improviser un dosage en vrac pour cet usage', true, 1);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Désinfection'
      and name = 'SDIC (Dichloroisocyanurate de sodium)';

  -- ============================================================
  -- 5) Acide cyanurique (stabilisant de chlore)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Désinfection', 'Acide cyanurique (stabilisant de chlore)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Acide cyanurique (stabilisant de chlore)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Acide isocyanurique (C₃H₃N₃O₃), CAS 87-90-1',
    'Acide cyanurique, stabilisant chlore, cyanuric acid',
    'Technique',
    'Poudre cristalline blanche, inodore',
    '4 (solution saturée, acide faible)',
    'Faible solubilité dans l''eau froide, soluble à chaud',
    1.75, null,
    'N''a aucun pouvoir désinfectant propre — protège le chlore libre de la dégradation par les UV solaires, prolongeant son efficacité en piscine extérieure. Un excès (> 75-100 ppm) "bloque" le chlore et réduit son efficacité désinfectante ("chlorine lock").',
    'Contrairement aux désinfectants chlorés (TCCA, SDIC, qui contiennent déjà un stabilisant), l''acide cyanurique se dose séparément quand on désinfecte avec de l''hypochlorite (calcium ou sodium), qui n''apporte aucun stabilisant.',
    'Faible',
    array['gants','lunettes','masque anti-poussière'],
    'Gants et lunettes recommandés, masque anti-poussière lors de la manipulation de la poudre concentrée.',
    'Yeux : rincer à l''eau en cas d''irritation. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau.',
    'Oxydants forts, produits chlorés concentrés (éviter tout mélange à sec, comme pour tout produit chloré).',
    'Récipient fermé, local sec.',
    5, 35, false, false, 36, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stabilisation du chlore (piscine extérieure, avec hypochlorite)',
   'Doser au démarrage de saison ou à chaque renouvellement d''eau important ; ne pas ajouter si le désinfectant utilisé (TCCA/SDIC) en contient déjà.',
   'plage', 30, 50, 'ppm à maintenir dans l''eau', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Désinfection'
      and name = 'Acide cyanurique (stabilisant de chlore)';

  -- ============================================================
  -- 6) Permanganate de potassium (KMnO₄) — nouvelle catégorie Oxydation
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Oxydation', 'Permanganate de potassium', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Permanganate de potassium';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Permanganate de potassium (KMnO₄), CAS 7722-64-7',
    'Permanganate de potasse',
    'Technique',
    'Cristaux violet foncé à noir, brillants',
    '7-8 (solution diluée, neutre à légèrement alcalin)',
    'Soluble dans l''eau, colore la solution en violet/rose intense',
    2.7, null,
    'Oxydant puissant utilisé pour précipiter le fer et le manganèse dissous dans l''eau de forage (les rendant filtrables) et pour oxyder certains composés organiques/odeurs (sulfure d''hydrogène). Aussi utilisé pour régénérer les filtres au manganèse ("Greensand").',
    'Contrairement au chlore, n''apporte pas de sous-produits chlorés et reste efficace pour l''oxydation du fer/manganèse même à pH neutre ; un surdosage colore l''eau en rose/violet, visible immédiatement (contrairement à un surdosage de chlore).',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants, lunettes étanches, masque, éviter tout contact avec matières organiques/combustibles (risque d''inflammation). Tache violette persistante sur peau et tissus.',
    'Yeux : rincer 15 min, consulter. Peau : rincer à l''eau. Ingestion : ne pas faire vomir, rincer la bouche, consulter en urgence.',
    'Matières organiques, glycérine, agents réducteurs, acides forts, matériaux combustibles (risque d''inflammation/explosion au contact).',
    'Récipient étanche non métallique, local frais et sec, à l''écart de toute matière combustible ou organique.',
    5, 30, true, false, 36, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H410')
  on conflict (academie_id, phrase_h_id) do nothing;
  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P220', 'P264', 'P280', 'P301+P330+P331', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement du fer et du manganèse (eau de forage)',
   'Injecter dans l''eau brute avant filtration pour oxyder et précipiter le fer/manganèse dissous, qui sont ensuite retenus par le filtre.',
   'plage', 1, 5, 'mg/L, selon la concentration en fer/manganèse à traiter', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Oxydation'
      and name = 'Permanganate de potassium';

  -- ============================================================
  -- 7) Sable siliceux filtrant
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Filtration', 'Sable siliceux filtrant', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Sable siliceux filtrant';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Silice cristalline / dioxyde de silicium (SiO₂), CAS 14808-60-7',
    'Sable de quartz filtrant, sable siliceux calibré',
    'Technique',
    'Grains sableux blancs à beige, calibrés',
    'Non applicable (matériau solide insoluble)',
    'Insoluble dans l''eau',
    'Média filtrant de base : retient les matières en suspension (turbidité) par filtration mécanique en lit de sable — média le plus utilisé et le moins cher pour la filtration d''eau (piscines, eau potable, eaux usées).',
    'Contrairement au charbon actif (adsorption chimique), le sable filtre uniquement par taille de grain (filtration mécanique), sans capacité d''adsorption des composés dissous.',
    'Faible (silice cristalline : poussière irritante à long terme, éviter l''inhalation répétée)',
    array['gants','masque anti-poussière'],
    'La poussière de silice cristalline inhalée de façon répétée et prolongée est dangereuse pour les voies respiratoires — masque anti-poussière adapté recommandé lors du chargement/déchargement des filtres.',
    'Inhalation de poussière : air frais. Yeux : rincer à l''eau en cas de contact.',
    'Aucune incompatibilité chimique notable.',
    'Sac ou vrac, local sec.',
    false, false, 120, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Filtration mécanique en lit filtrant (piscines, eau potable)',
   'Charger le filtre à sable selon la granulométrie et la hauteur de lit recommandées par le fabricant du filtre ; rétrolaver périodiquement pour évacuer les particules retenues.',
   'texte_libre', 'Granulométrie et hauteur de lit variables selon le modèle de filtre — voir spécifications du fabricant', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Filtration'
      and name = 'Sable siliceux filtrant';

  -- ============================================================
  -- 8) Anthracite filtrant
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Filtration', 'Anthracite filtrant', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Anthracite filtrant';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Anthracite filtrant (roche houillère métamorphique, charbon naturel) — pas de CAS unique',
    'Charbon anthracite filtrant',
    'Technique',
    'Grains noirs anguleux, calibrés',
    'Non applicable (matériau solide insoluble)',
    'Insoluble dans l''eau',
    'Média filtrant plus léger et plus poreux que le sable, utilisé en couche supérieure d''un filtre multicouche (sable + anthracite) pour améliorer la rétention de particules fines et augmenter le temps entre deux rétrolavages.',
    'Contrairement au sable utilisé seul, la combinaison anthracite/sable (filtration multicouche) retient des particules plus petites et nécessite moins de rétrolavages.',
    'Faible',
    array['gants','masque anti-poussière'],
    'Masque anti-poussière recommandé lors du chargement/déchargement du filtre.',
    'Inhalation de poussière : air frais. Yeux : rincer à l''eau en cas de contact.',
    'Aucune incompatibilité chimique notable.',
    'Sac ou vrac, local sec.',
    false, false, 120, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Filtration multicouche (couche supérieure, au-dessus du sable)',
   'Charger en couche supérieure d''un filtre multicouche, au-dessus du sable siliceux, selon les proportions recommandées par le fabricant du filtre.',
   'texte_libre', 'Proportions sable/anthracite variables selon le modèle de filtre — voir spécifications du fabricant', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Filtration'
      and name = 'Anthracite filtrant';

  -- ============================================================
  -- 9) Zéolite (média filtrant)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Filtration', 'Zéolite (média filtrant)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Zéolite (média filtrant)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Zéolite naturelle (clinoptilolite, aluminosilicate), CAS 1318-02-1',
    'Clinoptilolite, zéolite filtrante',
    'Technique',
    'Granulés minéraux beige à verdâtre',
    'Non applicable (matériau solide insoluble)',
    'Insoluble dans l''eau',
    'Média filtrant naturel à structure poreuse — filtre plus fin que le sable (retient des particules plus petites) et possède une capacité d''échange ionique qui capte aussi l''ammonium et certains métaux lourds, en plus de la filtration mécanique.',
    'Contrairement au sable (filtration mécanique pure), la zéolite ajoute une action d''échange ionique (capte l''ammonium/métaux) — utile pour les eaux chargées en ammonium (pisciculture, certaines eaux de forage).',
    'Faible',
    array['gants','masque anti-poussière'],
    'Masque anti-poussière recommandé lors du chargement/déchargement du filtre.',
    'Inhalation de poussière : air frais. Yeux : rincer à l''eau en cas de contact.',
    'Aucune incompatibilité chimique notable.',
    'Sac ou vrac, local sec.',
    false, false, 120, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Filtration fine et rétention d''ammonium/métaux (eau de forage, pisciculture)',
   'Charger le filtre selon les recommandations du fabricant, en remplacement ou complément du sable pour les eaux chargées en ammonium.',
   'texte_libre', 'Granulométrie et hauteur de lit variables selon le modèle de filtre — voir spécifications du fabricant', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Filtration'
      and name = 'Zéolite (média filtrant)';

  -- ============================================================
  -- 10) Gravier support filtrant
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Filtration', 'Gravier support filtrant', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Gravier support filtrant';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Gravier siliceux ou calcaire calibré — pas de CAS unique (mélange minéral naturel)',
    'Gravier de support, couche de drainage',
    'Technique',
    'Graviers calibrés, plusieurs granulométries selon l''usage',
    'Non applicable (matériau solide insoluble)',
    'Insoluble dans l''eau',
    'Couche de support au fond d''un filtre à sable — répartit l''eau uniformément et empêche le sable de s''échapper vers la crépine de drainage ; n''a pas de rôle filtrant actif lui-même.',
    'Contrairement au sable/anthracite (média filtrant actif), le gravier ne filtre pas — il soutient et draine.',
    'Faible',
    array['gants'],
    'Gants recommandés pour la manutention.',
    'Sans objet (matériau inerte).',
    'Aucune incompatibilité chimique notable.',
    'Sac ou vrac, local sec ou extérieur abrité.',
    false, false, 120, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Couche de support/drainage sous le lit filtrant',
   'Charger en fond de cuve, sous le sable/anthracite, selon les couches de granulométrie recommandées par le fabricant du filtre.',
   'texte_libre', 'Granulométrie et épaisseur de couche variables selon le modèle de filtre — voir spécifications du fabricant', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Filtration'
      and name = 'Gravier support filtrant';

  -- ============================================================
  -- 11) Résine échangeuse d'anions
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Adoucissement', 'Résine échangeuse d''anions', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Résine échangeuse d''anions';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Résine copolymère styrène-divinylbenzène, forme chlorure (échangeuse d''anions forte)',
    'Résine anionique forte, anion exchange resin (Cl-form)',
    'Technique',
    'Billes sphériques humides, jaune à ambré, quelques mm de diamètre',
    'Non applicable (matériau solide insoluble)',
    'Insoluble dans l''eau (matériau solide, gonfle légèrement en milieu aqueux)',
    'Échange les anions (nitrates, sulfates, silice) contre des ions chlorure au passage de l''eau — utilisée seule pour retirer les nitrates d''une eau de forage, ou combinée à une résine cationique pour la déminéralisation complète (eau ultra-pure).',
    'Contrairement à la résine échangeuse de cations (retire calcium/magnésium = dureté), la résine anionique retire les anions (nitrates, sulfates) — souvent utilisée en complément, pas en remplacement.',
    'Faible',
    array['gants'],
    'Gants recommandés pour éviter le dessèchement de la peau, rincer les résines neuves avant premier usage.',
    'Peau/yeux : rincer à l''eau en cas de contact avec la saumure/soude de régénération (pas la résine elle-même).',
    'Chlore/oxydants forts en continu (dégradation prématurée de la résine), gel (destruction des billes).',
    'Maintenir humide en permanence, à l''abri du gel, dans son emballage d''origine ou immergée dans l''eau.',
    true, false, 60, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Élimination des nitrates / déminéralisation (eau de forage, eau ultra-pure)',
   'Charger la colonne avec la résine ; l''eau traverse le lit qui capte nitrates/sulfates. Régénérer périodiquement avec une saumure de sel ou une solution de soude selon la forme régénérée souhaitée.',
   'texte_libre', 'Capacité et fréquence de régénération variables selon la qualité de l''eau et le volume traité — voir spécifications du fabricant', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Adoucissement'
      and name = 'Résine échangeuse d''anions';

  -- ============================================================
  -- 12) Sel régénérant (NaCl haute pureté)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Adoucissement', 'Sel régénérant (NaCl haute pureté)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;
  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Sel régénérant (NaCl haute pureté)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Chlorure de sodium haute pureté (NaCl), CAS 7647-14-5',
    'Sel régénérant, sel adoucisseur, sel pastille',
    'Technique',
    'Pastilles, granulés ou gros sel blanc',
    '6-8 (solution, neutre)',
    'Très soluble dans l''eau',
    2.16, null,
    'Utilisé en solution saturée (saumure) pour régénérer les résines échangeuses de cations (adoucisseurs). La haute pureté (faible teneur en insolubles) évite l''encrassement du bac à sel et de la vanne de l''adoucisseur, contrairement au sel de table courant.',
    'Contrairement au sel de table alimentaire, ce grade est calibré (pastilles/gros sel) et plus pur pour un usage adoucisseur — moins de résidus insolubles qui s''accumulent dans le bac à sel.',
    'Faible',
    array['gants'],
    'Gants recommandés pour la manutention, sans risque particulier.',
    'Ingestion accidentelle : rincer la bouche, boire de l''eau.',
    'Aucune incompatibilité chimique notable.',
    'Sac fermé, local sec (le sel absorbe l''humidité ambiante).',
    5, 40, true, false, 60, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Régénération des résines échangeuses de cations (adoucisseurs)',
   'Remplir le bac à sel de l''adoucisseur ; l''appareil prépare et injecte automatiquement la saumure lors du cycle de régénération.',
   'texte_libre', 'Fréquence et quantité de régénération variables selon le volume traité et la dureté de l''eau — voir spécifications du fabricant de l''adoucisseur', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Adoucissement'
      and name = 'Sel régénérant (NaCl haute pureté)';

end $$;

-- Vérification :
-- select category, name, visibility from public.products
-- where business_unit_id = (select id from public.business_units where slug = 'akor-eau')
-- order by category, name;
-- select p.name, peb.category from public.product_extra_business_units peb
-- join public.products p on p.id = peb.product_id
-- where peb.business_unit_id = (select id from public.business_units where slug = 'akor-eau');
