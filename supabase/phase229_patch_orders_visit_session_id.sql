-- ============================================================
-- AkoraHub - Patch Phase 229 : relie une commande à sa session de visite
-- web (tunnel visite -> commande)
--
-- Contexte (08/09) : site_visits (phase226) trace chaque visite avec un
-- session_id généré côté navigateur (assets/visits.js, sessionStorage),
-- mais rien ne relie ensuite une commande passée sur le site à la visite
-- qui l'a produite — orders.customer_id identifie le CLIENT, pas la
-- SESSION de navigation. Demande explicite : mesurer un vrai taux de
-- conversion visite -> commande dans la page admin du site.
--
-- panier.html envoie maintenant le même id (getVisitSessionId(),
-- assets/visits.js) dans ce nouveau champ au moment de créer la
-- commande — une simple jointure entre site_visits.session_id et
-- orders.visit_session_id suffit ensuite à savoir quelles commandes
-- viennent d'une visite web identifiée.
--
-- Nullable : une commande créée depuis l'app Flutter (pas de session web)
-- ou par un membre du staff pour un client n'aura jamais cette valeur —
-- c'est normal, elle sort simplement du périmètre "conversion web".
-- Aucune policy RLS à ajouter : orders_insert_own/orders_select_own_or_staff
-- (phase1_schema.sql) couvrent déjà toutes les colonnes de la table.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New
-- query. Idempotent (add column if not exists).
-- ============================================================

alter table public.orders
  add column if not exists visit_session_id text;

create index if not exists orders_visit_session_id_idx
  on public.orders (visit_session_id)
  where visit_session_id is not null;

-- Vérification : la colonne existe.
select column_name, data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'orders' and column_name = 'visit_session_id';
