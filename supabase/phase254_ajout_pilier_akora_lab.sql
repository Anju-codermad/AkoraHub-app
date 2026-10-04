-- ============================================================
-- AkoraHub - Patch Phase 254 : pilier "Akora Lab" + catégories +
-- brouillons de matériel de laboratoire — demande explicite de la
-- propriétaire (04/10/2026).
--
-- Contexte : "Akora Lab" était déjà prévu côté app (couleur + icône
-- dans product_catalog_tab.dart) mais jamais créé côté base — aucune
-- phase SQL précédente ne le mentionne. Ce script le crée s'il
-- n'existe pas encore (ou ne fait rien s'il a déjà été créé depuis
-- l'Admin — entièrement idempotent, sans risque à exécuter même si le
-- pilier existe déjà).
--
-- Liste de matériel proposée (standard, pas une liste fournie par la
-- propriétaire — à ajuster/compléter depuis l'Admin) : verrerie,
-- instruments de mesure, EPI, consommables, petit matériel, mobilier,
-- stérilisation & nettoyage. 7 catégories, ~35 produits.
--
-- Tous les produits sont créés en BROUILLON (visibility = false) :
-- ni prix, ni photo, ni stock réels fournis — à compléter depuis
-- l'Admin (fiche produit) avant publication, comme pour les flacons
-- PET d'Akora Packaging (phase243).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script entièrement idempotent (on conflict / where not exists).
-- ============================================================

-- 1. Le pilier lui-même.
insert into public.business_units (name, slug, active)
values ('Akora Lab', 'akora-lab', true)
on conflict (slug) do nothing;

-- 2. Ses catégories.
insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Verrerie de laboratoire'),
  ('Instruments de mesure'),
  ('Équipement de protection individuelle (EPI)'),
  ('Consommables de laboratoire'),
  ('Petit matériel & outillage'),
  ('Mobilier & rangement de laboratoire'),
  ('Stérilisation & nettoyage')
) as c(name)
where bu.slug = 'akora-lab'
on conflict (business_unit_id, name) do nothing;

