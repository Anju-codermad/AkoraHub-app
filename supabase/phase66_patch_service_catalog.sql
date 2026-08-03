-- ============================================================
-- AkoraHub - Patch Phase 66 : catalogue de services (onglet "Services")
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : jusqu'ici l'onglet "Services" ne proposait qu'un pilier +
-- un objet en texte libre. L'utilisateur a fourni une vision détaillée
-- (7 catégories, 35 services) et veut pouvoir activer/désactiver chaque
-- service depuis l'admin au fur et à mesure qu'il devient réellement
-- disponible — tous les services ci-dessous sont créés DÉSACTIVÉS
-- (`available = false`) par défaut : à l'admin d'activer ceux déjà
-- proposés aujourd'hui depuis le nouvel écran "Catalogue de services".
-- ============================================================

create table if not exists public.service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.service_catalog_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.service_categories(id) on delete cascade,
  name text not null,
  description text,
  available boolean not null default false,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (category_id, name)
);

create index if not exists service_catalog_items_category_idx
  on public.service_catalog_items (category_id);

alter table public.service_categories enable row level security;
alter table public.service_catalog_items enable row level security;

-- Les catégories elles-mêmes sont visibles de tous (juste des noms de
-- regroupement) ; le filtrage se fait au niveau des services.
drop policy if exists "service_categories_select_all" on public.service_categories;
create policy "service_categories_select_all" on public.service_categories
  for select using (true);

drop policy if exists "service_categories_write_staff" on public.service_categories;
create policy "service_categories_write_staff" on public.service_categories
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- Un client ne voit que les services activés ; le staff voit tout
-- (pour pouvoir activer/désactiver depuis l'admin).
drop policy if exists "service_catalog_items_select" on public.service_catalog_items;
create policy "service_catalog_items_select" on public.service_catalog_items
  for select using (available = true or public.current_role_is_staff());

drop policy if exists "service_catalog_items_write_staff" on public.service_catalog_items;
create policy "service_catalog_items_write_staff" on public.service_catalog_items
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- Une demande de service pointe maintenant vers un service précis du
-- catalogue plutôt qu'un simple pilier + texte libre (business_unit_id
-- reste en base pour les anciennes demandes déjà envoyées).
alter table public.service_requests
  add column if not exists service_catalog_item_id uuid
    references public.service_catalog_items(id);

