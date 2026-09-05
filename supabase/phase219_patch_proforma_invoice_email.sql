-- ============================================================
-- AkoraHub - Patch Phase 219 : facture proforma automatique par e-mail
-- pour le diagnostic qualité de l'eau (site web)
--
-- Contexte (05/09) : un client a demandé où était sa facture proforma
-- après avoir soumis le formulaire "Demander un diagnostic de votre
-- eau" — elle n'a jamais existé. Jusqu'ici la demande est seulement
-- enregistrée (phase214/215) et le staff notifié par push (phase216),
-- le suivi commercial (devis, facture) restait entièrement manuel.
--
-- Ce patch ajoute :
--   1) Un numéro de proforma stable (`proforma_number`), généré
--      server-side via une vraie séquence Postgres (pas un timestamp
--      côté client comme les numéros FAC-/DEV- de l'app Flutter —
--      ceux-là sont générés lors d'une action manuelle unique par
--      l'Admin, alors qu'ici plusieurs demandes anonymes peuvent
--      arriver en même temps).
--   2) Un trigger AFTER INSERT qui appelle une nouvelle Edge Function
--      (send-proforma-invoice, patchée séparément dans
--      supabase/functions/) dès qu'une demande arrive AVEC un e-mail
--      ET un montant réel (le forfait "ONG/Communauté" reste "sur
--      devis", donc estimated_total est null pour lui — aucune
--      proforma n'est générée, le staff continue de le traiter à la
--      main comme le formulaire le promet déjà).
--
-- ⚠️ Le secret ci-dessous (`x-webhook-secret`) a été mis à jour lors de
-- la rotation Phase 220 (WEBHOOK_SECRET n'était plus disponible côté
-- utilisatrice) — exécute Phase 220 EN MÊME TEMPS que ce script, après
-- avoir mis à jour le secret côté Edge Function (Dashboard -> Edge
-- Functions -> Secrets -> WEBHOOK_SECRET -> nouvelle valeur). Seule
-- l'Edge Function send-proforma-invoice elle-même a besoin d'un nouveau
-- secret propre, RESEND_API_KEY (voir son fichier).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New
-- query. Idempotent (create if not exists / create or replace).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Numéro de proforma — séquence + colonne + trigger BEFORE INSERT.
-- ------------------------------------------------------------
create sequence if not exists public.proforma_number_seq;

alter table public.website_service_requests
  add column if not exists proforma_number text;

create or replace function public.generate_proforma_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.service_slug = 'diagnostic-eau' and new.proforma_number is null then
    new.proforma_number := 'PROF-' || to_char(now(), 'YYYYMM') || '-' ||
      lpad((nextval('public.proforma_number_seq') % 1000000)::text, 6, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists generate_proforma_number_trigger on public.website_service_requests;
create trigger generate_proforma_number_trigger
  before insert on public.website_service_requests
  for each row execute function public.generate_proforma_number();

-- ------------------------------------------------------------
-- 2) Envoi de la facture proforma — même schéma que
-- notify_push_on_new_message()/phase216/phase38 : un trigger AFTER
-- INSERT appelle une Edge Function via net.http_post. Le `when` exclut
-- automatiquement "ONG/Communauté" (sur devis, estimated_total null)
-- et toute demande sans e-mail.
-- ------------------------------------------------------------
create or replace function public.send_proforma_invoice_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-proforma-invoice',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', TG_TABLE_NAME,
      'record', to_jsonb(new)
    )
  );
  return new;
end;
$$;

drop trigger if exists on_new_diagnostic_eau_request_proforma on public.website_service_requests;
create trigger on_new_diagnostic_eau_request_proforma
  after insert on public.website_service_requests
  for each row
  when (new.service_slug = 'diagnostic-eau'
        and new.email is not null
        and new.estimated_total is not null)
  execute procedure public.send_proforma_invoice_email();
