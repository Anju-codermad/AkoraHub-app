-- ============================================================
-- AkoraHub - Patch Phase 114 : ajout au catalogue de 23 nouveaux
-- colorants — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Exclus volontairement : 5 doublons (E163 déjà au catalogue ;
-- CI 19140 = Tartrazine E102 déjà au catalogue ; CI 42090 = Bleu
-- brillant FCF E133 déjà au catalogue ; CI 45410 et CI 47005 =
-- formes laque de l'Érythrosine E127 et du Jaune de quinoléine E104
-- déjà proposés dans la même liste) ; Rhodamine B (interdite en
-- alimentaire, suspectée cancérogène) et Violet de gentiane/Cristal
-- violet (IARC groupe 2B, cancérogène possible) — décision de
-- l'utilisatrice suivant la recommandation.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Colorants'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Colorants".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Colorants', 'Rouge de betterave / bétanine (E162)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Carmin / Cochenille (E120)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Chlorophylles et chlorophyllines (E140/E141)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Curcumine, extrait de curcuma (E100)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Extrait de paprika / capsanthine (E160c)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Lycopène, extrait de tomate (E160d)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Lutéine, extrait de tagète (E161b)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Noir végétal / charbon végétal (E153)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Rocou / Annatto (bixine, norbixine) (E160b)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Spiruline, extrait de phycocyanine', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Jaune de quinoléine (E104)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Rouge allura AC (E129)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Rouge carmoisine / Azorubine (E122)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Rouge érythrosine (E127)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Bleu patenté V (E131)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Vert S (E142)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Noir brillant BN (E151)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Brun FK (E154)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Brun HT (E155)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'CI 15850 (rouge lithol, laque de calcium)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'CI 61570 (vert D&C, laque d''aluminium)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'CI 77007 (outremer bleu)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'CI 77289 (vert d''oxyde de chrome)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'CI 77742 (violet de manganèse)', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Bleu de méthylène', 'rupture', null),
    (v_business_unit_id, 'Colorants', 'Fluorescéine', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
