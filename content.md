# Rapport — Séparation du site web dans son propre dépôt

*Dernière mise à jour : 03/09/2026*

**Ce fichier documentait avant la migration de domaine du site web ; il
est obsolète depuis que le site a été extrait dans son propre dépôt.**

Le site web (catalogue, formation, à-propos, etc.) ne vit plus dans ce
dépôt. Il a été déplacé vers **`Anju-codermad/groupe-akora-site`**
(dossier `site/`), déployé sur `https://groupe-akora.com`. L'historique
complet de la migration de domaine et de marque ("Groupe Akora" vs
"Akora Fanadiovana") se trouve dans le `content.md` de **ce nouveau
dépôt**, pas ici.

Ce dépôt-ci (`AkoraHub-app`) ne contient plus que :
- L'application Flutter (`lib/`) — mobile + build web admin.
- Les fonctions Supabase (`supabase/`).
- Les workflows GitHub Actions de build/déploiement de l'app.

## Rappel important : données partagées, code séparé

Le site (autre dépôt) et l'application (ce dépôt) ne partagent aucun
code, mais utilisent la **même base Supabase**. Concrètement :
- Un produit ajouté via l'admin de l'app apparaît **automatiquement**
  sur le site (les deux lisent Supabase en direct, rien n'est codé en
  dur).
- Les demandes d'accès Formation (Académie) et les demandes de devis
  du site (`website_leads`) arrivent aussi en direct dans les écrans
  admin de l'app.
- La **vraie commande** (panier, paiement, suivi de livraison)
  n'existe que dans l'application mobile — le site propose seulement un
  formulaire "Demander un devis", pas un panier.

Voir `SITE_APP_SYNC.md` pour la liste précise des règles d'AFFICHAGE
dupliquées entre les deux dépôts (celles-là ne se synchronisent pas
automatiquement, contrairement aux données).
