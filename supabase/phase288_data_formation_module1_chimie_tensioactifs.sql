-- ============================================================
-- AkoraHub - Phase 288 : contenu du Module 1 "Chimie des
-- tensioactifs" — formation Liquide Vaisselle
--
-- Demande explicite (29/10) : écrire le contenu réel du premier
-- module de la nouvelle structure pro (après le renommage en
-- phase287). Couvre : SLES, LABSA, CAPB, et le calcul de matière
-- active (MA%) — repris des tags de la maquette fournie, SAUF "ISO
-- 8022" qui ne correspond à aucune norme vérifiable pour les
-- tensioactifs/savons (le document BNM NMG 401-1/2004 fourni par la
-- propriétaire cite ISO 456/457/672/8212/4318, pas 8022 — à confirmer
-- avec elle avant d'ajouter une référence non vérifiée).
--
-- Les seuils de % tensioactif cités plus bas viennent directement du
-- document BNM NMG 401-1/2004 (tableau §4, page 5) fourni par la
-- propriétaire — chiffres réels, pas une estimation.
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

Le taux de tensioactif exigé varie selon le type de produit (chiffres officiels du document BNM) :
- Détergent en poudre : 12% minimum, 20% maximum
- Lessive liquide : 10% minimum, 20% maximum
- Produit d'entretien multiusage : 10% minimum, 20% maximum

Rester dans cette fourchette n'est pas qu'une question de conformité — un produit sous le minimum nettoie mal, un produit au-dessus du maximum gaspille de la matière première sans gain réel d'efficacité.$$
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
and sort_order = 0;
