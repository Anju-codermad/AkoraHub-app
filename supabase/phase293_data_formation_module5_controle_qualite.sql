-- ============================================================
-- AkoraHub - Phase 293 : contenu du Module 5 "Contrôle qualité ISO"
-- — formation Liquide Vaisselle
--
-- Demande explicite (29/10). Note sur les tags de la maquette : "ISO
-- 9001" est une vraie norme vérifiable (management de la qualité,
-- générique, non spécifique au savon) — utilisée ici. "ISO 17887" ne
-- correspond à aucune norme vérifiable pour les savons/détergents
-- (comme "ISO 8022" signalé au Module 1) — non utilisée, remplacée
-- par les VRAIES normes de test citées dans le document BNM fourni
-- par la propriétaire (ISO 456, 457, 672, 8212, 4318).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set content_text = $$1. ISO 9001 — une démarche, pas juste un papier

ISO 9001 est la norme internationale de management de la qualité — elle ne décrit pas comment fabriquer un produit précis, mais comment organiser son activité pour que la qualité soit constante : procédures écrites, vérifications systématiques, traçabilité (voir la fiche de lot du Module 4), et amélioration continue à partir des problèmes rencontrés.

Elle n'est pas obligatoire pour vendre localement, mais s'en inspirer dès maintenant (même sans certification officielle, qui a un coût) prépare le terrain si vous visez un jour des clients professionnels (B2B) ou l'export, où elle est souvent exigée.

2. Les vraies normes de test pour savons et détergents

Le document officiel BNM (NMG 401-1/2004) que vous avez fourni cite précisément les normes ISO utilisées pour contrôler un savon/détergent à Madagascar :

- ISO 456 : dosage des chlorures
- ISO 457 : dosage des matières grasses totales
- ISO 672 : méthodes d'échantillonnage (comment prélever un échantillon représentatif d'un lot)
- ISO 8212 : détermination de l'alcalinité libre ou de l'acidité libre
- ISO 4318 : détermination de la matière insoluble dans l'alcool

Ce sont ces normes, et non des références non vérifiées, qui servent de base aux contrôles officiels — c'est pour ça qu'elles sont reprises ici plutôt que d'autres numéros qui circulent parfois sans source fiable.

3. Vérifier la conformité d'un lot

À chaque fabrication, avant de mettre un lot en vente, vérifier :
- pH (cible 6-7, voir Module 3 §3)
- Viscosité (texture correcte, voir Module 3 §3)
- Taux de tensioactif réellement utilisé, par le calcul (voir Module 1 §6) — ou par une analyse en laboratoire agréé si vous visez une certification officielle plus tard
- Aspect visuel : couleur homogène, pas de dépôt ni de séparation dans le bidon

Tout ceci se note directement sur la fiche de lot (Module 4 §3) : c'est elle qui prouve, lot par lot, que vos produits respectent les seuils de la norme BNM (rappel Module 1 §7 : 10% à 20% de tensioactif pour un produit d'entretien).

4. Que faire si un lot n'est pas conforme

- Ne jamais vendre un lot hors norme, même "probablement sans danger" — mieux vaut perdre ce lot que perdre la confiance d'un client ou risquer un contrôle.
- Si le problème est mesurable et rattrapable (ex. trop concentré → diluer légèrement avec de l'eau, en recalculant le nouveau % de MA), corriger puis re-tester avant de valider le lot.
- Si le problème n'est pas rattrapable (pH très éloigné de la cible, séparation visible), ne pas conditionner ce lot — noter la cause probable sur la fiche de lot pour éviter de refaire la même erreur.$$
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
and sort_order = 4;
