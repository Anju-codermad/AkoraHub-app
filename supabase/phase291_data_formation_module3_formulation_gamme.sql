-- ============================================================
-- AkoraHub - Phase 291 : contenu du Module 3 "Formulation par
-- gamme" — formation Liquide Vaisselle
--
-- Demande explicite (29/10). Couvre : pourquoi faire plusieurs
-- gammes (notion reprise du document BNM — "1ère/2ème/3ème gamme"),
-- 5 formules concrètes à 3 niveaux de gamme, ajustement
-- viscosité/pH, et un calculateur de mise à l'échelle — repris des
-- tags de la maquette fournie (MA% calcul, 5 formules, Viscosité &
-- pH, Calculateur).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set content_text = $$1. Pourquoi faire plusieurs gammes ?

Le document BNM (NMG 401-1/2004) distingue déjà officiellement plusieurs "gammes" pour le savon de ménage, selon leur taux de matières grasses. On applique le même principe au liquide vaisselle : proposer plusieurs niveaux de qualité/prix permet de toucher différents clients (prix serré vs qualité premium) avec la même recette de base, juste en faisant varier le % de matière active (MA, voir Module 1).

- Gamme Économique (MA ~6-8%) : mousse correcte, dégraissage standard, prix de revient le plus bas — pour la vente en grande quantité ou en gros conditionnements.
- Gamme Standard (MA ~10-12%) : le bon équilibre mousse/dégraissage/coût — c'est la formule "tout public" (proche de la formule de base déjà utilisée).
- Gamme Premium/Concentré (MA ~14-16%) : très concentré, dégraisse plus vite, flacon plus petit pour le même nombre d'utilisations — positionnement haut de gamme.

Rappel : rester toujours dans la fourchette BNM pour les produits d'entretien (10% à 20% de tensioactif, voir Module 1 §7).

2. Cinq formules prêtes à l'emploi (pour 5 litres)

Formule 1 — Économique (MA ~6%) :
SLES 70% : 430 g · CAPB 45% : 100 g · Comperlan 85% : 30 g · Sel : 50-80 g · Acide citrique : qs pH 6-7 · Colorant + Parfum : qs · Conservateur : selon dose fournisseur

Formule 2 — Standard (MA ~8%, la formule de base déjà en place) :
SLES 70% : 400 g · CAPB 45% : 150 g · Comperlan 85% : 50 g · Sel : 50-100 g · Acide citrique : qs pH 6-7 · Colorant + Parfum : qs · Conservateur : selon dose fournisseur

Formule 3 — Standard anti-graisse renforcé (MA ~10%) :
SLES 70% : 550 g · CAPB 45% : 180 g · Comperlan 85% : 60 g · Sel : 60-100 g · Acide citrique : qs pH 6-7 · Colorant + Parfum : qs · Conservateur : selon dose fournisseur

Formule 4 — Premium concentré (MA ~14%) :
SLES 70% : 750 g · CAPB 45% : 250 g · Comperlan 85% : 80 g · Sel : 80-120 g (souvent moins nécessaire, le produit est déjà plus épais) · Acide citrique : qs pH 6-7 · Colorant + Parfum : qs (dose légèrement augmentée) · Conservateur : selon dose fournisseur

Formule 5 — Sans parfum / peau sensible (MA ~8%, base de la Formule 2 sans parfum) :
Identique à la Formule 2, sans colorant ni parfum — CAPB en proportion légèrement augmentée (180 g) pour compenser la douceur perçue habituellement apportée par le parfum.

(qs = quantité suffisante, à ajuster/mesurer comme vu dans la formule de base d'origine.)

3. Ajuster la viscosité et le pH

- Viscosité : se règle avec le sel (NaCl), comme vu dans la formule de base — ajouter progressivement en testant à chaque fois (une cuillère versée doit s'écouler en ruban continu, ni trop liquide ni trop figée). Les formules plus concentrées (Premium) ont naturellement besoin de moins de sel.
- pH : cible 6 à 7 (mesuré au papier pH ou pH-mètre). En dessous de 6, le produit est trop acide (peut irriter) ; au-dessus de 7, le pouvoir moussant/dégraissant diminue. Ajuster avec de l'acide citrique dilué, goutte à goutte, en remesurant à chaque ajout.

4. Calculateur — mettre une formule à l'échelle

Toutes ces formules sont données pour 5 litres. Pour fabriquer un autre volume, multiplier CHAQUE ingrédient par le même facteur :

Facteur = Volume souhaité (L) / 5

Exemple : fabriquer 20 litres de Formule 2 (Standard) → Facteur = 20 / 5 = 4
- SLES 70% : 400 g × 4 = 1 600 g
- CAPB 45% : 150 g × 4 = 600 g
- Comperlan 85% : 50 g × 4 = 200 g
- Sel : 50-100 g × 4 = 200-400 g (toujours ajuster progressivement, même à grande échelle)

Le sel, le colorant, le parfum et l'acide citrique restent toujours "à ajuster en testant" même à grande échelle — seuls les tensioactifs (SLES/CAPB/Comperlan) peuvent être calculés à l'avance avec certitude.$$
where course_id = (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
and sort_order = 2;
