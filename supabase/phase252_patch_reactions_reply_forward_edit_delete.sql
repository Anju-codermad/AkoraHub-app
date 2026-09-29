-- ============================================================
-- AkoraHub - Patch Phase 252 : réactions, répondre, transférer,
-- modifier, supprimer, copier (messagerie client <-> staff)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (29/09/2026) : troisième tranche de "Interactions sur les
-- messages" (comparaison messagerie AkoraHub vs WhatsApp/Messenger) :
--   5. Réagir avec un emoji (👍❤️😂...) sur un message précis
--   6. Répondre à un message spécifique (citation)
--   7. Transférer un message à une autre conversation (staff uniquement
--      — un client n'a qu'une seule conversation avec l'équipe)
--   8. Modifier un message déjà envoyé
--   9. Supprimer/annuler l'envoi (pour soi, ou pour tout le monde par
--      l'auteur)
--   10. Copier le texte (pas de colonne nécessaire, `Clipboard` côté
--       app)
-- ============================================================

alter table public.messages
  add column if not exists reply_to_message_id uuid references public.messages(id) on delete set null,
  add column if not exists forwarded boolean not null default false,
  add column if not exists edited_at timestamptz,
  add column if not exists deleted_at timestamptz;

-- Assouplit `protect_message_content` (phase155) : l'AUTEUR d'origine
-- d'un message (même un client, sur son propre message) peut désormais
-- modifier `content`/`edited_at`/`deleted_at` — nécessaire pour
-- "Modifier" et "Supprimer pour tout le monde" (qui vide `content` et
-- les colonnes attachment_*). La protection d'origine reste intacte
-- pour tout le reste : un client ne peut toujours pas toucher au
-- contenu d'un message qui n'est pas le sien (ex: un message du
-- staff/IA dans sa propre conversation), ni changer
-- sender_id/sender_role/is_request/conversation_id/created_at (staff
-- excepté, comme avant).
create or replace function public.protect_message_content()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.current_role_is_staff() then
    if old.sender_id is distinct from auth.uid() then
      new.content := old.content;
      new.edited_at := old.edited_at;
      new.deleted_at := old.deleted_at;
    end if;
    new.sender_id := old.sender_id;
    new.sender_role := old.sender_role;
    new.is_request := old.is_request;
    new.conversation_id := old.conversation_id;
    new.created_at := old.created_at;
  end if;
  return new;
end;
$$;

-- Réactions emoji (29/09) : une seule réaction par utilisateur et par
-- message (comme WhatsApp) — retaper le même emoji la retire, en taper
-- un autre la remplace (upsert sur la contrainte unique).
create table if not exists public.message_reactions (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  unique (message_id, user_id)
);

alter table public.message_reactions enable row level security;

drop policy if exists "message_reactions_select_visible" on public.message_reactions;
create policy "message_reactions_select_visible" on public.message_reactions
  for select using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );

drop policy if exists "message_reactions_insert_own" on public.message_reactions;
create policy "message_reactions_insert_own" on public.message_reactions
  for insert with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );

drop policy if exists "message_reactions_update_own" on public.message_reactions;
create policy "message_reactions_update_own" on public.message_reactions
  for update using (user_id = auth.uid());

drop policy if exists "message_reactions_delete_own" on public.message_reactions;
create policy "message_reactions_delete_own" on public.message_reactions
  for delete using (user_id = auth.uid());

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'message_reactions'
  ) then
    alter publication supabase_realtime add table public.message_reactions;
  end if;
end $$;

-- "Supprimer pour moi" (29/09) : masque un message uniquement pour
-- l'utilisateur qui l'a supprimé, sans toucher au message lui-même —
-- distinct de "Supprimer pour tout le monde" (`messages.deleted_at`,
-- ci-dessus, qui vide vraiment le contenu pour tous).
create table if not exists public.message_hidden_for (
  user_id uuid not null references auth.users(id) on delete cascade,
  message_id uuid not null references public.messages(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, message_id)
);

alter table public.message_hidden_for enable row level security;

drop policy if exists "message_hidden_for_select_own" on public.message_hidden_for;
create policy "message_hidden_for_select_own" on public.message_hidden_for
  for select using (user_id = auth.uid());

drop policy if exists "message_hidden_for_insert_own" on public.message_hidden_for;
create policy "message_hidden_for_insert_own" on public.message_hidden_for
  for insert with check (user_id = auth.uid());

drop policy if exists "message_hidden_for_delete_own" on public.message_hidden_for;
create policy "message_hidden_for_delete_own" on public.message_hidden_for
  for delete using (user_id = auth.uid());
