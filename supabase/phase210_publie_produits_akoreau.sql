-- ============================================================
-- AkoraHub - Patch Phase 210 : publie les 12 produits Akor'Eau restés
-- en brouillon depuis les phases 190/195 — demande explicite de la
-- propriétaire le 05/09/2026, après relecture du tableau récapitulatif
-- (danger, dosage, EPI) présenté pour ces 12 fiches.
--
-- Renumérotée de 203 à 210 (05/09/2026) : la conversation du site avait
-- entretemps déjà pris les numéros 203-209 pour le pilier "Akora
-- NutriLab" — collision de numérotation résolue en renommant ce
-- fichier, aucun changement de contenu autrement.
--
-- Les 2 autres produits du pilier (Hypochlorite de calcium 70%,
-- Sulfate d'aluminium) étaient déjà publiés — non concernés ici.
--
-- Scopé par nom ET pilier Akor'Eau (pas un UPDATE global sur
-- visibility) pour ne toucher que ces 12 produits précisément.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (sans effet si déjà publié).
-- ============================================================

do $$
declare
  v_akoreau_id uuid;
  v_names text[] := array[
    'TCCA (Trichloroisocyanurate)',
    'Chaux eteinte',
    'Polymeres floculants',
    'PAC (Polychlorure d''aluminium)',
    'Hexamétaphosphate de sodium (SHMP)',
    'Bisulfate de sodium (NaHSO₄)',
    'Charbon actif granulaire (GAC)',
    'STPP — grade traitement de l''eau (anti-tartre)',
    'Polyacrylamide (PAM)',
    'Chlorure ferrique (FeCl₃)',
    'Sulfate ferrique (Fe₂(SO₄)₃)',
    'Résine échangeuse de cations (adoucissement)'
  ];
  v_published_count int;
begin
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';
  if v_akoreau_id is null then
    raise exception 'Aucun pilier avec le slug "akor-eau" trouvé — arrêt.';
  end if;

  update public.products
  set visibility = true
  where business_unit_id = v_akoreau_id
    and name = any(v_names);
  get diagnostics v_published_count = row_count;
  raise notice '% produit(s) publié(s).', v_published_count;
end $$;

-- Vérification : les 14 produits Akor'Eau doivent tous être visibility = true
-- select name, visibility from public.products
-- where business_unit_id = (select id from public.business_units where slug = 'akor-eau')
-- order by name;
