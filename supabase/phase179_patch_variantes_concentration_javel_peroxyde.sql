-- ============================================================
-- AkoraHub - Patch Phase 179 : photo par variante + produits Eau de
-- Javel / Peroxyde d'hydrogène en variantes de concentration
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (25/08, demande explicite) : l'utilisatrice veut vendre
-- l'Eau de Javel (9°/12°/18°/36°/48°) et le Peroxyde d'hydrogène
-- (3%/10%/50%) comme un seul produit avec plusieurs variantes de
-- concentration, chacune avec sa PROPRE PHOTO (étiquette différente
-- par degré/concentration) en plus de son propre prix — le mécanisme
-- Format x Parfum (phase4) gère déjà le prix par variante, mais pas
-- de photo par variante. Ce patch :
--
-- 1) Ajoute `product_variants.image_url` (nullable) — l'écran
--    "Variantes" de l'app (product_variants_screen.dart) et la fiche
--    produit client (product_detail_client.dart) sont mis à jour dans
--    ce même commit pour l'utiliser.
-- 2) Ajoute les degrés/concentrations comme nouveaux `formats`
--    (réutilise l'axe Format existant, comme phase172 l'a déjà fait
--    pour les conditionnements industriels — pas un nouveau système).
-- 3) Crée les 2 fiches produit via `sync_product_from_raw_material`
--    (phase159, déjà existante) plutôt qu'un INSERT manuel : reprend
--    automatiquement le bon business_unit_id/catégorie/description
--    depuis les fiches Académie déjà existantes (phase101), sans
--    risque d'incohérence. Les matières premières liées existent déjà
--    (Hypochlorite de sodium NaClO, Peroxyde d'hydrogène) mais dataient
--    d'avant la création du trigger auto : il faut donc l'appeler
--    manuellement une fois ici. Renommées ensuite pour rester
--    reconnaissables côté client ("Eau de Javel" plutôt que le seul
--    nom chimique), en ciblant par raw_material_id (jamais par nom
--    deviné) pour rester sûr même si le nom exact déjà en base diffère.
--
-- Les fiches restent en BROUILLON (visibility = false, comportement
-- par défaut du trigger) : à publier une fois les variantes (prix +
-- photo par degré) ajoutées depuis l'écran "Variantes" de l'app.
-- ============================================================

alter table public.product_variants
  add column if not exists image_url text;

insert into public.formats (name) values
  ('3%'), ('10%'), ('50%'),
  ('9°'), ('12°'), ('18°'), ('36°'), ('48°')
on conflict (name) do nothing;

select public.sync_product_from_raw_material('b49c6261-ea6d-4dc7-923e-b7885abd6f60'); -- Hypochlorite de sodium (eau de Javel)
select public.sync_product_from_raw_material('14107942-bb36-417b-a19f-44efb35120cf'); -- Peroxyde d'hydrogène

update public.products
  set name = 'Eau de Javel (Hypochlorite de sodium)'
  where raw_material_id = 'b49c6261-ea6d-4dc7-923e-b7885abd6f60'::uuid;

update public.products
  set name = 'Peroxyde d''hydrogène'
  where raw_material_id = '14107942-bb36-417b-a19f-44efb35120cf'::uuid;
