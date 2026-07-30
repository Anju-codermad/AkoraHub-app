-- ============================================================
-- AkoraHub - Correctif : colonnes manquantes sur public.messages
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Cause du bug (30/07) : deux implémentations de la messagerie ont été
-- construites en parallèle (voir PROJECT_CONTEXT.md, section 3bis).
-- `phase6_schema.sql` (session Backend/Infra, depuis supprimé du dépôt)
-- créait déjà `public.messages` SANS sender_role/is_request/read_by_*.
-- `phase8_patch_messaging.sql` (session Client UX, gardée comme
-- référence) utilise `create table if not exists public.messages (...)`
-- avec ces colonnes en plus — mais comme la table existait déjà (créée
-- par phase6 sur ce projet Supabase), `if not exists` n'a RIEN fait :
-- les colonnes manquantes n'ont jamais été ajoutées. Résultat : tout
-- envoi de message depuis l'app échoue avec
-- "column sender_role of relation messages does not exist", le trigger
-- de la Phase 17 (notification push) n'a même pas l'occasion de
-- s'exécuter puisque l'INSERT lui-même échoue avant.
-- ============================================================

alter table public.messages
  add column if not exists sender_role text,
  add column if not exists is_request boolean not null default false,
  add column if not exists read_by_staff boolean not null default false,
  add column if not exists read_by_client boolean not null default true;

-- Comble les messages déjà existants (créés du temps du schéma phase6,
-- avant cette correction) : on les traite comme des messages client par
-- défaut, faute de mieux — l'ancien schéma ne distinguait pas
-- client/staff.
update public.messages set sender_role = 'client' where sender_role is null;

alter table public.messages
  alter column sender_role set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'messages_sender_role_check'
  ) then
    alter table public.messages
      add constraint messages_sender_role_check
      check (sender_role in ('client', 'staff'));
  end if;
end $$;

-- Vérification : les 4 colonnes doivent maintenant apparaître.
select column_name from information_schema.columns
where table_name = 'messages'
  and column_name in ('sender_role', 'is_request', 'read_by_staff', 'read_by_client');
