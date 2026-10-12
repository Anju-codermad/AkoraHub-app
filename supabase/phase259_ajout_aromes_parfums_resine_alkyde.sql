-- ============================================================
-- AkoraHub - Patch Phase 259 : brouillons arômes alimentaires (Akora
-- Foods), parfums pour détergents liquides (Akora Pro) et résine
-- alkyde (Akora Coatings) — demande explicite de la propriétaire
-- (12/10), à partir de 2 listes fournisseur (codes réf. + conditionnement)
-- et d'un document de fiches détaillées déjà préparé par ailleurs pour
-- 7 arômes + la résine alkyde.
--
-- Contenu non inventé : descriptions rédigées selon les mêmes règles
-- que le document fourni ("Règles communes pour AkoraHub" : pas de
-- code-barres/dosage/pureté/formule/numéro CAS inventé) — uniquement
-- des notes sensorielles et usages plausibles pour la famille de
-- produits, pas des caractéristiques techniques garanties. Les 7
-- arômes + la résine alkyde dont une fiche détaillée existait déjà
-- reprennent ce contenu ; les 15 arômes et 12 parfums restants suivent
-- le même style, à vérifier/compléter auprès du fournisseur.
--
-- Créés en BROUILLON (visibility = false) : ni prix, ni photo, ni
-- stock réels fournis — à compléter depuis l'Admin avant publication.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Arômes alimentaires — pilier Akora Foods, nouvelle catégorie.
-- ------------------------------------------------------------

insert into public.categories (business_unit_id, name)
select bu.id, 'Arômes alimentaires'
from public.business_units bu
where bu.slug = 'akora-foods'
on conflict (business_unit_id, name) do nothing;

