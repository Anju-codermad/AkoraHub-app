-- ============================================================
-- AkoraHub - Patch Phase 280 : publication de la formation
-- "Liquide vaisselle"
--
-- Demande explicite (28/10) : rendre la formation achetable par les
-- clients. Côté app (akora_formation_screen.dart), une formation
-- n'apparaît comme achetable que si status = 'deja_developpee' ET
-- price n'est pas null — voir phase274 (création du cours, status
-- 'en_projet', price null).
--
-- Prix fixé par la cliente : 650 000 Ar.
-- Publiée avec le contenu actuel (texte de la formule uniquement,
-- vidéo/photos pourront être ajoutées plus tard sans rien casser).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_courses
set status = 'deja_developpee',
    price = 650000
where title = 'Liquide vaisselle';
