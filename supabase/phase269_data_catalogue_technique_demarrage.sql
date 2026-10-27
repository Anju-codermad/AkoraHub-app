-- ============================================================
-- AkoraHub - Patch Phase 269 : import du "Catalogue technique de
-- démarrage" (PDF fourni par l'utilisatrice le 27/10)
--
-- Deux actions, non destructives et rejouables :
--
-- 1) Les 12 produits "Parfum X (détergent)" existent déjà (phase259,
--    pilier Akora Pro, catégorie "Parfums & Additifs") — "Parfum Pêche
--    (détergent)" est déjà publié (visibility=true, basculé
--    manuellement depuis phase259), les 11 autres restent des
--    brouillons (visibility=false) tels quels. On ENRICHIT leur
--    description existante (gardée telle quelle) avec les précisions
--    techniques/sécurité du PDF, sans toucher à leur visibilité — un
--    produit déjà publié le reste, un brouillon le reste aussi.
--
-- 2) 4 nouvelles matières premières du PDF n'ont encore aucun produit
--    correspondant (sirop de glucose, PEG 200, vitamine E acétate,
--    extrait d'aloé vera) — créées en brouillon (visibility=false),
--    à compléter/publier manuellement une fois les données
--    fournisseur (TDS/FDS) confirmées, comme le précise le PDF
--    lui-même ("limite importante" en page 1).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ------------------------------------------------------------
-- 1) Enrichissement des 12 "Parfum X (détergent)" déjà au catalogue.
-- Garde-fou anti-doublon (position(...) = 0) : si ce script est
-- rejoué, la note n'est pas ajoutée une seconde fois.
-- ------------------------------------------------------------

update public.products p
set description = trim(both E'\n' from coalesce(p.description, '') || E'\n\n' || v.extra_note)
from (
  values
    ('Parfum Cerise (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Citron (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Citronnelle (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Fraise (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Lavande (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Lavender 15991 (détergent)', $$Précisions fournisseur (27/10) : référence fournisseur à vérifier précisément. Vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Menthe Kelix (détergent)', $$Précisions fournisseur (27/10) : référence commerciale à confirmer auprès du fournisseur. Vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Menthe (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Orange (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Pêche (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Pin (détergent)', $$Précisions fournisseur (27/10) : vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$),
    ('Parfum Pomme (détergent)', $$Précisions fournisseur (27/10) : la couleur du visuel ne garantit pas celle du produit réel — vérifier la compatibilité avec la formule finale avant utilisation. Dosage selon la plage recommandée par le fournisseur, avec essai de stabilité. Stockage en emballage fermé, selon la FDS. À confirmer avant toute publication définitive : référence fournisseur exacte, composition, allergènes, point éclair, classification de danger, compatibilité et dosage précis.$$)
) as v(name, extra_note)
where p.name = v.name
  and position(v.extra_note in coalesce(p.description, '')) = 0;

