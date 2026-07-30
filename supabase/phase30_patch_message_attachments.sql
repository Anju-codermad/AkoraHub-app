-- ============================================================
-- AkoraHub - Patch Phase 30 : Pièces jointes dans la messagerie
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Ajoute la possibilité d'envoyer une photo, une vidéo, un message vocal
-- ou un fichier dans la messagerie client <-> équipe (en plus du texte
-- existant). Bucket privé (contrairement à `avatars`) : ce sont des
-- échanges privés entre un client et l'équipe, pas des documents
-- publics — seuls les participants de la conversation (le client
-- concerné, ou le staff) peuvent lire les pièces jointes.
-- ============================================================

alter table public.messages
  alter column content drop not null;

alter table public.messages
  add column if not exists attachment_url text,
  add column if not exists attachment_type text,
  add column if not exists attachment_name text,
  add column if not exists attachment_duration_ms integer;

alter table public.messages
  drop constraint if exists messages_attachment_type_check;
alter table public.messages
  add constraint messages_attachment_type_check
    check (attachment_type is null or attachment_type in ('image', 'video', 'audio', 'file'));

insert into storage.buckets (id, name, public)
values ('chat-attachments', 'chat-attachments', false)
on conflict (id) do nothing;

-- Chemin de stockage : chat-attachments/<conversation_id>/<fichier> —
-- le premier segment du chemin sert à retrouver la conversation et
-- vérifier que l'utilisateur y participe (client propriétaire ou staff).
drop policy if exists "chat_attachments_participant_read" on storage.objects;
create policy "chat_attachments_participant_read" on storage.objects
  for select using (
    bucket_id = 'chat-attachments'
    and exists (
      select 1 from public.conversations c
      where c.id::text = (storage.foldername(name))[1]
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );

drop policy if exists "chat_attachments_participant_write" on storage.objects;
create policy "chat_attachments_participant_write" on storage.objects
  for insert with check (
    bucket_id = 'chat-attachments'
    and exists (
      select 1 from public.conversations c
      where c.id::text = (storage.foldername(name))[1]
        and (c.customer_id = auth.uid() or public.current_role_is_staff())
    )
  );
