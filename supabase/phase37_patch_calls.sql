-- ============================================================
-- AkoraHub - Patch Phase 37 : Appels audio/vidéo dans la messagerie (Agora)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande (31/07) : ajouter l'appel vocal et vidéo dans la messagerie
-- (client <-> staff). Utilise Agora RTC (compte créé par l'utilisateur,
-- 10 000 minutes gratuites/mois) — voir supabase/functions/generate-agora-token
-- pour la génération de token côté serveur (le certificat Agora ne doit
-- jamais être présent côté client).
--
-- Cette table sert de signalisation minimale : elle ne transporte AUCUN
-- flux audio/vidéo (ça, c'est Agora qui s'en charge directement entre les
-- deux téléphones) — juste "qui appelle qui, sur quel canal, pour quel
-- type d'appel, et où en est cet appel" pour que l'autre partie soit
-- notifiée et puisse rejoindre le même canal Agora.
--
-- ⚠️ Avant d'exécuter ce script : remplace `<WEBHOOK_SECRET>` ci-dessous
-- par la même valeur secrète que les autres triggers (Edge Functions ->
-- send-push-notification -> Manage secrets -> WEBHOOK_SECRET).
--
-- ⚠️ Limite connue (MVP) : sans intégration CallKit (iOS) / native
-- ConnectionService (Android), l'appel ne "sonne" pas comme un vrai appel
-- téléphonique tant que l'app est fermée/en arrière-plan — seule une
-- notification push classique arrive, et la sonnerie/l'écran d'appel
-- entrant ne s'affichent qu'une fois l'app rouverte (au tap sur la
-- notification). Suffisant pour un usage normal (app ouverte ou en
-- veille récente), mais pas un vrai appel qui réveille le téléphone
-- verrouillé comme un appel GSM.
-- ============================================================

create table if not exists public.call_invitations (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  caller_id uuid not null references public.profiles(id) on delete cascade,
  callee_id uuid not null references public.profiles(id) on delete cascade,
  call_type text not null check (call_type in ('audio','video')),
  channel_name text not null,
  status text not null default 'ringing'
    check (status in ('ringing','accepted','declined','ended','missed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists call_invitations_callee_idx
  on public.call_invitations (callee_id, status);

alter table public.call_invitations enable row level security;

drop policy if exists "call_invitations_select_participant" on public.call_invitations;
create policy "call_invitations_select_participant" on public.call_invitations
  for select using (auth.uid() = caller_id or auth.uid() = callee_id);

drop policy if exists "call_invitations_insert_caller" on public.call_invitations;
create policy "call_invitations_insert_caller" on public.call_invitations
  for insert with check (auth.uid() = caller_id);

drop policy if exists "call_invitations_update_participant" on public.call_invitations;
create policy "call_invitations_update_participant" on public.call_invitations
  for update using (auth.uid() = caller_id or auth.uid() = callee_id);

-- Pas de publication Realtime nécessaire ici : la notification push
-- (via `send-push-notification`, reçue par `FirebaseMessaging.onMessage`
-- même app ouverte) suffit à détecter un appel entrant dans tous les
-- états de l'app (ouverte/arrière-plan/fermée) — voir
-- push_notification_service.dart.

create or replace function public.notify_push_on_call_invitation()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', TG_TABLE_NAME,
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_call_invitation_push on public.call_invitations;
create trigger on_call_invitation_push
  after insert on public.call_invitations
  for each row
  execute procedure public.notify_push_on_call_invitation();
