-- ============================================================
-- AkoraHub - Patch Phase 131 : fiches Académie pour le lot 1 (7
-- polymères épaississants/filmogènes de base) des nouveaux produits
-- "Polymères & Résines" — contenu DeepSeek, vérifié par
-- l'utilisatrice.
--
-- Lot 1/3 : Carbomère (Carbopol), Copolymère d'acrylates,
-- Polyacrylate de sodium, Polyvinylpyrrolidone (PVP), Alcool
-- polyvinylique (PVA), Polyéthylène glycol (PEG), Copolymère VP/VA.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Carbomère (Carbopol)
  -- ------------------------------------------------------------
  v_material_id := '7d1af0c9-fb83-45c0-b25a-da0229a9cde7'::uuid;

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
    'Poly(acide acrylique) réticulé avec des allyl éthers de pentaérythritol ou de sucrose',
    'Carbomer, Carbopol, Acrylates/C10-30 Alkyl Acrylate Crosspolymer, Ultrez, Pemulen',
    'Cosmétique',
    'Poudre blanche très fine, floconneuse, extrêmement légère et volatile',
    '3-4 (dispersion aqueuse avant neutralisation)',
    'Se disperse dans l''eau sans se dissoudre. Forme un gel translucide uniquement après neutralisation du pH à 6-7 avec une base (soude, triéthanolamine TEA, aminométhylpropanol AMP).',
    0.20, null,
    'Épaississant synthétique très efficace à faible dose (0,1-1 %). Le mécanisme repose sur la neutralisation des groupes carboxyle (-COOH) en carboxylate (-COO⁻). La répulsion électrostatique déplie les chaînes polymères et piège l''eau, formant un gel viscoélastique transparent. Excellente stabilité thermique et tolérance aux électrolytes (surtout les grades copolymères). Nécessite impérativement une neutralisation (TEA, NaOH ou AMP) pour former le gel — sans neutralisant, la dispersion reste liquide et acide.',
    'Par rapport au polyacrylate de sodium, le carbomère nécessite une neutralisation pour gélifier, ce qui offre un meilleur contrôle de la viscosité. Contrairement aux gommes naturelles (xanthane, guar), il donne des gels parfaitement transparents et est moins sensible aux électrolytes.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière FFP2 lors de la manipulation de la poudre (très volatile, irritante pour les voies respiratoires). Lunettes recommandées.',
    'Inhalation : air frais. Yeux : rincer à l''eau. Peau : laver.',
    'Cations polyvalents (calcium, magnésium) qui écrantent la répulsion électrostatique et réduisent fortement la viscosité.',
    'Récipient étanche, au sec, à l''abri de l''humidité et des chocs (poudre très volatile).',
    5, 35, true, false, 36, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Gel hydroalcoolique (SHA) et gel cosmétique transparent',
   'Disperser 0,3-1,0 % de carbomère dans l''eau (ou mélange eau-alcool). Laisser hydrater 1-2 h. Neutraliser avec TEA (0,5-1,5 % du gel) ou NaOH diluée jusqu''à pH 6-7. Le gel se forme instantanément.',
   'plage', 0.3, 1.0, '% du produit fini', 'Ambiante', '1-2 h d''hydratation + neutralisation', false, 0);

  -- ------------------------------------------------------------
  -- Copolymère d'acrylates
  -- ------------------------------------------------------------
  v_material_id := '5602b0a9-be53-4606-b1fa-87a6f722a8bb'::uuid;

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
    'Copolymère d''acrylates de sodium et d''acryloyldiméthyltaurate (ou alkyl acrylate crosspolymer)',
    'Acrylates Copolymer, Aqua SF-1, Aristoflex AVC, Sepinov EMT 10',
    'Cosmétique',
    'Poudre blanche fine, ou liquide laiteux (émulsion aqueuse pré-neutralisée)',
    '3-4 (poudre avant neutralisation), 6-7 (après neutralisation ou version pré-neutralisée liquide)',
    'Se disperse dans l''eau. La forme poudre nécessite une neutralisation (NaOH, TEA). La forme liquide pré-neutralisée (émulsion) gonfle immédiatement.',
    0.90, null,
    'Épaississant polymère synthétique prêt à l''emploi (version liquide) ou à neutraliser. Excellente tolérance aux électrolytes, aux UV et aux tensioactifs. Donne des gels lisses, soyeux, non collants, avec un toucher velouté. Utilisé pour stabiliser des émulsions ou suspendre des particules (billes, nacres).',
    'Par rapport au carbomère classique, il est plus facile à disperser (moins de grumeaux), plus résistant aux sels et aux UV, et donne un toucher moins collant. La version liquide (Aqua SF-1) est particulièrement appréciée pour sa simplicité d''emploi à froid.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la forme poudre.',
    'Yeux : rincer. Peau : laver.',
    'Cations polyvalents à forte dose.',
    'Récipient étanche, au sec, à l''abri du gel pour la forme liquide.',
    5, 35, true, false, 24, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Épaississant pour gels douche, shampoings et crèmes',
   'Ajouter 0,5-2,0 % sous agitation lente. La version liquide gonfle immédiatement à froid. La version poudre nécessite une neutralisation (pH 6-7).',
   'plage', 0.5, 2.0, '% du produit fini', 'Ambiante', 'Immédiat (forme liquide) ou 30 min (forme poudre)', false, 0);

  -- ------------------------------------------------------------
  -- Polyacrylate de sodium (épaississant)
  -- ------------------------------------------------------------
  v_material_id := '5289548a-cf20-46c4-b742-9a9a15bbb29d'::uuid;

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
    'Poly(acrylate de sodium) réticulé ([-CH₂-CH(COONa)-]n)',
    'Sodium Polyacrylate, polymère superabsorbant (SAP), épaississant acrylique',
    'Technique, Cosmétique',
    'Poudre blanche très fine, légèrement hygroscopique',
    '7-8 (dispersion aqueuse)',
    'Gonfle dans l''eau en formant un gel visqueux. N''a pas besoin de neutralisation (déjà sous forme de sel de sodium).',
    0.70, null,
    'Polymère superabsorbant capable de retenir jusqu''à 300-500 fois son poids en eau. Utilisé comme épaississant, agent de rétention d''eau, et dans les couches absorbantes. En cosmétique, il sert d''épaississant instantané sans neutralisation, avec un toucher glissant caractéristique.',
    'Par rapport au carbomère, il ne nécessite pas de neutralisation (gain de temps), mais donne un toucher plus glissant et moins transparent. Il est moins cher mais plus sensible aux électrolytes. Il est le choix économique pour les gels opaques.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière. Éviter l''inhalation de poudre fine.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver.',
    'Sels, cations polyvalents (perte de viscosité), acides (régénération d''acide polyacrylique insoluble).',
    'Récipient étanche, au sec, à l''abri de l''humidité (très hygroscopique).',
    5, 35, true, false, 36, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Épaississant économique pour gels et produits ménagers',
   'Disperser 0,5-2,0 % dans l''eau sous agitation. Le gel se forme en quelques minutes sans neutralisation.',
   'plage', 0.5, 2.0, '% du produit fini', 'Ambiante', '5-15 min d''hydratation', false, 0);

  -- ------------------------------------------------------------
  -- Polyvinylpyrrolidone (PVP)
  -- ------------------------------------------------------------
  v_material_id := '514c8e38-8234-4f0f-8e92-413e32af7b54'::uuid;

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
    'Poly(1-vinylpyrrolidin-2-one) (C₆H₉NO)n',
    'PVP, Povidone, Polyvidone, Polyvinylpyrrolidone',
    'Cosmétique, Technique',
    'Poudre blanche à crème, fine, hygroscopique, ou solution aqueuse',
    '5-7 (solution à 5 %)',
    'Très soluble dans l''eau, l''alcool, les glycols et de nombreux solvants organiques. Insoluble dans les huiles.',
    1.20, null,
    'Polymère filmogène, liant et stabilisant. Forme un film transparent, flexible et non collant après séchage. Utilisé comme fixateur capillaire (laques, gels), liant dans les mascaras et eye-liners, et agent de suspension. Disponible en différents grades de poids moléculaire (K-30, K-90) qui influencent la viscosité et la tenue.',
    'Par rapport au copolymère VP/VA, il est plus soluble dans l''eau, moins résistant à l''humidité, et donne un film moins rigide. Comparé au PVA (alcool polyvinylique), il est plus compatible avec les solvants organiques et a un toucher moins collant.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour manipuler la poudre.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts, bases fortes.',
    'Récipient étanche, au sec, à l''abri de l''humidité (hygroscopique).',
    5, 35, true, false, 36, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Fixateur capillaire (gels, laques, sprays coiffants)',
   'Dissoudre 2-5 % de PVP dans la phase aqueuse. Ajouter un plastifiant (glycérine, PEG) pour assouplir le film.',
   'plage', 2.0, 5.0, '% du produit fini', 'Ambiante', 'Immédiat après séchage', false, 0),
  (v_academie_id, 'Liant pour mascaras, eye-liners et rouges à lèvres',
   'Dissoudre 1-3 % dans la phase aqueuse. Améliore l''adhérence des pigments et la tenue.',
   'plage', 1.0, 3.0, '% du produit fini', 'Ambiante à 60°C', 'Pendant le mélange', false, 1);

  -- ------------------------------------------------------------
  -- Alcool polyvinylique (PVA)
  -- ------------------------------------------------------------
  v_material_id := '07b65192-c690-42b2-b1d8-2c350c2042bb'::uuid;

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
    'Poly(alcool vinylique) ([-CH₂-CHOH-]n)',
    'Polyvinyl Alcohol, PVA, PVOH, alcool polyvinylique, polymère hydrosoluble',
    'Technique, Cosmétique',
    'Poudre blanche granuleuse, ou paillettes translucides, inodore',
    '5-7 (solution à 5 %)',
    'Soluble dans l''eau chaude (90-95°C). Forme un film transparent et résistant après séchage. Insoluble dans les solvants organiques.',
    1.19, null,
    'Polymère hydrosoluble filmogène, non toxique, biodégradable. Excellentes propriétés filmogènes, adhésives et émulsifiantes. Disponible en différents degrés d''hydrolyse (partiellement hydrolysé 87-89 %, ou totalement hydrolysé 98-99 %) qui influencent la solubilité et la résistance à l''eau.',
    'Par rapport au PVP, le PVA est moins cher, forme des films plus résistants à l''eau, et est le composant principal des colles blanches et des films hydrosolubles (pods de lessive). Comparé au polyacrylate de sodium, il est filmogène plutôt qu''épaississant.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poudre lors de la manipulation.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
    5, 35, true, false, 36, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Masque peel-off cosmétique',
   'Dissoudre 10-15 % de PVA dans l''eau chaude (90-95°C) sous agitation. Refroidir, ajouter les actifs, appliquer sur la peau, laisser sécher et peler.',
   'valeur_unique', 12.0, null, '% du masque', '90-95°C pour dissolution', 'Séchage 15-20 min', false, 0),
  (v_academie_id, 'Colle blanche artisanale et liant pour papiers/cartons',
   'Dissoudre 10-15 % de PVA dans l''eau chaude, agiter jusqu''à dissolution, refroidir. Appliquer au pinceau.',
   'valeur_unique', 12.0, null, '% dans l''eau', '90-95°C', '30 min de dissolution', false, 1);

  -- ------------------------------------------------------------
  -- Polyéthylène glycol (PEG)
  -- ------------------------------------------------------------
  v_material_id := '5f56086c-997b-4701-b8cf-0c5a4a0dad1f'::uuid;

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
    'Poly(oxyéthylène) (HO-(CH₂CH₂O)n-H)',
    'PEG, Macrogol, Polyethylene Glycol, Carbowax',
    'Cosmétique, Technique, Pharmaceutique',
    'Liquide visqueux incolore (PEG-400), pâte blanche (PEG-1500), solide cireux blanc (PEG-4000 et plus). Inodore.',
    '6-7 (solution aqueuse)',
    'Très soluble dans l''eau, l''alcool et de nombreux solvants organiques. Insoluble dans les huiles.',
    1.13, 230.0,
    'Polymère polyéther linéaire. Selon le poids moléculaire, il se présente sous forme liquide (PEG-200 à 600), pâteuse (PEG-1000 à 1500) ou solide cireuse (PEG-3000 à 20000). Utilisé comme humectant, plastifiant, lubrifiant, liant et solubilisant. Le PEG solide est un excellent support pour les sticks et les suppositoires.',
    'Par rapport au polyacrylate de sodium, il n''épaissit pas mais lubrifie et plastifie. Contrairement au PVA, il ne forme pas de film résistant mais un toucher glissant. Il est le polymère de référence pour les bases hydrosolubles.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter le contact prolongé avec les yeux.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, acides forts.',
    'Récipient étanche, au frais (pour les liquides), au sec (pour les solides).',
    5, 35, true, false, 36, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Plastifiant et humectant en cosmétique (crèmes, lotions)',
   'Ajouter 2-10 % de PEG liquide (PEG-400) dans la phase aqueuse. Améliore la texture, la souplesse et l''hydratation.',
   'plage', 2.0, 10.0, '% du produit fini', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Base hydrosoluble pour sticks et suppositoires',
   'Faire fondre le PEG solide (PEG-4000 ou 6000) à 60-70°C, ajouter les actifs, couler en moule. Se dissout dans l''eau au contact de la peau.',
   'valeur_unique', 100.0, null, 'pur comme base', 'Fusion 60-70°C', 'Refroidissement', false, 1);

  -- ------------------------------------------------------------
  -- Copolymère VP/VA (fixateur capillaire)
  -- ------------------------------------------------------------
  v_material_id := '5bb170f4-576b-400e-abdb-5af6f55a04ac'::uuid;

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
    'Copolymère de vinylpyrrolidone et d''acétate de vinyle',
    'VP/VA Copolymer, PVP/VA, copolymère de vinylpyrrolidone/acétate de vinyle',
    'Cosmétique',
    'Poudre blanche à jaunâtre, ou solution éthanolique claire, odeur légère d''alcool',
    '5-7 (solution aqueuse)',
    'Soluble dans l''eau et l''éthanol. Insoluble dans les huiles.',
    1.10, null,
    'Copolymère filmogène pour la fixation capillaire. Combine les propriétés du PVP (solubilité, filmogène) avec la résistance à l''humidité de l''acétate de vinyle. Disponible en différents ratios VP/VA (70/30, 60/40, 50/50) qui ajustent la rigidité du film et la résistance à l''eau.',
    'Par rapport au PVP seul, il résiste mieux à l''humidité (moins collant par temps humide) et donne un film plus rigide. C''est le polymère de référence pour les laques et gels coiffants professionnels.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour manipuler la poudre.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
    5, 35, true, false, 36, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Fixateur capillaire pour laques, gels, mousses coiffantes',
   'Dissoudre 2-5 % dans un mélange eau-alcool. Ajouter un plastifiant (PEG, glycérine) si nécessaire. Appliquer sur cheveux secs ou humides.',
   'plage', 2.0, 5.0, '% du produit fini', 'Ambiante', 'Séchage à l''air ou au sèche-cheveux', false, 0);
end $$;
