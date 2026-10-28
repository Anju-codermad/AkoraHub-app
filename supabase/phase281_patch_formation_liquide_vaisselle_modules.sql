-- ============================================================
-- AkoraHub - Patch Phase 281 : découpage de la formation
-- "Liquide vaisselle" en plusieurs modules
--
-- Demande explicite (28/10) : compléter la liste des modules de la
-- formation "Liquide vaisselle" — jusqu'ici un seul module contenait
-- tout le texte (formule complète, voir phase274). Ce patch éclate ce
-- contenu en 6 modules distincts, pour un vrai parcours pas-à-pas
-- (chaque module pourra plus tard recevoir sa propre vidéo/ses
-- propres photos, voir phase275/276).
--
-- Remplace le module unique créé en phase274 par le même contenu,
-- réorganisé — rien n'est perdu, seulement redécoupé.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

delete from public.formation_course_modules
where course_id = (select id from public.formation_courses where title = 'Liquide vaisselle');

insert into public.formation_course_modules (course_id, title, content_text, sort_order)
select (select id from public.formation_courses where title = 'Liquide vaisselle'), title, content_text, sort_order
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

update public.formation_courses
set module_count = 6
where title = 'Liquide vaisselle';
