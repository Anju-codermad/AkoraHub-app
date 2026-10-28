-- ============================================================
-- AkoraHub - Patch Phase 282 : fusion des deux formations
-- "Liquide vaisselle" en doublon
--
-- Découverte le 28/10 (capture d'écran Admin) : la formation créée en
-- phase274/phase280 ("Liquide vaisselle", catégorie "Entretien
-- ménager") faisait doublon avec une entrée déjà présente depuis le
-- lancement du menu Académie (phase43 : "Liquide Vaisselle",
-- catégorie "Entretien & Hygiène", déclarée 'deja_developpee'/8
-- modules dès le départ, mais SANS aucun module ni prix réels — un
-- simple emplacement réservé dans le catalogue).
--
-- Ce patch REMPLACE phase281 (ne pas l'exécuter séparément si ce
-- patch-ci est exécuté) : il écrit directement les 6 modules réels
-- sur l'emplacement officiel du catalogue ("Entretien & Hygiène"),
-- fixe le prix, puis supprime le doublon créé aujourd'hui.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- 1) Repartir d'un emplacement catalogue vide (au cas où)
delete from public.formation_course_modules
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
);

-- 2) Écrire les 6 modules réels sur l'emplacement catalogue
insert into public.formation_course_modules (course_id, title, content_text, sort_order)
select
  (select id from public.formation_courses
   where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'),
  title, content_text, sort_order
from (values
  (0, 'Objectif de la formation', $$Apprendre à fabriquer un liquide vaisselle moussant, dégraissant et stable, à partir d'une formule de base simple, ajustable selon le budget et la qualité recherchée.$$),
  (1, 'Matériel nécessaire', $$- Un seau ou bassine de mélange (minimum 6 L)
- Une spatule ou agitateur
- Un pèse (balance de cuisine ou balance précise)
- Un bidon/bouteille vide pour conditionner
- Gants de protection$$),
  (2, 'Ingrédients (pour 5 litres)', $$- Eau : Qsp 5 L (quantité suffisante pour) — base/solvant
- SLES 70% : 400 g (~8%) — agent moussant/nettoyant principal
- CAPB 45% : 150 g (~3%) — douceur, renforce la mousse
- Comperlan / Cocamide DEA 85% : 50 g (~1%) — stabilise et épaissit la mousse
- Sel (NaCl), dissous dans un peu d'eau : 50 à 100 g (à ajuster) — épaissit le produit
- Acide citrique : quelques grammes, dilué — ajuste le pH (cible : 6 à 7)
- Colorant : quelques gouttes, dilué — couleur
- Parfum : 15 à 20 g (~0,3%) — odeur
- Conservateur : selon dose du fournisseur (souvent 0,1 à 0,5%) — évite la prolifération de microbes$$),
  (3, 'Procédure de fabrication', $$1. Verser environ 70% de l'eau totale dans le récipient de mélange.
2. Ajouter le SLES sous agitation douce (une agitation trop forte crée trop de mousse pendant la fabrication). Bien dissoudre.
3. Ajouter la CAPB, mélanger.
4. Ajouter le Comperlan/Cocamide DEA, mélanger.
5. Étape clé — épaississement : diluer le sel dans un peu d'eau tiède, puis l'ajouter petit à petit en mélangeant, jusqu'à obtenir la consistance désirée. Arrêter dès que la texture convient — trop de sel peut rendre le produit trouble ou granuleux.
6. Ajouter le colorant dilué, mélanger.
7. Ajouter le parfum, mélanger doucement.
8. Ajouter le conservateur selon la dose indiquée par le fournisseur.
9. Vérifier le pH (papier pH ou pH-mètre) et ajuster avec l'acide citrique dilué si besoin — viser un pH entre 6 et 7.
10. Compléter avec le reste de l'eau jusqu'à 5 litres.
11. Laisser reposer 24h avant la mise en bouteille — les bulles d'air se dissipent et la texture se stabilise.$$),
  (4, 'Conseils et erreurs à éviter', $$- Ne jamais ajouter le sel avant d'avoir bien dissous le SLES — le résultat serait inégal.
- Ajouter le sel progressivement et tester à chaque ajout — difficile de revenir en arrière si on en met trop.
- Un produit trop fin (liquide) manque souvent de sel ; un produit granuleux/trouble en a généralement trop.$$),
  (5, 'Sécurité', $$- Porter des gants pendant la fabrication.
- Éviter le contact avec les yeux.
- Bien étiqueter les bidons de matière première.
- Stocker à l'abri de la chaleur et du soleil direct.$$)
) as modules(sort_order, title, content_text);

-- 3) Prix + nombre de modules sur l'emplacement catalogue
update public.formation_courses
set price = 650000,
    module_count = 6
where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle';

-- 4) Supprimer le doublon créé aujourd'hui (modules puis cours)
delete from public.formation_course_modules
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien ménager' and title = 'Liquide vaisselle'
);

delete from public.formation_courses
where category = 'Entretien ménager' and title = 'Liquide vaisselle';
