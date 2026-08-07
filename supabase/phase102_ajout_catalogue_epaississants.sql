-- ============================================================
-- AkoraHub - Patch Phase 102 : ajout de 10 nouveaux épaississants au
-- catalogue "Épaississants" (raw_materials), suggérés par DeepSeek et
-- validés par l'utilisatrice. Stock à 'rupture', prix vide par défaut
-- — à compléter dans l'admin (fiche produit) une fois approvisionnée.
--
-- Volontairement exclus de la liste DeepSeek : Bentonite, Silice
-- colloïdale, Kaolin, Hectorite/Laponite (relèvent de "Charges
-- Minérales") ; Cire d'abeille/carnauba/candelilla, Acides gras
-- stéarique/palmitique (relèvent de "Huiles & Beurres Cosmétiques") ;
-- Carbomères, Polyacrylates, PVA, PVP, PEG (relèvent de "Polymères &
-- Résines") ; sucres/polyols et protéines (hors sujet/trop niche).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Épaississants'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Épaississants" — vérifiez qu''au moins un produit existe déjà dans cette catégorie.';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Épaississants', 'Gomme de caroube (LBG, E410)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'Gomme Tara (E417)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'Gomme gellane (E418)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'Gomme de konjac (E425)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'Alginate de sodium (E401)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'Gomme karaya (E416)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'Gomme adragante (E413)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'HPMC (hydroxypropylméthylcellulose, E464)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'Méthylcellulose (E461)', 'rupture', null),
    (v_business_unit_id, 'Épaississants', 'Éthylcellulose (E462)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
