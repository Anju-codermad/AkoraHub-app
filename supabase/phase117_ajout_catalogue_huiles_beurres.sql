-- ============================================================
-- AkoraHub - Patch Phase 117 : ajout au catalogue de 37 nouvelles
-- huiles, beurres et cires cosmétiques — contenu DeepSeek, vérifié
-- par l'utilisatrice.
--
-- Huile de neem incluse sur décision explicite de l'utilisatrice
-- suivant la recommandation (avertissements renforcés prévus dans
-- sa fiche Académie : usage externe uniquement, ingestion dangereuse
-- notamment chez le nourrisson, également utilisable comme biocide
-- naturel — chevauchement avec la catégorie "Anti-Nuisibles").
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Huiles & Beurres Cosmétiques'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Huiles & Beurres Cosmétiques".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile d''olive', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de palme', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de palmiste', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de tournesol', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de ricin', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile d''amande douce', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de jojoba', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile d''argan', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de coco fractionnée (caprylic/capric triglyceride)', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de pépin de raisin', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile d''avocat', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de sésame', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de noisette', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de macadamia', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de noyau d''abricot', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de chanvre', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de bourrache', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile d''onagre', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de rose musquée', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de neem', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de germe de blé', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de coton', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de soja', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile de maïs', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Huile d''arachide', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Beurre de mangue', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Beurre de kokum', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Beurre de sal', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Beurre de mowrah', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Beurre d''illipe', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Beurre de cupuaçu', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Beurre de babassu', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Cire de candelilla', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Cire de soja', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Lanoline', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Cire de riz', 'rupture', null),
    (v_business_unit_id, 'Huiles & Beurres Cosmétiques', 'Cire d''acacia (mimosa)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
