-- ============================================================
-- AkoraHub - Patch Phase 185 : stock partagé (produits vendus en vrac) +
-- base_unit_quantity pour les formats liquides
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (25/08, demande explicite) : pour un produit vendu en vrac
-- avec plusieurs contenants (ex. Liquide Vaisselle en 1L/5L/Bidon 20L/
-- Fût 170L rempli depuis le même stock de liquide), la quantité en stock
-- ne doit être saisie qu'UNE FOIS, en unité de base (litres ou kg), pas
-- répétée pour chaque format. L'app calcule ensuite combien de chaque
-- contenant sont disponibles (stock total ÷ contenance du format).
--
-- 1) `products.use_shared_stock` (défaut false) : active ce mode pour un
--    produit donné, sans rien changer pour les produits existants
--    (Softberry etc., phase156) qui gardent un stock par variante.
--    Quand actif, `products.stock_quantity` (colonne déjà existante,
--    jusqu'ici inutilisée pour les produits à variantes) devient le
--    stock total en unité de base ; le stock propre à chaque variante
--    (`product_variants.stock_quantity`) n'est alors plus utilisé.
-- 2) `formats.base_unit_quantity` (phase172, jusqu'ici renseigné
--    seulement pour les conditionnements au poids) est complété pour
--    les formats liquides existants — nécessaire pour le calcul de
--    disponibilité par contenant ET pour le choix du format par défaut
--    (1 L, comme pour "1 kg" déjà en place).
-- ============================================================

alter table public.products
  add column if not exists use_shared_stock boolean not null default false;

-- Format "Pièce" (25/08, demande explicite) : pour les produits vendus à
-- l'unité plutôt qu'au poids/volume (ex. accessoires), afin que le choix
-- par défaut du format (voir _defaultVariantInKg côté app) ait aussi une
-- valeur "de base" (1) à privilégier, comme pour 1 kg / 1 L.
insert into public.formats (name, base_unit_quantity) values
  ('Pièce', 1)
on conflict (name) do update set base_unit_quantity = excluded.base_unit_quantity;

update public.formats set base_unit_quantity = v.qty
from (values
  ('100 ml', 0.1), ('250 ml', 0.25), ('500 ml', 0.5),
  ('1 L', 1), ('2 L', 2), ('5 L', 5), ('10 L', 10),
  ('Bidon 20 L', 20), ('Fût 170 L', 170), ('Fût 200 L', 200)
) as v(name, qty)
where public.formats.name = v.name
  and public.formats.base_unit_quantity is null;

-- 3) Prix de base à 0 pour les produits créés automatiquement à partir
--    d'une matière première (Eau de Javel, Peroxyde d'hydrogène —
--    phase179, via sync_product_from_raw_material) : ils n'ont jamais eu
--    de price_detail propre, donc leur carte catalogue affichait
--    "Dès 0 Ar" au client. Repris depuis leur variante la moins chère.
update public.products p
set price_detail = v.min_price
from (
  select product_id, min(price_detail) as min_price
  from public.product_variants
  where price_detail > 0
  group by product_id
) v
where p.id = v.product_id
  and coalesce(p.price_detail, 0) = 0;
