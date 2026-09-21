-- ============================================================
-- AkoraHub - Patch Phase 243 : ajoute les flacons/bouteilles PET
-- au pilier Akora Packaging, catégorie "Flacons & bouteilles"
-- (créée en phase242) — demande explicite de la propriétaire le
-- 21/09/2026.
--
-- Formats demandés : 250 ml, 400 ml, 500 ml, 750 ml, 1 L, 5 L, 20 L.
--
-- Créés en brouillon (visibility = false) : ni prix, ni photo, ni
-- stock réels fournis pour l'instant — à compléter depuis l'Admin
-- (fiche produit) avant publication.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (where not exists, ne duplique pas si déjà créé).
-- ============================================================

insert into public.products (
  business_unit_id, category, name, description, visibility
)
select bu.id, 'Flacons & bouteilles', v.name, v.description, false
from public.business_units bu
cross join (
  values
    ('Flacon PET 250 ml',
     'Flacon en plastique PET, contenance 250 ml — pour le conditionnement de liquides (produits d''entretien, cosmétiques, etc.).'),
    ('Flacon PET 400 ml',
     'Flacon en plastique PET, contenance 400 ml — pour le conditionnement de liquides (produits d''entretien, cosmétiques, etc.).'),
    ('Flacon PET 500 ml',
     'Flacon en plastique PET, contenance 500 ml — pour le conditionnement de liquides (produits d''entretien, cosmétiques, etc.).'),
    ('Flacon PET 750 ml',
     'Flacon en plastique PET, contenance 750 ml — pour le conditionnement de liquides (produits d''entretien, cosmétiques, etc.).'),
    ('Flacon PET 1 L',
     'Flacon en plastique PET, contenance 1 litre — pour le conditionnement de liquides (produits d''entretien, cosmétiques, etc.).'),
    ('Bidon PET 5 L',
     'Bidon en plastique PET, contenance 5 litres — pour le conditionnement de liquides en gros volume (produits d''entretien, etc.).'),
    ('Bidon PET 20 L',
     'Bidon en plastique PET, contenance 20 litres — pour le conditionnement de liquides en très gros volume (produits d''entretien, etc.).')
) as v(name, description)
where bu.slug = 'akora-packaging'
  and not exists (
    select 1 from public.products p
    where p.business_unit_id = bu.id and p.name = v.name
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
-- where category = 'Flacons & bouteilles'
-- order by name;
