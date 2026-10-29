-- ============================================================
-- AkoraHub - Phase 292 : contenu du Module 4 "Processus de
-- fabrication" — formation Liquide Vaisselle
--
-- Demande explicite (29/10). Couvre : organisation de l'atelier en 5
-- zones, ordre d'ajout des ingrédients (et pourquoi), fiche de lot
-- (traçabilité), et planification des lots selon les commandes —
-- repris des tags de la maquette fournie (5 zones atelier, Ordre
-- ajout, Fiche lot, Batch calc).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set content_text = $$1. Organiser l'atelier en 5 zones

Même dans un petit espace, séparer physiquement (ou au minimum dans le temps) ces 5 étapes évite les erreurs et accélère la production :

1. Réception & stockage des matières premières — bidons fermés, étiquetés, à l'abri de la chaleur/du soleil (voir Module 1 §7 et la formule de base).
2. Pesée & dosage — un seul poste avec la balance, où chaque ingrédient est pesé avant d'être versé. Jamais "à l'œil".
3. Mélange & fabrication — le poste avec le seau/la bassine de mélange, où se déroule l'ordre d'ajout (voir §2 ci-dessous).
4. Contrôle qualité — poste séparé avec le papier pH et de quoi vérifier la viscosité, à l'écart du mélange en cours pour éviter toute contamination.
5. Conditionnement & stockage produit fini — mise en bouteille, étiquetage, stockage des produits finis séparément des matières premières brutes (pour ne jamais confondre un bidon de matière première avec un bidon de produit fini).

2. L'ordre d'ajout des ingrédients — et pourquoi il compte

L'ordre donné dans la formule de base n'est pas arbitraire :
1. Eau d'abord (base/solvant)
2. SLES, sous agitation douce — une agitation trop forte à ce stade crée une mousse excessive qui gêne les étapes suivantes
3. CAPB, puis Comperlan — ajoutés après le SLES pour bien se disperser dans la base déjà diluée
4. Sel, progressivement — épaissit ; ajouté trop tôt (avant que les tensioactifs soient bien dissous), le résultat est inégal
5. Correcteur de pH (acide citrique), colorant, parfum, conservateur — toujours en dernier, une fois la texture stabilisée, pour ne pas fausser les dosages avant la fin du mélange

Respecter cet ordre évite trois problèmes fréquents : une mousse ingérable pendant la fabrication, un produit trouble ou granuleux (sel mal dissous), et un parfum/colorant mal réparti dans le mélange.

3. La fiche de lot — pourquoi la remplir à chaque fabrication

Une fiche de lot est un document simple à remplir à CHAQUE fabrication, qui note :
- Numéro de lot et date de fabrication
- Quantités exactes pesées de chaque ingrédient (pas la quantité théorique de la formule — la quantité réellement versée)
- Qui a fabriqué le lot
- Résultats du contrôle qualité : pH mesuré, viscosité jugée correcte ou non
- Heure de début et de fin de fabrication

Son utilité concrète :
- Traçabilité en cas de réclamation client (retrouver précisément quel lot a été vendu, avec quels ingrédients)
- Répétabilité : reproduire exactement un bon lot, ou identifier ce qui a changé sur un lot problématique
- Document à présenter en cas de contrôle (voir Module 7 — Sécurité, FDS & Réglementation)

Même un simple cahier avec ces informations, lot par lot, suffit pour démarrer.

4. Planifier la taille des lots (batch calc)

Utiliser le calculateur de mise à l'échelle du Module 3 pour adapter la taille du lot aux besoins réels :
- Trop petit lot par rapport aux commandes → ruptures fréquentes, fabrication trop souvent répétée
- Trop grand lot par rapport à la demande → stock immobilisé, risque que le produit fini vieillisse avant d'être vendu

Méthode simple : additionner les commandes en attente + une marge de stock de sécurité (par exemple l'équivalent d'une semaine de vente habituelle), puis utiliser le facteur d'échelle (Module 3 §4) pour calculer les quantités d'ingrédients du lot à produire.$$
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
and sort_order = 3;
