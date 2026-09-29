-- ============================================================
-- AkoraHub - Patch Phase 251 : recherche, épingler, messages
-- enregistrés, filtres (messagerie client <-> staff)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (29/09/2026) : suite de "Recherche & organisation" (items 11
-- à 14 de la comparaison messagerie AkoraHub vs WhatsApp/Messenger) :
--   11. Recherche dans l'historique d'une conversation (filtrage local
--       sur `content`, aucune colonne nécessaire)
--   12. Épingler un message important en haut du fil
--   13. Messages favoris/enregistrés, cross-conversations, par
--       utilisateur ("Messages relayés à moi-même" façon WhatsApp)
--   14. Filtrer les conversations (non lues, pièce jointe, demandes)
--       côté staff (agrégations sur `messages`, comme pour les badges
--       non lus — aucune colonne nécessaire)
-- ============================================================

alter table public.messages
  add column if not exists pinned boolean not null default false,
  add column if not exists pinned_at timestamptz;

-- Pas de nouvelle policy nécessaire pour pinned/pinned_at :
-- `messages_update_own_or_staff` (phase8) autorise déjà la mise à jour
-- de n'importe quelle colonne par l'auteur de la conversation ou le
-- staff, et `protect_message_content` (phase155) ne protège que
-- content/sender_id/sender_role/is_request/conversation_id/created_at.

create table if not exists public.starred_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  message_id uuid not null references public.messages(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, message_id)
);

alter table public.starred_messages enable row level security;

drop policy if exists "starred_messages_select_own" on public.starred_messages;
create policy "starred_messages_select_own" on public.starred_messages
  for select using (user_id = auth.uid());

drop policy if exists "starred_messages_insert_own" on public.starred_messages;
create policy "starred_messages_insert_own" on public.starred_messages
  for insert with check (user_id = auth.uid());

drop policy if exists "starred_messages_delete_own" on public.starred_messages;
create policy "starred_messages_delete_own" on public.starred_messages
  for delete using (user_id = auth.uid());

create index if not exists starred_messages_user_id_idx
  on public.starred_messages (user_id, created_at desc);
