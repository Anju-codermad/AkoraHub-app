-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 12
-- Fidélité par paliers : points gagnés automatiquement à chaque commande
-- livrée (1 point par 1000 Ar dépensé), paliers Bronze/Argent/Or calculés
-- côté app à partir du total de points (pas besoin de table séparée).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.profiles
  add column if not exists loyalty_points integer not null default 0;

-- Attribue des points automatiquement quand une commande passe au statut
-- "livree" (et seulement à ce moment précis, pas à chaque update, pour
-- éviter de recréditer plusieurs fois si le statut est modifié ensuite
-- pour une autre raison).
create or replace function public.award_loyalty_points()
returns trigger as $$
begin
  if new.status = 'livree' and (old.status is distinct from 'livree') then
    update public.profiles
    set loyalty_points = loyalty_points + floor(new.total_amount / 1000)::integer
    where id = new.customer_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_order_delivered_award_points on public.orders;
create trigger on_order_delivered_award_points
  after update on public.orders
  for each row execute procedure public.award_loyalty_points();
