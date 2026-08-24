-- ============================================================
-- AkoraHub - Patch Phase 177 : approbation des publications
-- Communauté par le staff avant mise en ligne
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (24/08, sur demande) : on garde la possibilité pour les
-- clients de publier sur le mur Communauté (pas de suppression de la
-- fonctionnalité), mais chaque nouvelle publication d'un client doit être
-- validée par le staff (Admin/Commercial) avant d'apparaître publiquement
-- — même logique que la modération des signalements (phase47), mais en
-- amont plutôt qu'en réaction. Les publications du staff restent
-- publiées immédiatement (annonces officielles, badge "Officiel" —
-- phase52). Les groupes de Formation (`formation_group_posts`, phase56)
-- ne sont PAS concernés — table séparée, publication toujours immédiate
-- pour les participants payants.
--
-- ⚠️ Avant d'exécuter : remplace `<WEBHOOK_SECRET>` par la même valeur
-- secrète que les autres triggers.
-- ============================================================

alter table public.posts
  add column if not exists approval_status text not null default 'approved'
    check (approval_status in ('pending', 'approved', 'rejected'));

-- ------------------------------------------------------------
-- Statut fixé automatiquement à l'insertion selon le rôle de l'auteur —
-- jamais confié à la valeur envoyée par le client (une policy RLS
-- `with check` ne peut pas empêcher un client d'essayer d'envoyer
-- 'approved' directement).
-- ------------------------------------------------------------
create or replace function public.set_post_approval_status()
returns trigger as $$
begin
  if public.current_role_is_staff() then
    new.approval_status := 'approved';
  else
    new.approval_status := 'pending';
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_post_set_approval_status on public.posts;
create trigger on_post_set_approval_status
  before insert on public.posts
  for each row
  execute procedure public.set_post_approval_status();

-- ------------------------------------------------------------
-- Le mur public ne montre que les publications approuvées ; l'auteur et
-- le staff voient toujours les leurs/toutes, y compris en attente.
-- ------------------------------------------------------------
drop policy if exists "posts_select" on public.posts;
create policy "posts_select" on public.posts
  for select using (
    (visibility = 'public' and approval_status = 'approved')
    or author_id = auth.uid()
    or public.current_role_is_staff()
  );

-- ------------------------------------------------------------
-- Notifie le staff (Admin/Commercial) à chaque nouvelle publication en
-- attente — même destinataires que les signalements (phase47). Réutilise
-- le même Edge Function `send-push-notification` (nouveau cas
-- `posts_pending_approval`, livré dans le même commit) — redéploiement
-- nécessaire après ce script.
-- ------------------------------------------------------------
create or replace function public.notify_push_on_post_pending_approval()
returns trigger as $$
begin
  if new.approval_status = 'pending' then
    perform net.http_post(
      url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-webhook-secret', '<WEBHOOK_SECRET>'
      ),
      body := jsonb_build_object(
        'table', 'posts_pending_approval',
        'record', to_jsonb(new)
      )
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_post_pending_approval on public.posts;
create trigger on_post_pending_approval
  after insert on public.posts
  for each row
  execute procedure public.notify_push_on_post_pending_approval();
