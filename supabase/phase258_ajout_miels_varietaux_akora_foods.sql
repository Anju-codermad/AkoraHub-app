-- ============================================================
-- AkoraHub - Patch Phase 258 : brouillons de miels variétaux sous
-- Akora Foods — demande explicite de la propriétaire (05/10) : "Miel
-- de niaouli, Miel de letchis, miel de mokarana, miel polyfloral,
-- etc." + question "Est-il possible de créer un pilier pour ça ?".
--
-- Réponse : pas besoin de nouveau pilier. "Akora Foods" existe déjà
-- (phase223) — explicitement décrit comme "produits alimentaires finis
-- ... destinés au grand public", exactement le profil d'un miel
-- variétal vendu en pot (B2C). Distinct du "Miel brut" ajouté en
-- phase257 sous Akora Pro, qui lui vise un usage COSMÉTIQUE en gros
-- (matière première B2B pour savonnerie) — les deux peuvent coexister
-- sans se chevaucher.
--
-- Nouvelle catégorie "Miel" sous Akora Foods (aucune des 11 catégories
-- existantes de la phase223 ne correspond précisément). Liste
-- complétée au-delà des 4 noms cités ("etc.") avec d'autres miels
-- variétaux malgaches courants — À AJUSTER depuis l'Admin, cette
-- liste n'est qu'une proposition de départ, pas une liste confirmée
-- par la propriétaire comme pour les huiles (phase257).
--
-- Créés en BROUILLON (visibility = false) : ni prix, ni photo, ni
-- stock réels fournis — à compléter depuis l'Admin avant publication.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent.
-- ============================================================

-- 1. Nouvelle catégorie "Miel" sous Akora Foods.
insert into public.categories (business_unit_id, name)
select bu.id, 'Miel'
from public.business_units bu
where bu.slug = 'akora-foods'
on conflict (business_unit_id, name) do nothing;

-- 2. Les brouillons de miels variétaux.
insert into public.products (
  business_unit_id, category, name, description, visibility
)
select bu.id, 'Miel', v.name, v.description, false
from public.business_units bu
cross join (
  values
    ('Miel de niaouli',
     'Miel monofloral issu des fleurs de niaouli, au goût marqué et légèrement mentholé.'),
    ('Miel de letchis',
     'Miel monofloral issu des fleurs de litchi, parfum fruité délicat, l''un des miels malgaches les plus réputés à l''export.'),
    ('Miel de mokarana',
     'Miel variétal issu des fleurs de mokarana.'),
    ('Miel polyfloral',
     'Miel toutes fleurs, issu de plusieurs origines florales, goût équilibré et polyvalent.'),
    ('Miel de girofle',
     'Miel monofloral issu des fleurs de giroflier, région productrice de girofle malgache (SAVA), arôme épicé caractéristique.'),
    ('Miel d''eucalyptus',
     'Miel monofloral issu des fleurs d''eucalyptus, goût prononcé et légèrement mentholé.'),
    ('Miel de ravintsara',
     'Miel variétal issu des fleurs de ravintsara.'),
    ('Miel de mangue',
     'Miel monofloral issu des fleurs de manguier, parfum fruité doux.'),
    ('Miel de baobab',
     'Miel variétal issu des fleurs de baobab.')
) as v(name, description)
where bu.slug = 'akora-foods'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = v.name
  );

-- Garde-fou : prévenir si le pilier Akora Foods n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-foods'
  ) then
    raise notice 'Aucun pilier avec le slug ''akora-foods'' trouvé — rien inséré.';
  end if;
end $$;

-- Vérification :
-- select name, category, visibility from public.products
-- where category = 'Miel'
-- order by name;
