-- ============================================================
-- AkoraHub - Patch Phase 264 : archivage des devis côté client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande explicite (26/10) : pouvoir masquer un devis (ou tous) de sa
-- liste, comme c'est déjà possible pour les commandes depuis phase69.
-- Même choix retenu et pour la même raison : un ARCHIVAGE réversible,
-- jamais une vraie suppression — un devis reste une pièce commerciale
-- (traçabilité des négociations), elle doit rester intacte en base et
-- visible côté staff même si le client la masque de sa propre liste.
--
-- Deux fonctions security definer (plutôt qu'une policy UPDATE large),
-- même raison que phase69 : le client ne doit pouvoir toucher QUE la
-- colonne `hidden_by_customer` de ses propres devis, jamais le statut,
-- le montant ou tout autre champ.
-- ============================================================

alter table public.quotes
  add column if not exists hidden_by_customer boolean not null default false;

create or replace function public.set_quote_hidden(p_quote_id uuid, p_hidden boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.quotes
  set hidden_by_customer = p_hidden
  where id = p_quote_id and customer_id = auth.uid();
end;
$$;

grant execute on function public.set_quote_hidden(uuid, boolean) to authenticated;

create or replace function public.hide_all_my_quotes()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.quotes
  set hidden_by_customer = true
  where customer_id = auth.uid();
end;
$$;

grant execute on function public.hide_all_my_quotes() to authenticated;