-- 3. Les produits brouillons, par catégorie.
insert into public.products (
  business_unit_id, category, name, description, visibility
)
select bu.id, v.category, v.name, v.description, false
from public.business_units bu
cross join (
  values
    -- Verrerie de laboratoire
    ('Verrerie de laboratoire', 'Bécher en verre 250 ml',
     'Bécher en verre borosilicate, contenance 250 ml, graduations imprimées.'),
    ('Verrerie de laboratoire', 'Bécher en verre 500 ml',
     'Bécher en verre borosilicate, contenance 500 ml, graduations imprimées.'),
    ('Verrerie de laboratoire', 'Erlenmeyer 250 ml',
     'Fiole conique (erlenmeyer) en verre, contenance 250 ml, col étroit.'),
    ('Verrerie de laboratoire', 'Éprouvette graduée 100 ml',
     'Éprouvette graduée en verre, contenance 100 ml, pour mesures de volume précises.'),
    ('Verrerie de laboratoire', 'Tube à essai (lot de 10)',
     'Lot de 10 tubes à essai en verre, usage général en laboratoire.'),
    ('Verrerie de laboratoire', 'Entonnoir en verre',
     'Entonnoir en verre pour filtration et transfert de liquides.'),
    ('Verrerie de laboratoire', 'Ballon à fond rond 500 ml',
     'Ballon en verre à fond rond, contenance 500 ml, pour chauffe/distillation.'),

    -- Instruments de mesure
    ('Instruments de mesure', 'Balance de précision électronique',
     'Balance électronique de précision pour pesées de laboratoire.'),
    ('Instruments de mesure', 'pH-mètre numérique',
     'pH-mètre numérique portable avec sonde, pour contrôle qualité.'),
    ('Instruments de mesure', 'Thermomètre de laboratoire (-10°C à 150°C)',
     'Thermomètre de précision pour usage en laboratoire, plage -10°C à 150°C.'),
    ('Instruments de mesure', 'Réfractomètre portable',
     'Réfractomètre manuel pour mesure d''indice de réfraction/concentration.'),
    ('Instruments de mesure', 'Viscosimètre manuel',
     'Viscosimètre manuel pour contrôle de la viscosité des liquides.'),
    ('Instruments de mesure', 'Densimètre (aréomètre)',
     'Aréomètre pour mesure de la densité des liquides.'),

    -- Équipement de protection individuelle (EPI)
    ('Équipement de protection individuelle (EPI)', 'Gants en nitrile (boîte de 100)',
     'Boîte de 100 gants en nitrile, résistants aux produits chimiques courants.'),
    ('Équipement de protection individuelle (EPI)', 'Lunettes de protection',
     'Lunettes de protection oculaire contre projections chimiques.'),
    ('Équipement de protection individuelle (EPI)', 'Blouse de laboratoire',
     'Blouse de laboratoire en coton/polyester, manches longues.'),
    ('Équipement de protection individuelle (EPI)', 'Masque de protection respiratoire',
     'Masque de protection respiratoire pour manipulation de produits chimiques.'),
    ('Équipement de protection individuelle (EPI)', 'Tablier résistant aux produits chimiques',
     'Tablier imperméable résistant aux éclaboussures de produits chimiques.'),

    -- Consommables de laboratoire
    ('Consommables de laboratoire', 'Pipettes jetables (lot de 50)',
     'Lot de 50 pipettes jetables graduées, usage unique.'),
    ('Consommables de laboratoire', 'Papier filtre (paquet de 100)',
     'Paquet de 100 feuilles de papier filtre pour filtration de laboratoire.'),
    ('Consommables de laboratoire', 'Gants en latex jetables (boîte de 100)',
     'Boîte de 100 gants en latex jetables, usage général.'),
    ('Consommables de laboratoire', 'Étiquettes résistantes aux solvants',
     'Étiquettes adhésives résistantes aux solvants pour identification des contenants.'),
    ('Consommables de laboratoire', 'Spatules jetables (lot de 50)',
     'Lot de 50 spatules jetables en plastique, usage unique.'),

    -- Petit matériel & outillage
    ('Petit matériel & outillage', 'Agitateur magnétique',
     'Agitateur magnétique de laboratoire avec vitesse réglable.'),
    ('Petit matériel & outillage', 'Support universel avec pinces',
     'Support universel en métal avec pinces, pour maintenir la verrerie.'),
    ('Petit matériel & outillage', 'Bec Bunsen',
     'Bec Bunsen pour chauffe au gaz en laboratoire.'),
    ('Petit matériel & outillage', 'Spatule en inox',
     'Spatule en acier inoxydable, usage général de laboratoire.'),
    ('Petit matériel & outillage', 'Pince en bois pour tube à essai',
     'Pince en bois pour la manipulation sécurisée des tubes à essai chauds.'),

    -- Mobilier & rangement de laboratoire
    ('Mobilier & rangement de laboratoire', 'Armoire de stockage pour produits chimiques',
     'Armoire de stockage sécurisée pour produits chimiques de laboratoire.'),
    ('Mobilier & rangement de laboratoire', 'Étagère de laboratoire en inox',
     'Étagère en acier inoxydable pour rangement de matériel de laboratoire.'),
    ('Mobilier & rangement de laboratoire', 'Paillasse de laboratoire',
     'Plan de travail de laboratoire résistant aux produits chimiques.'),

    -- Stérilisation & nettoyage
    ('Stérilisation & nettoyage', 'Autoclave de laboratoire',
     'Autoclave pour stérilisation du matériel de laboratoire.'),
    ('Stérilisation & nettoyage', 'Flacon laveur (pissette) 500 ml',
     'Flacon laveur souple, contenance 500 ml, pour rinçage de la verrerie.'),
    ('Stérilisation & nettoyage', 'Détergent de nettoyage pour verrerie',
     'Détergent spécialement formulé pour le nettoyage de la verrerie de laboratoire.'),
    ('Stérilisation & nettoyage', 'Brosse pour tube à essai',
     'Brosse à long manche pour le nettoyage intérieur des tubes à essai.')
) as v(category, name, description)
where bu.slug = 'akora-lab'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = v.name
  );

-- Garde-fou : prévenir si le pilier Akora Lab n'a pas été trouvé
-- (ne devrait jamais arriver, le script le crée juste avant).
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-lab'
  ) then
    raise notice 'Aucun pilier avec le slug ''akora-lab'' trouvé — rien inséré.';
  end if;
end $$;

-- Vérification :
-- select p.name, p.category, p.visibility
-- from public.products p
-- join public.business_units bu on bu.id = p.business_unit_id
-- where bu.slug = 'akora-lab'
-- order by p.category, p.name;
