-- ============================================================
-- AkoraHub - Patch Phase 299 : photo de couverture par formation
--
-- Demande explicite (29/10) : pouvoir changer la photo de couverture
-- de chaque formation depuis l'Admin (celle affichée en fond de la
-- vignette dans l'Académie côté client, à la place du simple
-- dégradé de couleur).
--
-- Bucket PUBLIC (contrairement à `formation-videos`, privé et réservé
-- aux acheteurs) : la couverture doit être visible par tout le monde
-- en parcourant le catalogue, avant même l'achat — même logique que
-- le bucket `products` des photos produit (voir
-- supabase/phase8_patch_product_images.sql).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.formation_courses
  add column if not exists cover_image_url text;

insert into storage.buckets (id, name, public)
values ('formation-covers', 'formation-covers', true)
on conflict (id) do nothing;

drop policy if exists "formation_covers_bucket_public_read" on storage.objects;
create policy "formation_covers_bucket_public_read" on storage.objects
  for select using (bucket_id = 'formation-covers');

drop policy if exists "formation_covers_bucket_staff_write" on storage.objects;
create policy "formation_covers_bucket_staff_write" on storage.objects
  for insert with check (bucket_id = 'formation-covers' and public.current_role_is_staff());

drop policy if exists "formation_covers_bucket_staff_update" on storage.objects;
create policy "formation_covers_bucket_staff_update" on storage.objects
  for update using (bucket_id = 'formation-covers' and public.current_role_is_staff());

drop policy if exists "formation_covers_bucket_staff_delete" on storage.objects;
create policy "formation_covers_bucket_staff_delete" on storage.objects
  for delete using (bucket_id = 'formation-covers' and public.current_role_is_staff());
