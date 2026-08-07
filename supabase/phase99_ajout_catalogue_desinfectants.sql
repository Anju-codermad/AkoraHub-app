-- ============================================================
-- AkoraHub - Patch Phase 99 : ajout de 11 nouveaux désinfectants au
-- catalogue "Désinfectants" (raw_materials), suggérés par DeepSeek et
-- validés par l'utilisatrice. Stock à 'rupture', prix vide par défaut
-- — à compléter dans l'admin (fiche produit) une fois approvisionnée.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Désinfectants'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Désinfectants" — vérifiez qu''au moins un produit existe déjà dans cette catégorie.';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Désinfectants', 'Chlorure de benzalkonium (BAC)', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'Chlorure de didecyldiméthylammonium (DDAC)', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'Éthanol 96° (alcool éthylique)', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'Isopropanol (IPA)', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'PHMB (polyhexaméthylène biguanide)', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'BCDMH (brome piscine/SPA)', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'Dioxyde de chlore (kit chlorite de sodium + activateur)', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'Glutaraldéhyde 50%', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'Chloramine-T', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'Nitrate d''argent (AgNO₃)', 'rupture', null),
    (v_business_unit_id, 'Désinfectants', 'Iode cristallisé (I₂)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
