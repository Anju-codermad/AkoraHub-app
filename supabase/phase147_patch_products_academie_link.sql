-- ============================================================
-- AkoraHub - Patch Phase 147 : lien produit -> fiche Académie +
-- résumé public de sécurité (chantiers "Akora Pro" du 09/08)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : un produit vendable (`products`, ex. "Soude Caustique
-- (NaOH)") et sa fiche technique/sécurité Académie (`raw_materials` +
-- `matieres_premieres_academie`) sont deux entités séparées sans lien
-- explicite jusqu'ici. On ajoute :
-- 1) `products.raw_material_id` (optionnel, choisi manuellement par le
--    staff dans l'admin) pour afficher un lien "Fiche sécurité" sur la
--    page produit client.
-- 2) Une vue publique `academie_summary_public` exposant UNIQUEMENT le
--    niveau de danger, la particularité et les domaines d'usage
--    généraux — gratuit, visible sans achat Formation — tandis que le
--    dosage et le détail technique complet restent derrière l'achat
--    existant (`has_purchased_raw_material`, phase45/83).
-- ============================================================

alter table public.products
  add column if not exists raw_material_id uuid
    references public.raw_materials(id) on delete set null;

create index if not exists products_raw_material_id_idx
  on public.products (raw_material_id);

-- La vue s'exécute avec les droits de son propriétaire (même principe
-- que raw_materials_preview, phase40, et public_profiles, phase9) :
-- elle reste lisible même si la RLS de matieres_premieres_academie /
-- matieres_premieres_usages est restrictive (achat requis) pour un
-- accès direct aux tables sources.
create or replace view public.academie_summary_public as
select
  a.matiere_premiere_id,
  a.niveau_danger,
  a.particularite,
  (
    select array_agg(distinct u.domaine_application order by u.domaine_application)
    from public.matieres_premieres_usages u
    where u.academie_id = a.id
  ) as domaines_usage
from public.matieres_premieres_academie a;

grant select on public.academie_summary_public to authenticated, anon;
