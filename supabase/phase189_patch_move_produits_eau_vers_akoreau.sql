-- ============================================================
-- AkoraHub - Patch Phase 189 : déplace vers "Akor'Eau" les 3 produits
-- existants dont l'usage est EXCLUSIVEMENT le traitement de l'eau
-- (demande explicite du 04/09/2026, suite à Phase 188).
--
-- Choix (confirmé par la propriétaire) : ne PAS déplacer les réactifs
-- multi-usages (soude caustique, acide chlorhydrique, EDTA, charbon
-- actif, hypochlorite, peroxyde d'hydrogène, PAA...) qui servent aussi
-- à d'autres usages dans le catalogue — un produit n'a qu'UNE seule
-- catégorie, les y déplacer leur ferait perdre leur classement actuel.
--
-- Les 3 produits ci-dessous n'ont aucun autre usage décrit dans leur
-- fiche que le traitement de l'eau/piscine :
--   - "Sulfate d'aluminium (Alun)" — actuellement "Acides & Bases"
--   - "Polymeres floculants" — actuellement "Polymères & Résines"
--   - "TCCA (Trichloroisocyanurate)" — actuellement "Désinfectants"
--
-- Met à jour raw_materials.category_name ET products.category : le
-- trigger sync_product_after_raw_material_insert (Phase 159) ne se
-- déclenche qu'à l'INSERT, pas à l'UPDATE — les deux tables doivent
-- donc être mises à jour explicitement ici pour rester cohérentes.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (les UPDATE sont sans effet si déjà appliqués).
--
-- CORRECTIF 04/09/2026 : le pilier "Akora Fanadiovana" a été renommé
-- "Akora Pro" (rebranding "Groupe Akora" fait en parallèle côté site
-- web) — le lookup ci-dessous utilise désormais bu.slug =
-- 'matieres-premieres' (identifiant stable) au lieu de bu.name. La
-- première exécution (nom obsolète) a rapporté "Success" mais n'a en
-- réalité rien déplacé (sortie anticipée du garde-fou) — à
-- ré-exécuter avec ce correctif.
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
  v_names text[] := array[
    'Sulfate d''aluminium (Alun)',
    'Polymeres floculants',
    'TCCA (Trichloroisocyanurate)'
  ];
begin
  select id into v_business_unit_id
    from public.business_units where slug = 'matieres-premieres';

  if v_business_unit_id is null then
    raise notice 'Aucun pilier avec le slug "matieres-premieres" trouvé — rien déplacé.';
    return;
  end if;

  update public.raw_materials
    set category_name = 'Akor''Eau'
    where business_unit_id = v_business_unit_id
      and name = any(v_names);

  update public.products
    set category = 'Akor''Eau'
    where business_unit_id = v_business_unit_id
      and name = any(v_names);
end $$;

-- Vérification : les 3 produits doivent maintenant afficher "Akor'Eau"
-- select name, category_name from public.raw_materials
--   where name = any(array['Sulfate d''aluminium (Alun)', 'Polymeres floculants', 'TCCA (Trichloroisocyanurate)']);
-- select name, category from public.products
--   where name = any(array['Sulfate d''aluminium (Alun)', 'Polymeres floculants', 'TCCA (Trichloroisocyanurate)']);
