-- ============================================================
-- AkoraHub - Patch Phase 241 : ajoute "Bouchon push-pull" au pilier
-- Akora Packaging — demande explicite de la propriétaire le
-- 19/09/2026 (photo fournie : bouchon push-pull jaune sur flacon
-- blanc).
--
-- Contexte : le pilier Akora Packaging (phase233, créé par la
-- conversation du site) existe déjà avec ses 9 catégories, mais
-- toutes vides — aucun produit n'y a encore été ajouté, d'où le fait
-- que la propriétaire ne trouvait rien en cherchant "push-pull".
--
-- Créé en brouillon (visibility = false) : ni prix, ni photo, ni stock
-- réels fournis pour l'instant — à compléter depuis l'Admin (fiche
-- produit) avant publication, notamment la photo (à uploader
-- directement dans l'app, pas transmissible depuis cette conversation).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing, ne duplique pas si déjà créé).
-- ============================================================

-- Pas de contrainte unique sur products(business_unit_id, category, name)
-- (contrairement à raw_materials, phase40) : idempotence assurée via
-- `where not exists` plutôt que `on conflict`.
insert into public.products (
  business_unit_id, category, name, description, visibility
)
select bu.id, 'Accessoires d''emballage', 'Bouchon push-pull',
  'Bouchon verseur push-pull (bouchon-poussoir) pour flacon — ouverture/fermeture par simple pression, évite les fuites accidentelles. Utilisé pour le conditionnement de liquides (produits d''entretien, cosmétiques, etc.).',
  false
from public.business_units bu
where bu.slug = 'akora-packaging'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = 'Bouchon push-pull'
  );

-- Garde-fou : prévenir si le pilier Akora Packaging n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-packaging'
  ) then
    raise notice 'Aucun pilier avec le slug ''akora-packaging'' trouvé — rien inséré.';
  end if;
end $$;

-- Vérification :
-- select id, name, category, visibility from public.products
-- where name = 'Bouchon push-pull';
