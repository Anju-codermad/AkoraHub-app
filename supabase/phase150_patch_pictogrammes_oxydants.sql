-- ============================================================
-- AkoraHub - Patch Phase 150 : pictogrammes SGH/CLP pour les 5
-- matières de la catégorie "Oxydants & Agents de Blanchiment"
-- (phase149) — jusqu'ici, les pictogrammes (`academie_pictograms`)
-- n'étaient jamais posés automatiquement par script pour AUCUNE des
-- 13 catégories, uniquement sélectionnables à la main dans l'éditeur
-- admin. Ce patch le fait pour les 5 nouvelles matières seulement,
-- cohérent avec les phrases H déjà assignées en phase149 :
--   GHS03 (comburant)  <-> H272
--   GHS05 (corrosif)   <-> H318 (lésions oculaires graves)
--   GHS07 (irritant)   <-> H302/H315/H317/H319/H335
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ⚠️ Prérequis : phase149_categorie_oxydants_agents_blanchiment.sql
-- déjà exécuté.
-- ============================================================

do $$
declare
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Percarbonate de sodium : GHS03 + GHS05 + GHS07
  -- ------------------------------------------------------------
  select a.id into v_academie_id
  from public.matieres_premieres_academie a
  join public.raw_materials rm on rm.id = a.matiere_premiere_id
  where rm.category_name = 'Oxydants & Agents de Blanchiment'
    and rm.name = 'Percarbonate de sodium';

  if v_academie_id is not null then
    delete from public.academie_pictograms where academie_id = v_academie_id;
    insert into public.academie_pictograms (academie_id, pictogram_id)
    select v_academie_id, id from public.danger_pictograms where code in ('GHS03', 'GHS05', 'GHS07')
    on conflict (academie_id, pictogram_id) do nothing;
  end if;

  -- ------------------------------------------------------------
  -- Perborate de sodium monohydraté : GHS03 + GHS05 + GHS07
  -- ------------------------------------------------------------
  select a.id into v_academie_id
  from public.matieres_premieres_academie a
  join public.raw_materials rm on rm.id = a.matiere_premiere_id
  where rm.category_name = 'Oxydants & Agents de Blanchiment'
    and rm.name = 'Perborate de sodium monohydraté';

  if v_academie_id is not null then
    delete from public.academie_pictograms where academie_id = v_academie_id;
    insert into public.academie_pictograms (academie_id, pictogram_id)
    select v_academie_id, id from public.danger_pictograms where code in ('GHS03', 'GHS05', 'GHS07')
    on conflict (academie_id, pictogram_id) do nothing;
  end if;

  -- ------------------------------------------------------------
  -- TAED : GHS07 seulement (irritant léger, pas de comburant)
  -- ------------------------------------------------------------
  select a.id into v_academie_id
  from public.matieres_premieres_academie a
  join public.raw_materials rm on rm.id = a.matiere_premiere_id
  where rm.category_name = 'Oxydants & Agents de Blanchiment'
    and rm.name = 'TAED (Tétraacétyléthylènediamine)';

  if v_academie_id is not null then
    delete from public.academie_pictograms where academie_id = v_academie_id;
    insert into public.academie_pictograms (academie_id, pictogram_id)
    select v_academie_id, id from public.danger_pictograms where code in ('GHS07')
    on conflict (academie_id, pictogram_id) do nothing;
  end if;

  -- ------------------------------------------------------------
  -- Persulfate de sodium : GHS03 + GHS07
  -- ------------------------------------------------------------
  select a.id into v_academie_id
  from public.matieres_premieres_academie a
  join public.raw_materials rm on rm.id = a.matiere_premiere_id
  where rm.category_name = 'Oxydants & Agents de Blanchiment'
    and rm.name = 'Persulfate de sodium';

  if v_academie_id is not null then
    delete from public.academie_pictograms where academie_id = v_academie_id;
    insert into public.academie_pictograms (academie_id, pictogram_id)
    select v_academie_id, id from public.danger_pictograms where code in ('GHS03', 'GHS07')
    on conflict (academie_id, pictogram_id) do nothing;
  end if;

  -- ------------------------------------------------------------
  -- Azurant optique : GHS07 seulement (danger "Faible")
  -- ------------------------------------------------------------
  select a.id into v_academie_id
  from public.matieres_premieres_academie a
  join public.raw_materials rm on rm.id = a.matiere_premiere_id
  where rm.category_name = 'Oxydants & Agents de Blanchiment'
    and rm.name = 'Azurant optique';

  if v_academie_id is not null then
    delete from public.academie_pictograms where academie_id = v_academie_id;
    insert into public.academie_pictograms (academie_id, pictogram_id)
    select v_academie_id, id from public.danger_pictograms where code in ('GHS07')
    on conflict (academie_id, pictogram_id) do nothing;
  end if;
end $$;
