-- ============================================================
-- AkoraHub - Patch Phase 257 : brouillons huiles, beurres, cires et
-- produits de la ruche (miel, propolis...) — demande explicite de la
-- propriétaire (05/10).
--
-- Pas de nouveau pilier : la catégorie "Huiles & Beurres Cosmétiques"
-- existe déjà sous Akora Pro (slug `matieres-premieres`), utilisée
-- depuis les phases 117-123 pour les fiches Académie (37 huiles/
-- beurres/cires, contenu vérifié par la propriétaire à l'époque). Ce
-- script réutilise EXACTEMENT la même liste de 37 noms côté catalogue
-- vendable (`products`, brouillons), et y ajoute 5 produits de la
-- ruche (miel, cire d'abeille, propolis, gelée royale, pollen) qui n'y
-- figuraient pas — la cire d'abeille en particulier manquait déjà de
-- la liste Académie malgré 4 autres cires (candelilla, soja, riz,
-- acacia) déjà présentes. Garder huiles/beurres/cires/produits de la
-- ruche dans UNE SEULE catégorie suit le même regroupement déjà choisi
-- par la propriétaire (les cires étaient déjà dans cette catégorie,
-- pas dans une catégorie à part) plutôt que d'en créer une nouvelle.
--
-- Idempotent : si un produit du même nom existe déjà sous Akora Pro
-- (les "9 déjà existants" mentionnés en phase123, par exemple), il
-- n'est pas dupliqué.
--
-- Créés en BROUILLON (visibility = false) : ni prix, ni photo, ni
-- stock réels fournis — à compléter depuis l'Admin avant publication,
-- comme pour Akora Lab (phase254) et les flacons PET (phase243).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- 1. S'assure que la catégorie existe dans la table `categories`
--    (navigation/filtre du catalogue) — elle n'existait jusqu'ici que
--    comme valeur libre dans `raw_materials.category_name` (Académie).
insert into public.categories (business_unit_id, name)
select bu.id, 'Huiles & Beurres Cosmétiques'
from public.business_units bu
where bu.slug = 'matieres-premieres'
on conflict (business_unit_id, name) do nothing;

-- 2. Les brouillons de produits.
insert into public.products (
  business_unit_id, category, name, description, visibility
)
select bu.id, 'Huiles & Beurres Cosmétiques', v.name, v.description, false
from public.business_units bu
cross join (
  values
    ('Huile d''olive', 'Huile végétale polyvalente, base classique de saponification à froid.'),
    ('Huile de palme', 'Huile végétale riche en acides gras saturés, apporte dureté et mousse crémeuse au savon.'),
    ('Huile de palmiste', 'Huile végétale proche de l''huile de coco, utilisée pour la mousse et la dureté en savonnerie.'),
    ('Huile de tournesol', 'Huile végétale légère, riche en vitamine E, usage cosmétique et savonnerie.'),
    ('Huile de ricin', 'Huile végétale épaisse, utilisée pour la mousse onctueuse et la brillance en savonnerie/cosmétique.'),
    ('Huile d''amande douce', 'Huile végétale douce et nourrissante, très utilisée en cosmétique pour peaux sensibles.'),
    ('Huile de jojoba', 'Cire liquide végétale proche du sébum humain, excellente stabilité, usage cosmétique haut de gamme.'),
    ('Huile d''argan', 'Huile végétale précieuse, riche en acides gras essentiels, usage cosmétique anti-âge.'),
    ('Huile de coco fractionnée (caprylic/capric triglyceride)', 'Huile de coco modifiée pour rester liquide à température ambiante, texture légère non grasse.'),
    ('Huile de pépin de raisin', 'Huile végétale légère, riche en antioxydants, usage cosmétique courant.'),
    ('Huile d''avocat', 'Huile végétale riche et nourrissante, usage cosmétique pour peaux sèches.'),
    ('Huile de sésame', 'Huile végétale traditionnelle, usage cosmétique et savonnerie.'),
    ('Huile de noisette', 'Huile végétale légère, pénétration rapide, usage cosmétique.'),
    ('Huile de macadamia', 'Huile végétale riche en acide palmitoléique, usage cosmétique nourrissant.'),
    ('Huile de noyau d''abricot', 'Huile végétale douce, usage cosmétique pour peaux sensibles.'),
    ('Huile de chanvre', 'Huile végétale riche en oméga-3/6, usage cosmétique régénérant.'),
    ('Huile de bourrache', 'Huile végétale riche en acide gamma-linolénique, usage cosmétique actif.'),
    ('Huile d''onagre', 'Huile végétale riche en acides gras essentiels, usage cosmétique actif.'),
    ('Huile de rose musquée', 'Huile végétale régénérante, usage cosmétique haut de gamme (cicatrices, anti-âge).'),
    ('Huile de neem', 'Huile végétale aux propriétés insectifuges naturelles — usage externe uniquement, à tenir hors de portée des nourrissons.'),
    ('Huile de germe de blé', 'Huile végétale riche en vitamine E, antioxydante, usage cosmétique.'),
    ('Huile de coton', 'Huile végétale neutre, usage cosmétique et savonnerie.'),
    ('Huile de soja', 'Huile végétale courante, usage cosmétique et savonnerie.'),
    ('Huile de maïs', 'Huile végétale neutre, usage cosmétique et savonnerie.'),
    ('Huile d''arachide', 'Huile végétale traditionnelle, usage cosmétique et savonnerie.'),
    ('Beurre de mangue', 'Beurre végétal nourrissant, alternative au beurre de karité, usage cosmétique.'),
    ('Beurre de kokum', 'Beurre végétal ferme, usage cosmétique (baumes, savons durs).'),
    ('Beurre de sal', 'Beurre végétal proche du karité, usage cosmétique et savonnerie.'),
    ('Beurre de mowrah', 'Beurre végétal, usage cosmétique et savonnerie.'),
    ('Beurre d''illipe', 'Beurre végétal très ferme, usage cosmétique (baumes à lèvres, savons durs).'),
    ('Beurre de cupuaçu', 'Beurre végétal très hydratant, usage cosmétique haut de gamme.'),
    ('Beurre de babassu', 'Beurre végétal léger, non comédogène, usage cosmétique.'),
    ('Cire de candelilla', 'Cire végétale dure, alternative végane à la cire d''abeille, usage cosmétique.'),
    ('Cire de soja', 'Cire végétale douce, usage cosmétique et bougies.'),
    ('Lanoline', 'Cire d''origine animale (laine de mouton), très hydratante, usage cosmétique (baumes, crèmes).'),
    ('Cire de riz', 'Cire végétale légère, alternative végane à la cire d''abeille, usage cosmétique.'),
    ('Cire d''acacia (mimosa)', 'Cire végétale, usage cosmétique (baumes, sticks).'),
    ('Cire d''abeille', 'Cire naturelle d''origine animale, épaississant et protecteur classique en cosmétique (baumes, crèmes, sticks lèvres) et en bougies.'),
    ('Miel brut', 'Miel non transformé, utilisé comme actif hydratant et adoucissant en cosmétique (savons, masques) en plus de son usage alimentaire.'),
    ('Propolis', 'Résine naturelle récoltée par les abeilles, propriétés assainissantes, usage cosmétique et compléments.'),
    ('Gelée royale', 'Sécrétion des abeilles ouvrières, actif cosmétique régénérant haut de gamme.'),
    ('Pollen d''abeille', 'Pollen récolté par les abeilles, utilisé comme actif en cosmétique et en complément alimentaire.')
) as v(name, description)
where bu.slug = 'matieres-premieres'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = v.name
  );

-- Garde-fou : prévenir si le pilier Akora Pro n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'matieres-premieres'
  ) then
    raise notice 'Aucun pilier avec le slug ''matieres-premieres'' (Akora Pro) trouvé — rien inséré.';
  end if;
end $$;

-- Vérification :
-- select name, category, visibility from public.products
-- where category = 'Huiles & Beurres Cosmétiques'
-- order by name;
