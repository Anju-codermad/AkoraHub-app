-- ============================================================
-- AkoraHub - Patch Phase 305 : prix de "Liquide Vaisselle" de
-- nouveau perdu (price = null)
--
-- Diagnostic (29/10) : capture d'écran côté client montrant "Liquide
-- Vaisselle" avec le badge "Disponible" mais un clic affichant "Cette
-- formation n'est pas encore programmée" -> price = null à nouveau,
-- même symptôme que phase300.
--
-- Cause probable cette fois : le dialogue "Modifier la formation"
-- (ajout de la photo de couverture) a été ouvert sur une liste de
-- cours pas rafraîchie depuis avant le correctif phase300 -> le champ
-- Prix s'est initialisé vide -> l'enregistrement a renvoyé price =
-- null pour toute la ligne. Un garde-fou a été ajouté côté app
-- (confirmation avant de supprimer un prix déjà existant) pour éviter
-- que ça se reproduise.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_courses
set price = 650000,
    status = 'deja_developpee'
where title ilike '%liquide vaisselle%';

-- Vérification : doit renvoyer exactement 1 ligne, avec price = 650000
-- et status = deja_developpee.
select id, category, title, price, status, cover_image_url
from public.formation_courses
where title ilike '%liquide vaisselle%';
