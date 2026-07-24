-- ============================================================
-- Akora Fanadiovana - Patch Phase 8 : messagerie privée client ↔ staff
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Une conversation par client (canal unique avec l'équipe commerciale).
-- Une "Demande" (ex "Demandes & annonces") est un message avec
-- is_request = true — jamais visible par les autres clients, uniquement
-- par le staff, contrairement à un post public sur le Mur.
--
-- NOTE pour la session Backend/Infra : l'écran Admin existant
-- lib/presentation/messaging_center/messaging_center.dart tourne
-- actuellement sur des données 100% mock. Ce schéma est prévu pour le
-- brancher dessus (une conversation = un client, messages ordonnés par
-- created_at, sender_role distingue client/staff).
-- ============================================================

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.profiles(id) on delete cascade unique,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id uuid references public.profiles(id),
  sender_role text not null check (sender_role in ('client', 'staff')),
  content text not null,
  is_request boolean not null default false,
  read_by_staff boolean not null default false,
  read_by_client boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- Un client ne voit/gère que sa propre conversation ; le staff voit tout.
drop policy if exists "conversations_select_own_or_staff" on public.conversations;
create policy "conversations_select_own_or_staff" on public.conversations
  for select using (auth.uid() = customer_id or public.current_role_is_staff());

drop policy if exists "conversations_insert_own" on public.conversations;
create policy "conversations_insert_own" on public.conversations
  for insert with check (auth.uid() = customer_id);

drop policy if exists "conversations_update_own_or_staff" on public.conversations;
create policy "conversations_update_own_or_staff" on public.conversations
  for update using (auth.uid() = customer_id or public.current_role_is_staff());

drop policy if exists "messages_select_own_or_staff" on public.messages;
create policy "messages_select_own_or_staff" on public.messages
  for select using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );

drop policy if exists "messages_insert_own_or_staff" on public.messages;
create policy "messages_insert_own_or_staff" on public.messages
  for insert with check (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );

drop policy if exists "messages_update_own_or_staff" on public.messages;
create policy "messages_update_own_or_staff" on public.messages
  for update using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );

-- Realtime : permet au client de voir les réponses du staff sans recharger.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
