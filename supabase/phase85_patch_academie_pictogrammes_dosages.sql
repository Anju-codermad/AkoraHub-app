-- ============================================================
-- AkoraHub - Patch Phase 85 : pictogrammes de danger (SGH/CLP), phrases
-- H/P, dosages structurés et champs de stockage détaillés pour la fiche
-- Académie
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ IMPORTANT : ce script renomme `matieres_premieres_usages.dosage_
-- concentration` en `dosage_legacy` (point 5). Le code Flutter actuel
-- (raw_material_editor_screen.dart, raw_material_detail_client.dart)
-- lit/écrit encore `dosage_concentration` — NE PAS EXÉCUTER avant que
-- le code Flutter soit mis à jour pour utiliser les nouvelles colonnes
-- structurées (dosage_type/dosage_min/dosage_max/unite_dosage/
-- dosage_texte), sous peine de casser l'affichage et la saisie des
-- usages détaillés.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Référentiel des pictogrammes de danger SGH/CLP — table catalogue
-- générique (comme academie_pricing_tiers), pas liée à une matière en
-- particulier : lecture publique (les pictogrammes eux-mêmes ne sont
-- pas une donnée confidentielle), écriture staff uniquement.
-- ------------------------------------------------------------
create table if not exists public.danger_pictograms (
  id uuid primary key default gen_random_uuid(),
  code text unique not null, -- ex: 'GHS05'
  nom text,
  image_url text
);

alter table public.danger_pictograms enable row level security;

drop policy if exists "danger_pictograms_select_all" on public.danger_pictograms;
create policy "danger_pictograms_select_all" on public.danger_pictograms
  for select using (true);

drop policy if exists "danger_pictograms_write_staff_only" on public.danger_pictograms;
create policy "danger_pictograms_write_staff_only" on public.danger_pictograms
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 2) Association pictogrammes <-> fiche Académie — table de liaison
-- spécifique à une matière première : lecture soumise au même achat
-- que le reste de la fiche Académie (jointure vers matieres_premieres_
-- academie pour retrouver matiere_premiere_id), écriture staff.
-- ------------------------------------------------------------
create table if not exists public.academie_pictograms (
  id uuid primary key default gen_random_uuid(),
  academie_id uuid not null references public.matieres_premieres_academie(id) on delete cascade,
  pictogram_id uuid not null references public.danger_pictograms(id) on delete cascade,
  unique (academie_id, pictogram_id)
);

create index if not exists academie_pictograms_academie_idx
  on public.academie_pictograms (academie_id);

alter table public.academie_pictograms enable row level security;

drop policy if exists "academie_pictograms_select_staff_or_purchaser" on public.academie_pictograms;
create policy "academie_pictograms_select_staff_or_purchaser" on public.academie_pictograms
  for select using (
    public.current_role_is_staff()
    or exists (
      select 1 from public.matieres_premieres_academie a
      where a.id = academie_id
        and public.has_purchased_raw_material(auth.uid(), a.matiere_premiere_id)
    )
  );

drop policy if exists "academie_pictograms_write_staff_only" on public.academie_pictograms;
create policy "academie_pictograms_write_staff_only" on public.academie_pictograms
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 3) Référentiel des phrases H (danger) et P (précaution) — tables
-- catalogue génériques, même principe que danger_pictograms.
-- ------------------------------------------------------------
create table if not exists public.phrases_h (
  id uuid primary key default gen_random_uuid(),
  code text unique not null, -- ex: 'H314'
  texte text
);

create table if not exists public.phrases_p (
  id uuid primary key default gen_random_uuid(),
  code text unique not null, -- ex: 'P280'
  texte text
);

alter table public.phrases_h enable row level security;
alter table public.phrases_p enable row level security;

drop policy if exists "phrases_h_select_all" on public.phrases_h;
create policy "phrases_h_select_all" on public.phrases_h
  for select using (true);
drop policy if exists "phrases_h_write_staff_only" on public.phrases_h;
create policy "phrases_h_write_staff_only" on public.phrases_h
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

drop policy if exists "phrases_p_select_all" on public.phrases_p;
create policy "phrases_p_select_all" on public.phrases_p
  for select using (true);
