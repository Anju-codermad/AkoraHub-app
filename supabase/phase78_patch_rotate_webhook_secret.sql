-- ============================================================
-- AkoraHub - Patch Phase 78 : rotation du WEBHOOK_SECRET
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : l'ancien WEBHOOK_SECRET (utilisé par 9 fonctions
-- déclencheuses différentes pour appeler l'Edge Function
-- send-push-notification) n'était plus disponible côté utilisatrice —
-- les secrets Supabase ne sont pas récupérables une fois créés (Manage
-- secrets écrase, n'affiche jamais l'ancienne valeur). On ne peut donc
-- pas le retrouver : on le REMPLACE partout où il est utilisé.
--
-- Nouvelle valeur : <WEBHOOK_SECRET>
--
-- ⚠️ AVANT d'exécuter ce script : mets à jour le secret côté Edge
-- Function (Dashboard -> Edge Functions -> send-push-notification ->
-- Manage secrets -> WEBHOOK_SECRET -> remplace par la valeur ci-dessus).
-- Si l'ordre est inversé (script d'abord, secret Edge Function après),
-- toute notification poussée entre les deux étapes échouera
-- silencieusement (401) — pas grave, juste des notifications manquées
-- pendant quelques minutes, rien de cassé de façon permanente.
--
-- Remplace les 9 fonctions qui embarquent le secret directement dans
-- leur corps (`create or replace function`, idempotent — aucune donnée
-- touchée, seulement la définition des fonctions). Les triggers eux-
-- mêmes ne changent pas.
-- ============================================================

create or replace function public.notify_push_on_new_message()
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

create or replace function public.notify_push_on_status_change()
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

create or replace function public.notify_push_on_new_product()
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

create or replace function public.notify_push_on_payment_status_change()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'orders_payment_status',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

create or replace function public.notify_push_on_manual_payment_submitted()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'orders_manual_payment_submitted',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

create or replace function public.notify_push_on_formation_purchase_submitted()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'formation_purchases',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

create or replace function public.notify_push_on_course_purchase_submitted()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'course_purchases',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

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

-- Corrige au passage le trigger de la phase 77 (M'alerter quand
-- disponible), exécuté avec le littéral non remplacé "<WEBHOOK_SECRET>"
-- au lieu d'une vraie valeur (capture d'écran du 06/08) — sans ce
-- correctif, ce trigger précis aurait continué à échouer (401) même
-- après la rotation ci-dessus.
create or replace function public.notify_push_on_product_back_in_stock()
returns trigger as $$
begin
  if coalesce(old.stock_quantity, 0) <= 0 and coalesce(new.stock_quantity, 0) > 0 then
    perform net.http_post(
      url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-webhook-secret', '<WEBHOOK_SECRET>'
      ),
      body := jsonb_build_object(
        'table', 'product_back_in_stock',
        'record', to_jsonb(new)
      )
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;
