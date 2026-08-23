-- ============================================================
-- AkoraHub - Patch Phase 176 : assistant Akora AI dans la messagerie
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Objectif : l'assistant Akora AI (akora-fb-assistant, backend Gemini)
-- peut désormais répondre automatiquement dans la messagerie client/staff
-- déjà existante (phase8_patch_messaging.sql). Le client choisit à tout
-- moment de continuer avec l'IA ou de demander une vraie personne :
--   'ia'              -> l'assistant répond automatiquement (défaut)
--   'humain_demande'  -> le client a demandé un humain, en attente de prise
--                        en charge ; l'IA ne répond plus, une alerte
--                        WhatsApp est envoyée au staff.
--   'humain_actif'    -> un membre du staff a répondu, la conversation
--                        reste en mode humain jusqu'à ce que le client (ou
--                        le staff) repasse en 'ia'.
-- ============================================================

alter table public.conversations
  add column if not exists mode text not null default 'ia'
  check (mode in ('ia', 'humain_demande', 'humain_actif'));

-- Élargit la contrainte existante (phase23_patch_messages_missing_columns.sql)
-- pour accepter les messages générés par l'assistant IA.
alter table public.messages drop constraint if exists messages_sender_role_check;
alter table public.messages
  add constraint messages_sender_role_check
  check (sender_role in ('client', 'staff', 'ai'));

-- sender_id référence profiles(id) et reste nullable (schéma phase8) : les
-- messages IA sont insérés sans profil, sender_id = null.

comment on column public.conversations.mode is
  'Qui répond au client dans cette conversation : ia (auto), humain_demande (en attente), humain_actif (staff a repris la main).';

-- Realtime sur conversations : le client doit voir la bannière d'état
-- (IA / en attente d'un humain / staff en ligne) changer sans recharger,
-- même chose que `messages` déjà activé en phase8.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'conversations'
  ) then
    alter publication supabase_realtime add table public.conversations;
  end if;
end $$;
