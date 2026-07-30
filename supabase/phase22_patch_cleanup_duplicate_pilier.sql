-- ============================================================
-- AkoraHub - Nettoyage : doublon du pilier "Matières Premières"
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : deux sessions différentes ont créé "Matières Premières" avec
-- des slugs différents (matieres-premieres vs matieres-premieres-chimiques),
-- donc la protection anti-doublon (unique sur slug) ne les a pas vus comme
-- le même pilier. Ce script :
--   1. Garde le pilier slug='matieres-premieres' (celui qui a déjà ses 12
--      catégories, créé en premier)
--   2. Transfère vers lui tout produit/catégorie qui aurait été accroché
--      par erreur à l'autre (normalement rien, par sécurité)
--   3. Supprime le doublon vide (slug='matieres-premieres-chimiques')
-- ============================================================

do $$
declare
  keep_id uuid;
  dup_id uuid;
begin
  select id into keep_id from public.business_units
    where slug = 'matieres-premieres';
  select id into dup_id from public.business_units
    where slug = 'matieres-premieres-chimiques';

  if keep_id is null or dup_id is null then
    raise notice 'Rien à nettoyer (un des deux piliers est déjà absent).';
    return;
  end if;

  -- Migre toute catégorie/produit qui serait accroché au doublon
  update public.categories set business_unit_id = keep_id
    where business_unit_id = dup_id;
  update public.products set business_unit_id = keep_id
    where business_unit_id = dup_id;

  delete from public.business_units where id = dup_id;

  raise notice 'Doublon supprimé, pilier conservé : %', keep_id;
end $$;

-- Vérification : un seul "Matières Premières" doit apparaître désormais
select name, slug, active from public.business_units
where name = 'Matières Premières';
