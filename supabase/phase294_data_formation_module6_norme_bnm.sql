-- ============================================================
-- AkoraHub - Phase 294 : contenu du Module 6 "Norme Malagasy & BNM"
-- — formation Liquide Vaisselle
--
-- Demande explicite (29/10). Contenu rédigé directement à partir du
-- document officiel fourni par la propriétaire : Bureau des Normes
-- de Madagascar, "Savons et Détergents", NMG 401-1/2004 (éd.
-- 29-06-2004). Chiffres et mentions obligatoires repris tels quels
-- du document, pas une estimation.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set content_text = $$Ce module est basé directement sur la norme officielle NMG 401-1/2004 du Bureau des Normes de Madagascar (BNM), "Savons et Détergents".

1. Ce que couvre cette norme

Elle fixe les conditions pour les savons de ménage, savons de toilette, produits d'entretien, détergents et eaux de javel vendus à Madagascar. Elle ne s'applique PAS aux shampoings, savons médicaux et médicamenteux.

Le liquide vaisselle se classe dans la catégorie "Produit d'entretien multiusage" de cette norme (catégorie la plus proche — à confirmer directement auprès du BNM si vous visez une certification officielle).

2. Seuils exigés pour un produit d'entretien multiusage

D'après le tableau officiel de la norme (§4) :
- Tensioactif : 10% minimum, 20% maximum
- Biodégradabilité : 80% minimum
- pH à 1% de solution à 23°C : maximum 8

Rappel général (§4, toutes catégories) : les produits doivent être non radioactifs, biodégradables à 80% minimum, à chaîne linéaire (voir Module 1 §4 sur le LABSA linéaire), et non irritants pour le derme.

3. Mentions obligatoires sur l'étiquette

D'après la norme (§5.3, catégorie détergents liquides — la plus proche du liquide vaisselle), votre étiquette doit obligatoirement comporter :
- Le poids ou le volume net selon le système métrique international
- La marque de fabrique
- La désignation du produit : "RANON-TSAVONY"
- La date de fabrication
- Le pays d'origine
- La composition : taux de phosphate, taux des tensioactifs, taux de biodégradabilité
- Le mode d'emploi au moins en malgache, avec les indications de dosage
- Le code à barres (recommandé)
- La mention obligatoire : « TSY AZO SOTROINA », en caractères lisibles et visibles

Les inscriptions doivent aussi comporter obligatoirement, en malgache, en caractères lisibles et visibles, cette phrase de sécurité :
« AMPIRIMO TSARA MBA TSY HO LALAOVIN'NY ANKIZY. RAHA SENDRA VOA NY MASO DIA SASAO AVY HATRANY AMIN'NY RANO BE. RAHA SENDRA VOATELINA DIA MANATONA HAINGANA MPITSABO »

(Traduction indicative : « Conserver hors de portée des enfants. En cas de contact avec les yeux, rincer abondamment à l'eau. En cas d'ingestion, consulter rapidement un médecin. »)

4. Formats de conditionnement autorisés (en millilitres)

La norme fixe des paliers précis pour les détergents liquides — tous les formats vendus doivent respecter ces multiples :
- de 25 à 150 ml : tous les multiples de 25
- de 150 à 750 ml : tous les multiples de 50
- de 750 à 2 500 ml : tous les multiples de 250
- de 2 500 à 5 000 ml : tous les multiples de 500
- de 5 000 à 10 000 ml : tous les multiples de 1 000

Un bidon de 5 litres (5 000 ml) comme dans la formule de base respecte déjà ces paliers. Pour d'autres tailles (ex. petits flacons), toujours vérifier que le volume choisi correspond à l'un de ces multiples autorisés avant de commander les contenants.

5. Ce qu'il reste à vérifier vous-même

Ce module reprend les exigences écrites de la norme NMG 401-1/2004. Pour une certification officielle (si vous la visez), contactez directement le BNM (B.P : 1316 Soarano, Antananarivo — bnm@bnm.mg) pour la procédure de demande, les coûts et délais à jour — ces informations pratiques ne figurent pas dans le document technique fourni et doivent être confirmées directement auprès d'eux.$$
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
and sort_order = 5;