insert into public.products (
  business_unit_id, category, name, description, use_cases, visibility
)
select bu.id, 'Arômes alimentaires', v.name, v.description, v.use_cases, false
from public.business_units bu
cross join (
  values
    ('Arôme Abricot',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée et douce rappelant l''abricot mûr, avec des nuances sucrées ou légèrement acidulées selon la formulation. Référence fournisseur : AR526. Conditionnement : boîte 500g et bidon 25kg.',
     array['Boissons aromatisées','Jus et sirops','Limonades','Boulangerie','Pâtisserie','Biscuits et gâteaux','Glaces et sorbets','Crèmes dessert','Yaourts aromatisés','Confiserie']),
    ('Arôme Ananas',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée, acidulée et sucrée rappelant l''ananas mûr. Référence fournisseur : AR6099. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Sirops','Glaces et sorbets','Confiserie','Yaourts aromatisés']),
    ('Arôme Banane',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée, douce et gourmande rappelant la banane mûre ; le profil peut être crémeux ou plus intense selon la formulation. Référence fournisseur : AR911. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Milk-shakes et smoothies','Sirops','Boulangerie','Pâtisserie','Gâteaux et muffins','Glaces et sorbets','Crèmes dessert','Produits laitiers aromatisés','Confiserie']),
    ('Arôme Beurre',
     'Arôme destiné à apporter aux préparations alimentaires une note beurrée, douce et crémeuse, pouvant rappeler le beurre frais ou fondu selon la formulation. Référence fournisseur : AR1007. Conditionnement : boîte 500g.',
     array['Biscuiterie','Biscuits sablés','Cookies','Boulangerie','Pâtisserie','Gâteaux et muffins','Viennoiserie','Confiserie','Desserts']),
    ('Arôme Biscuit',
     'Arôme destiné à apporter aux préparations alimentaires une note gourmande rappelant les biscuits fraîchement cuits, avec des nuances possibles de céréales dorées, beurre et biscuit sablé. Référence fournisseur : AR1044. Conditionnement : boîte 500g.',
     array['Biscuiterie','Biscuits sablés','Cookies','Gaufrettes','Boulangerie','Pâtisserie','Gâteaux et muffins','Confiserie','Chocolaterie','Glaces et desserts']),
    ('Arôme Café',
     'Arôme destiné à apporter aux préparations alimentaires une note caractéristique de café torréfié ; le profil peut être corsé, grillé, doux ou crémeux selon la formulation. Référence fournisseur : AR1306/G. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Boissons lactées','Boulangerie','Pâtisserie','Gâteaux et muffins','Biscuiterie','Glaces et desserts','Crèmes dessert','Chocolaterie','Confiserie']),
    ('Arôme Caramel',
     'Arôme destiné à apporter aux préparations alimentaires une note gourmande de sucre caramélisé, sans la nuance beurre salé (voir aussi Arôme Caramel Beurre Salé). Référence fournisseur : AR1473. Conditionnement : boîte 500g.',
     array['Boulangerie','Pâtisserie','Confiserie','Glaces et sorbets','Crèmes dessert','Boissons gourmandes']),
    ('Arôme Caramel Beurre Salé',
     'Arôme destiné à apporter aux préparations alimentaires une note gourmande de caramel et de sucre caramélisé, avec une nuance beurrée et une touche salée selon la formulation. Le nom ne garantit pas la présence réelle de beurre ou de sel. Référence fournisseur : AR1036. Conditionnement : boîte 500g.',
     array['Boulangerie','Pâtisserie','Gâteaux et muffins','Biscuiterie','Cookies','Crêpes et gaufres','Glaces et sorbets','Crèmes dessert','Confiserie','Chocolaterie']),
    ('Arôme Chocolat',
     'Arôme destiné à apporter aux préparations alimentaires une note cacaotée et gourmande, pouvant rappeler le chocolat noir ou au lait selon la formulation. Référence fournisseur : AR1232/G. Conditionnement : boîte 500g.',
     array['Chocolaterie','Pâtisserie','Biscuiterie','Glaces et desserts','Boissons lactées','Confiserie']),
    ('Arôme Citron',
     'Arôme destiné à apporter aux préparations alimentaires une note fraîche et acidulée rappelant le citron. Référence fournisseur : AR1670. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Limonades','Sirops','Confiserie','Pâtisserie','Glaces et sorbets']),
    ('Arôme Coco',
     'Arôme destiné à apporter aux préparations alimentaires une note douce, exotique et gourmande rappelant la noix de coco ; elle peut être crémeuse, lactée ou évoquer la chair fraîche selon la formulation. Un arôme coco ne contient pas nécessairement de noix de coco réelle. Référence fournisseur : AR1806/G. Conditionnement : boîte 500g et bidon 25kg.',
     array['Boissons aromatisées','Smoothies et milk-shakes','Sirops','Boulangerie','Pâtisserie','Gâteaux et muffins','Biscuiterie','Glaces et sorbets','Crèmes dessert','Yaourts aromatisés']),
    ('Arôme Fleur d''Oranger',
     'Arôme destiné à apporter aux préparations alimentaires une note florale et délicate rappelant la fleur d''oranger. Référence fournisseur : AR3226. Conditionnement : boîte 500g.',
     array['Pâtisserie orientale','Boulangerie','Boissons aromatisées','Confiserie','Desserts parfumés']),
    ('Arôme Fraise',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée, sucrée et gourmande rappelant la fraise mûre. Référence fournisseur : AR2294. Conditionnement : boîte 500g et bidon 25kg.',
     array['Boissons aromatisées','Sirops','Yaourts aromatisés','Glaces et sorbets','Confiserie','Pâtisserie']),
    ('Arôme Fruits Rouges',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée complexe évoquant un mélange de fruits rouges (framboise, cassis, groseille selon formulation). Référence fournisseur : AR2495. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Sirops','Yaourts aromatisés','Glaces et sorbets','Confiserie']),
    ('Arôme Grenadine',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée sucrée caractéristique de la grenadine. Référence fournisseur : AR2559. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Sirops','Confiserie']),
    ('Arôme Lait',
     'Arôme destiné à apporter aux préparations alimentaires une note lactée, douce et crémeuse. Référence fournisseur : AR2816. Conditionnement : boîte 500g.',
     array['Boissons lactées','Pâtisserie','Confiserie','Glaces et sorbets','Crèmes dessert']),
    ('Arôme Menthe',
     'Arôme destiné à apporter aux préparations alimentaires une note fraîche et mentholée. Référence fournisseur : AR3068. Conditionnement : boîte 500g.',
     array['Confiserie','Boissons aromatisées','Pâtisserie','Glaces et sorbets']),
    ('Arôme Orange',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée et acidulée rappelant l''orange. Référence fournisseur : AR3402. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Sirops','Confiserie','Pâtisserie','Glaces et sorbets']),
    ('Arôme Pêche',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée, douce et juteuse rappelant la pêche mûre. Référence fournisseur : AR3712. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Sirops','Yaourts aromatisés','Glaces et sorbets','Confiserie']),
    ('Arôme Pistache',
     'Arôme destiné à apporter aux préparations alimentaires une note caractéristique de la pistache, pouvant être douce ou plus marquée selon la formulation. Référence fournisseur : AR3758/G. Conditionnement : boîte 500g.',
     array['Pâtisserie','Glaces et sorbets','Confiserie','Chocolaterie']),
    ('Arôme Pomme',
     'Arôme destiné à apporter aux préparations alimentaires une note fruitée rappelant la pomme, verte ou mûre selon la formulation. Référence fournisseur : AR3807. Conditionnement : boîte 500g.',
     array['Boissons aromatisées','Sirops','Pâtisserie','Confiserie']),
    ('Arôme Vanille',
     'Arôme destiné à apporter aux préparations alimentaires une note douce, ronde et gourmande rappelant la vanille. Référence fournisseur : AR4625. Conditionnement : boîte 500g.',
     array['Pâtisserie','Boulangerie','Glaces et sorbets','Confiserie','Boissons lactées','Desserts'])
) as v(name, description, use_cases)
where bu.slug = 'akora-foods'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = v.name
  );

-- ------------------------------------------------------------
-- 2) Parfums pour détergents liquides — pilier Akora Pro, catégorie
-- "Parfums & Additifs" (déjà existante depuis phase41). Noms distincts
-- des arômes alimentaires ci-dessus (préfixe "Parfum", pilier
-- différent) pour éviter toute confusion entre les deux usages.
-- ------------------------------------------------------------

insert into public.products (
  business_unit_id, category, name, description, use_cases, visibility
)
select bu.id, 'Parfums & Additifs', v.name, v.description, v.use_cases, false
from public.business_units bu
cross join (
  values
    ('Parfum Cerise (détergent)',
     'Parfum de synthèse à note fruitée de cerise, destiné au parfumage de produits d''entretien liquides.',
     array['Détergents liquides','Produits d''entretien ménager']),
    ('Parfum Citron (détergent)',
     'Parfum de synthèse à note fraîche et acidulée d''agrume, destiné au parfumage de produits d''entretien liquides et dégraissants.',
     array['Détergents liquides','Dégraissants','Produits d''entretien ménager']),
    ('Parfum Citronnelle (détergent)',
     'Parfum de synthèse à note herbacée et citronnée, destiné au parfumage de produits d''entretien liquides, notamment extérieurs.',
     array['Détergents liquides','Produits d''entretien extérieur']),
    ('Parfum Fraise (détergent)',
     'Parfum de synthèse à note fruitée et sucrée de fraise, destiné au parfumage de produits d''entretien liquides.',
     array['Détergents liquides','Produits d''entretien ménager']),
    ('Parfum Lavande (détergent)',
     'Parfum de synthèse à note florale, douce et apaisante, classique en entretien ménager (lessives, détergents liquides).',
     array['Détergents liquides','Lessives','Produits d''entretien ménager']),
    ('Parfum Lavender 15991 (détergent)',
     'Référence/variante spécifique de parfum lavande (code fournisseur 15991), destinée au parfumage de produits d''entretien liquides.',
     array['Détergents liquides','Lessives']),
    ('Parfum Menthe Kelix (détergent)',
     'Référence/variante spécifique de parfum menthe (nom commercial "Kelix"), destinée au parfumage de produits d''entretien liquides.',
     array['Détergents liquides','Produits d''entretien ménager']),
    ('Parfum Menthe (détergent)',
     'Parfum de synthèse à note fraîche et mentholée, destiné au parfumage de produits d''entretien liquides.',
     array['Détergents liquides','Produits d''entretien ménager']),
    ('Parfum Orange (détergent)',
     'Parfum de synthèse à note fruitée et acidulée d''agrume, destiné au parfumage de produits d''entretien liquides et dégraissants.',
     array['Détergents liquides','Dégraissants','Produits d''entretien ménager']),
    ('Parfum Pêche (détergent)',
     'Parfum de synthèse à note fruitée et douce de pêche, destiné au parfumage de produits d''entretien liquides.',
     array['Détergents liquides','Produits d''entretien ménager']),
    ('Parfum Pin (détergent)',
     'Parfum de synthèse à note boisée et résineuse, classique en entretien ménager (nettoyants sols, détergents liquides).',
     array['Détergents liquides','Nettoyants sols','Produits d''entretien ménager']),
    ('Parfum Pomme (détergent)',
     'Parfum de synthèse à note fruitée et fraîche de pomme, destiné au parfumage de produits d''entretien liquides.',
     array['Détergents liquides','Produits d''entretien ménager'])
) as v(name, description, use_cases)
where bu.slug = 'matieres-premieres'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = v.name
  );

-- ------------------------------------------------------------
-- 3) Résine alkyde — pilier Akora Coatings, nouvelle catégorie.
-- Garde-fou : ne fait rien si "Akora Coatings" n'existe pas encore
-- sous ce slug (créé ailleurs, jamais vu dans l'historique SQL de ce
-- dépôt — voir le message de réponse).
-- ------------------------------------------------------------

