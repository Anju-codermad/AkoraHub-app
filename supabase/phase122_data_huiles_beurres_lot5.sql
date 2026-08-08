-- ============================================================
-- AkoraHub - Patch Phase 122 : fiches Académie pour le lot 5 (5
-- cires et lanoline) des nouveaux produits "Huiles & Beurres
-- Cosmétiques" — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Lot 5/5 (dernier lot) : Cire de candelilla, Cire de soja,
-- Lanoline, Cire de riz, Cire d'acacia (mimosa).
--
-- Lanoline documentée avec avertissement allergène de contact connu
-- (dermatite de contact documentée) dans particularite et notes_epi.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Cire de candelilla
  -- ------------------------------------------------------------
  v_material_id := '0dd9328d-8e23-4b51-847a-b9f2fc4404b5'::uuid;

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
    'Mélange d''esters d''acides gras et d''alcools gras (Euphorbia cerifera)',
    'Euphorbia Cerifera Wax, Candelilla Wax, cire de candelilla',
    'Cosmétique',
    'Solide beige clair à jaune pâle, dure, cassante, granules ou paillettes, odeur neutre à légèrement sucrée, point de fusion 68-73°C',
    'Non applicable (cire pure)',
    'Insoluble dans l''eau, soluble dans les huiles, les alcools chauds et les solvants organiques',
    0.98, 240.0,
    'Composition : esters d''acides gras (acide hentriacontanoïque, acide lacéroïque) et d''alcools gras, résines. Point de fusion 68-73°C. Cire végétale dure, brillante, excellent substitut végétalien à la cire d''abeille. Bon pouvoir filmogène et protecteur.',
    'Par rapport à la cire d''abeille, elle est plus dure et plus cassante, avec un point de fusion plus élevé. Comparée à la cire de carnauba, elle est moins dure et plus facile à incorporer dans les baumes. Idéale pour les formulations vegan.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poussières lors de la manipulation de granules.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la chaleur et de la lumière.',
    10, 30, false, true, 36, 'a_valider'
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
  (v_academie_id, 'Stick à lèvres et baume solide vegan',
   'Faire fondre 5 à 15 % avec les beurres et huiles. Apporte dureté, brillance et un film protecteur.',
   'plage', 5, 15, '% de la formule', 'Fusion à 75-80°C', 'Refroidissement', false, 0),
  (v_academie_id, 'Bougie vegan (agent de dureté et brillance)',
   'Ajouter 5 à 10 % dans le mélange de cire de soja pour améliorer la dureté et la brillance de la bougie.',
   'plage', 5, 10, '% du poids de cire', '75-85°C', 'Refroidissement', false, 1);

  -- ------------------------------------------------------------
  -- Cire de soja
  -- ------------------------------------------------------------
  v_material_id := '15a1052c-c237-4685-b0cf-8b9cc1b4675f'::uuid;

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
    'Triglycérides hydrogénés d''huile de soja (Glycine max)',
    'Hydrogenated Soybean Oil, Soy Wax, cire de soja',
    'Cosmétique, Technique',
    'Solide blanc crème à ivoire, texture crémeuse, fondant facilement, odeur neutre, point de fusion 45-55°C',
    'Non applicable (cire pure)',
    'Insoluble dans l''eau, soluble dans les huiles chaudes et les solvants organiques',
    0.91, 200.0,
    'Composition : triglycérides saturés (acide stéarique, acide palmitique) obtenus par hydrogénation de l''huile de soja. Point de fusion 45-55°C. Cire 100 % végétale, biodégradable, sans OGM dans les grades cosmétiques. Fond plus facilement que les cires dures, idéale pour les bougies coulées.',
    'Par rapport à la cire d''abeille, elle est plus molle et fond à plus basse température. Comparée à la cire de candelilla, elle est beaucoup moins dure et donne des bougies crémeuses. Elle est la cire de référence pour les bougies végétales artisanales.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter la surchauffe prolongée au-dessus de 90°C.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts, chaleur excessive (dénaturation).',
    'Récipient hermétique, au frais, à l''abri de la chaleur (fond facilement en été).',
    10, 25, false, true, 24, 'a_valider'
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
  (v_academie_id, 'Bougie végétale coulée (pot, moule)',
   'Faire fondre à 70-80°C, ajouter parfum et colorant, couler à 55-65°C. Bonne adhérence au contenant, surface lisse.',
   'valeur_unique', 100, null, 'pure ou en mélange', 'Fusion 70-80°C, coulage 55-65°C', 'Refroidissement 4-6 h', false, 0),
  (v_academie_id, 'Baume corporel et crème fouettée',
   'Incorporer 10 à 25 % avec des beurres et huiles. Apporte une texture crémeuse et fondante.',
   'plage', 10, 25, '% de la formule', 'Fusion à 50-60°C', 'Refroidissement et fouettage', false, 1);

  -- ------------------------------------------------------------
  -- Lanoline
  -- ------------------------------------------------------------
  v_material_id := '6291ba8d-0075-4281-ae2c-13d7b8cda8bc'::uuid;

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
    'Mélange de stérols, esters de cholestérol et d''acides gras (graisse de laine de mouton purifiée)',
    'Lanolin, Adeps Lanae, graisse de laine, cire de laine',
    'Cosmétique, Pharmaceutique',
    'Pâte épaisse jaune à jaune-brun, odeur lanolée caractéristique, point de ramollissement 36-42°C',
    'Non applicable (cires et esters)',
    'Insoluble dans l''eau, absorbe jusqu''à 2 fois son poids en eau, soluble dans les huiles et les solvants organiques chauds',
    0.95, 230.0,
    'Composition : mélange complexe de stérols (cholestérol, lanostérol), esters de lanoline et acides gras libres. Point de ramollissement 36-42°C. Excellente capacité émulsifiante et hydratante, mimant le film lipidique cutané. Allergène de contact connu, des cas de dermatite de contact sont documentés. À utiliser avec prudence chez les personnes sensibles ou atopiques. Usage externe uniquement.',
    'Par rapport à la cire d''abeille, elle est émulsifiante et absorbe l''eau, ce que la cire d''abeille ne fait pas. Comparée aux beurres végétaux, elle est d''origine animale et bien plus occlusive. Sa capacité à retenir l''eau en fait un ingrédient unique pour les crèmes barrières.',
    'Faible',
    array['gants'],
    'Porter des gants lors de la manipulation de grandes quantités. Risque d''allergie de contact (dermatite de contact documentée) : informer les clients et éviter l''usage sur peaux réactives ou lésées. Bien étiqueter.',
    'Yeux : rincer abondamment. Peau : enlever l''excédent, laver au savon. Ingestion : boire de l''eau, ne pas faire vomir. En cas de réaction allergique (rougeur, démangeaisons), cesser l''utilisation et consulter un médecin.',
    'Oxydants forts, bases fortes (saponification).',
    'Récipient hermétique, à température ambiante, à l''abri de la chaleur et de la lumière.',
    10, 30, false, true, 24, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux (allergène de contact, hors classification H/P SGH).

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Crème barrière et baume pour les lèvres très abîmées',
   'Incorporer 5 à 20 % dans la phase grasse. Excellente protection contre le froid et le dessèchement. Attention au risque d''allergie.',
   'plage', 5, 20, '% de la formule', 'Fusion à 50-60°C', 'Refroidissement', false, 0),
  (v_academie_id, 'Émulsifiant naturel pour crèmes épaisses',
   'Utiliser 5 à 10 % avec un co-émulsifiant pour stabiliser des émulsions E/H. Apporte un toucher riche et protecteur.',
   'plage', 5, 10, '% de la formule', '70-75°C', 'Émulsification 10-15 min', false, 1);

  -- ------------------------------------------------------------
  -- Cire de riz
  -- ------------------------------------------------------------
  v_material_id := 'b7fb6215-85d0-4102-b630-3955f4686cf9'::uuid;

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
    'Esters cireux de son de riz (Oryza sativa)',
    'Oryza Sativa Bran Wax, Rice Bran Wax, cire de riz, cire de son de riz',
    'Cosmétique',
    'Solide beige clair à jaune pâle, dure, paillettes ou pastilles, odeur très faible, point de fusion 78-82°C',
    'Non applicable (cire pure)',
    'Insoluble dans l''eau, soluble dans les huiles chaudes et les solvants organiques',
    0.96, 250.0,
    'Composition : esters d''acides gras (acide béhénique, acide lignocérique) et d''alcools gras (alcool cétylique, alcool mélyssique). Point de fusion 78-82°C. Cire végétale très dure, excellent substitut à la cire de carnauba. Toucher soyeux, bon pouvoir liant.',
    'Par rapport à la cire de carnauba, elle est très proche en dureté, mais avec un toucher plus soyeux. Comparée à la cire de candelilla, elle a un point de fusion plus élevé et donne des sticks plus résistants. Idéale pour les sticks exigeant une bonne tenue à la chaleur.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
    10, 30, false, true, 36, 'a_valider'
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
  (v_academie_id, 'Stick à lèvres et rouge à lèvres haute tenue',
   'Incorporer 5 à 15 % dans la formule. Apporte dureté, résistance à la chaleur et un fini soyeux.',
   'plage', 5, 15, '% de la formule', 'Fusion à 85-90°C', 'Refroidissement rapide', false, 0),
  (v_academie_id, 'Bougie végétale (agent de dureté)',
   'Ajouter 3 à 8 % dans la cire de soja pour augmenter la dureté et le point de fusion.',
   'plage', 3, 8, '% du poids de cire', '80-90°C', 'Refroidissement', false, 1);

  -- ------------------------------------------------------------
  -- Cire d'acacia (mimosa)
  -- ------------------------------------------------------------
  v_material_id := '59f712dc-3cbb-4ca0-aa94-c61ac9a9e8c5'::uuid;

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
    'Esters cireux des fleurs d''Acacia decurrens (mimosa)',
    'Acacia Decurrens Flower Wax, Mimosa Wax, cire de mimosa, cire d''acacia',
    'Cosmétique',
    'Solide jaune doré à brun clair, texture cireuse et malléable, odeur florale douce et caractéristique de mimosa, point de fusion 55-65°C',
    'Non applicable (cire pure)',
    'Insoluble dans l''eau, soluble dans les huiles chaudes et les solvants organiques',
    0.90, 220.0,
    'Composition : esters d''acides gras à longue chaîne (acide mimosaique, acide palmitique) et d''alcools gras. Point de fusion 55-65°C. Cire florale rare, au parfum délicat de mimosa. Apporte un toucher velouté et une odeur naturelle subtile aux cosmétiques haut de gamme.',
    'Par rapport à la cire d''abeille, elle est plus douce et parfumée naturellement. Comparée à la cire de candelilla, elle est beaucoup moins dure et apporte une fragrance naturelle. C''est une cire de spécialité, utilisée en parfumerie solide et soins premium.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Peut contenir des traces de pollen.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière et des odeurs fortes (absorbe les odeurs).',
    10, 25, false, true, 24, 'a_valider'
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
  (v_academie_id, 'Parfum solide et baume parfumé haut de gamme',
   'Incorporer 5 à 15 % dans la formule. Apporte une note florale naturelle et un toucher velouté.',
   'plage', 5, 15, '% de la formule', 'Fusion à 65-75°C', 'Refroidissement', false, 0),
  (v_academie_id, 'Stick à lèvres et baume teinté naturel',
   'Utiliser 3 à 10 % comme cire co-émolliente. Apporte souplesse, parfum et brillance au stick.',
   'plage', 3, 10, '% de la formule', '65-75°C', 'Refroidissement', false, 1);
end $$;
