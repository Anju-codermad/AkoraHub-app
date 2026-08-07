-- ============================================================
-- AkoraHub - Patch Phase 111 : ajout au catalogue de 16 nouvelles
-- charges minérales — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Exclus volontairement : Terre d'infusoires (quasi-doublon de la
-- "Diatomite / Kieselguhr" déjà au catalogue) et Sable de quartz
-- (silice cristalline respirable, cancérogène avéré IARC groupe 1) —
-- décision de l'utilisatrice suivant la recommandation.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Charges Minérales'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Charges Minérales".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Charges Minérales', 'Talc (silicate de magnésium)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Kaolin (silicate d''aluminium)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Mica (silicate d''aluminium et de potassium)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Illite (argile verte)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Rhassoul (argile marocaine, ghassoul)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Perlite expansée', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Vermiculite expansée', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Zéolithe naturelle (clinoptilolite)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Dolomie (carbonate de calcium et magnésium)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Gypse (sulfate de calcium dihydraté)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Sulfate de baryum naturel (barytine)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Phosphate tricalcique', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Pierre ponce (poudre)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Graphite (carbone minéral)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Oxyde de zinc (poudre)', 'rupture', null),
    (v_business_unit_id, 'Charges Minérales', 'Oxyde de magnésium', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
