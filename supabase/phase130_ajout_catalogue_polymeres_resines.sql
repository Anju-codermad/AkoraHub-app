-- ============================================================
-- AkoraHub - Patch Phase 130 : ajout au catalogue de 20 nouveaux
-- polymères et résines — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Carbomère, PVA, PVP et PEG avaient été volontairement écartés de
-- la catégorie "Épaississants" (phase102) précisément pour être
-- traités ici. Réintégrés à cette liste malgré l'hypothèse erronée
-- de DeepSeek qu'ils étaient déjà documentés ailleurs.
-- Aucune exclusion sécurité : produits légaux et courants (résine
-- époxy et résine UV seront documentées avec avertissements
-- renforcés sur la sensibilisation cutanée, sans exclusion).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Polymères & Résines'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Polymères & Résines".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Polymères & Résines', 'Carbomère (Carbopol)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Copolymère d''acrylates', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Polyacrylate de sodium (épaississant)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Polyvinylpyrrolidone (PVP)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Alcool polyvinylique (PVA)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Polyéthylène glycol (PEG)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Copolymère VP/VA (fixateur capillaire)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Diméthicone', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Cyclopentasiloxane / Cyclométhicone', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Polyquaternium (conditionneur capillaire)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Résine acrylique filmogène (vernis à ongles, mascara)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Polyuréthane filmogène (vernis)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Résine époxy', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Résine polyester', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Résine UV (acrylate photopolymérisable)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Résine polyuréthane (bijouterie/art)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Colophane (rosin)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Gomme laque (shellac)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Acétate de polyvinyle (colle blanche)', 'rupture', null),
    (v_business_unit_id, 'Polymères & Résines', 'Silicone RTV (caoutchouc silicone pour moules)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
