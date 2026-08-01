-- ============================================================
-- AkoraHub - Patch Phase 43 : liste des formations/modules AkoraFormation
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01/08) : première brique du vrai "AkoraFormation" (cours,
-- distinct de la base de matières premières — voir PROJECT_CONTEXT.md,
-- section "Refonte de l'accès Formation"). Pour l'instant, juste la
-- LISTE structurée des formations par catégorie avec leur statut
-- ("Déjà développée"/"En projet"/"À créer") et leur nombre de modules
-- quand connu — pas encore le contenu réel des cours (vidéos, leçons),
-- qui viendra dans une prochaine étape. Sert à visualiser/valider la
-- structure avant de construire le contenu.
--
-- Données seedées d'après le document fourni par l'utilisatrice
-- (Akora_Activites_Piliers.md, section 3 "FORMATIONS").
-- ============================================================

create table if not exists public.formation_courses (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  title text not null,
  status text not null default 'a_creer'
    check (status in ('deja_developpee', 'en_projet', 'a_creer')),
  module_count integer,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (category, title)
);

create index if not exists formation_courses_category_idx
  on public.formation_courses (category, sort_order);

alter table public.formation_courses enable row level security;

-- Lecture publique (tout utilisateur connecté) : c'est une vitrine/liste
-- de ce qui existe ou est prévu, pas du contenu sensible — contrairement
-- aux fiches matières premières, pas besoin d'abonnement pour la voir.
drop policy if exists "formation_courses_select_all" on public.formation_courses;
create policy "formation_courses_select_all" on public.formation_courses
  for select using (true);

drop policy if exists "formation_courses_write_staff" on public.formation_courses;
create policy "formation_courses_write_staff" on public.formation_courses
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

insert into public.formation_courses (category, title, status, module_count, sort_order) values
  ('Entretien & Hygiène', 'Eau de Javel', 'deja_developpee', 8, 0),
  ('Entretien & Hygiène', 'Liquide Vaisselle', 'deja_developpee', 8, 1),
  ('Entretien & Hygiène', 'Lave-Vitre', 'deja_developpee', null, 2),
  ('Entretien & Hygiène', 'Lessive (poudre/liquide)', 'deja_developpee', null, 3),
  ('Entretien & Hygiène', 'Assouplissant textile', 'a_creer', null, 4),
  ('Entretien & Hygiène', 'Nettoyant multi-usage', 'a_creer', null, 5),
  ('Entretien & Hygiène', 'Détergent sol parfumé', 'a_creer', null, 6),
  ('Entretien & Hygiène', 'Désinfectant de surface', 'a_creer', null, 7),

  ('Soins Capillaires & Beauté', 'Soins capillaires', 'deja_developpee', null, 0),
  ('Soins Capillaires & Beauté', 'Fabrication de savons cosmétiques', 'a_creer', null, 1),
  ('Soins Capillaires & Beauté', 'Crèmes & lotions corporelles', 'a_creer', null, 2),
  ('Soins Capillaires & Beauté', 'Savon liquide corps/mains', 'a_creer', null, 3),
  ('Soins Capillaires & Beauté', 'Gel douche & shampooing', 'a_creer', null, 4),
  ('Soins Capillaires & Beauté', 'Parfumerie de base', 'a_creer', null, 5),
  ('Soins Capillaires & Beauté', 'Cosmétique bébé', 'a_creer', null, 6),

  ('Peinture', 'Peinture murale intérieure (MURO)', 'deja_developpee', null, 0),
  ('Peinture', 'Peinture façade (FAÇAD)', 'deja_developpee', null, 1),
  ('Peinture', 'Peinture métal/anti-rouille (FERRO)', 'deja_developpee', null, 2),
  ('Peinture', 'Peinture bois (LUSSO, PRIMO)', 'deja_developpee', null, 3),
  ('Peinture', 'Peinture écologique zéro-VOC (SANO)', 'en_projet', null, 4),
  ('Peinture', 'Vernis & finitions', 'a_creer', null, 5),
  ('Peinture', 'Enduits & sous-couches', 'a_creer', null, 6),

  ('Cire & Bougie', 'Cire meuble/bois', 'a_creer', null, 0),
  ('Cire & Bougie', 'Cire sol/plancher', 'a_creer', null, 1),
  ('Cire & Bougie', 'Cire voiture', 'a_creer', null, 2),
  ('Cire & Bougie', 'Bougies parfumées', 'a_creer', null, 3),
  ('Cire & Bougie', 'Cire à cacheter/artisanale', 'a_creer', null, 4),

  ('Agroalimentaire', 'Sirop & boissons industrielles', 'deja_developpee', 8, 0),
  ('Agroalimentaire', 'Transformation du lait', 'a_creer', null, 1),
  ('Agroalimentaire', 'Transformation des fruits', 'a_creer', null, 2),
  ('Agroalimentaire', 'Transformation des légumes', 'a_creer', null, 3),
  ('Agroalimentaire', 'Panification de base', 'a_creer', null, 4),
  ('Agroalimentaire', 'Conservation alimentaire', 'a_creer', null, 5),
  ('Agroalimentaire', 'Normes d''hygiène agroalimentaire (HACCP)', 'a_creer', null, 6),

  ('Chimie Fondamentale', 'Cours surfactants (4 familles)', 'deja_developpee', null, 0),
  ('Chimie Fondamentale', 'Chimie des émulsions', 'a_creer', null, 1),
  ('Chimie Fondamentale', 'Réglementation CLP/REACH', 'a_creer', null, 2),
  ('Chimie Fondamentale', 'Rédaction de FDS', 'a_creer', null, 3),
  ('Chimie Fondamentale', 'Contrôle qualité de base', 'a_creer', null, 4),

  ('Coaching Entrepreneur', 'Calcul du prix de revient', 'deja_developpee', null, 0),
  ('Coaching Entrepreneur', 'Sourcing matières premières', 'deja_developpee', null, 1),
  ('Coaching Entrepreneur', 'Recherche de marchés', 'deja_developpee', null, 2),
  ('Coaching Entrepreneur', 'Gestion administrative de base', 'a_creer', null, 3),
  ('Coaching Entrepreneur', 'Marketing digital pour artisans', 'a_creer', null, 4),
  ('Coaching Entrepreneur', 'Gestion des stocks', 'a_creer', null, 5)
on conflict (category, title) do nothing;
