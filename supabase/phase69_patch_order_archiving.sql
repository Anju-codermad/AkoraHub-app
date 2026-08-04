-- ============================================================
-- AkoraHub - Patch Phase 69 : archivage des commandes côté client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande explicite de l'utilisateur : pouvoir "supprimer" une commande
-- (ou tout l'historique) de sa liste. Choix retenu (recommandé et
-- confirmé par l'utilisateur) : un ARCHIVAGE réversible plutôt qu'une
-- vraie suppression — une commande est une pièce comptable/une preuve
-- en cas de litige, elle doit rester intacte en base et visible côté
-- staff même si le client la masque de sa propre liste.
--
-- Deux fonctions security definer (plutôt qu'une policy UPDATE large)
-- pour que le client ne puisse toucher QUE la colonne
-- `hidden_by_customer` de ses propres commandes, jamais le statut, le
-- montant ou tout autre champ — une policy UPDATE classique avec
-- `using (auth.uid() = customer_id)` ouvrirait la porte à modifier
-- n'importe quelle colonne dans la même requête.
-- ============================================================

alter table public.orders
  add column if not exists hidden_by_customer boolean not null default false;

create or replace function public.set_order_hidden(p_order_id uuid, p_hidden boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.orders
  set hidden_by_customer = p_hidden
  where id = p_order_id and customer_id = auth.uid();
end;
$$;

grant execute on function public.set_order_hidden(uuid, boolean) to authenticated;

create or replace function public.hide_all_my_orders()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.orders
  set hidden_by_customer = true
  where customer_id = auth.uid();
end;
$$;

grant execute on function public.hide_all_my_orders() to authenticated;
