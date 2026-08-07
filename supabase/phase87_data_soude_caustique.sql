-- ============================================================
-- AkoraHub - Patch Phase 87 : remplissage fiche Académie "Soude
-- caustique" (Hydroxyde de sodium NaOH) à partir du contenu généré
-- avec DeepSeek, vérifié par l'utilisatrice
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ Prérequis : cliquer "Enregistrer" dans l'app sur la fiche "Soude
-- caustique" AVANT d'exécuter ce script (pour que la ligne
-- matieres_premieres_academie et les 4 usages détaillés existent déjà
-- en base — ce script les complète, il ne les crée pas depuis zéro).
--
-- ⚠️ Après exécution : ne pas ré-appuyer sur "Enregistrer" sur l'écran
-- actuellement ouvert dans l'app (son état local ne connaît pas ces
-- nouvelles valeurs et écraserait ce script). Quittez l'écran et
-- rouvrez la fiche pour voir le contenu à jour.
--
-- ⚠️ 07/08 : id ciblé directement (au lieu d'une recherche par nom) —
-- il existe deux matières nommées "Soude caustique..." en base
-- (probablement un doublon), la recherche par nom tombait sur la
-- mauvaise et n'avait pas de fiche Académie enregistrée.
-- ============================================================

do $$
declare
  v_material_id uuid := 'fe71d1cb-6af9-4c80-ae72-840f8b358725'::uuid;
  v_academie_id uuid;
begin
  if v_material_id is null then
    raise exception 'Matière "Soude caustique" introuvable — vérifiez le nom exact dans raw_materials.';
  end if;

  update public.matieres_premieres_academie
  set
    densite = 2.13,
    point_eclair = null,
    particularite = 'Déliquescent (absorbe l''humidité de l''air et se liquéfie) – réaction de dissolution dans l''eau fortement exothermique.',
    difference_produit_similaire = 'Donne des savons plus durs et moins solubles que la potasse (KOH). Moins coûteuse, mais ne convient pas pour les savons liquides.',
    notes_epi = 'Gants en nitrile ou néoprène (pas de latex), lunettes de protection étanches ou écran facial, tablier résistant aux produits chimiques, bottes de sécurité. En cas de manipulation de poudre : masque anti-poussière.',
    premiers_secours = 'Contact peau : retirer les vêtements contaminés, rincer immédiatement à grande eau pendant au moins 15 minutes. Consulter un médecin. Contact yeux : rincer à l''eau courante en écartant les paupières pendant 15 minutes. Appeler immédiatement un médecin. Ingestion : rincer la bouche, ne pas faire vomir, boire un verre d''eau. Appeler immédiatement un centre antipoison ou un médecin. Inhalation : déplacer la personne à l''air libre, consulter un médecin en cas de gêne respiratoire.',
    incompatibilites = 'Acides (réaction violente), métaux légers (aluminium, zinc, magnésium → dégagement d''hydrogène inflammable), produits chlorés (dégagement de gaz toxiques). Ne jamais verser de l''eau sur la soude solide, toujours ajouter la soude à l''eau.',
    consignes_stockage = 'Conserver dans un récipient hermétique en plastique (PEHD ou PP) ou en acier inoxydable. Ne pas utiliser d''aluminium. Stocker dans un endroit frais, sec et bien ventilé, à l''écart des acides et matières incompatibles.',
    temperature_stockage_min = 5,
    temperature_stockage_max = 35,
    sensible_humidite = true,
    sensible_lumiere = false,
    duree_conservation_mois = 24,
    updated_at = now()
  where matiere_premiere_id = v_material_id
  returning id into v_academie_id;

  if v_academie_id is null then
    raise exception 'Aucune fiche Académie trouvée pour cette matière — avez-vous cliqué "Enregistrer" dans l''app avant d''exécuter ce script ?';
  end if;

  -- Phrases H suggérées par DeepSeek, vérifiées par l'utilisatrice
  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H290')
  on conflict (academie_id, phrase_h_id) do nothing;

  -- Phrases P suggérées par DeepSeek, vérifiées par l'utilisatrice
  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310', 'P405', 'P260')
  on conflict (academie_id, phrase_p_id) do nothing;

  -- Usages détaillés : complète les 4 lignes déjà créées (par domaine),
  -- ne fait rien si le domaine correspondant n'existe pas encore.
  update public.matieres_premieres_usages
  set technique_methode = 'Verser 100 g de soude dans le conduit bouché, ajouter progressivement 1 L d''eau froide. Laisser agir, puis rincer abondamment à l''eau chaude. Ne jamais utiliser d''eau chaude au départ.',
      dosage_type = 'valeur_unique',
      dosage_min = 100,
      unite_dosage = 'g (par utilisation)',
      temperature_utilisation = 'Eau froide (réaction exothermique)',
      temps_action = '30 minutes',
      a_verifier_labo = false
  where academie_id = v_academie_id and domaine_application = 'Débouchage canalisation';

  update public.matieres_premieres_usages
  set technique_methode = 'Préparer une solution diluée (ex. 10 %), ajouter lentement sous agitation dans le produit à ajuster. Contrôler le pH en continu jusqu''à la valeur cible.',
      dosage_type = 'plage',
      dosage_min = 0.1,
      dosage_max = 2,
      unite_dosage = '% (v/v) par rapport au volume du produit à ajuster',
      temperature_utilisation = 'Ambiante (20-25 °C)',
      temps_action = 'Instantané (ajuster pendant l''incorporation)',
      a_verifier_labo = true
  where academie_id = v_academie_id and domaine_application = 'Ajustement pH';

  update public.matieres_premieres_usages
  set technique_methode = 'Injecter une solution de soude diluée à 10 % dans le flux d''eau à traiter, doser en fonction du pH désiré. Utiliser une pompe doseuse pour un ajustement continu.',
      dosage_type = 'plage',
      dosage_min = 0.1,
      dosage_max = 1,
      unite_dosage = 'g/L (grammes de NaOH solide par litre d''eau à traiter)',
      temperature_utilisation = 'Ambiante (20-25 °C)',
      temps_action = 'Immédiat (réaction instantanée)',
      a_verifier_labo = true
  where academie_id = v_academie_id and domaine_application = 'Traitement de l''Eau';

  update public.matieres_premieres_usages
  set technique_methode = 'Dissoudre la soude dans l''eau (toujours ajouter la soude à l''eau, jamais l''inverse). Laisser refroidir jusqu''à 40-50 °C. Chauffer les huiles à la même température. Verser la solution de soude dans les huiles, mixer jusqu''à la trace, puis mouler.',
      dosage_type = 'plage',
      dosage_min = 12,
      dosage_max = 15,
      unite_dosage = '% par rapport au poids total des huiles (selon l''indice de saponification)',
      temperature_utilisation = '40-50 °C (mélange soude+eau et huiles)',
      temps_action = 'Quelques minutes (trace), puis 24-48 h de prise avant démoulage',
      a_verifier_labo = false
  where academie_id = v_academie_id and domaine_application = 'Savonnerie';
end $$;
