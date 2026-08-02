-- ============================================================
-- AkoraHub - Patch Phase 61 : CRM Lot 2/5 — notes, étiquettes, relances
-- (Partie A — table/colonnes/fonctions ; voir aussi
-- phase61_patch_crm_lot2_b_cron_optional.sql pour la planification)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Notes internes, étiquettes personnalisées, et alerte sur les devis
-- en attente sans réponse depuis trop longtemps. L'historique des
-- messages (déjà en base via `conversations`/`messages`, Phase 8) ne
-- nécessite aucun changement SQL — juste affiché en plus dans la
-- fiche 360° côté app.
--
-- ⚠️ "Devis accepté sans commande liée" (autre item du Lot 2) n'a
-- volontairement PAS de nouvelle colonne ici : il n'existe aujourd'hui
-- aucun lien formel entre `quotes` et `orders` (aucune conversion
-- devis -> commande n'existe dans l'app), donc `orders.quote_id`
-- serait une colonne qui ne serait jamais réellement remplie. La
-- fiche 360° calcule à la place une approximation côté app (devis
-- accepté sans aucune commande du même client créée après lui) —
-- amélioration possible avec un vrai lien si un flux "convertir un
-- devis en commande" est construit plus tard.
--
-- ⚠️ Avant d'exécuter : remplace `<WEBHOOK_SECRET>` par la même valeur
-- secrète que les autres triggers (Edge Functions -> send-push-notification
-- -> Manage secrets -> WEBHOOK_SECRET).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Notes internes — jamais visibles du client, uniquement du staff.
-- ------------------------------------------------------------
create table if not exists public.customer_notes (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  author_id uuid references public.profiles(id),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists customer_notes_customer_idx
  on public.customer_notes (customer_id, created_at desc);

alter table public.customer_notes enable row level security;

drop policy if exists "customer_notes_staff_only" on public.customer_notes;
create policy "customer_notes_staff_only" on public.customer_notes
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 2) Étiquettes personnalisées — même pattern que
-- `profiles.business_unit_ids` (Phase 1) : tableau de texte libre,
-- éditable par le staff via la policy `profiles_update_own_or_staff`
-- déjà existante, aucune nouvelle policy nécessaire.
-- ------------------------------------------------------------
alter table public.profiles
  add column if not exists tags text[] not null default '{}';

-- ------------------------------------------------------------
-- 3) Relance automatique des devis "envoyé" sans réponse depuis trop
-- longtemps. `last_reminder_at` évite de relancer chaque jour en
-- boucle une fois qu'une relance est partie.
-- ------------------------------------------------------------
alter table public.quotes
  add column if not exists last_reminder_at timestamptz;

create or replace function public.process_stale_quote_reminders()
returns void as $$
declare
  q record;
begin
  for q in
    select id, quote_number, customer_id
    from public.quotes
    where status = 'envoye'
      and created_at < now() - interval '5 days'
      and (last_reminder_at is null or last_reminder_at < now() - interval '3 days')
  loop
    perform net.http_post(
      url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-webhook-secret', '<WEBHOOK_SECRET>'
      ),
      body := jsonb_build_object(
        'table', 'quotes_stale_reminder',
        'record', jsonb_build_object(
          'id', q.id,
          'quote_number', q.quote_number,
          'customer_id', q.customer_id
        )
      )
    );
    update public.quotes set last_reminder_at = now() where id = q.id;
  end loop;
end;
$$ language plpgsql security definer;
