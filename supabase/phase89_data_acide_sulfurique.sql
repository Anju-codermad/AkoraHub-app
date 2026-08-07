-- ============================================================
-- AkoraHub - Patch Phase 89 : fiche Académie complète "Acide
-- sulfurique" (H₂SO₄) à partir du contenu généré avec DeepSeek,
-- vérifié par l'utilisatrice
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ 07/08 : converti en upsert — une fiche Académie existait déjà
-- pour cette matière (créée par une session précédente), le insert
-- brut échouait sur la contrainte unique (matiere_premiere_id).
-- ============================================================

do $$
declare
  v_material_id uuid := '244641c3-a4d2-4dc6-8007-7f0f7064412c'::uuid; -- Acide sulfurique
  v_academie_id uuid;
begin
  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite, difference_produit_similaire,
    niveau_danger, epi_requis, notes_epi, premiers_secours,
    incompatibilites, consignes_stockage, temperature_stockage_min,
    temperature_stockage_max, sensible_humidite, sensible_lumiere,
    duree_conservation_mois, statut_verification
  ) values (
    v_material_id,
    'Acide sulfurique (H₂SO₄)',
    'Acide sulfurique',
    null,
    'Liquide huileux, incolore à légèrement jaunâtre, inodore à l''état pur (à froid).',
    'Fortement acide – une solution à 1 % a un pH d''environ 1, une solution 0,1 M a un pH ≈ 1.',
    'Totalement miscible à l''eau en toutes proportions. La dilution est très exothermique (toujours verser l''acide dans l''eau, jamais l''inverse).',
    'Très hygroscopique et déshydratant (carbonise les matières organiques), réaction de dilution extrêmement exothermique. Densité 1,84 g/cm³ (acide concentré 96-98 %).',
    'Moins volatil que l''acide chlorhydrique (pas de vapeurs acides à température ambiante), mais plus agressif vis-à-vis des métaux et plus oxydant. Ne convient pas au détartrage courant à cause de la formation de sulfates de calcium insolubles.',
    'Corrosif',
    array['gants','lunettes','tablier','bottes','masque'],
    'Gants en caoutchouc butyle ou néoprène, lunettes de protection étanches ou écran facial, tablier anti-acide, bottes de sécurité. En cas de risque de brouillard ou de vapeurs (manipulation à chaud) : appareil respiratoire filtrant anti-gaz acides.',
    'Contact peau : retirer les vêtements contaminés, rincer immédiatement à grande eau pendant au moins 15 minutes. Ne pas neutraliser. Consulter un médecin. Contact yeux : rincer à l''eau courante en écartant les paupières pendant 15 minutes. Appeler immédiatement un médecin. Ingestion : rincer la bouche, ne pas faire vomir, faire boire un peu d''eau. Appeler immédiatement un centre antipoison ou un médecin. Inhalation : déplacer la personne à l''air libre, consulter un médecin en cas de gêne respiratoire.',
    'Bases (réaction violente), métaux légers et leurs alliages (dégagement d''hydrogène inflammable), matières organiques (risque d''incendie ou de carbonisation), oxydants forts, eau (ajout d''eau dans l''acide concentré provoque des éclaboussures dangereuses).',
    'Conserver dans des récipients en acier inoxydable ou en plastiques résistants (PEHD). Stocker debout, dans un local frais, sec, bien ventilé, à l''écart des bases, des matières combustibles et des sources de chaleur. Prévoir une rétention pour les fuites.',
    10,
    30,
    true,
    false,
    24,
    'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique,
    synonymes = excluded.synonymes,
    aspect = excluded.aspect,
    ph_solution = excluded.ph_solution,
    solubilite = excluded.solubilite,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger,
    epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi,
    premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  -- Repart de zéro pour les usages et les phrases H/P (au cas où une
  -- fiche précédente en avait déjà, pour ne pas se retrouver avec des
  -- doublons ou des sélections obsolètes).
  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  -- Phrases H suggérées par DeepSeek, vérifiées par l'utilisatrice
  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H290')
  on conflict (academie_id, phrase_h_id) do nothing;

  -- Phrases P suggérées par DeepSeek, vérifiées par l'utilisatrice
  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310', 'P405')
  on conflict (academie_id, phrase_p_id) do nothing;

  -- Usages détaillés
  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, dosage_texte,
    temperature_utilisation, temps_action, a_verifier_labo, ordre
  ) values
  (
    v_academie_id,
    'Nettoyage industriel',
    'Utiliser une solution diluée à 5-10 %, appliquer au pinceau ou par circulation, laisser agir, puis rincer abondamment. Ne pas utiliser sur aluminium, zinc, acier non protégé.',
    'dilution',
    null, null,
    '% (v/v)',
    '1 pour 10 à 1 pour 20 (acide/eau), soit environ 5-10 %',
    'Ambiante (20-25 °C) ; un léger chauffage (< 40 °C) accélère l''action mais dégage plus de vapeurs',
    '10 à 30 minutes selon l''épaisseur des dépôts',
    true,
    0
  ),
  (
    v_academie_id,
    'Détartrage',
    'Injection d''une solution à 2-5 % avec un inhibiteur de corrosion adapté. Circulation en boucle dans le circuit, suivi d''un rinçage neutralisant (bicarbonate). Non conseillé pour le tartre calcaire simple (forme du sulfate de calcium peu soluble) — à réserver aux circuits où les autres acides sont inefficaces.',
    'plage',
    2, 5,
    '%',
    null,
    '20-50 °C',
    '2 à 6 heures selon l''encrassement',
    true,
    1
  ),
  (
    v_academie_id,
    'Ajustement pH',
    'Injecter l''acide concentré ou dilué sous agitation dans le flux à traiter, en contrôlant en continu le pH avec une sonde. Préférer un dosage progressif pour éviter les variations brutales.',
    'plage',
    0.05, 2,
    '% (soit 0,5 à 20 g/L)',
    null,
    'Ambiante (20-25 °C)',
    'Instantané (ajuster le débit)',
    true,
    2
  ),
  (
    v_academie_id,
    'Batteries',
    'Dilution de l''acide sulfurique concentré (98 %) dans de l''eau déminéralisée jusqu''à la concentration souhaitée. Remplir les éléments de la batterie.',
    'valeur_unique',
    35, null,
    '% massique (33-37 %)',
    null,
    'Ambiante ; ne pas dépasser 50 °C en fonctionnement',
    'Non applicable (électrolyte permanent)',
    false,
    3
  );
end $$;
