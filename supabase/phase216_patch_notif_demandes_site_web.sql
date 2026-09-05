-- ============================================================
-- AkoraHub - Patch Phase 216 : notification push au staff dès qu'une
-- demande arrive depuis le site web (`website_leads` phase186 et
-- `website_service_requests` phase214/215).
--
-- Contexte (05/09) : la propriétaire a testé le formulaire "Demander un
-- diagnostic de votre eau" en production et n'a rien vu apparaître côté
-- admin (ni notification, ni écran). Deux lacunes distinctes :
--   1. Aucun trigger n'appelait l'Edge Function send-push-notification
--      pour ces deux tables (contrairement à `service_requests`,
--      `orders_manual_payment_submitted`, etc.) — rien ne signalait au
--      staff qu'une demande venait d'arriver, il fallait ouvrir l'écran
--      manuellement pour le savoir.
--   2. L'écran app "Demandes du site web" n'affichait que `website_leads`
--      — `website_service_requests` (créée après lui, Phase 214) n'a
--      jamais été branchée à un écran. Voir le patch Flutter associé
--      (website_leads_management.dart) qui ajoute un 2e onglet.
--
-- Réutilise la fonction générique déjà en place (Phase 17/78/176)
-- `notify_push_on_new_message()`, qui envoie simplement TG_TABLE_NAME et
-- la ligne insérée — pas besoin d'une nouvelle fonction SQL, seulement
-- de deux nouveaux triggers, et de deux nouveaux cas côté Edge Function
-- (voir supabase/functions/send-push-notification/index.ts).
-- ============================================================

drop trigger if exists on_new_website_lead_push on public.website_leads;
create trigger on_new_website_lead_push
  after insert on public.website_leads
  for each row execute procedure public.notify_push_on_new_message();

drop trigger if exists on_new_website_service_request_push on public.website_service_requests;
create trigger on_new_website_service_request_push
  after insert on public.website_service_requests
  for each row execute procedure public.notify_push_on_new_message();
