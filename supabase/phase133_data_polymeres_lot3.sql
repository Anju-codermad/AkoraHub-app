-- ============================================================
-- AkoraHub - Patch Phase 133 : fiches Académie pour le lot 3 (dernier
-- lot — 6 résines naturelles et techniques diverses) des nouveaux
-- produits "Polymères & Résines" — contenu DeepSeek, vérifié par
-- l'utilisatrice.
--
-- Lot 3/3 (dernier lot) : Résine UV, Résine polyuréthane
-- (bijouterie/art), Colophane, Gomme laque, Acétate de polyvinyle
-- (colle blanche), Silicone RTV.
--
-- Résine UV et Résine polyuréthane (bijouterie/art) documentées avec
-- avertissements renforcés sur la sensibilisation cutanée/respiratoire
-- (acrylates et isocyanates).
-- Termine les 20 nouveaux produits de la catégorie "Polymères &
-- Résines" (phases 131-133).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Résine UV (acrylate photopolymérisable)
  -- ------------------------------------------------------------
  v_material_id := '100237da-3718-458c-8c3a-13d86ad87d10'::uuid;

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
    'Mélange de monomères et oligomères d''acrylates (ex. uréthane acrylate, époxy acrylate) et photo-initiateur',
    'UV Resin, résine LED, résine photopolymérisable, résine à polymériser sous lampe UV/LED',
    'Artistique, Technique',
    'Liquide visqueux, incolore à légèrement jaunâtre, transparent, odeur acrylique caractéristique (plus ou moins marquée)',
    'Non applicable (résine réactive)',
    'Non polymérisée : soluble dans l''acétone, les esters, les glycols. Polymérisée : insoluble dans l''eau et les solvants courants.',
    1.10, 120.0,
    'Résine durcissant sous rayonnement UV (365-405 nm) ou LED en quelques secondes à quelques minutes. Ne nécessite pas de mélange (monocomposant). Le composant principal est constitué d''acrylates, connus pour leur potentiel sensibilisant cutané (allergènes de contact fréquents, notamment dans le secteur des ongles). La résine non polymérisée est irritante ; la lampe UV peut causer des dommages oculaires et cutanés (photovieillissement).',
    'Par rapport à la résine époxy ou polyester, la prise est quasi instantanée sous lampe, sans pot life, mais la résine est plus chère et le matériel UV nécessaire. Contrairement à la résine acrylique solvantée pour vernis à ongles, elle ne contient pas de solvant qui s''évapore, mais des monomères réactifs.',
    'Modéré',
    array['gants','lunettes','masque','ventilation'],
    'Porter des gants en nitrile (les acrylates traversent le latex), des lunettes de protection UV filtrantes, un masque à vapeurs organiques (type A) en cas de travail prolongé. Utiliser la lampe UV dans un espace confiné avec protection des yeux et de la peau. Éviter tout contact cutané avec la résine non polymérisée.',
    'Peau : laver immédiatement à l''eau et au savon, ne pas utiliser de solvant. Yeux : rincer 15 min, consulter si irritation. Inhalation : air frais. Ingestion : rincer la bouche, ne pas faire vomir, consulter un médecin. En cas de réaction allergique, cesser l''exposition et consulter un dermatologue.',
    'Sources de chaleur, oxydants forts, lumière UV ambiante (polymérisation prématurée).',
    'Flacon opaque, bien fermé, dans un endroit frais et à l''abri de la lumière (y compris UV). Tenir hors de portée des enfants.',
    15, 25, false, true, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H317', 'H319', 'H335', 'H341')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P261', 'P264', 'P272', 'P280', 'P302+P352', 'P305+P351+P338', 'P308+P313', 'P333+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Bijouterie fantaisie, moulage de petits objets, réparation, vernis à ongles permanent',
   'Appliquer ou couler une fine couche de résine. Exposer sous une lampe UV/LED (puissance recommandée 36W ou plus) pendant 30 secondes à 2 minutes selon l''épaisseur. La résine durcit immédiatement. Éviter de surchauffer.',
   'texte_libre', null, null, 'Quantité suffisante pour la pièce', 'Ambiante', '30 secondes à 2 minutes sous lampe UV/LED', false, 0);

  -- ------------------------------------------------------------
  -- Résine polyuréthane (bijouterie/art)
  -- ------------------------------------------------------------
  v_material_id := 'f21b5e93-78ff-49f9-b071-529229f1e836'::uuid;

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
    'Mélange de polyols et d''isocyanates (généralement diisocyanate de diphénylméthane MDI ou diisocyanate d''isophorone IPDI)',
    'PU resin, résine polyuréthane, résine de coulée polyuréthane, résine PU pour bijouterie',
    'Technique, Artistique',
    'Liquide visqueux, incolore à ambré clair (partie A polyol). Le durcisseur (partie B isocyanate) est un liquide incolore à jaunâtre. Le mélange dégage une chaleur modérée.',
    'Non applicable (réactif)',
    'Non polymérisée : soluble dans les cétones, esters. Polymérisée : insoluble et résistante.',
    1.10, 200.0,
    'Résine thermodurcissable à deux composants, offrant une grande résistance aux chocs et un aspect verre. Les isocyanates du durcisseur sont des sensibilisants respiratoires reconnus (asthme professionnel, rhinite allergique). Le mélange non polymérisé est irritant pour la peau et les voies respiratoires. Une fois complètement durcie (24-48h), la résine est inerte et non toxique.',
    'Par rapport à la résine époxy, la polyuréthane est moins visqueuse, coule mieux dans les moules complexes, et est plus résistante aux chocs. Le durcisseur isocyanate est plus dangereux à inhaler que les amines époxy ; il requiert des protections respiratoires spécifiques.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Porter impérativement des gants en nitrile épais (les isocyanates traversent le latex), un écran facial, un masque à cartouche filtrante combinée (vapeurs organiques + particules, type A2P3) ou un appareil respiratoire isolant si la ventilation est insuffisante. Travailler sous hotte aspirante. Éviter tout contact cutané et l''inhalation de vapeurs/aérosols.',
    'Inhalation : transporter la victime à l''air frais, consulter immédiatement un médecin. Peau : laver abondamment à l''eau et au savon, retirer les vêtements contaminés. Yeux : rincer 15 min, consulter un ophtalmologue. Ingestion : rincer la bouche, ne pas faire vomir, appeler un centre antipoison.',
    'Eau (réaction avec les isocyanates formant du CO₂ et des polyurées, expansion), amines, alcools, bases fortes.',
    'Récipients d''origine hermétiques, dans un endroit frais, sec et bien ventilé, à l''abri de l''humidité. Le durcisseur (isocyanate) doit être stocké sous atmosphère inerte (azote) après ouverture pour éviter la formation de cristaux.',
    10, 25, true, false, 6, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H317', 'H319', 'H332', 'H334', 'H335', 'H351', 'H373')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P260', 'P264', 'P272', 'P280', 'P284', 'P302+P352', 'P304+P340', 'P305+P351+P338', 'P308+P313', 'P333+P313', 'P403+P233')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Moulage de bijoux, figurines, prototypes, pièces techniques',
   'Mélanger les deux composants en respectant le ratio exact (généralement 1:1 ou 2:1 en poids), couler dans le moule. Temps de gel 5-15 min, démoulage après 30-60 min, durcissement complet en 24-48h à température ambiante.',
   'texte_libre', null, null, 'Selon le ratio du fabricant', 'Ambiante (18-25°C idéal)', 'Gel 5-15 min, durcissement complet 24-48 h', false, 0);

  -- ------------------------------------------------------------
  -- Colophane (rosin)
  -- ------------------------------------------------------------
  v_material_id := '53230c96-02a6-43ca-9f6f-716a08f15e15'::uuid;

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
    'Mélange d''acides résiniques (acide abiétique, acide pimarique, etc.) extrait de la résine de pin',
    'Colophane, Rosin, résine de pin, colophonium, poudre de colophane',
    'Technique, Artistique, Cosmétique',
    'Solide vitreux, cassant, jaune clair à brun, translucide, odeur de pin caractéristique. Point de ramollissement 70-90°C.',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, l''acétone, les essences, les huiles',
    1.08, 190.0,
    'Résine naturelle issue de la distillation de la gemme de pin. Agent filmogène, adhésif, augmentateur de frottement. Utilisée pour le fer à souder (flux), la colophane pour instruments à cordes (archets), et comme ingrédient dans des adhésifs et vernis. Peut provoquer des allergies de contact (dermatite), surtout sous forme oxydée.',
    'Par rapport à la gomme laque, elle est plus cassante et moins résistante à l''eau. Contrairement aux résines synthétiques, elle est naturelle, mais sensibilisante. Elle est le flux de soudure de référence.',
    'Faible',
    array['masque','gants'],
    'Porter un masque anti-poussière et des gants si manipulation de poudre fine ou chauffage (fumées irritantes). Peut provoquer des allergies de contact.',
    'Inhalation : air frais. Peau : laver au savon. Yeux : rincer 15 min. Ingestion : boire de l''eau, consulter un médecin si symptômes.',
    'Oxydants forts.',
    'Récipient étanche, au frais, à l''écart des sources de chaleur. La poudre est inflammable.',
    5, 30, false, false, 120, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H317', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P272', 'P280', 'P302+P352', 'P305+P351+P338', 'P333+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Flux de soudure pour électronique et plomberie',
   'Appliquer la colophane solide ou dissoute dans l''alcool sur les surfaces à souder. Nettoie les oxydes et favorise l''adhérence de la soudure.',
   'texte_libre', null, null, 'Quantité suffisante pour recouvrir la zone', '200-350°C (température de soudure)', 'Quelques secondes', false, 0),
  (v_academie_id, 'Résine pour archets d''instruments à cordes (violon, alto)',
   'Frotter le bloc de colophane sur le crin de l''archet. Augmente le frottement et la vibration des cordes.',
   'texte_libre', null, null, 'Application manuelle', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Gomme laque (shellac)
  -- ------------------------------------------------------------
  v_material_id := '330ce860-b5e3-46a6-9037-6a2a7eb37996'::uuid;

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
    'Résine naturelle exsudée par l''insecte Kerria lacca, composée d''esters d''acides aleuritique, jalaric et laccijalaric',
    'Shellac, gomme laque, résine laque, vernis à l''alcool, E904 (enrobage alimentaire)',
    'Technique, Alimentaire (E904), Cosmétique',
    'Paillettes dorées à brunes, ou poudre. La solution alcoolique est un liquide ambré. Odeur douce caractéristique.',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool (éthanol, méthanol), les solutions alcalines',
    1.10, 12.0,
    'Résine naturelle thermoplastique. Excellentes propriétés filmogènes, brillance, dureté. Utilisée comme vernis traditionnel (ébénisterie, lutherie), enrobage alimentaire (E904, confiserie, fruits), et en cosmétique (laque pour cheveux, vernis à ongles). La solution alcoolique est très inflammable (point éclair bas).',
    'Par rapport à la colophane, elle est plus dure, plus résistante à l''eau et ne ramollit pas à la chaleur corporelle. Contrairement aux résines synthétiques, elle est d''origine naturelle et comestible (E904). C''est le vernis traditionnel des meubles anciens.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. La solution alcoolique est très inflammable : manipuler loin des flammes.',
    'Yeux : rincer 15 min. Peau : laver à l''eau et au savon. Ingestion : boire de l''eau, consulter un médecin si symptômes.',
    'Oxydants forts, bases fortes, eau (précipitation de la résine).',
    'Récipient étanche, au frais, à l''écart des sources d''inflammation. La solution alcoolique doit être stockée comme un liquide inflammable.',
    5, 25, false, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H225', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P264', 'P280', 'P305+P351+P338', 'P403+P233')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Vernis traditionnel pour meubles, instruments de musique (lutherie)',
   'Dissoudre 100-200 g de gomme laque dans 1 L d''alcool à 95°. Appliquer au tampon (vernis au tampon) ou au pinceau. Séchage rapide (15-30 min).',
   'valeur_unique', 200.0, null, 'g/L d''alcool', 'Ambiante', 'Séchage 15-30 min', false, 0),
  (v_academie_id, 'Enrobage alimentaire (E904) pour confiseries, fruits, comprimés',
   'Appliquer une solution alcoolique diluée par pulvérisation ou trempage. L''alcool s''évapore en laissant un film protecteur brillant.',
   'texte_libre', null, null, 'Selon l''application', 'Ambiante', 'Séchage rapide', false, 1);

  -- ------------------------------------------------------------
  -- Acétate de polyvinyle (colle blanche)
  -- ------------------------------------------------------------
  v_material_id := '9b2d3039-3477-4bbc-afee-45481d331554'::uuid;

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
    'Poly(acétate de vinyle) (PVAc) en dispersion aqueuse',
    'Colle blanche, PVAc, colle vinylique, colle à bois, white glue',
    'Technique, Artistique',
    'Liquide visqueux blanc laiteux, odeur très faible ou nulle. Sèche en un film transparent et flexible.',
    '4-6 (légèrement acide)',
    'Miscible à l''eau à l''état liquide. Le film sec est insoluble dans l''eau mais peut être ramolli par l''humidité.',
    1.10, null,
    'Colle en dispersion aqueuse, sans solvant organique, non toxique, ininflammable une fois sèche. Excellente adhérence sur le bois, le papier, le carton, les tissus. Le film sec est transparent et flexible. Non résistante à l''eau (sauf versions D3 ou D4 pour usage extérieur).',
    'Par rapport à la colle cyanoacrylate, elle est non toxique, sans vapeur, mais le temps de séchage est plus long et nécessite un serrage. Contrairement à la colle époxy, elle est monocomposant et ne dégage pas de chaleur. C''est la colle standard pour le bois et les loisirs créatifs.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Laver les mains après usage.',
    'Yeux : rincer à l''eau. Peau : laver à l''eau tiède avant séchage. Ingestion : boire de l''eau.',
    'Bases fortes (coagulation), températures inférieures à 0°C (déstabilisation de la dispersion).',
    'Récipient hermétique, à l''abri du gel. Stocker entre +5 et +30°C.',
    5, 30, false, false, 24, 'a_valider'
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
  (v_academie_id, 'Collage du bois, papier, carton, tissus (menuiserie, loisirs créatifs, reliure)',
   'Appliquer une couche mince sur l''une des surfaces, assembler et serrer. Temps de prise : 30-60 min. Séchage complet en 24 h.',
   'texte_libre', null, null, 'Application directe', 'Ambiante (15-25°C idéal)', 'Prise 30-60 min, séchage complet 24 h', false, 0);

  -- ------------------------------------------------------------
  -- Silicone RTV (caoutchouc silicone pour moules)
  -- ------------------------------------------------------------
  v_material_id := 'b727ac0a-fc48-4cc4-85fd-1b7181753c94'::uuid;

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
    'Polydiméthylsiloxane linéaire réticulable à température ambiante (RTV-2, polycondensation ou polyaddition)',
    'Silicone RTV, caoutchouc de silicone, silicone de moulage, RTV silicone',
    'Technique, Artistique',
    'Liquide visqueux, blanc ou translucide (partie A). Le catalyseur (partie B) est un liquide clair ou coloré. Odeur caractéristique d''acide acétique (polycondensation) ou neutre (polyaddition).',
    'Non applicable (réactif)',
    'Non polymérisée : miscible aux solvants apolaires. Polymérisée : insoluble dans l''eau et les solvants, résistante chimiquement.',
    1.10, 100.0,
    'Élastomère de silicone vulcanisant à température ambiante après mélange avec un catalyseur. Excellente reproduction des détails, flexibilité, résistance à la chaleur (jusqu''à 200-300°C selon les grades), anti-adhérence naturelle (démoulage facile). Les silicones à polycondensation dégagent de l''acide acétique (odeur de vinaigre) ; les silicones à polyaddition sont inodores. Le catalyseur peut contenir des composés organostanniques (toxiques).',
    'Par rapport aux résines époxy ou polyuréthane pour moules, le silicone RTV est flexible, ce qui facilite le démoulage de pièces complexes sans agent de démoulage. Il est plus cher mais réutilisable de nombreuses fois.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. La silicone à polycondensation dégage de l''acide acétique : ventiler la pièce. Éviter le contact cutané avec le catalyseur.',
    'Peau : enlever mécaniquement, laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau.',
    'Certains matériaux inhibent la polymérisation (latex, soufre, amines, catalyseurs au platine pour polyaddition).',
    'Récipients d''origine hermétiques, à l''abri de l''humidité, dans un endroit frais. Le catalyseur doit être stocké séparément, à l''abri de la chaleur.',
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Fabrication de moules pour résines, plâtre, cire, savons',
   'Mélanger la silicone et le catalyseur (ratio 100:5 ou 100:10 selon les marques), débuller sous vide, couler sur le modèle. Polymérisation en 2-6 h à température ambiante. Démouler.',
   'texte_libre', null, null, 'Selon le ratio du fabricant', 'Ambiante (18-25°C)', 'Démoulage après 2-6 h', false, 0);
end $$;
