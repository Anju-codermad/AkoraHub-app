-- ============================================================
-- AkoraHub - Patch Phase 149 : nouvelle catégorie Académie
-- "Oxydants & Agents de Blanchiment" (13/13) — comble le vide
-- identifié après la recherche infructueuse de "Percarbonate de
-- soude" dans le catalogue produits (10/08) : aucun des 12 piliers
-- terminés ne couvrait les agents oxydants/blanchissants utilisés en
-- fabrication de détergents en poudre.
--
-- Diligence doublon inter-catégories (grep supabase/*.sql) : l'acide
-- peracétique, l'hypochlorite de calcium/sodium et le peroxyde
-- d'hydrogène sont DÉJÀ documentés dans la catégorie "Désinfectants"
-- (phase99-101, 16/16 terminée) — volontairement PAS re-créés ici
-- pour éviter un doublon. Cette catégorie se concentre sur les 5
-- matières encore absentes, spécifiques au blanchiment/oxydation en
-- détergence poudre :
--   1) Percarbonate de sodium — l'agent recherché à l'origine
--   2) Perborate de sodium monohydraté
--   3) TAED (activateur de blanchiment basse température)
--   4) Persulfate de sodium (oxydant technique)
--   5) Azurant optique (blancheur perçue, pas un oxydant chimique
--      à proprement parler, mais indissociable d'une formule de
--      lessive en poudre complète — inclus dans cette catégorie
--      plutôt que d'en créer une 14e pour un seul produit)
--
-- Contenu DeepSeek, à faire vérifier par l'utilisatrice comme les
-- 12 catégories précédentes (statut_verification = 'a_valider').
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ------------------------------------------------------------
-- 0) Codes H/P manquants au catalogue (phase86) — nécessaires pour
-- classer correctement les comburants (percarbonate, perborate,
-- persulfate), absents des 12 catégories précédentes qui ne
-- comptaient aucun oxydant solide classé comburant.
-- ------------------------------------------------------------
insert into public.phrases_h (code, texte) values
  ('H272', 'Peut aggraver un incendie; comburant')
on conflict (code) do nothing;

insert into public.phrases_p (code, texte) values
  ('P220', 'Tenir/Stocker à l''écart des vêtements et des matières combustibles'),
  ('P221', 'Prendre toute précaution pour éviter le mélange avec des matières combustibles')
on conflict (code) do nothing;

do $$
declare
  v_business_unit_id uuid;
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- Même pilier "Matières Premières" que les 12 catégories déjà
  -- créées — réutilise le business_unit_id d'une catégorie existante
  -- plutôt que de le redéclarer en dur.
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Désinfectants'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé (catégorie "Désinfectants" introuvable).';
  end if;

  -- ------------------------------------------------------------
  -- Percarbonate de sodium
  -- ------------------------------------------------------------
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Oxydants & Agents de Blanchiment', 'Percarbonate de sodium', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do update set updated_at = now()
  returning id into v_material_id;

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
    'Carbonate de sodium peroxyhydraté (2Na₂CO₃·3H₂O₂)',
    'Percarbonate de soude, PCS, Sodium Percarbonate, "oxygène actif" solide',
    'Technique / Détergence',
    'Poudre ou granulés blancs, légère odeur d''oxygène',
    '10-11 (solution à 1 %)',
    'Soluble dans l''eau — se dissout en libérant du carbonate de sodium et du peroxyde d''hydrogène (environ 27-28 % d''oxygène actif)',
    2.1, null,
    'Agent de blanchiment à l''oxygène de référence en détergence poudre moderne, en remplacement progressif du perborate (pas de bore, meilleur profil environnemental). Peu actif en dessous de 40-50 °C utilisé seul — nécessite un activateur (TAED) pour un blanchiment efficace en lavage à basse température (30-40 °C). Sensible à l''humidité : se décompose prématurément si mal stocké, d''où l''enrobage (silicate/carbonate de sodium) sur les qualités commerciales pour améliorer la stabilité.',
    'Comparé au perborate de sodium : dissolution plus rapide, aucune trace de bore (substance sous restriction réglementaire croissante), mais légèrement moins stable au stockage prolongé en ambiance humide — d''où l''intérêt des qualités enrobées.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Éviter tout contact de la poudre avec des matières combustibles, des réducteurs ou des poussières métalliques (catalysent la décomposition et le dégagement d''oxygène).',
    'Yeux : rincer abondamment 15 min, consulter si persistance. Peau : laver à l''eau. Inhalation : air frais. Ingestion : rincer la bouche, ne pas faire vomir, consulter un médecin.',
    'Matières combustibles, réducteurs, acides, métaux lourds et leurs sels (catalysent la décomposition), autres oxydants forts.',
    'Récipient hermétique, au sec, local frais, à l''écart de la chaleur et de toute matière combustible ou métallique.',
    5, 25, true, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H318', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P220', 'P280', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détergents en poudre (agent blanchissant à l''oxygène)',
   'Incorporer en poudre après les autres composants secs, en fin de mélange, pour limiter le contact prolongé avec l''humidité résiduelle du mix. Associer systématiquement au TAED (voir fiche dédiée) pour une activation efficace en lavage à basse température ; seul, n''est réellement actif qu''au-delà de 50-60 °C.',
   'plage', 10, 25, '% de la formule poudre', '30-60 °C selon activation', 'Cycle de lavage complet (30-90 min)', true, 0),
  (v_academie_id, 'Détachants oxygénés / poudres multi-usages',
   'Diluer dans l''eau tiède avant application ou incorporer directement dans une poudre détachante. Laisser agir en tremper avant lavage.',
   'plage', 15, 30, '% de la formule poudre', '30-50 °C', '30 min à quelques heures en trempage', true, 1);

  -- ------------------------------------------------------------
  -- Perborate de sodium monohydraté
  -- ------------------------------------------------------------
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Oxydants & Agents de Blanchiment', 'Perborate de sodium monohydraté', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do update set updated_at = now()
  returning id into v_material_id;

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
    'Perborate de sodium monohydraté (NaBO₃·H₂O)',
    'Perborate de sodium, PBS-1, Sodium Perborate Monohydrate',
    'Technique / Détergence',
    'Poudre cristalline blanche, inodore',
    '10 (solution à 1 %)',
    'Modérément soluble dans l''eau froide, bien meilleure à chaud',
    2.2, null,
    'Libère du peroxyde d''hydrogène en solution, comme le percarbonate, mais avec une meilleure stabilité au stockage en ambiance humide et une dissolution plus lente. Contient du bore : substance sous surveillance réglementaire croissante (restrictions REACH sur les composés du bore dans certaines juridictions) — vérifier la réglementation en vigueur avant tout usage commercial et prévoir une alternative percarbonate si besoin.',
    'Comparé au percarbonate de sodium : plus stable au stockage prolongé mais dissolution plus lente et présence de bore (percarbonate = zéro bore, aujourd''hui privilégié dans la plupart des formulations modernes).',
    'Modéré',
    array['gants','lunettes','masque'],
    'Éviter tout contact avec des matières combustibles ou réductrices ; port de gants et lunettes recommandé lors de la manipulation de la poudre.',
    'Yeux : rincer abondamment 15 min. Peau : laver à l''eau. Inhalation : air frais. Ingestion : rincer la bouche, ne pas faire vomir, consulter un médecin.',
    'Matières combustibles, réducteurs, acides, métaux lourds (catalysent la décomposition), autres oxydants forts.',
    'Récipient hermétique, au sec, local frais, à l''écart de la chaleur et des matières combustibles.',
    5, 25, true, false, 18, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H318', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P220', 'P280', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détergents en poudre (agent blanchissant à l''oxygène, alternative au percarbonate)',
   'Mêmes principes d''incorporation que le percarbonate : ajouter en fin de mélange sec, associer à un activateur (TAED) pour une efficacité en lavage à basse température. À réserver aux formulations où la stabilité au stockage prime sur la vitesse de dissolution.',
   'plage', 10, 20, '% de la formule poudre', '40-60 °C selon activation', 'Cycle de lavage complet (30-90 min)', true, 0);

  -- ------------------------------------------------------------
  -- TAED (Tétraacétyléthylènediamine)
  -- ------------------------------------------------------------
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Oxydants & Agents de Blanchiment', 'TAED (Tétraacétyléthylènediamine)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do update set updated_at = now()
  returning id into v_material_id;

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
    'N,N,N'',N''-Tétraacétyléthylènediamine (TAED)',
    'TAED, activateur de blanchiment',
    'Technique / Détergence',
    'Poudre cristalline blanche, faible odeur',
    'Neutre (peu soluble à froid)',
    'Faiblement soluble dans l''eau froide, réagit avec le peroxyde d''hydrogène libéré par le percarbonate/perborate en solution',
    1.2, null,
    'N''est PAS un oxydant en lui-même : c''est un ACTIVATEUR. Il réagit avec le peroxyde d''hydrogène libéré par le percarbonate ou le perborate pour former in situ de l''acide peracétique, beaucoup plus actif à basse température. Permet un blanchiment efficace dès 30-40 °C au lieu des 50-60 °C+ nécessaires avec l''oxydant seul — utile pour les cycles de lavage économes en énergie. Toujours utilisé EN COMPLÉMENT d''un oxydant (percarbonate/perborate), jamais seul.',
    'Sans TAED, le percarbonate/perborate reste globalement inactif en dessous de 40-50 °C ; avec TAED, l''efficacité de blanchiment à froid est comparable à celle d''un lavage chaud sans activateur.',
    'Faible',
    array['lunettes','masque'],
    'Éviter la génération de poussière lors du dosage ; lunettes recommandées.',
    'Yeux : rincer abondamment 15 min. Peau : laver à l''eau. Inhalation : air frais.',
    'Oxydants forts en contact direct concentré (réaction prévue en solution diluée, pas en mélange sec concentré), acides forts.',
    'Récipient hermétique, au sec, température ambiante.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détergents en poudre basse température (activateur de percarbonate/perborate)',
   'Mélanger avec le percarbonate ou le perborate dans un ratio typique d''environ 3 à 4 parts d''oxydant pour 1 part de TAED. Incorporer en poudre avec les autres composants secs. Ne fonctionne qu''en présence d''un oxydant à activer — inutile seul.',
   'plage', 3, 8, '% de la formule poudre', '30-40 °C (lavage basse température)', 'Cycle de lavage complet (30-90 min)', true, 0);

  -- ------------------------------------------------------------
  -- Persulfate de sodium
  -- ------------------------------------------------------------
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Oxydants & Agents de Blanchiment', 'Persulfate de sodium', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do update set updated_at = now()
  returning id into v_material_id;

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
    'Persulfate de sodium (Na₂S₂O₈)',
    'Sodium Persulfate, peroxydisulfate de sodium, SPS',
    'Technique',
    'Poudre cristalline blanche, inodore',
    '3-4 (solution à 1 %, légèrement acide)',
    'Très soluble dans l''eau',
    2.4, null,
    'Oxydant puissant : se décompose en libérant des radicaux sulfate, un pouvoir oxydant supérieur au percarbonate/perborate mais un usage plus spécialisé (formulations techniques industrielles, amorceur de polymérisation, gravure) — moins courant en lessive grand public. Décomposition accélérée par la chaleur et les métaux (fer, cuivre).',
    'Contrairement au percarbonate/perborate qui libèrent du peroxyde d''hydrogène, le persulfate agit via des radicaux sulfate : oxydant plus puissant mais usage plus technique/spécialisé, à réserver aux formulations testées en laboratoire.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Sensibilisant respiratoire et cutané reconnu (risque d''asthme professionnel en cas d''exposition répétée) : port impératif d''un masque en cas de manipulation fréquente ou de poussière, éviter tout contact cutané prolongé.',
    'Yeux : rincer 15 min. Peau : laver abondamment, retirer les vêtements contaminés. Inhalation : air frais, consulter si toux ou gêne respiratoire persiste. Ingestion : rincer la bouche, consulter un médecin.',
    'Matières combustibles, réducteurs, métaux (fer, cuivre catalysent la décomposition), acides, bases fortes, amines.',
    'Récipient hermétique, au sec, local frais, à l''écart de la chaleur et des matières incompatibles.',
    5, 25, true, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H315', 'H317', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P220', 'P261', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Additif technique en détergence poudre industrielle',
   'Usage mineur et spécialisé en complément du percarbonate dans certaines formulations techniques pour renforcer le pouvoir oxydant à froid. Compte tenu du profil de sensibilisation respiratoire, à réserver aux formulations testées et validées en laboratoire, pas pour un usage artisanal courant.',
   'plage', 2, 5, '% de la formule poudre', 'Ambiante à 40 °C', 'Cycle de lavage complet', true, 0);

  -- ------------------------------------------------------------
  -- Azurant optique
  -- ------------------------------------------------------------
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Oxydants & Agents de Blanchiment', 'Azurant optique', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do update set updated_at = now()
  returning id into v_material_id;

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
    'Agent blanchissant fluorescent, généralement de type dérivé stilbène-triazine (formule exacte variable selon fournisseur)',
    'Azurant optique, FWA (Fluorescent Whitening Agent), blancheur optique — noms commerciaux courants : Tinopal CBS-X, Blankophor',
    'Technique / Détergence',
    'Poudre ou granulés blanc-jaunâtre, parfois liquide concentré jaune pâle selon le fournisseur',
    '7-9 (solution diluée)',
    'Soluble ou dispersible dans l''eau selon la formulation (poudre ou liquide)',
    null, null,
    'N''EST PAS un agent de blanchiment chimique : il absorbe les UV et les réémet dans le bleu visible, ce qui compense le jaunissement naturel du linge et donne une perception de "blanc plus blanc". Utilisé à très faible dose (0,05-0,3 %). Aucun effet réel sur les taches ni sur la désinfection — rôle purement optique/esthétique, à ne pas confondre avec le percarbonate ou le TAED qui, eux, blanchissent chimiquement.',
    'Contrairement au percarbonate/perborate/TAED (blanchiment chimique réel des taches et matières colorées), l''azurant optique n''agit que sur la perception visuelle de blancheur : les deux familles sont complémentaires dans une formule de lessive complète, pas substituables l''une à l''autre.',
    'Faible',
    array['gants','masque'],
    'Éviter l''inhalation de poussières lors du dosage ; gants recommandés (irritation ou sensibilisation cutanée légère possible chez les personnes sensibles selon le produit).',
    'Yeux : rincer à l''eau. Peau : laver à l''eau et au savon. Inhalation : air frais.',
    'Oxydants forts en très forte concentration (peuvent dégrader l''azurant et réduire son efficacité — dosage séparé recommandé en cas de doute), peu réactif par ailleurs.',
    'Récipient fermé, à l''abri de la lumière directe et de la chaleur prolongée (certains azurants se dégradent aux UV).',
    5, 30, false, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détergents en poudre et liquides (blancheur optique perçue)',
   'Ajouter en toute fin de formulation et bien disperser pour éviter les points de sur-concentration (risque de taches jaunes localisées sur textile clair en cas de surdosage mal mélangé). Réservé au linge blanc/clair : à proscrire sur les couleurs foncées, où il peut ternir ou griser le rendu.',
   'plage', 0.05, 0.3, '% de la formule', 'Ambiante à 60 °C (cycle de lavage)', 'Cycle de lavage complet', false, 0);

end $$;
