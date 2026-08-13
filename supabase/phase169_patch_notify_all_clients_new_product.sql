-- ============================================================
-- AkoraHub - Patch Phase 169 : notifier tous les clients à la
-- publication d'un nouveau produit
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (13/08, demande explicite) : le trigger `on_new_product_push`
-- (Phase 36) ne se déclenchait qu'à la CRÉATION d'un produit déjà visible
-- (`after insert ... when NEW.visibility = true`). Depuis l'ajout du
-- statut Brouillon/Publié (09/08), un nouveau produit démarre toujours en
-- Brouillon puis passe en Publié plus tard via une MODIFICATION — ce
-- trigger ne se déclenchait donc quasiment plus jamais en pratique.
-- Ce script ajoute un second trigger, sur UPDATE, qui se déclenche
-- précisément au passage Brouillon -> Publié (et laisse le trigger INSERT
-- existant intact pour le cas où un produit serait créé déjà publié).
--
-- Le ciblage des destinataires (tous les clients, plutôt que seulement
-- les abonnés à une catégorie précise) se fait côté Edge Function — voir
-- le fichier envoyé séparément pour le redéploiement de
-- send-push-notification.
-- ============================================================

drop trigger if exists on_product_published_push on public.products;
create trigger on_product_published_push
  after update on public.products
  for each row
  when (NEW.visibility = true and OLD.visibility = false)
  execute procedure public.notify_push_on_new_product();