insert into public.categories (business_unit_id, name)
select bu.id, 'Résines et polymères'
from public.business_units bu
where bu.slug = 'akora-coatings'
on conflict (business_unit_id, name) do nothing;

insert into public.products (
  business_unit_id, category, name, description, use_cases, visibility
)
select bu.id, 'Résines et polymères', 'Résine Alkyde',
  'La résine alkyde est un liant polymère utilisé dans la formulation de peintures, de vernis et de revêtements protecteurs. Elle contribue à former un film continu après application et participe à l''adhérence, à la brillance, à la dureté et à la résistance du revêtement, selon le grade et la formulation finale. Viscosité, matières non volatiles, solvant, couleur et temps de séchage dépendent du grade commercialisé — à confirmer auprès du fournisseur.',
  array['Fabrication de peintures','Fabrication de vernis','Formulation de peintures alkydes','Revêtements pour bois','Peintures pour métaux','Apprêts anticorrosion si le grade convient','Revêtements décoratifs','Finitions brillantes/satinées'],
  false
from public.business_units bu
where bu.slug = 'akora-coatings'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = 'Résine Alkyde'
  );

-- Garde-fous : prévenir si un des piliers n'a pas été trouvé.
do $$
begin
  if not exists (select 1 from public.business_units where slug = 'akora-foods') then
    raise notice 'Aucun pilier avec le slug ''akora-foods'' trouvé — arômes alimentaires non insérés.';
  end if;
  if not exists (select 1 from public.business_units where slug = 'matieres-premieres') then
    raise notice 'Aucun pilier avec le slug ''matieres-premieres'' (Akora Pro) trouvé — parfums détergents non insérés.';
  end if;
  if not exists (select 1 from public.business_units where slug = 'akora-coatings') then
    raise notice 'Aucun pilier avec le slug ''akora-coatings'' trouvé — résine alkyde non insérée. Vérifier le slug réel du pilier Akora Coatings et l''indiquer pour correction.';
  end if;
end $$;

-- Vérification :
-- select name, category, visibility from public.products
-- where category in ('Arômes alimentaires', 'Résines et polymères')
--    or name like 'Parfum %(détergent)'
-- order by category, name;
