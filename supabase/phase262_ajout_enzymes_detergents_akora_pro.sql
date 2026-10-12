-- ============================================================
-- AkoraHub - Patch Phase 262 : ajout des enzymes de lessive (Protéase,
-- Amylase, Lipase, Cellulase) — lacune identifiée lors de l'audit des
-- matières premières pour la fabrication de détergents liquides
-- (discussion du 12/10 sur l'acide chlorhydrique manquant), jamais
-- ajoutée depuis. Absentes des deux tables (raw_materials/Académie et
-- products) avant ce script.
--
-- Contenu non inventé : chaque enzyme est l'une des 4 familles
-- standard utilisées en formulation de lessive (détachage par type de
-- salissure) — information générale et bien établie dans l'industrie
-- du détergent, pas une donnée propre à un fournisseur. Pas de CAS,
-- dosage, activité enzymatique (U/g) ni pureté inventés.
--
-- Nouvelle catégorie "Enzymes" sous Akora Pro (pilier
-- matieres-premieres), à la fois dans raw_materials (fiche Académie)
-- ET dans products (brouillon catalogue, visibility = false), liés
-- par raw_material_id — même logique que la synchronisation de la
-- phase158, mais faite directement ici pour ces 4 matières.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict / where not exists).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Fiches Académie (raw_materials).
-- ------------------------------------------------------------

insert into public.raw_materials
  (business_unit_id, category_name, name, description, safety_note, stock_status)
select bu.id, v.category_name, v.name, v.description, v.safety_note, 'en_stock'
from (values
  ($$matieres-premieres$$, $$Enzymes$$, $$Protéase$$,
   $$Enzyme protéolytique qui dégrade les protéines en fragments plus petits (peptides, acides aminés) ; incorporée dans les formulations de lessive pour aider à éliminer les taches d'origine protéique (sang, œuf, herbe, sueur).$$,
   $$Les poudres d'enzymes concentrées peuvent provoquer une sensibilisation respiratoire ou cutanée par inhalation répétée ou contact prolongé — manipuler avec gants et protection respiratoire, éviter de mettre en suspension la poudre dans l'air.$$),
  ($$matieres-premieres$$, $$Enzymes$$, $$Amylase$$,
   $$Enzyme amylolytique qui dégrade l'amidon en sucres plus simples ; incorporée dans les formulations de lessive et de lave-vaisselle pour aider à éliminer les taches amidonnées (sauces, féculents, bouillies).$$,
   $$Les poudres d'enzymes concentrées peuvent provoquer une sensibilisation respiratoire ou cutanée par inhalation répétée ou contact prolongé — manipuler avec gants et protection respiratoire, éviter de mettre en suspension la poudre dans l'air.$$),
  ($$matieres-premieres$$, $$Enzymes$$, $$Lipase$$,
   $$Enzyme lipolytique qui dégrade les graisses et huiles en acides gras et glycérol ; incorporée dans les formulations de lessive pour aider à éliminer les taches grasses (huile, beurre, sauces grasses).$$,
   $$Les poudres d'enzymes concentrées peuvent provoquer une sensibilisation respiratoire ou cutanée par inhalation répétée ou contact prolongé — manipuler avec gants et protection respiratoire, éviter de mettre en suspension la poudre dans l'air.$$),
  ($$matieres-premieres$$, $$Enzymes$$, $$Cellulase$$,
   $$Enzyme cellulolytique qui agit sur les microfibrilles de cellulose à la surface des fibres de coton ; utilisée en lessive pour raviver l'aspect du tissu, réduire le boulochage et adoucir le toucher après lavages répétés.$$,
   $$Les poudres d'enzymes concentrées peuvent provoquer une sensibilisation respiratoire ou cutanée par inhalation répétée ou contact prolongé — manipuler avec gants et protection respiratoire, éviter de mettre en suspension la poudre dans l'air.$$)
) as v(bu_slug, category_name, name, description, safety_note)
join public.business_units bu on bu.slug = v.bu_slug
on conflict (business_unit_id, category_name, name) do nothing;

-- ------------------------------------------------------------
-- 2) Catégorie "Enzymes" côté catalogue (table categories, utilisée
-- pour le filtrage par catégorie dans l'app — distincte de
-- raw_materials.category_name).
-- ------------------------------------------------------------

insert into public.categories (business_unit_id, name)
select bu.id, 'Enzymes'
from public.business_units bu
where bu.slug = 'matieres-premieres'
on conflict (business_unit_id, name) do nothing;

-- ------------------------------------------------------------
-- 3) Produits brouillons liés (catalogue Akora Pro), avec usages
-- complets dès la création (cf. phase261 : éviter de republier des
-- fiches incomplètes).
-- ------------------------------------------------------------

insert into public.products (
  business_unit_id, category, name, description, use_cases,
  raw_material_id, visibility
)
select rm.business_unit_id, rm.category_name, rm.name, rm.description, v.use_cases, rm.id, false
from public.raw_materials rm
join (values
  ($$Protéase$$, array['Détachant pour taches protéiques (sang, œuf, herbe, sueur)','Lessives liquides et poudres','Détergents industriels textiles']),
  ($$Amylase$$, array['Détachant pour taches d''amidon (sauces, féculents, bouillies)','Lessives liquides et poudres','Détergents pour lave-vaisselle']),
  ($$Lipase$$, array['Détachant pour taches grasses (huile, beurre, sauces)','Lessives liquides et poudres','Dégraissants industriels']),
  ($$Cellulase$$, array['Avivage et adoucissement des textiles en coton','Lessives liquides','Réduction du boulochage des tissus'])
) as v(name, use_cases) on v.name = rm.name
where rm.category_name = 'Enzymes'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = rm.business_unit_id and p.name = rm.name
  );

-- Garde-fou : prévenir si le pilier Akora Pro n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'matieres-premieres'
  ) then
    raise notice 'Aucun pilier avec le slug ''matieres-premieres'' (Akora Pro) trouvé — enzymes non insérées.';
  end if;
end $$;

-- Vérification :
-- select p.category, p.name, p.description, p.use_cases, p.visibility
-- from public.products p
-- join public.business_units bu on bu.id = p.business_unit_id
-- where bu.slug = 'matieres-premieres' and p.category = 'Enzymes'
-- order by p.name;
