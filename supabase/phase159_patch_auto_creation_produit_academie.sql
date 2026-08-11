-- ============================================================
-- AkoraHub - Patch Phase 159 : création automatique du produit
-- catalogue quand une matière première Académie est ajoutée
--
-- Contexte (11/08, demande explicite) : phase148/phase158 faisaient ce
-- travail manuellement, à rejouer à chaque fois qu'une nouvelle matière
-- première est ajoutée. Ce patch automatise ça via deux déclencheurs
-- qui appellent la même fonction idempotente :
--   1) après insertion dans `raw_materials` (matière juste créée, sans
--      fiche Académie détaillée pour l'instant)
--   2) après insertion/mise à jour dans `matieres_premieres_academie`
--      (fiche détaillée créée ou complétée — la particularité devient
--      disponible pour la description du produit)
-- Les deux appellent la même fonction, avec les mêmes garde-fous que
-- le script manuel (jamais d'écrasement d'une fiche produit existante,
-- jamais de doublon) — sûr d'exécuter plusieurs fois pour la même
-- matière première au fil de sa création.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create or replace function public.sync_product_from_raw_material(p_raw_material_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $func$
declare
  v_rm record;
  v_academie record;
  v_usages text[];
  v_description text;
begin
  select * into v_rm from public.raw_materials where id = p_raw_material_id;
  if not found then
    return;
  end if;

  select * into v_academie
    from public.matieres_premieres_academie
    where matiere_premiere_id = p_raw_material_id;

  if v_academie.id is not null then
    select array_agg(distinct u.domaine_application order by u.domaine_application)
      into v_usages
      from public.matieres_premieres_usages u
      where u.academie_id = v_academie.id;
  end if;

  v_description := coalesce(nullif(trim(v_academie.particularite), ''), nullif(trim(v_rm.description), ''));

  -- Lier un produit déjà existant du même nom/catégorie, pas encore lié.
  update public.products
  set raw_material_id = p_raw_material_id
  where raw_material_id is null
    and name = v_rm.name
    and category = v_rm.category_name;

  -- Compléter la description d'un produit lié mais encore vide.
  if v_description is not null then
    update public.products
    set description = v_description
    where raw_material_id = p_raw_material_id
      and (description is null or trim(description) = '');
  end if;

  -- Créer le produit (brouillon) s'il n'existe vraiment pas encore.
  if not exists (select 1 from public.products where raw_material_id = p_raw_material_id)
     and not exists (select 1 from public.products where name = v_rm.name and category = v_rm.category_name)
  then
    insert into public.products (
      business_unit_id, category, name, description, use_cases,
      raw_material_id, visibility
    ) values (
      v_rm.business_unit_id,
      v_rm.category_name,
      v_rm.name,
      v_description,
      coalesce(v_usages, '{}'),
      p_raw_material_id,
      false -- brouillon : invisible côté client tant que non publié
    );
  end if;
end;
$func$;

create or replace function public.trg_sync_product_from_raw_material()
returns trigger
language plpgsql
security definer
set search_path = public
as $func$
begin
  perform public.sync_product_from_raw_material(new.id);
  return new;
end;
$func$;

drop trigger if exists sync_product_after_raw_material_insert on public.raw_materials;
create trigger sync_product_after_raw_material_insert
  after insert on public.raw_materials
  for each row execute function public.trg_sync_product_from_raw_material();

create or replace function public.trg_sync_product_from_academie()
returns trigger
language plpgsql
security definer
set search_path = public
as $func$
begin
  perform public.sync_product_from_raw_material(new.matiere_premiere_id);
  return new;
end;
$func$;

drop trigger if exists sync_product_after_academie_insert on public.matieres_premieres_academie;
create trigger sync_product_after_academie_insert
  after insert or update on public.matieres_premieres_academie
  for each row execute function public.trg_sync_product_from_academie();