drop policy if exists "phrases_p_write_staff_only" on public.phrases_p;
create policy "phrases_p_write_staff_only" on public.phrases_p
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- Association phrases H/P <-> fiche Académie — même principe de lecture
-- gated par achat que academie_pictograms.
create table if not exists public.academie_phrases_h (
  id uuid primary key default gen_random_uuid(),
  academie_id uuid not null references public.matieres_premieres_academie(id) on delete cascade,
  phrase_h_id uuid not null references public.phrases_h(id) on delete cascade,
  unique (academie_id, phrase_h_id)
);

create table if not exists public.academie_phrases_p (
  id uuid primary key default gen_random_uuid(),
  academie_id uuid not null references public.matieres_premieres_academie(id) on delete cascade,
  phrase_p_id uuid not null references public.phrases_p(id) on delete cascade,
  unique (academie_id, phrase_p_id)
);

create index if not exists academie_phrases_h_academie_idx on public.academie_phrases_h (academie_id);
create index if not exists academie_phrases_p_academie_idx on public.academie_phrases_p (academie_id);

alter table public.academie_phrases_h enable row level security;
alter table public.academie_phrases_p enable row level security;

drop policy if exists "academie_phrases_h_select_staff_or_purchaser" on public.academie_phrases_h;
create policy "academie_phrases_h_select_staff_or_purchaser" on public.academie_phrases_h
  for select using (
    public.current_role_is_staff()
    or exists (
      select 1 from public.matieres_premieres_academie a
      where a.id = academie_id
        and public.has_purchased_raw_material(auth.uid(), a.matiere_premiere_id)
    )
  );
drop policy if exists "academie_phrases_h_write_staff_only" on public.academie_phrases_h;
create policy "academie_phrases_h_write_staff_only" on public.academie_phrases_h
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

drop policy if exists "academie_phrases_p_select_staff_or_purchaser" on public.academie_phrases_p;
create policy "academie_phrases_p_select_staff_or_purchaser" on public.academie_phrases_p
  for select using (
    public.current_role_is_staff()
    or exists (
      select 1 from public.matieres_premieres_academie a
      where a.id = academie_id
        and public.has_purchased_raw_material(auth.uid(), a.matiere_premiere_id)
    )
  );
drop policy if exists "academie_phrases_p_write_staff_only" on public.academie_phrases_p;
create policy "academie_phrases_p_write_staff_only" on public.academie_phrases_p
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 4) Nouveaux champs physico-chimiques/stockage sur la fiche Académie
-- (tous optionnels, RLS déjà en place sur la table depuis phase81/83).
-- L'ancien champ texte libre `stockage` est conservé (migration
-- manuelle progressive, pas de perte de contenu déjà saisi).
-- ------------------------------------------------------------
alter table public.matieres_premieres_academie
  add column if not exists densite real,
  add column if not exists point_eclair real,
  add column if not exists temperature_stockage_min real,
  add column if not exists temperature_stockage_max real,
  add column if not exists sensible_humidite boolean not null default false,
  add column if not exists sensible_lumiere boolean not null default false,
  add column if not exists duree_conservation_mois integer,
  add column if not exists consignes_stockage text,
  add column if not exists notes_epi text;

-- ------------------------------------------------------------
-- 5) Dosage structuré sur les usages détaillés — remplace le texte
-- libre par un format exploitable (plage/valeur unique/dilution/texte
-- libre au choix). L'ancien contenu est préservé sous `dosage_legacy`
-- pour reprise manuelle progressive, pas de perte de données.
-- ------------------------------------------------------------
alter table public.matieres_premieres_usages
  rename column dosage_concentration to dosage_legacy;

alter table public.matieres_premieres_usages
  add column if not exists dosage_type text
    check (dosage_type in ('plage','valeur_unique','dilution','texte_libre')),
  add column if not exists dosage_min real,
  add column if not exists dosage_max real,
  add column if not exists unite_dosage text,
  add column if not exists dosage_texte text,
  add column if not exists temperature_utilisation text,
  add column if not exists temps_action text,
  add column if not exists source_reference text;
