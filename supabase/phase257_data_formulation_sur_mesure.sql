-- ============================================================
-- AkoraHub - Patch Phase 257 : activation du service "Formulation
-- sur mesure" dans le catalogue de services de l'app.
--
-- Contexte : le site web (groupe-akora-site, services.html) a reçu
-- une nouvelle section "Produits et Formules Personnalisés" (formules
-- bio sur mesure pour particuliers/marques/entreprises, devis gratuit
-- avant commande). L'utilisateur veut la même offre visible côté app.
-- Le catalogue de services de l'app (phase66) contenait déjà un
-- service correspondant, "Formulation sur mesure" (catégorie
-- "Laboratoire & R&D"), mais désactivé par défaut (available=false).
-- Ce patch l'active et aligne son nom/sa description sur le site, au
-- lieu de créer une entrée dupliquée.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (where ciblé sur l'id existant, sans insert).
-- ============================================================

update public.service_catalog_items
set name = 'Produits et formules personnalisés',
    description = 'Formulation bio sur mesure pour particuliers, marques et entreprises — devis gratuit et clair avant toute commande.',
    available = true,
    updated_at = now()
where name = 'Formulation sur mesure'
  and category_id = (
    select id from public.service_categories where name = 'Laboratoire & R&D'
  );

-- Vérification
select cat.name as categorie, i.name as service, i.description, i.available
from public.service_catalog_items i
join public.service_categories cat on cat.id = i.category_id
where i.name = 'Produits et formules personnalisés';
