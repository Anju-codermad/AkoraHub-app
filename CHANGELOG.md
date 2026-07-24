# Journal des changements — AkoraHub

> Ce fichier se met à jour automatiquement à chaque modification poussée sur
> `main` (voir `.github/workflows/changelog.yml`). Il ne remplace pas
> `PROJECT_CONTEXT.md` (qui reste le résumé "intelligent" à mettre à jour
> manuellement), mais donne un historique brut et fiable de chaque commit.


## 2026-07-23 09:11 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/akora-fanadiovana-app (`d0fba0c`)

## 2026-07-23 09:32 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/akora-fanadiovana-app (`c8ea97b`)

## 2026-07-23 09:45 UTC — Anju-codermad
- Fix critical bug: remove legacy mock product screens entirely (bottom nav Products tab still led to fake catalog) (`1fc300f`)

## 2026-07-23 09:59 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/akora-fanadiovana-app (`3059988`)

## 2026-07-23 10:12 UTC — Claude
- Merge remote changes (Backend/Infra session) into client UX work (`3b330aa`)

## 2026-07-23 10:27 UTC — Claude
- Docs: mettre à jour PROJECT_CONTEXT.md (nav 3 onglets, panier en en-tête, mur retiré, piliers évoqués) (`842a815`)

## 2026-07-23 10:44 UTC — Claude
- Client: localisation automatique (Niveau 1) dans le profil (`9210c92`)

## 2026-07-23 10:59 UTC — Claude
- Docs: documenter la localisation automatique (Niveau 1 fait / Niveau 2 spec pour Backend-Infra) et lister les suggestions d'amélioration côté client (`c921e90`)

## 2026-07-23 11:19 UTC — Claude
- Client: frais de livraison automatiques (modèle taxi rapide) (`43a9238`)

## 2026-07-23 11:20 UTC — Claude
- Merge branch 'main' of https://github.com/Anju-codermad/akora-fanadiovana-app (`74cb8c5`)

## 2026-07-23 12:46 UTC — Claude
- Backend/Infra: script SQL géolocalisation précise (profiles.latitude/longitude) (`d98d97f`)

## 2026-07-23 12:52 UTC — Claude
- Backend/Infra: brancher latitude/longitude GPS dans profile_tab.dart (Localisation Niveau 2) (`e03ec56`)

## 2026-07-23 12:58 UTC — Claude
- Backend/Infra: script SQL géolocalisation orders (latitude/longitude) (`e535417`)

## 2026-07-23 19:34 UTC — Anju-codermad
- Backend/Infra: set real depot GPS coordinates (Rue Seimad, Antananarivo) (`359f239`)

## 2026-07-23 19:48 UTC — Claude
- merge: intégrer coordonnées dépôt + confirmation SQL orders (`97b0062`)

## 2026-07-23 20:30 UTC — Claude
- Backend/Infra: table categories (sous-catégories produit scopées par pilier) + Dropdown Admin (`43d81c9`)

## 2026-07-23 20:56 UTC — Claude
- docs: retirer mention obsolète sous-catégories (livrées en phase 6) (`c11a05e`)

## 2026-07-23 21:04 UTC — Claude
- Merge: résolution conflit coordonnées dépôt (garde la version Rue Seimad, quasi-identique) (`9b1ba36`)

## 2026-07-24 02:30 UTC — Claude
- Client: écran 'Mes devis' ajouté (sous-onglet dans Commandes) (`780fede`)

## 2026-07-24 02:45 UTC — Claude
- Docs: documenter l'écran Mes devis (sous-onglet Commandes/Devis) (`fca8ae9`)

## 2026-07-24 02:54 UTC — Claude
- Client: fonctionnalité Favoris (étoile contour vide/pleine) (`d00f3c8`)

## 2026-07-24 03:07 UTC — Claude
- Docs: documenter la fonctionnalité Favoris (`39f7673`)

## 2026-07-24 03:33 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/akora-fanadiovana-app (`b26588c`)

## 2026-07-24 03:56 UTC — Claude
- chore: supprimer les 3 écrans mock morts (customer/order/analytics non-real), plus jamais routés depuis l'UI (`508325b`)

## 2026-07-24 04:02 UTC — Claude
- chore: débrancher Campaign Management (factice) des menus + simplifier le splash screen (retirer 4 fausses étapes d'init) (`b3828a4`)

## 2026-07-24 04:32 UTC — Claude
- feat(Backend/Infra): photos produit (jusqu'à 10) - table product_images + bucket storage + upload Admin + affichage carrousel client (`4d8e589`)

## 2026-07-24 05:35 UTC — Claude (Client UX/Design)
- Merge Backend/Infra (favoris, photos produit, messagerie, etc.) avec les changements Client UX/Design (en-tête AkoraHub, SafeArea, bannière hero Admin) (`0472465`)

## 2026-07-24 05:46 UTC — Claude (Client UX/Design)
- docs: mettre à jour PROJECT_CONTEXT.md (en-tête AkoraHub + SafeArea, bannière hero Admin, décision sur les menus sociaux) (`3862840`)

## 2026-07-24 05:51 UTC — Claude (Client UX/Design)
- Intègre le Mur social dans le Profil (Client UX/Design) (`07b843e`)

## 2026-07-24 05:52 UTC — Claude (Client UX/Design)
- Merge: changelog auto-généré + mise à jour PROJECT_CONTEXT.md (`c2003e4`)

## 2026-07-24 07:35 UTC — Claude
- Merge: résolution conflit en-tête (wordmark AkoraHub + icône messagerie) (`7b9aaa1`)

## 2026-07-24 07:50 UTC — Claude
- Docs: documenter la messagerie privée + action requise Backend/Infra pour brancher messaging_center.dart (`912ab79`)

## 2026-07-24 08:17 UTC — Claude
- Docs: rapport discussion Connexion/Inscription (SMS OTP, vérif anti-fraude) + signalement conflit messagerie dupliquée (`4496849`)

## 2026-07-24 08:43 UTC — Anju-codermad
- Fix: resolve duplicate messaging implementation (adopt shared conversations/messages schema with sender_role, keep single ChatScreen + admin wired to it) (`cf38b48`)

## 2026-07-24 10:06 UTC — Claude
- Backend/Infra: config de signature release (keystore réel via secrets CI) + build .aab pour Play Store (`7487613`)

## 2026-07-24 10:43 UTC — Claude
- fix: corriger le chemin storeFile dans key.properties (résolu relatif à android/app/, pas android/) (`40d162d`)

## 2026-07-24 11:02 UTC — Claude
- docs: politique de confidentialité (hébergée via GitHub Pages) pour la fiche Play Store (`2622f04`)

## 2026-07-24 11:53 UTC — Claude (Client UX/Design)
- docs: documenter les 5 fonctionnalites sociales, le renommage du depot et l elargissement de perimetre (`7100fa9`)

## 2026-07-24 18:42 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/akora-fanadiovana-app (`c63b049`)
