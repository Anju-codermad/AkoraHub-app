-- ============================================================
-- AkoraHub - Patch Phase 124 : ajout au catalogue de 30 nouveaux
-- conservateurs et antioxydants — contenu DeepSeek, vérifié par
-- l'utilisatrice.
--
-- Exclus volontairement : doublons inter-catégories (Alcool
-- benzylique déjà dans Solvants ; EDTA déjà dans Chélatants ; Acide
-- citrique, Acide acétique, Acide formique appartenant à la famille
-- Acides & Bases ; Phosphates déjà couverts via Charges Minérales) ;
-- doublons de grade avec produits déjà existants (Sorbate de
-- potassium cosmétique/œnologique, Benzoate de sodium cosmétique —
-- fusionnés dans les fiches existantes) ; Propyl/Butylparabène
-- (restrictions UE sévères, perturbateurs endocriniens suspectés) et
-- Biphényle/E230 (retiré des additifs alimentaires autorisés en UE
-- depuis 2004) — décisions de l'utilisatrice suivant la
-- recommandation. BHA/E320, BHT/E321 et Hexaméthylènetétramine/E239
-- inclus avec avertissements renforcés sur décision de l'utilisatrice.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Conservateurs & Antioxydants'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Conservateurs & Antioxydants".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Phénoxyéthanol', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Acide benzoïque (E210)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Acide déhydroacétique (DHA) et sodium déhydroacétate', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Méthylparabène', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Éthylparabène', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Éthylhexylglycérine', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Caprylyl glycol', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Capryloyl glycine', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Extrait de radis fermenté (Leucidal)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Gluconolactone', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Acide lévulinique + Acide p-anisique (blend conservateur naturel)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Acide salicylique (usage conservateur cosmétique)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Propionate de calcium (E282)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Propionate de sodium (E281)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Acide propionique (E280)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Natamycine (E235)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Hexaméthylènetétramine (E239)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Tocophérols (vitamine E naturelle)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Extrait de romarin (acide rosmarinique)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Palmitate d''ascorbyle (E304)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'BHA (Butylhydroxyanisole, E320)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'BHT (Butylhydroxytoluène, E321)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Gallate de propyle (E310)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Gallate d''octyle (E311)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Gallate de dodécyle (E312)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Citrate de sodium (E331)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Tartrate de sodium (E335)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Ascorbate de calcium (E302)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Anhydride sulfureux (SO₂)', 'rupture', null),
    (v_business_unit_id, 'Conservateurs & Antioxydants', 'Dicarbonate de diméthyle (DMDC, E242)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do nothing;
end $$;