-- ------------------------------------------------------------
-- Seed : 7 catégories, 35 services (vision fournie par l'utilisateur),
-- tous désactivés par défaut.
-- ------------------------------------------------------------

insert into public.service_categories (name, sort_order) values
  ('Nettoyage & Hygiène des espaces', 1),
  ('Blanchisserie & Soin du linge', 2),
  ('Traitement & Protection', 3),
  ('Cosmétiques & Bien-être', 4),
  ('Agro-industrie & Transformation', 5),
  ('Laboratoire & R&D', 6),
  ('Services logistiques & terrain', 7)
on conflict (name) do nothing;

insert into public.service_catalog_items (category_id, name, description, sort_order)
select c.id, v.name, v.description, v.sort_order
from public.service_categories c
cross join (values
  ('Nettoyage industriel', 'Usines, entrepôts, zones de production', 1),
  ('Nettoyage après sinistre', 'Après incendie, inondation, dégât des eaux', 2),
  ('Nettoyage de vitres en hauteur', 'Immeubles, grandes surfaces vitrées', 3),
  ('Nettoyage de toiture et façade', 'Démoussage, nettoyage haute pression', 4),
  ('Nettoyage de véhicules', 'Auto, moto, camion — intérieur et extérieur', 5),
  ('Désinfection médicale', 'Cliniques, cabinets, laboratoires médicaux', 6)
) as v(name, description, sort_order)
where c.name = 'Nettoyage & Hygiène des espaces'
on conflict (category_id, name) do nothing;

insert into public.service_catalog_items (category_id, name, description, sort_order)
select c.id, v.name, v.description, v.sort_order
from public.service_categories c
cross join (values
  ('Blanchisserie hôtelière', 'Contrats réguliers avec hôtels et resorts', 1),
  ('Nettoyage vêtements professionnels', 'Uniformes, blouses, tenues de travail', 2),
  ('Nettoyage rideau et voilage', 'Retrait, lavage et repose inclus', 3),
  ('Nettoyage costumes & robes', 'Tenues de soirée, robes de mariée', 4),
  ('Pressing express à domicile', 'Repassage et livraison en 24h', 5)
) as v(name, description, sort_order)
where c.name = 'Blanchisserie & Soin du linge'
on conflict (category_id, name) do nothing;

insert into public.service_catalog_items (category_id, name, description, sort_order)
select c.id, v.name, v.description, v.sort_order
from public.service_categories c
cross join (values
  ('Traitement anti-termites', 'Protection du bois et des structures', 1),
  ('Fumigation', 'Traitement des espaces fermés contre les nuisibles', 2),
  ('Traitement anti-moisissures', 'Murs humides, salles de bain, caves', 3),
  ('Désinfection climatiseurs', 'Nettoyage et désinfection des filtres', 4),
  ('Traitement eau de forage', 'Analyse et traitement des forages privés', 5)
) as v(name, description, sort_order)
where c.name = 'Traitement & Protection'
on conflict (category_id, name) do nothing;

insert into public.service_catalog_items (category_id, name, description, sort_order)
select c.id, v.name, v.description, v.sort_order
from public.service_categories c
cross join (values
  ('Soin beauté naturel sur mesure', 'Formulation de produits cosmétiques personnalisés', 1),
  ('Atelier beauté DIY', 'Apprendre à fabriquer ses propres cosmétiques', 2),
  ('Conseil beauté naturelle', 'Recommandations produits selon type de peau', 3),
  ('Spa à domicile', 'Soins relaxants réalisés chez le client', 4)
) as v(name, description, sort_order)
where c.name = 'Cosmétiques & Bien-être'
on conflict (category_id, name) do nothing;

insert into public.service_catalog_items (category_id, name, description, sort_order)
select c.id, v.name, v.description, v.sort_order
from public.service_categories c
cross join (values
  ('Transformation fruits locaux', 'Jus, sirops, confitures, fruits séchés', 1),
  ('Production jus minceur / détox', 'Jus santé à base d''ingrédients naturels malgaches', 2),
  ('Fabrication fromage artisanal', 'Formation et production de fromages locaux', 3),
  ('Vinification artisanale', 'Vin de fruits, bières artisanales locales', 4),
  ('Conditionnement et emballage', 'Service de mise en bouteille et étiquetage', 5),
  ('Analyse qualité alimentaire', 'Tests conformité produits agroalimentaires', 6)
) as v(name, description, sort_order)
where c.name = 'Agro-industrie & Transformation'
on conflict (category_id, name) do nothing;

insert into public.service_catalog_items (category_id, name, description, sort_order)
select c.id, v.name, v.description, v.sort_order
from public.service_categories c
cross join (values
  ('Formulation sur mesure', 'Création de formules pour marques externes', 1),
  ('Analyse eau (pH, microbiologie)', 'Tests qualité eau pour particuliers et entreprises', 2),
  ('Analyse produits chimiques', 'Contrôle qualité pour tiers', 3),
  ('Certification produits', 'Accompagnement BNM, conformité NMG', 4),
  ('Sous-traitance fabrication', 'Fabriquer les produits d''autres marques (OEM)', 5)
) as v(name, description, sort_order)
where c.name = 'Laboratoire & R&D'
on conflict (category_id, name) do nothing;

insert into public.service_catalog_items (category_id, name, description, sort_order)
select c.id, v.name, v.description, v.sort_order
from public.service_categories c
cross join (values
  ('Livraison express à domicile', 'Livraison produits en moins de 24h à Tana', 1),
  ('Recharge Éco (vrac)', 'Recharge des flacons clients à prix réduit', 2),
  ('Gestion stock externalisée', 'Gérer les stocks produits d''hygiène pour entreprises', 3),
  ('Approvisionnement B2B', 'Fourniture régulière hôtels, bureaux, cliniques', 4)
) as v(name, description, sort_order)
where c.name = 'Services logistiques & terrain'
on conflict (category_id, name) do nothing;

-- Vérification : 7 catégories, 35 services, tous désactivés au départ
select cat.name as categorie, count(i.id) as nb_services,
       count(i.id) filter (where i.available) as nb_disponibles
from public.service_categories cat
left join public.service_catalog_items i on i.category_id = cat.id
group by cat.name
order by min(cat.sort_order);
