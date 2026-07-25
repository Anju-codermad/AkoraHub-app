-- ============================================================
-- Akora Fanadiovana - Patch Phase 9 : activer/désactiver les catégories
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : les piliers (business_units) ont déjà un champ `active` avec
-- un interrupteur côté Admin (écran "Piliers d'entreprise") — un pilier
-- désactivé disparaît du catalogue client. On donne la même capacité aux
-- catégories : les préparer à l'avance (ex: "Anti-Nuisibles" avec ses
-- sous-catégories) sans qu'elles soient visibles/sélectionnables tant
-- qu'on n'est pas prêt à "lancer" cette gamme.
-- ============================================================

alter table public.categories
  add column if not exists active boolean not null default true;
