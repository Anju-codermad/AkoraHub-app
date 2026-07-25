-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 11
-- Négociation de devis : fil de discussion par devis, permettant au
-- client et au staff de faire des allers-retours (proposition de prix,
-- modification de la demande) au lieu d'une réponse unique et figée.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create table if not exists public.quote_messages (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references public.quotes(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  sender_role text not null check (sender_role in ('client','staff')),
  content text not null default '',
  proposed_amount numeric,
  created_at timestamptz not null default now()
);

alter table public.quote_messages enable row level security;

-- Le client voit/écrit uniquement sur ses propres devis ; le staff voit et
-- répond à tous les devis.
create policy "quote_messages_select_related" on public.quote_messages
  for select using (
    exists (
      select 1 from public.quotes q
      where q.id = quote_id
        and (q.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );
create policy "quote_messages_insert_related" on public.quote_messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.quotes q
      where q.id = quote_id
        and (q.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );
