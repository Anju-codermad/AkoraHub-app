-- ============================================================
-- AkoraHub - Patch Phase 42 : alignement partiel sur le document
-- "Groupe Akora — Activités (Produits, Services, Formations)" (02/08)
--
-- Contexte : l'utilisatrice a fourni la structure réelle complète du
-- Groupe Akora (3 piliers : Produits, Services, Formations). Décision
-- actée : ne PAS tout restructurer d'un coup ce soir (Services et le vrai
-- AkoraFormation — cours/modules — sont des chantiers neufs, à traiter
-- dans une session dédiée). Ce script se limite au strict nécessaire et
-- SANS RISQUE pour les données déjà réelles :
--
-- 1. Crée le nouveau pilier "Akora Soins" (cosmétique produit fini, 5
--    catégories) — inactif par défaut, comme les piliers dormants de
--    phase10, en attendant que l'utilisatrice l'active.
-- 2. Ajoute 2 catégories manquantes au pilier existant "Akora
--    Fanadiovana" (Cire & Bougie, Produits spécialisés) pour compléter
--    ses 9 catégories du document (Akora Home). Matché par `name ilike`
--    (même prudence que phase6_patch_categories.sql) — n'écrase RIEN,
--    ajoute seulement les catégories manquantes.
-- 3. Ajoute 1 catégorie manquante au pilier "Anti-Nuisibles" (Traitement
--    de l'eau & Piscine), pour compléter les 2 catégories du document
--    (Akora Protect).
--
-- ⚠️ Volontairement PAS fait ici (décision de garder l'existant intact) :
-- - Renommer "Akora Fanadiovana" → "Akora Home", "Matières Premières" →
--   "Akora Pro", "Anti-Nuisibles" → "Akora Protect", "ARCA PAINTS" →
--   "Peinture" : un simple renommage de nom (aucun risque), mais laissé
--   à l'utilisatrice depuis "Piliers d'entreprise" — l'exécuter ici en
--   SQL demanderait de deviner le nom exact déjà stocké en base (risque
--   d'update silencieusement 0 ligne si le nom diffère un peu).
-- - Recatégoriser les ~192 matières premières déjà seedées (phase41) : le
--   document d'"Akora Pro" (11 catégories, ex: "Cosmétique",
--   "Agroalimentaire") est une classification PAR USAGE, alors que les
--   catégories déjà en place (Tensioactifs, Solvants, Acides & Bases...)
--   sont une classification PAR FAMILLE CHIMIQUE — les deux ne se
--   recouvrent pas ligne à ligne. Reclasser 192 fiches à l'aveugle
--   casserait une donnée déjà correcte pour un gain flou ; à trancher
--   consciemment avec l'utilisatrice si besoin, pas improvisé ce soir.
-- - Le pilier "Akora Services" et le vrai "AkoraFormation" (cours,
--   modules, statut "Déjà développée"/"À créer") : nouvelles
--   fonctionnalités à part entière (nouveaux écrans, nouveau modèle de
--   données), pas de simples ajouts de catégories.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Nouveau pilier "Akora Soins" (cosmétique produit fini).
-- ------------------------------------------------------------
insert into public.business_units (name, slug, active)
values ('Akora Soins', 'akora-soins', false)
on conflict (slug) do nothing;

insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Soins Visage'),
  ('Soins Corps'),
  ('Soins Capillaires'),
  ('Hygiène intime & Bébé'),
  ('Parfums & Eaux de toilette')
) as c(name)
where bu.slug = 'akora-soins'
on conflict (business_unit_id, name) do nothing;

-- ------------------------------------------------------------
-- 2) Catégories manquantes sur le pilier "Akora Fanadiovana" (Akora Home).
-- ------------------------------------------------------------
insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Cire & Bougie'),
  ('Produits spécialisés')
) as c(name)
where bu.name ilike 'Akora Fanadiovana'
on conflict (business_unit_id, name) do nothing;

do $$
begin
  if not exists (select 1 from public.business_units where name ilike 'Akora Fanadiovana') then
    raise notice 'Aucun pilier nommé "Akora Fanadiovana" trouvé — les 2 catégories Akora Home n''ont pas été ajoutées. Vérifie le nom exact du pilier et adapte le WHERE ci-dessus.';
  end if;
end $$;

-- ------------------------------------------------------------
-- 3) Catégorie manquante sur le pilier "Anti-Nuisibles" (Akora Protect).
-- ------------------------------------------------------------
insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Traitement de l''eau & Piscine')
) as c(name)
where bu.slug = 'anti-nuisibles'
on conflict (business_unit_id, name) do nothing;

-- Vérification : voir le résultat des 3 piliers touchés par ce script
select bu.name as pilier, bu.active, cat.name as categorie
from public.business_units bu
left join public.categories cat on cat.business_unit_id = bu.id
where bu.slug = 'akora-soins'
   or bu.slug = 'anti-nuisibles'
   or bu.name ilike 'Akora Fanadiovana'
order by bu.name, cat.name;
