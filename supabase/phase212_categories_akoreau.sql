-- ============================================================
-- AkoraHub - Patch Phase 212 : divise le pilier Akor'Eau en 7
-- catégories thématiques — demande explicite de la propriétaire le
-- 05/09/2026, après avoir remarqué que presque tous les produits
-- partageaient la catégorie générique "Akor'Eau" (choix volontaire au
-- lancement du pilier, phase191 : "pas de sous-catégories pour
-- l'instant... à subdiviser plus tard si besoin").
--
-- Nouvelles catégories : Coagulants, Floculants, Désinfection,
-- Correction du pH, Anti-tartre, Adoucissement, Filtration.
-- ("Traitement de l'eau & Piscine", créée en phase192, n'est pas
-- touchée — catégorie distincte, actuellement sans produit.)
--
-- Deux types de mise à jour selon comment le produit est rattaché à
-- Akor'Eau :
--   - Pilier PRINCIPAL (11 produits) : met à jour products.category
--     directement.
--   - Pilier SUPPLÉMENTAIRE (Hypochlorite de calcium, STPP — liés via
--     product_extra_business_units, phase202/211) : met à jour la
--     colonne `category` du LIEN uniquement (phase208) — ne touche pas
--     à leur catégorie sous Akora Pro (Désinfectants, Épaississants).
--   - Charbon actif : "Charbon actif (vrac)" (phase41) n'a en fait
--     jamais eu de fiche `products` (jamais vendable). Le produit déjà
--     publié qui correspond réellement à l'usage eau est "Charbon Actif
--     Granulaire (GAC) – Filtration Eau" (créé indépendamment, sous
--     Akora Pro) — relié ici à Akor'Eau plutôt que dupliqué, décision
--     de la propriétaire le 05/09/2026.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing / UPDATE sans effet si déjà appliqué).
-- ============================================================

do $$
declare
  v_akoreau_id uuid;
begin
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';
  if v_akoreau_id is null then
    raise exception 'Aucun pilier avec le slug "akor-eau" trouvé — arrêt.';
  end if;

  -- ============================================================
  -- 1) Crée les 7 nouvelles catégories
  -- ============================================================
  insert into public.categories (business_unit_id, name)
  select v_akoreau_id, c.name
  from (values
    ('Coagulants'), ('Floculants'), ('Désinfection'),
    ('Correction du pH'), ('Anti-tartre'), ('Adoucissement'), ('Filtration')
  ) as c(name)
  on conflict (business_unit_id, name) do nothing;

  -- ============================================================
  -- 2) Produits dont Akor'Eau est le pilier PRINCIPAL
  -- ============================================================
  update public.products set category = 'Coagulants'
    where business_unit_id = v_akoreau_id and name in (
      'Sulfate d''aluminium (Sulfate d''alumine)',
      'PAC (Polychlorure d''aluminium)',
      'Chlorure ferrique (FeCl₃)',
      'Sulfate ferrique (Fe₂(SO₄)₃)'
    );

  update public.products set category = 'Floculants'
    where business_unit_id = v_akoreau_id and name in (
      'Polymeres floculants',
      'Polyacrylamide (PAM)'
    );

  update public.products set category = 'Désinfection'
    where business_unit_id = v_akoreau_id and name in (
      'TCCA (Trichloroisocyanurate)'
    );

  update public.products set category = 'Correction du pH'
    where business_unit_id = v_akoreau_id and name in (
      'Chaux eteinte',
      'Bisulfate de sodium (NaHSO₄)'
    );

  update public.products set category = 'Anti-tartre'
    where business_unit_id = v_akoreau_id and name in (
      'Hexamétaphosphate de sodium (SHMP)'
    );

  update public.products set category = 'Adoucissement'
    where business_unit_id = v_akoreau_id and name in (
      'Résine échangeuse de cations (adoucissement)'
    );

  -- ============================================================
  -- 3) Produits reliés à Akor'Eau comme pilier SUPPLÉMENTAIRE —
  --    catégorie du LIEN uniquement, pas de products.category
  -- ============================================================
  update public.product_extra_business_units
  set category = 'Désinfection'
  where business_unit_id = v_akoreau_id
    and product_id = (select id from public.products where name = 'Hypochlorite de calcium 70%');

  update public.product_extra_business_units
  set category = 'Anti-tartre'
  where business_unit_id = v_akoreau_id
    and product_id = (select id from public.products where name = 'Tripolyphosphate de sodium STPP (E451)');

  -- Charbon actif : "Charbon actif (vrac)" (phase41) n'a en fait jamais
  -- eu de fiche `products` (jamais vendable). À sa place, "Charbon Actif
  -- Granulaire (GAC) – Filtration Eau" existe déjà, publié, sous Akora
  -- Pro — créé indépendamment (style de nom différent, probablement la
  -- conversation du site). Décision de la propriétaire le 05/09/2026 :
  -- le relier à Akor'Eau plutôt que d'en créer un nouveau.
  declare
    v_gac_id uuid;
  begin
    select id into v_gac_id from public.products
      where name = 'Charbon Actif Granulaire (GAC) – Filtration Eau';
    if v_gac_id is not null then
      insert into public.product_extra_business_units (product_id, business_unit_id, category)
      values (v_gac_id, v_akoreau_id, 'Filtration')
      on conflict (product_id, business_unit_id) do update set category = excluded.category;
    else
      raise notice '"Charbon Actif Granulaire (GAC) – Filtration Eau" introuvable — rien relié.';
    end if;
  end;

  -- ============================================================
  -- 4) Nettoyage : retire la catégorie générique "Akor'Eau" devenue
  --    vide (si elle existait en tant que ligne dans `categories`)
  -- ============================================================
  delete from public.categories
  where business_unit_id = v_akoreau_id and name = 'Akor''Eau';
end $$;

-- Vérification :
-- select category, name from public.products
-- where business_unit_id = (select id from public.business_units where slug = 'akor-eau')
-- order by category, name;
-- select bu.name, peb.category, p.name from public.product_extra_business_units peb
-- join public.business_units bu on bu.id = peb.business_unit_id
-- join public.products p on p.id = peb.product_id
-- where bu.slug = 'akor-eau';
