-- ============================================================
-- AkoraHub - Patch Phase 86 : seed des pictogrammes SGH/CLP et des
-- phrases H (danger) / P (précaution) les plus courantes
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ⚠️ Prérequis : phase85_patch_academie_pictogrammes_dosages.sql (+ le
-- code Flutter à jour) doit déjà avoir été exécuté.
--
-- Contexte (06/08) : `danger_pictograms`/`phrases_h`/`phrases_p` sont
-- des catalogues de référence (codes réglementaires SGH/CLP), pas du
-- contenu propre à AkoraHub — on les préremplit une fois ici plutôt que
-- de construire un écran d'administration dédié pour les saisir un par
-- un. Le staff pourra en ajouter d'autres plus tard directement via
-- l'éditeur de table Supabase si besoin (cas rare).
--
-- `image_url` est laissé vide (pas d'images hébergées pour l'instant) —
-- l'app affiche le code + le nom sous forme de badge texte tant qu'aucune
-- image n'est renseignée.
-- ============================================================

insert into public.danger_pictograms (code, nom) values
  ('GHS01', 'Explosif'),
  ('GHS02', 'Inflammable'),
  ('GHS03', 'Comburant'),
  ('GHS04', 'Gaz sous pression'),
  ('GHS05', 'Corrosif'),
  ('GHS06', 'Toxique'),
  ('GHS07', 'Irritant / Nocif'),
  ('GHS08', 'Danger pour la santé'),
  ('GHS09', 'Danger pour l''environnement')
on conflict (code) do nothing;

insert into public.phrases_h (code, texte) values
  ('H225', 'Liquide et vapeurs très inflammables'),
  ('H226', 'Liquide et vapeurs inflammables'),
  ('H290', 'Peut être corrosif pour les métaux'),
  ('H302', 'Nocif en cas d''ingestion'),
  ('H303', 'Peut être nocif en cas d''ingestion'),
  ('H304', 'Peut être mortel en cas d''ingestion et de pénétration dans les voies respiratoires'),
  ('H311', 'Toxique par contact cutané'),
  ('H312', 'Nocif par contact cutané'),
  ('H314', 'Provoque des brûlures de la peau et des lésions oculaires graves'),
  ('H315', 'Provoque une irritation cutanée'),
  ('H317', 'Peut provoquer une allergie cutanée'),
  ('H318', 'Provoque des lésions oculaires graves'),
  ('H319', 'Provoque une sévère irritation des yeux'),
  ('H331', 'Toxique par inhalation'),
  ('H332', 'Nocif par inhalation'),
  ('H335', 'Peut irriter les voies respiratoires'),
  ('H336', 'Peut provoquer somnolence ou vertiges'),
  ('H351', 'Susceptible de provoquer le cancer'),
  ('H400', 'Très toxique pour les organismes aquatiques'),
  ('H410', 'Très toxique pour les organismes aquatiques, entraîne des effets néfastes à long terme'),
  ('H411', 'Toxique pour les organismes aquatiques, entraîne des effets néfastes à long terme'),
  ('H412', 'Nocif pour les organismes aquatiques, entraîne des effets néfastes à long terme')
on conflict (code) do nothing;

insert into public.phrases_p (code, texte) values
  ('P101', 'En cas de consultation d''un médecin, garder à disposition le récipient ou l''étiquette'),
  ('P102', 'Tenir hors de portée des enfants'),
  ('P210', 'Tenir à l''écart de la chaleur, des surfaces chaudes, des étincelles, des flammes nues et de toute autre source d''inflammation. Ne pas fumer'),
  ('P233', 'Maintenir le récipient fermé de manière étanche'),
  ('P260', 'Ne pas respirer les poussières/fumées/gaz/brouillards/vapeurs/aérosols'),
  ('P264', 'Se laver soigneusement après manipulation'),
  ('P271', 'Utiliser seulement en plein air ou dans un endroit bien ventilé'),
  ('P280', 'Porter des gants de protection/des vêtements de protection/un équipement de protection des yeux/du visage'),
  ('P301+P330+P331', 'EN CAS D''INGESTION : rincer la bouche. NE PAS faire vomir'),
  ('P302+P352', 'EN CAS DE CONTACT AVEC LA PEAU : laver abondamment à l''eau'),
  ('P303+P361+P353', 'EN CAS DE CONTACT AVEC LA PEAU (ou les cheveux) : enlever immédiatement les vêtements contaminés. Rincer la peau à l''eau'),
  ('P304+P340', 'EN CAS D''INHALATION : transporter la personne à l''extérieur et la maintenir dans une position où elle peut confortablement respirer'),
  ('P305+P351+P338', 'EN CAS DE CONTACT AVEC LES YEUX : rincer avec précaution à l''eau pendant plusieurs minutes. Enlever les lentilles de contact si la victime en porte et si elles peuvent être facilement enlevées'),
  ('P310', 'Appeler immédiatement un CENTRE ANTIPOISON/un médecin'),
  ('P312', 'Appeler un CENTRE ANTIPOISON/un médecin en cas de malaise'),
  ('P321', 'Traitement spécifique (voir les indications sur cette étiquette)'),
  ('P332+P313', 'En cas d''irritation cutanée : consulter un médecin'),
  ('P337+P313', 'Si l''irritation oculaire persiste : consulter un médecin'),
  ('P362+P364', 'Enlever les vêtements contaminés et les laver avant réutilisation'),
  ('P403+P233', 'Stocker dans un endroit bien ventilé. Maintenir le récipient fermé de manière étanche'),
  ('P405', 'Garder sous clef'),
  ('P501', 'Éliminer le contenu/récipient conformément à la réglementation locale')
on conflict (code) do nothing;
