-- ============================================================
-- AkoraHub - Patch Phase 108 : ajout au catalogue de 16 nouveaux
-- solvants — contenu DeepSeek, vérifié par l'utilisatrice.
-- Inclut 3 produits sensibles (Éther diéthylique, n-Hexane, Xylène)
-- ajoutés sur décision explicite de l'utilisatrice ; ils recevront
-- un grade strict "Technique" et des avertissements renforcés dans
-- leur fiche Académie.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Solvants'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Solvants".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Solvants', 'Acétone (propan-2-one)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'White spirit (naphta lourd)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Butylène glycol (1,3-butanediol)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Dipropylène glycol', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'D-Limonène (terpène d''agrumes)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Essence de térébenthine', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Méthyléthylcétone (MEK, butanone)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Propylène glycol monométhyl éther (PGME)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Xylène (diméthylbenzène, xylol)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'n-Hexane', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Isoparaffine (C10-C13)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Carbonate de propylène', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Éther diéthylique (éther éthylique)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Éthoxydiglycol (Transcutol)', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'Cyclohexane', 'rupture', null),
    (v_business_unit_id, 'Solvants', 'DMSO (diméthylsulfoxyde)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
