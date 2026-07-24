-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 6
-- Messagerie unifiée client ↔ équipe commerciale (une seule conversation
-- par client, pas de séparation par pilier — décision utilisateur).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ------------------------------------------------------------
-- 1. CONVERSATIONS (une par client)
-- ------------------------------------------------------------
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  unique (customer_id)
);

-- ------------------------------------------------------------
-- 2. MESSAGES
-- ------------------------------------------------------------
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

-- Met à jour automatiquement `last_message_at` sur la conversation à
-- chaque nouveau message, pour trier facilement la liste par récence
-- côté Admin.
create or replace function public.touch_conversation_last_message()
returns trigger as $$
begin
  update public.conversations
  set last_message_at = new.created_at
  where id = new.conversation_id;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_message_inserted on public.messages;
create trigger on_message_inserted
  after insert on public.messages
  for each row execute procedure public.touch_conversation_last_message();

-- ============================================================
-- SÉCURITÉ
-- ============================================================
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- Un client voit/crée uniquement sa propre conversation ; le staff voit tout.
create policy "conversations_select_own_or_staff" on public.conversations
  for select using (customer_id = auth.uid() or public.current_role_is_staff());
create policy "conversations_insert_own_or_staff" on public.conversations
  for insert with check (customer_id = auth.uid() or public.current_role_is_staff());

-- Un client voit/envoie des messages uniquement dans sa propre conversation ;
-- le staff peut lire/répondre dans toutes les conversations.
create policy "messages_select_related" on public.messages
  for select using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );
create policy "messages_insert_related" on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );
create policy "messages_update_read_staff" on public.messages
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
