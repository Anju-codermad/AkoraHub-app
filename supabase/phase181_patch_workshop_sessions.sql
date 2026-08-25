-- ============================================================
-- AkoraHub - Patch Phase 181 : ateliers en présentiel avec capacité
-- limitée (sessions programmées, réservation, staff-validation)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (25/08) : l'assistant Akora AI (chatbot Messenger/WhatsApp,
-- dépôt akora-fb-assistant) devait volontairement refuser de parler
-- d'ateliers en présentiel faute de vraies données (aucune notion de
-- date/lieu/capacité n'existait dans le schéma — voir
-- CATALOG_DB_BLOCK côté chatbot). Ce patch crée ce système, sur le
-- même principe que course_purchases (phase50) : paiement manuel,
-- validation staff, une seule ligne par (client, session), re-soumission
-- possible après refus — avec en plus une vraie limite de places,
-- absente de tout le reste du schéma jusqu'ici.
--
-- ⚠️ Script idempotent (create table if not exists, drop policy if
-- exists) : si une première exécution s'est arrêtée en erreur, relancer
-- ce script en entier depuis le début est sans risque.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Sessions d'atelier programmées par le staff.
-- ------------------------------------------------------------
create table if not exists public.workshop_sessions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text,
  date_start timestamptz not null,
  date_end timestamptz,
  location text not null,
  capacity_max int not null check (capacity_max > 0),
  price numeric,
  status text not null default 'planifiee'
    check (status in ('planifiee', 'annulee', 'terminee')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists workshop_sessions_date_start_idx
  on public.workshop_sessions (date_start);

alter table public.workshop_sessions enable row level security;

drop policy if exists "workshop_sessions_select_all" on public.workshop_sessions;
create policy "workshop_sessions_select_all" on public.workshop_sessions
  for select using (true);

drop policy if exists "workshop_sessions_staff_write" on public.workshop_sessions;
create policy "workshop_sessions_staff_write" on public.workshop_sessions
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 2) Réservations — même principe que course_purchases (phase50) :
-- paiement manuel, validation staff, une seule ligne par (client,
-- session), re-soumission possible après refus.
-- ------------------------------------------------------------
create table if not exists public.workshop_bookings (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workshop_sessions(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'en_attente'
    check (status in ('en_attente', 'validee', 'refusee')),
  payment_method text,
  payment_reference text,
  payment_proof_path text,
  created_at timestamptz not null default now(),
  validated_at timestamptz,
  unique (session_id, customer_id)
);

create index if not exists workshop_bookings_session_idx
  on public.workshop_bookings (session_id, status);

alter table public.workshop_bookings enable row level security;

drop policy if exists "workshop_bookings_select_own_or_staff" on public.workshop_bookings;
create policy "workshop_bookings_select_own_or_staff" on public.workshop_bookings
  for select using (customer_id = auth.uid() or public.current_role_is_staff());

drop policy if exists "workshop_bookings_insert_own" on public.workshop_bookings;
create policy "workshop_bookings_insert_own" on public.workshop_bookings
  for insert with check (customer_id = auth.uid() and status = 'en_attente');

-- Le client peut re-soumettre après un refus (upsert), mais ne peut
-- jamais lui-même passer une ligne à 'validee'.
drop policy if exists "workshop_bookings_resubmit_own_refused" on public.workshop_bookings;
create policy "workshop_bookings_resubmit_own_refused" on public.workshop_bookings
  for update using (customer_id = auth.uid() and status = 'refusee')
  with check (customer_id = auth.uid() and status = 'en_attente');

drop policy if exists "workshop_bookings_update_staff" on public.workshop_bookings;
create policy "workshop_bookings_update_staff" on public.workshop_bookings
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 3) Capacité réellement appliquée (nouveau dans ce schéma — rien
-- d'équivalent n'existait ailleurs, orders.delivery_zone n'est qu'une
-- étiquette de zone en texte libre, pas un créneau/une capacité).
--
-- Un trigger BEFORE INSERT, pas juste une contrainte CHECK : il faut
-- COMPTER les réservations actives de la session au moment de l'insert,
-- ce qu'une contrainte déclarative ne peut pas faire. Le SELECT ... FOR
-- UPDATE verrouille la ligne de la session pendant la transaction : deux
-- réservations concurrentes pour la même session s'exécutent en série
-- (la seconde attend que la première commit avant de recompter), donc
-- jamais de survente même avec deux clients qui réservent la dernière
-- place au même instant.
--
-- 'en_attente' ET 'validee' comptent contre la capacité (la place est
-- réservée dès la demande, pas seulement après validation du paiement
-- par le staff) — seul 'refusee' libère la place.
-- ------------------------------------------------------------
create or replace function public.enforce_workshop_capacity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_capacity int;
  v_taken int;
begin
  select capacity_max into v_capacity
  from public.workshop_sessions
  where id = new.session_id
  for update;

  if v_capacity is null then
    raise exception 'Session atelier introuvable';
  end if;

  select count(*) into v_taken
  from public.workshop_bookings
  where session_id = new.session_id
    and status in ('en_attente', 'validee');

  if v_taken >= v_capacity then
    raise exception 'Atelier complet (capacité % atteinte)', v_capacity;
  end if;

  return new;
end;
$$;

drop trigger if exists workshop_bookings_capacity_check on public.workshop_bookings;
create trigger workshop_bookings_capacity_check
  before insert on public.workshop_bookings
  for each row execute function public.enforce_workshop_capacity();