-- ------------------------------------------------------------
-- 2) Nouvelles matières premières (brouillon) — pas encore au
-- catalogue. Pilier/catégorie selon les recommandations du PDF.
-- Catégories enregistrées dans `categories` (même table que le
-- picker de l'écran Admin, voir phase6/phase42) pour qu'elles
-- apparaissent proprement si l'utilisatrice édite ces brouillons.
-- ------------------------------------------------------------

insert into public.categories (business_unit_id, name)
select bu.id, 'Sucres & Sirops' from public.business_units bu
where bu.slug = 'akora-nutrisource'
on conflict (business_unit_id, name) do nothing;

insert into public.categories (business_unit_id, name)
select bu.id, 'Solvants & Auxiliaires de Formulation' from public.business_units bu
where bu.slug = 'matieres-premieres'
on conflict (business_unit_id, name) do nothing;

insert into public.categories (business_unit_id, name)
select bu.id, 'Actifs & Ingrédients Cosmétiques' from public.business_units bu
where bu.slug = 'akora-soins'
on conflict (business_unit_id, name) do nothing;

insert into public.products (business_unit_id, category, name, description, use_cases, visibility)
select bu.id, 'Sucres & Sirops', 'Sirop de glucose 85 % (DE 38-42)',
  $$Sirop de glucose avec DE annoncé de 38-42 et teneur annoncée de 85 %. Apporte du corps et de la viscosité, aide à contrôler la cristallisation des sucres et ajuste la texture de certaines préparations alimentaires. Dosage selon la recette et la fiche technique du fournisseur (pas de dosage universel). Stockage en récipient fermé, endroit propre, selon les instructions du fournisseur. Important : ne pas confondre le DE 38-42 (degré d'hydrolyse/pouvoir réducteur) avec une concentration de 38-42 %. À confirmer avant publication : signification exacte des 85 % (matière sèche ou autre spécification), composition, paramètres microbiologiques et durée de conservation.$$,
  array['Confiseries','Caramels','Pâtisseries','Glaces & Sorbets','Sauces sucrées'],
  false
from public.business_units bu
where bu.slug = 'akora-nutrisource'
  and not exists (
    select 1 from public.products p
    where p.name = 'Sirop de glucose 85 % (DE 38-42)'
  );

insert into public.products (business_unit_id, category, name, description, use_cases, visibility)
select bu.id, 'Solvants & Auxiliaires de Formulation', 'PEG 200 — Polyéthylène glycol 200',
  $$Polyéthylène glycol de faible masse moléculaire, généralement liquide et miscible à l'eau. Utilisé comme solvant/co-solvant et auxiliaire de formulation dans des applications compatibles avec son grade (formulation industrielle, et certaines applications cosmétiques selon le grade). Attention : ne pas attribuer automatiquement les fonctions de tensioactif principal, émulsifiant principal ou épaississant — ce ne sont pas ses fonctions générales. Stockage en emballage fermé ; suivre la FDS exacte et les instructions du fournisseur. À confirmer avant publication : pureté, spécifications, identifiants, compatibilité et aptitude à l'usage cosmétique/pharmaceutique. Ne jamais déclarer un grade pharmaceutique, alimentaire ou cosmétique sans documentation correspondante.$$,
  array['Solvant / co-solvant','Auxiliaire de formulation industrielle','Applications cosmétiques selon grade'],
  false
from public.business_units bu
where bu.slug = 'matieres-premieres'
  and not exists (
    select 1 from public.products p
    where p.name = 'PEG 200 — Polyéthylène glycol 200'
  );

insert into public.products (business_unit_id, category, name, description, use_cases, visibility)
select bu.id, 'Actifs & Ingrédients Cosmétiques', 'Vitamine E acétate (Tocopheryl Acetate)',
  $$Dérivé acétylé de la vitamine E utilisé comme ingrédient dans certaines formulations cosmétiques (soins de la peau et des cheveux). La forme, la concentration et la compatibilité dépendent du grade fournisseur. Dosage : suivre les recommandations du fournisseur et les limites applicables au produit fini. Stockage : suivre la fiche technique et la FDS du produit exact. À confirmer avant publication : pureté, forme, support éventuel, grade, nom INCI exact et recommandations d'incorporation — ne pas déduire les identifiants techniques d'une image illustrative.$$,
  array['Soins de la peau','Soins des cheveux'],
  false
from public.business_units bu
where bu.slug = 'akora-soins'
  and not exists (
    select 1 from public.products p
    where p.name = 'Vitamine E acétate (Tocopheryl Acetate)'
  );

insert into public.products (business_unit_id, category, name, description, use_cases, visibility)
select bu.id, 'Actifs & Ingrédients Cosmétiques', 'Extrait d''aloé vera',
  $$Ingrédient dérivé de l'aloé vera employé dans certaines formulations cosmétiques (crèmes, lotions, gels, shampoings), selon le grade et le mode d'emploi. Les caractéristiques varient selon qu'il s'agit d'un jus, gel, extrait concentré ou poudre. Dosage dépendant de la forme, de la concentration, du support et des recommandations du fournisseur. Stockage : suivre la fiche technique ; vérifier les conservateurs et les conditions microbiologiques. À confirmer avant publication : nom INCI exact, partie de plante, forme, ratio d'extraction, solvant, concentration, conservateurs et pH — le nom "extrait d'aloé vera" seul ne suffit pas à établir un CAS, une concentration ou un dosage précis.$$,
  array['Crèmes','Lotions','Gels','Shampoings'],
  false
from public.business_units bu
where bu.slug = 'akora-soins'
  and not exists (
    select 1 from public.products p
    where p.name = 'Extrait d''aloé vera'
  );

-- Garde-fous : prévenir si un pilier attendu n'existe pas (rien
-- n'est inséré pour la ligne concernée dans ce cas).
do $$
begin
  if not exists (select 1 from public.business_units where slug = 'akora-nutrisource') then
    raise notice 'Aucun pilier avec le slug ''akora-nutrisource'' trouvé — sirop de glucose non inséré.';
  end if;
  if not exists (select 1 from public.business_units where slug = 'matieres-premieres') then
    raise notice 'Aucun pilier avec le slug ''matieres-premieres'' (Akora Pro) trouvé — PEG 200 non inséré.';
  end if;
  if not exists (select 1 from public.business_units where slug = 'akora-soins') then
    raise notice 'Aucun pilier avec le slug ''akora-soins'' trouvé — vitamine E acétate / extrait d''aloé vera non insérés.';
  end if;
end $$;
