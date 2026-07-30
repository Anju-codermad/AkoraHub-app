-- ============================================================
-- AkoraHub - Patch : 3 nouveaux piliers d'activité
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

insert into public.business_units (name, slug, active)
values
  ('Matières Premières', 'matieres-premieres-chimiques', true),
  ('Anti-Nuisibles', 'anti-nuisibles', true),
  ('Matières Premières Peinture', 'matieres-premieres-peinture', true)
on conflict (slug) do nothing;
