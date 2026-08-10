-- ============================================================
-- AkoraHub - Patch Phase 155 : protéger le contenu des messages
-- (messagerie client/staff) contre la falsification
--
-- Faille trouvée le 10/08 (revue systématique des policies RLS) :
-- `messages_update_own_or_staff` (phase8_patch_messaging.sql) autorise
-- la mise à jour de N'IMPORTE QUEL message d'une conversation dès lors
-- que le client est le propriétaire de la CONVERSATION (`c.customer_id
-- = auth.uid()`) — pas seulement ses propres messages. Un client
-- pouvait donc modifier le contenu ou l'expéditeur affiché d'un
-- message envoyé par le STAFF dans sa propre conversation (falsifier
-- une promesse/réponse du support, par exemple), ou changer
-- `sender_role`/`sender_id` pour usurper l'identité de l'expéditeur.
--
-- Correctif : un trigger BEFORE UPDATE qui restaure `content`,
-- `sender_id`, `sender_role`, `is_request` et `conversation_id` à
-- leur valeur d'origine pour toute tentative venant d'un compte
-- non-staff — seuls `read_by_client`/`read_by_staff` (marquer comme
-- lu, l'action légitime du client sur cette policy) restent
-- librement modifiables. Même principe déjà appliqué à
-- `posts.is_pinned` (phase52) et `profiles.role` (phase153).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create or replace function public.protect_message_content()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.current_role_is_staff() then
    new.content := old.content;
    new.sender_id := old.sender_id;
    new.sender_role := old.sender_role;
    new.is_request := old.is_request;
    new.conversation_id := old.conversation_id;
    new.created_at := old.created_at;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_message_content_trigger on public.messages;
create trigger protect_message_content_trigger
  before update on public.messages
  for each row execute function public.protect_message_content();
