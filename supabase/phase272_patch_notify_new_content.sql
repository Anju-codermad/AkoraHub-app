-- ============================================================
-- AkoraHub - Patch Phase 272 : notifie tous les clients à la
-- publication de nouveau contenu (services, formations, annonces)
--
-- Demande explicite (27/10) : "Nous devons aussi ajouter de
-- notification pour tous les utilisateurs quand il y a des nouveaux
-- (produits publié, annonce, promo, formation publié, services
-- disponible ou publié, Etc.)". Les produits sont déjà couverts
-- (phase169). Trois nouveaux cas, même diffusion large (tous les
-- clients) que les produits :
--
-- - service_catalog_items.available : false -> true (catalogue de
--   services, phase66 — "disponible ou publié" = activé par l'Admin).
-- - formation_courses.status -> 'deja_developpee' (c'est précisément
--   ce statut qui rend un cours achetable, voir
--   akora_formation_screen.dart ligne ~137).
-- - flash_infos : nouvelle annonce active créée (annonce/promo,
--   flash_infos_management.dart).
--
-- ⚠️ Redéployer d'abord l'Edge Function `send-push-notification` avec
-- le code à jour du dépôt (nouveaux cas "service_catalog_items",
-- "formation_courses", "flash_infos") — Supabase Dashboard -> Edge
-- Functions -> send-push-notification -> coller le nouveau code ->
-- Deploy. Sans ça, ces triggers appelleront la fonction mais elle ne
-- saura pas encore quoi faire de ces nouveaux cas.
--
-- Pas de <WEBHOOK_SECRET> à renseigner ici (contrairement aux scripts
-- précédents) : ces triggers réutilisent la fonction existante
-- `notify_push_on_new_product()` (déjà déployée avec le bon secret
-- pour la notification "nouveau produit", phase36/78/176/220) au lieu
-- d'en recréer une — un seul secret à tenir à jour reste plus simple.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

drop trigger if exists on_service_available_push on public.service_catalog_items;
create trigger on_service_available_push
  after update on public.service_catalog_items
  for each row
  when (NEW.available = true and OLD.available = false)
  execute procedure public.notify_push_on_new_product();

drop trigger if exists on_formation_published_push on public.formation_courses;
create trigger on_formation_published_push
  after update on public.formation_courses
  for each row
  when (NEW.status = 'deja_developpee' and OLD.status is distinct from 'deja_developpee')
  execute procedure public.notify_push_on_new_product();

drop trigger if exists on_flash_info_published_push on public.flash_infos;
create trigger on_flash_info_published_push
  after insert on public.flash_infos
  for each row
  when (NEW.active = true)
  execute procedure public.notify_push_on_new_product();
