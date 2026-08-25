-- ============================================================
-- AkoraHub - Patch Phase 181 : durcissement sécurité (audit du 25/08)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Suite à une demande de renforcement général de la sécurité (client,
-- admin, site web), un audit a identifié deux fonctions `security
-- definer` accessibles à tout utilisateur connecté (`grant ... to
-- authenticated`) qui acceptaient un paramètre `uid` arbitraire SANS
-- vérifier qu'il correspond bien à l'utilisateur connecté. Dans les
-- deux cas, l'app mobile n'appelle ces fonctions qu'avec le propre id
-- de l'utilisateur (aucun changement de comportement pour l'app) — mais
-- rien côté serveur n'empêchait un appel direct de l'API (hors app,
-- avec un jeton valide quelconque) de lire les données d'un AUTRE
-- utilisateur en passant son id à la place :
--
-- - client_top_categories(uid) : révélait l'historique d'achats (par
--   catégorie) de n'importe quel client à n'importe quel autre client.
-- - mutual_friends(uid, other_uid) : révélait la liste d'amis communs
--   entre deux comptes arbitraires, y compris sans lien avec le compte
--   appelant.
--
-- Correctif : chaque fonction ignore désormais toute valeur de `uid`
-- différente de auth.uid() (retourne un résultat vide plutôt qu'une
-- erreur, pour ne pas casser un appel legitime dont la session aurait
-- expiré entre-temps). Signature inchangée, aucune modification
-- nécessaire côté app.
-- ============================================================

create or replace function public.client_top_categories(uid uuid)
returns table(category text, times_ordered bigint)
language sql
stable
security definer
set search_path = public
as $$
  select p.category, count(*) as times_ordered
  from public.orders o
  join public.order_items oi on oi.order_id = o.id
  join public.products p on p.id = oi.product_id
  where o.customer_id = uid
    and uid = auth.uid()
    and o.status <> 'annulee'
    and p.category is not null
    and p.category <> ''
  group by p.category
  order by times_ordered desc;
$$;

create or replace function public.mutual_friends(uid uuid, other_uid uuid)
returns table(friend_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  with my_friends as (
    select case when requester_id = uid then addressee_id else requester_id end as friend_id
    from public.friendships
    where status = 'acceptee' and (requester_id = uid or addressee_id = uid)
  ),
  their_friends as (
    select case when requester_id = other_uid then addressee_id else requester_id end as friend_id
    from public.friendships
    where status = 'acceptee' and (requester_id = other_uid or addressee_id = other_uid)
  )
  select mf.friend_id from my_friends mf
  inner join their_friends tf on tf.friend_id = mf.friend_id
  where uid = auth.uid();
$$;
