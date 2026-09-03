# Logique dupliquée entre l'app et le site web

Depuis le 03/09/2026, le site web vit dans son propre dépôt GitHub
**`Anju-codermad/groupe-akora-site`** (dossier `site/`), séparé de ce
dépôt (`AkoraHub-app`, application Flutter, dossier `lib/`). Les deux
partagent la même base Supabase mais ne partagent aucun code — l'un est
écrit en Dart, l'autre en HTML/CSS/JS brut. Certaines règles
d'AFFICHAGE (pas les données produit, qui viennent automatiquement de
Supabase des deux côtés) sont donc écrites deux fois, séparément, **dans
deux dépôts différents**. Avant de changer une des règles ci-dessous,
vérifier TOUS les emplacements listés (y compris dans l'autre dépôt)
pour ne pas laisser l'app et le site se désynchroniser visuellement.

Ajouter une ligne ici dès qu'une nouvelle règle d'affichage doit exister
des deux côtés à la fois.

## 1. Unité de prix (kg / L / pièce) à côté du prix

Règle : format "1 kg"/"1 L"/"Pièce" (l'unité de base) → n'affiche que le
mot d'unité ("kg", "L") ; tout autre conditionnement ("25 kg", "Bidon 20
L") garde son nom complet.

- App : `lib/core/utils/price_unit.dart`
  (`unitSuffixFromFormatName`, `unitLabelFromEmbeddedVariants`)
- Site : fonction JS `unitSuffixFromFormatName`, dupliquée dans le
  `<script>` de `index.html`,
  `catalogue.html` et `produit.html`

## 2. Repli photo/prix pour un produit à variantes sans prix propre

Règle : si `products.price_detail`/`image_url` sont vides (produit
vendu uniquement via `product_variants`), prendre la photo/le prix de
la variante la moins chère.

- Fonction Cloudflare (aperçu de partage Facebook/Messenger) :
  `functions/_produit-og.js`
- Site (page produit elle-même, si JS activé) : fallback dans
  `produit.html`

## 3. Palette de couleurs et typographie du site

Les 7 pages (`index.html`, `a-propos.html`, `catalogue.html`,
`produit.html`, `formation.html`, `services.html`,
`privacy-policy.html` en partie) ont chacune leur PROPRE copie des
variables CSS (`--accent`, `--accent-strong`, `--accent-soft`,
`--font-display`, etc.) et du CSS du footer/nav — pas de fichier CSS
partagé entre les pages. Un changement de couleur ou de police doit
être répété sur chacune.

## 4. Indicateur horaires "Ouvert maintenant" / "Fermé actuellement"

Script JS (calcul via `Intl.DateTimeFormat`, fuseau
`Indian/Antananarivo`, horaires codés en dur) dupliqué dans le
`<script>` de chacune des 7 pages du site.

## Ce qui N'EST PAS dupliqué (pas de risque)

Les données elles-mêmes (produits, prix, stock, photos, catégories,
avis, dosages Académie...) viennent en direct de Supabase des deux
côtés — ajouter/modifier un produit dans l'Admin se reflète
automatiquement sur le site ET l'app, sans toucher au code.

## ⚠️ SQL / migrations Supabase : un seul endroit, pas deux

Les deux dépôts partagent la MÊME base Supabase. Toutes les migrations
SQL doivent vivre dans **`AkoraHub-app/supabase/`** (numérotées par
phase, voir `supabase/SOMMAIRE.md` dans ce dépôt) — jamais dans un
dossier `supabase/` du dépôt `groupe-akora-site`. Si une migration est
nécessaire pour une fonctionnalité du site, la faire passer par la
conversation/le dépôt de l'app d'abord pour éviter un conflit avec une
autre migration en cours.
