-- ============================================================
-- AkoraHub - Phase 296 : contenu du Module 8 "Commercialisation &
-- Business" — formation Liquide Vaisselle (dernier module)
--
-- Demande explicite (29/10). Couvre : calcul du coût de revient,
-- construction d'une grille tarifaire, différence B2C/B2B, et un
-- simulateur de rentabilité — repris des tags de la maquette fournie
-- (Coût de revient, Grille tarifaire, B2C/B2B, Simulateur).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set content_text = $$1. Calculer le vrai coût de revient

Le coût de revient d'un litre de liquide vaisselle, ce n'est pas que le prix des tensioactifs — il faut additionner :
- Matières premières : tensioactifs + sel + acide citrique + colorant + parfum + conservateur (voir Module 1 §6 pour le calcul de chaque quantité, Module 3 pour les 5 formules)
- Emballage : bidon/bouteille + étiquette (voir les formats autorisés, Module 6 §4)
- Main d'œuvre : temps de fabrication × votre coût horaire (même si c'est vous-même qui fabriquez, valorisez votre temps — sinon le calcul de rentabilité est faux)
- Frais généraux : énergie, eau, amortissement du matériel (balance, seaux...) réparti sur le nombre de litres produits

Coût de revient par litre = (Matières premières + Emballage + Main d'œuvre + Frais généraux) ÷ Nombre de litres du lot

2. Construire une grille tarifaire

Croisez vos 3 gammes (Module 3 §1 : Économique / Standard / Premium) avec vos formats autorisés (Module 6 §4) pour construire une grille complète. Pour chaque case, partez du coût de revient par litre puis appliquez une marge cohérente avec le positionnement :
- Économique : marge plus faible (20-30%), volume de vente plus important
- Standard : marge intermédiaire (30-50%)
- Premium : marge plus élevée (50% et plus), le client paie pour la concentration/qualité perçue

Attention : le prix au litre doit généralement diminuer un peu sur les plus grands formats (incitation à acheter plus), mais jamais en dessous du coût de revient + marge minimale acceptable.

3. Vendre en B2C ou en B2B — deux logiques différentes

- B2C (vente directe au client final) : petits formats, prix unitaire plus élevé, marge plus confortable par litre, paiement immédiat — c'est la vente "au détail".
- B2B (vente à des revendeurs, hôtels, entreprises de nettoyage...) : gros formats ou commandes groupées, prix dégressif au volume (marge plus faible par litre mais volume bien plus important), souvent des délais de paiement à négocier, et une relation commerciale à entretenir dans la durée plutôt qu'une vente ponctuelle.

Les deux peuvent cohabiter : garder une gamme Standard/Premium pour le B2C, et proposer la gamme Économique en gros conditionnements pour le B2B.

4. Simulateur de rentabilité — la formule de base

Avant de lancer un lot ou une nouvelle offre, simulez toujours la rentabilité avec ce calcul simple :

Bénéfice = (Prix de vente × Quantité vendue) − (Coût de revient par litre × Quantité produite)

Exemple : 20 litres de Formule 2 (Standard) produits, coût de revient estimé à 3 000 Ar/L, vendus à 5 000 Ar/L :
Bénéfice = (5 000 × 20) − (3 000 × 20) = 100 000 − 60 000 = 40 000 Ar

Refaites ce calcul à chaque fois que : le prix d'un fournisseur change (Module 2 §3), vous changez de gamme (Module 3), ou vous testez un nouveau format/canal de vente (B2C vs B2B) — c'est le meilleur moyen de savoir si une offre est réellement rentable avant de s'engager dessus.$$
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
and sort_order = 7;
