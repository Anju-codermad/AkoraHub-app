-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 14
-- Code-barre produit (EAN/UPC déjà imprimé sur l'emballage), en
-- complément du QR code de traçabilité par lot (Phase 13). Le code-barre
-- identifie le PRODUIT (générique), le QR code identifie un LOT précis
-- (avec date de fabrication et DLC).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.products
  add column if not exists barcode text;

-- Un code-barre ne doit pas être réutilisé par deux produits différents
-- (mais reste optionnel : tous les produits n'en ont pas forcément un).
create unique index if not exists products_barcode_unique_idx
  on public.products (barcode)
  where barcode is not null;
