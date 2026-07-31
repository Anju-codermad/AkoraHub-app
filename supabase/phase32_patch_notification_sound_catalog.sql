-- ============================================================
-- AkoraHub - Patch Phase 32 : Catalogue de sons de notification géré par l'Admin
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Jusqu'ici, les 20 sons de notification (phase24, "3neuvicies") étaient
-- une liste figée dans le code, identique pour tout le monde et pour
-- toutes les catégories. L'Admin veut pouvoir réordonner et masquer ceux
-- qu'il n'aime pas, PAR catégorie (Messagerie/Devis/Commandes), pour tous
-- les utilisateurs — même modèle que payment_method_settings (phase28) :
-- lecture publique, écriture réservée à l'Admin.
--
-- Note : ceci ne permet PAS d'ajouter un nouveau fichier son arbitraire
-- (limite Android/iOS — le son d'un canal de notification doit être une
-- ressource intégrée à l'app au moment de la compilation), seulement de
-- réordonner/masquer parmi les 20 déjà intégrés.
-- ============================================================

create table if not exists public.notification_sound_catalog (
  category text not null check (category in ('message','devis','commande')),
  sound_id text not null,
  sort_order int not null default 0,
  enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (category, sound_id)
);

alter table public.notification_sound_catalog enable row level security;

drop policy if exists "notification_sound_catalog_select_all" on public.notification_sound_catalog;
create policy "notification_sound_catalog_select_all" on public.notification_sound_catalog
  for select using (true);

drop policy if exists "notification_sound_catalog_write_admin_only" on public.notification_sound_catalog;
create policy "notification_sound_catalog_write_admin_only" on public.notification_sound_catalog
  for all using (public.current_role_is_admin())
  with check (public.current_role_is_admin());

-- Seed : les 20 sons existants, disponibles pour les 3 catégories, dans
-- l'ordre actuel du réservoir commun (lib/core/notifications/notification_sounds.dart).
insert into public.notification_sound_catalog (category, sound_id, sort_order, enabled)
select cat, snd.id, snd.ord, true
from (values ('message'), ('devis'), ('commande')) as c(cat)
cross join (
  values
    ('notif_message_classique', 0),
    ('notif_message_bulle', 1),
    ('notif_message_brillant', 2),
    ('notif_message_doux', 3),
    ('notif_message_fun', 4),
    ('notif_devis_classique', 5),
    ('notif_devis_chaleureux', 6),
    ('notif_devis_serieux', 7),
    ('notif_devis_discret', 8),
    ('notif_devis_fun', 9),
    ('notif_commande_classique', 10),
    ('notif_commande_rapide', 11),
    ('notif_commande_festif', 12),
    ('notif_commande_doux', 13),
    ('notif_commande_fun', 14),
    ('notif_bulle_eau', 15),
    ('notif_bulle_savon', 16),
    ('notif_bulle_liquide', 17),
    ('notif_bulles_profondes', 18),
    ('notif_radar', 19)
) as snd(id, ord)
on conflict (category, sound_id) do nothing;
