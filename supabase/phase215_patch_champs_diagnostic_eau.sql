-- ============================================================
-- AkoraHub - Patch Phase 215 : complète `website_service_requests`
-- (phase214) avec les champs finalisés en session pour le formulaire
-- "Demander un diagnostic de votre eau" — demande explicite de la
-- propriétaire le 05/09/2026, suite à la discussion complète de
-- l'organisation de l'étape 1.
--
-- Champs ajoutés (tous nullable, additifs — ne touche à rien
-- d'existant) :
--   - preferred_day : jour souhaité de prélèvement (lundi-jeudi
--     uniquement, prélèvements non assurés les autres jours)
--   - client_type : particulier / entreprise / organisation, pour
--     déterminer les champs de facturation nécessaires
--   - company_name, nif, stat, contact_person : facturation
--     entreprise/organisation (NIF/STAT indispensables pour qu'une
--     facture soit comptablement valable à Madagascar)
--   - selected_pack : forfait choisi si applicable ('eau_de_boisson',
--     'forage_complet', 'ong_communaute'), NULL si le client a
--     personnalisé ses analyses via `requested_analyses`
--   - estimated_total : montant total estimé en Ar (forfait ou somme
--     des analyses à la carte + flacon stérile si microbiologie)
--   - deposit_amount : acompte dû (50% du total pour une demande en
--     ligne — le direct/papier reste à 100%, hors de ce formulaire)
--   - accepted_terms : case à cocher d'acceptation des conditions
--     (remplace la signature manuscrite, réservée au moment du
--     prélèvement en personne)
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (add column if not exists).
-- ============================================================

alter table public.website_service_requests
  add column if not exists preferred_day text
    check (preferred_day is null or preferred_day in ('lundi','mardi','mercredi','jeudi')),
  add column if not exists client_type text
    check (client_type is null or client_type in ('particulier','entreprise','organisation')),
  add column if not exists company_name text,
  add column if not exists nif text,
  add column if not exists stat text,
  add column if not exists contact_person text,
  add column if not exists selected_pack text
    check (selected_pack is null or selected_pack in ('eau_de_boisson','forage_complet','ong_communaute')),
  add column if not exists estimated_total numeric,
  add column if not exists deposit_amount numeric,
  add column if not exists accepted_terms boolean not null default false;
