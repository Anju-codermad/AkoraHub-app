-- ============================================================
-- AkoraHub - Patch Phase 297 : recentrer la référence à la norme BNM
-- dans le Module 1 sur la seule catégorie du liquide vaisselle
--
-- Correction demandée (29/10) : le Module 1 §7 citait les seuils de
-- tensioactif des 3 catégories du tableau BNM (détergent poudre,
-- lessive liquide, produit d'entretien multiusage), alors que seule
-- la catégorie "Produit d'entretien multiusage" concerne le liquide
-- vaisselle (voir Module 6 §1, classification retenue). Les deux
-- autres catégories n'ont rien à faire dans cette formation.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set content_text = $$1. Qu'est-ce qu'un tensioactif ?

Un tensioactif (ou agent de surface) est une molécule à deux parties :
- une tête hydrophile (attirée par l'eau)
- une queue hydrophobe (attirée par les graisses)

C'est cette double nature qui permet au tensioactif de "décrocher" la saleté grasse d'une surface et de la disperser dans l'eau de rinçage — c'est le principe de base de tout produit moussant (liquide vaisselle, shampoing, lessive).

2. Les grandes familles de tensioactifs

- Anioniques (charge négative) : les plus moussants et nettoyants — SLES et LABSA en font partie. Ce sont la base de la plupart des formules.
- Amphotères (charge variable) : CAPB en fait partie — plus doux, utilisés en complément pour stabiliser et adoucir la mousse.
- Non-ioniques et cationiques : moins utilisés dans nos formules actuelles (cationiques surtout pour les adoucissants textile).

3. SLES (Sodium Laureth Sulfate)

Tensioactif anionique, base moussante principale des liquides vaisselle et shampoings. Mousse abondante et onctueuse, mais peut être irritant seul à forte dose — d'où l'intérêt de l'associer à un co-tensioactif plus doux (CAPB).

4. LABSA (Acide Dodécylbenzène Sulfonique Linéaire)

Autre tensioactif anionique, très puissant et économique — base de nombreux détergents en poudre et lessives liquides. Le "L" (Linéaire) est important : un LABSA à chaîne linéaire est biodégradable, contrairement aux anciennes versions ramifiées (branchées), aujourd'hui interdites dans la plupart des normes environnementales. Toujours vérifier que le LABSA acheté est bien linéaire (LAS).

5. CAPB (Cocamidopropyl Bétaïne)

Tensioactif amphotère doux, utilisé en complément du SLES ou du LABSA. Il stabilise et épaissit la mousse, et réduit l'irritation du tensioactif principal sur la peau — c'est pour ça qu'on l'ajoute même en petite quantité (souvent 2 à 5%) dans la formule.

6. Calcul de la matière active (MA%)

Les tensioactifs achetés ne sont jamais purs à 100% — ils sont vendus à une concentration donnée (ex. "SLES 70%" veut dire 70% de matière active, 30% d'eau/solvant). Pour savoir combien de produit brut utiliser afin d'atteindre un pourcentage de matière active donné dans la formule finale :

Quantité de produit brut = (% MA visé × masse totale de la formule) / % de concentration du produit brut

Exemple : viser 8% de MA de SLES dans une formule de 5 litres (5000 g), avec un SLES à 70% :
Quantité de SLES 70% = (8% × 5000 g) / 70% = 400 / 0,70 = 571 g

(Si on utilisait un SLES pur à 100%, il n'en faudrait que 400 g — d'où l'importance de toujours vérifier la concentration indiquée sur l'étiquette du fournisseur avant de calculer une formule.)

7. Ce que dit la norme malgache (BNM, NMG 401-1/2004)

Le liquide vaisselle se classe dans la catégorie "Produit d'entretien multiusage" de cette norme (voir Module 6). Pour cette catégorie, le taux de tensioactif exigé est de 10% minimum à 20% maximum.

Rester dans cette fourchette n'est pas qu'une question de conformité — un produit sous le minimum nettoie mal, un produit au-dessus du maximum gaspille de la matière première sans gain réel d'efficacité. (Le détail complet de la norme — biodégradabilité, pH, étiquetage obligatoire — est couvert au Module 6.)$$
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
and sort_order = 0;
