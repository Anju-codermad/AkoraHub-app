-- ============================================================
-- AkoraHub - Patch Phase 96 : ajout de 10 nouveaux chélatants au
-- catalogue "Chélatants" (raw_materials), suggérés par DeepSeek et
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
  where category_name = 'Chélatants'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Chélatants" — vérifiez qu''au moins un produit existe déjà dans cette catégorie.';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Chélatants', 'EDTA tétrasodique (Na₄EDTA)', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'GLDA', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'MGDA', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'Gluconate de sodium (E576)', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'HEDP (acide étidronique)', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'ATMP', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'DTPA', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'Polyaspartate de sodium', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'Acide phytique (E391)', 'rupture', null),
    (v_business_unit_id, 'Chélatants', 'DTPMPA', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
