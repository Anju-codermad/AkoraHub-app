-- ============================================================
-- AkoraHub - Patch Phase 83 : fusion de l'achat Académie avec l'achat
-- Matières premières
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (06/08) : la Phase 81 avait créé un DEUXIÈME achat séparé
-- pour débloquer la fiche technique Académie (table
-- `academie_purchases`), comme nouvelle source de revenus distincte de
-- l'achat de la fiche produit (`formation_purchases`). En pratique les
-- deux écrans admin de validation ("Demandes Matières" / "Demandes
-- Académie") jouaient le même rôle et créaient de la confusion, sans
-- qu'aucune demande Académie n'ait encore été faite. Décision : un seul
-- achat (`formation_purchases`, inchangé) donne désormais accès à la
-- fois à la fiche produit ET à la fiche technique Académie.
--
-- Ce script NE SUPPRIME PAS les tables `academie_purchases` /
-- `academie_pricing_tiers` (aucune perte de données), il change juste
-- les policies de lecture de `matieres_premieres_academie` /
-- `matieres_premieres_usages` pour utiliser `has_purchased_raw_material`
-- (Phase 45) au lieu de `has_purchased_academie_access` (Phase 81).
-- ============================================================

drop policy if exists "matieres_premieres_academie_select_staff_or_purchaser" on public.matieres_premieres_academie;
create policy "matieres_premieres_academie_select_staff_or_purchaser" on public.matieres_premieres_academie
  for select using (
    public.current_role_is_staff()
    or public.has_purchased_raw_material(auth.uid(), matiere_premiere_id)
  );

drop policy if exists "matieres_premieres_usages_select_staff_or_purchaser" on public.matieres_premieres_usages;
create policy "matieres_premieres_usages_select_staff_or_purchaser" on public.matieres_premieres_usages
  for select using (
    public.current_role_is_staff()
    or exists (
      select 1 from public.matieres_premieres_academie a
      where a.id = academie_id
        and public.has_purchased_raw_material(auth.uid(), a.matiere_premiere_id)
    )
  );
