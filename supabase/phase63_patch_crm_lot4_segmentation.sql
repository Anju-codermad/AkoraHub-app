-- ============================================================
-- AkoraHub - Patch Phase 63 : CRM Lot 4/5 — segmentation & marketing
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Vue agrégée par client (nombre de commandes, date de 1ère/dernière
-- commande, valeur totale) — les segments eux-mêmes (nouveau/récurrent/
-- inactif/gros compte) sont calculés côté app à partir de ces chiffres
-- bruts plutôt que figés en SQL, pour pouvoir ajuster les seuils
-- (ex : "inactif" = pas commandé depuis 90 jours) sans redéployer de
-- script SQL — même logique que l'heuristique "devis accepté sans
-- commande" côté app (Phase 61).
--
-- ⚠️ Sécurité : une vue Postgres classique n'applique PAS
-- automatiquement les policies RLS de `orders`/`profiles` à l'appelant
-- (elle peut s'exécuter avec les droits du propriétaire de la vue) —
-- contrairement à `post_engagement_scores` (Phase 54) qui porte sur des
-- données déjà publiques, `orders`/`profiles` sont sensibles. D'où le
-- filtre explicite `current_role_is_staff()` intégré à la vue
-- elle-même : elle renvoie 0 ligne pour un client, quels que soient les
-- GRANTs.
-- ============================================================

create or replace view public.customer_segments as
select
  p.id as customer_id,
  min(o.created_at) filter (where o.status <> 'annulee') as first_order_at,
  max(o.created_at) filter (where o.status <> 'annulee') as last_order_at,
  count(o.id) filter (where o.status <> 'annulee') as order_count,
  coalesce(sum(o.total_amount) filter (where o.status <> 'annulee'), 0) as lifetime_value
from public.profiles p
left join public.orders o on o.customer_id = p.id
where p.role = 'client'
  and public.current_role_is_staff()
group by p.id;

grant select on public.customer_segments to authenticated;
