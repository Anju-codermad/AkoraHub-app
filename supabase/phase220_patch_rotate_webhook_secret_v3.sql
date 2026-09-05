-- ============================================================
-- AkoraHub - Patch Phase 220 : rotation du WEBHOOK_SECRET (3e fois)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (05/09) : même situation qu'en Phase 78 et Phase 176 —
-- l'ancien WEBHOOK_SECRET n'est plus disponible côté utilisatrice (les
-- secrets Supabase ne sont jamais réaffichables une fois créés). On le
-- remplace partout où il est utilisé : les 11 fonctions de la Phase 176,
-- PLUS `notify_push_on_post_pending_approval` (Phase 177, créée après
-- cette rotation précédente, donc pas encore couverte).
--
-- Nouvelle valeur : remplace TOUS les `<WEBHOOK_SECRET>` ci-dessous par
-- la même nouvelle valeur secrète avant d'exécuter ce script.
--
-- ⚠️ AVANT d'exécuter ce script : mets d'abord à jour le secret côté
-- Edge Function (Dashboard -> Edge Functions -> Secrets -> WEBHOOK_SECRET
-- -> colle cette même valeur, en remplacement de l'ancienne). Si l'ordre
-- est inversé, les notifications échoueront silencieusement (401)
-- pendant quelques minutes entre les deux étapes — rien de cassé de
-- façon permanente.
--
-- Idempotent (`create or replace function`) : aucune donnée touchée,
-- seulement la définition des fonctions. Les triggers eux-mêmes ne
-- changent pas.
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

create or replace function public.notify_push_on_variant_back_in_stock()
returns trigger as $$
declare
  v_product record;
begin
  if coalesce(old.stock_quantity, 0) <= 0 and coalesce(new.stock_quantity, 0) > 0 then
    select id, name into v_product
    from public.products
    where id = new.product_id;

    if v_product.id is not null then
      perform net.http_post(
        url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-webhook-secret', '<WEBHOOK_SECRET>'
        ),
        body := jsonb_build_object(
          'table', 'product_back_in_stock',
          'record', jsonb_build_object('id', v_product.id, 'name', v_product.name)
        )
      );
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Nouvelle depuis Phase 176 (Phase 177, publications en attente
-- d'approbation) — pas encore couverte par la rotation précédente.
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
