-- ============================================================
-- Akora Fanadiovana - Patch Phase 8 : photos produit (jusqu'à 10 par produit)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : `products.image_url` existe depuis la Phase 1 mais n'a jamais
-- été branché nulle part dans l'app (ni upload Admin, ni affichage client) —
-- l'utilisateur a remarqué l'absence de photos en testant la saisie de
-- produits. On ajoute une vraie galerie multi-photos (jusqu'à 10, ordre
-- géré par `position`), tout en gardant `products.image_url` comme photo
-- de couverture (= la première de la galerie), pour ne rien casser côté
-- catalogue client qui affiche déjà ce champ en pensant qu'il pourrait un
-- jour être rempli.
-- ============================================================

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_url text not null,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists product_images_product_id_idx
  on public.product_images(product_id, position);

alter table public.product_images enable row level security;

drop policy if exists "product_images_select_all" on public.product_images;
create policy "product_images_select_all" on public.product_images
  for select using (true);

drop policy if exists "product_images_write_staff" on public.product_images;
create policy "product_images_write_staff" on public.product_images
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- Garde-fou serveur : jamais plus de 10 photos par produit, même si un bug
-- côté app laissait passer plus de 10 dans un même envoi.
create or replace function public.enforce_max_product_images()
returns trigger as $$
begin
  if (select count(*) from public.product_images where product_id = new.product_id) >= 10 then
    raise exception 'Un produit ne peut pas avoir plus de 10 photos.';
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_enforce_max_product_images on public.product_images;
create trigger trg_enforce_max_product_images
  before insert on public.product_images
  for each row execute procedure public.enforce_max_product_images();

-- ------------------------------------------------------------
-- Bucket Storage pour les fichiers image (public en lecture, écriture
-- réservée au staff — contrairement au bucket `avatars` où chaque client
-- gère son propre dossier, les photos produit sont ajoutées par l'Admin).
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('products', 'products', true)
on conflict (id) do nothing;

drop policy if exists "products_bucket_public_read" on storage.objects;
create policy "products_bucket_public_read" on storage.objects
  for select using (bucket_id = 'products');

drop policy if exists "products_bucket_staff_write" on storage.objects;
create policy "products_bucket_staff_write" on storage.objects
  for insert with check (bucket_id = 'products' and public.current_role_is_staff());

drop policy if exists "products_bucket_staff_update" on storage.objects;
create policy "products_bucket_staff_update" on storage.objects
  for update using (bucket_id = 'products' and public.current_role_is_staff());

drop policy if exists "products_bucket_staff_delete" on storage.objects;
create policy "products_bucket_staff_delete" on storage.objects
  for delete using (bucket_id = 'products' and public.current_role_is_staff());
