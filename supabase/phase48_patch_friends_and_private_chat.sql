-- ============================================================
-- AkoraHub - Patch Phase 48 : demandes d'ami + messagerie privée entre
-- clients (Communauté)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01/08) : demande explicite d'un vrai système d'amis + chat
-- privé DANS l'app (pas juste WhatsApp) — réservé aux clients ayant déjà
-- fait au moins un achat (commande ou abonnement Formation validé),
-- filtre anti-spam entre inconnus.
--
-- ⚠️ Limite connue, assumée pour cette première version : contrairement
-- aux publications de la Communauté (signalables, voir Phase 47), il
-- n'existe PAS d'outil de modération Admin pour ces messages privés —
-- cohérent avec le principe même d'une conversation privée, mais à
-- garder en tête si un abus est signalé autrement (support client).
-- ============================================================

-- ------------------------------------------------------------
-- 0) Éligibilité : avoir déjà fait au moins un achat (commande classique
-- OU abonnement Formation validé). Créée en premier — voir le correctif
-- Phase 40 : une expression de policy est résolue à la création, la
-- fonction référencée doit donc déjà exister.
-- ------------------------------------------------------------
create or replace function public.has_made_purchase(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.orders where customer_id = uid)
      or exists (
        select 1 from public.formation_purchases
        where customer_id = uid and status = 'validee'
      );
$$;

-- ------------------------------------------------------------
-- 1) Demandes d'ami. Une seule ligne par paire de clients quel que soit
-- le sens (index unique sur la paire triée) — empêche à la fois un
-- doublon ET une demande "inverse" pendant qu'une autre est déjà en
-- cours.
-- ------------------------------------------------------------
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'en_attente'
    check (status in ('en_attente','acceptee','refusee')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_id <> addressee_id)
);

create unique index if not exists friendships_unique_pair_idx
  on public.friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));

create index if not exists friendships_addressee_idx
  on public.friendships (addressee_id, status);

alter table public.friendships enable row level security;

drop policy if exists "friendships_select_own" on public.friendships;
create policy "friendships_select_own" on public.friendships
  for select using (auth.uid() = requester_id or auth.uid() = addressee_id);

drop policy if exists "friendships_insert_own_if_purchased" on public.friendships;
create policy "friendships_insert_own_if_purchased" on public.friendships
  for insert
  with check (
    auth.uid() = requester_id
    and status = 'en_attente'
    and public.has_made_purchase(auth.uid())
  );

-- L'addressee peut accepter/refuser une demande en attente ; annuler
-- (côté demandeur) ou retirer un ami (côté n'importe lequel des deux) se
-- fait par suppression de la ligne, voir la policy delete ci-dessous.
drop policy if exists "friendships_update_addressee" on public.friendships;
create policy "friendships_update_addressee" on public.friendships
  for update
  using (auth.uid() = addressee_id and status = 'en_attente')
  with check (auth.uid() = addressee_id and status in ('acceptee','refusee'));

drop policy if exists "friendships_delete_own" on public.friendships;
create policy "friendships_delete_own" on public.friendships
  for delete using (auth.uid() = requester_id or auth.uid() = addressee_id);

create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.friendships
    where status = 'acceptee'
      and ((requester_id = a and addressee_id = b)
        or (requester_id = b and addressee_id = a))
  );
$$;

-- ------------------------------------------------------------
-- 2) Messages privés — uniquement entre deux clients devenus amis
-- (vérifié à l'écriture par `are_friends`, pas seulement côté
-- application).
-- ------------------------------------------------------------
create table if not exists public.friend_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check (sender_id <> recipient_id)
);

create index if not exists friend_messages_pair_idx
  on public.friend_messages (least(sender_id, recipient_id), greatest(sender_id, recipient_id), created_at);

alter table public.friend_messages enable row level security;

drop policy if exists "friend_messages_select_own" on public.friend_messages;
create policy "friend_messages_select_own" on public.friend_messages
  for select using (auth.uid() = sender_id or auth.uid() = recipient_id);

drop policy if exists "friend_messages_insert_own_if_friends" on public.friend_messages;
create policy "friend_messages_insert_own_if_friends" on public.friend_messages
  for insert
  with check (
    auth.uid() = sender_id
    and public.are_friends(auth.uid(), recipient_id)
  );

-- Le destinataire marque ses propres messages reçus comme lus.
drop policy if exists "friend_messages_mark_read" on public.friend_messages;
create policy "friend_messages_mark_read" on public.friend_messages
  for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

-- Realtime : la conversation se met à jour sans recharger (même
-- principe que la messagerie client/staff, Phase 8).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'friend_messages'
  ) then
    alter publication supabase_realtime add table public.friend_messages;
  end if;
end $$;

-- ------------------------------------------------------------
-- 3) Notifications push — réutilise la fonction générique déjà en place
-- (Phase 17). `friendships` déclenche sur INSERT (nouvelle demande) ET
-- UPDATE (acceptée/refusée) ; l'Edge Function distingue les deux via le
-- champ `status` reçu.
-- ------------------------------------------------------------
drop trigger if exists on_friendship_change_push on public.friendships;
create trigger on_friendship_change_push
  after insert or update on public.friendships
  for each row execute procedure public.notify_push_on_new_message();

drop trigger if exists on_new_friend_message_push on public.friend_messages;
create trigger on_new_friend_message_push
  after insert on public.friend_messages
  for each row execute procedure public.notify_push_on_new_message();
