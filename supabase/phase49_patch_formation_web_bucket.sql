-- ============================================================
-- AkoraHub - Patch Phase 49 : espace public pour la page web Formation
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01/08) : conformité Google Play. L'achat d'accès Formation
-- (déblocage de fiches ingrédients) était jusqu'ici entièrement intégré
-- dans l'app Android, payé manuellement en dehors de Google Play — un
-- motif de rejet possible sur la fiche "Sécurité des données"/Paiements
-- de Google (contenu numérique débloqué via un paiement hors Play
-- Billing). Solution retenue (modèle "reader app", déjà utilisé par de
-- nombreuses apps de contenu) : sortir l'écran d'achat de l'application
-- et le déplacer sur une page web ouverte dans le navigateur externe.
-- Le même backend (formation_purchases, validation par le staff) reste
-- inchangé ; seul le point d'entrée du paiement change.
--
-- Ce script crée juste le bucket Storage public qui hébergera cette page
-- web (fichier HTML statique) — le fichier lui-même doit être déposé
-- manuellement dans ce bucket depuis le Dashboard (Storage -> formation-web
-- -> Upload file), comme indiqué dans le tutoriel fourni séparément.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('formation-web', 'formation-web', true)
on conflict (id) do nothing;
