-- ============================================================
-- Patch Phase 2 : permet aux clients de créer leurs propres lignes
-- de commande/devis (order_items, quote_items). Nécessaire pour que
-- l'espace client (catalogue + commande) fonctionne.
-- À exécuter une seule fois dans Supabase (SQL Editor) si vous avez
-- déjà exécuté phase1_schema.sql avant le 20/07.
-- ============================================================

drop policy if exists "order_items_write_staff" on public.order_items;

create policy "order_items_insert_own" on public.order_items
  for insert with check (
    exists (select 1 from public.orders o where o.id = order_id
            and (o.customer_id = auth.uid() or public.current_role_is_staff()))
  );
create policy "order_items_update_staff" on public.order_items
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
create policy "order_items_delete_staff" on public.order_items
  for delete using (public.current_role_is_staff());

drop policy if exists "quote_items_write_staff" on public.quote_items;

create policy "quote_items_insert_own" on public.quote_items
  for insert with check (
    exists (select 1 from public.quotes q where q.id = quote_id
            and (q.customer_id = auth.uid() or public.current_role_is_staff()))
  );
create policy "quote_items_update_staff" on public.quote_items
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
create policy "quote_items_delete_staff" on public.quote_items
  for delete using (public.current_role_is_staff());
