-- ============================================================
-- AkoraHub - Patch Phase 303 : restaurer le module "Matières
-- premières & Sourcing" disparu — formation Liquide Vaisselle
--
-- Diagnostic (29/10) : après phase302, la vérification CSV de la
-- cliente montre 8 lignes avec un trou à sort_order = 2 — le module
-- "Matières premières & Sourcing" a disparu entièrement (pas
-- seulement le doublon visé). Ce patch le recrée avec son contenu
-- d'origine (déjà rédigé en phase290), à la bonne position.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

insert into public.formation_course_modules
  (course_id, title, content_text, sort_order, duree_minutes)
select
  id,
  'Matières premières & Sourcing',
  $$1. Les trois documents à toujours demander à un fournisseur

- TDS (Technical Data Sheet / Fiche technique) : décrit le produit tel que vendu — concentration, aspect, pH, densité, conditions de stockage. C'est la référence pour calculer vos formules (voir Module 1, calcul de matière active).
- FDS (Fiche de Données de Sécurité) : document obligatoire pour tout produit chimique — dangers, précautions de manipulation, stockage, premiers secours en cas d'accident. À conserver et à présenter en cas de contrôle (voir aussi Module 7 — Sécurité, FDS & Réglementation).
- CoA (Certificate of Analysis / Certificat d'analyse) : propre à CHAQUE lot livré — confirme que ce lot précis correspond bien aux valeurs annoncées sur la TDS (ex. "SLES 70%" réellement mesuré à 69,8% sur ce lot). Un fournisseur sérieux fournit un CoA par lot, pas seulement une TDS générique.

Un fournisseur qui ne peut fournir aucun de ces trois documents est un signal d'alerte sur la fiabilité de ses produits.

2. Matières premières locales ou importées ?

- Local : délai de livraison plus court, pas de frais de douane, pas de risque de blocage à l'importation, mais le choix est plus limité (tous les tensioactifs ne sont pas produits localement) et les prix peuvent varier plus selon les stocks disponibles.
- Importé : plus large choix et souvent meilleur rapport qualité-prix à l'achat en gros, mais délais plus longs, frais de douane et de transport à intégrer dans le coût réel, et risque de rupture si un envoi est retardé.

Dans la pratique : privilégier le local pour les matières premières de base utilisées en continu (éviter la rupture de stock), et réserver l'import aux achats groupés/planifiés à l'avance pour les volumes plus importants.

3. Comparer le coût réel entre deux fournisseurs — piège à éviter

Ne jamais comparer deux produits seulement par leur prix au kg : il faut comparer le coût par unité de matière active, sinon un produit "moins cher" au kg peut en réalité coûter plus cher une fois dilué à la même concentration utile.

Méthode :
Coût réel par kg de matière active = Prix d'achat au kg ÷ % de concentration du produit

Exemple :
- Fournisseur A : SLES 70% à 8 000 Ar/kg → coût réel = 8 000 / 0,70 = 11 430 Ar par kg de matière active
- Fournisseur B : SLES 60% à 7 200 Ar/kg → coût réel = 7 200 / 0,60 = 12 000 Ar par kg de matière active

Le Fournisseur A est en réalité moins cher, même si son prix affiché au kg est plus élevé. Toujours faire ce calcul avant de choisir un fournisseur uniquement sur le prix affiché.$$,
  2,
  120
from public.formation_courses
where title ilike '%liquide vaisselle%';

-- Vérification : doit renvoyer 9 lignes, sort_order 0 à 8, sans trou.
select sort_order, title
from public.formation_course_modules
where course_id = (
  select id from public.formation_courses
  where title ilike '%liquide vaisselle%'
)
order by sort_order;
