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

## 2026-07-24 19:13 UTC — Claude (Client UX/Design)
- Nettoyage traces Rocket.new (23/07) (`2987158`)

## 2026-07-24 19:14 UTC — Claude (Client UX/Design)
- Merge: changelog auto-généré (`ec78583`)

## 2026-07-24 19:17 UTC — Claude (Client UX/Design)
- Onboarding : corrige le texte de la derniere page (prix USD/abonnement inexistant) (`cbf36ea`)

## 2026-07-24 19:17 UTC — Claude (Client UX/Design)
- Merge: changelog auto-généré (`75cde0c`)

## 2026-07-24 19:36 UTC — Claude
- docs: ajouter les coordonnées de contact réelles (copie de secours de la politique de confidentialité) (`dc92cb6`)

## 2026-07-24 20:35 UTC — Claude
- feat(Backend/Infra): activer/désactiver les catégories (comme les piliers) - phase9_patch_categories_active.sql + écran category_management.dart (`59f41d4`)

## 2026-07-25 01:59 UTC — Claude
- debug: compiler APK avant AAB pour isoler l'origine de l'échec de build (`ebbc822`)

## 2026-07-25 02:22 UTC — Claude
- fix: share_plus ^10.1.4 -> ^12.0.2 (le code utilise l'API SharePlus.instance.share/ShareParams introduite en v11+) (`2b80853`)

## 2026-07-25 02:39 UTC — Claude
- docs: consigner le bug share_plus (version incompatible) et son correctif (`ce2e8d5`)

## 2026-07-25 02:43 UTC — Claude
- Backend/Infra: script SQL des 3 nouveaux piliers (Matières Premières, Anti-Nuisibles, Matières Premières Peinture) + catégories, créés désactivés (`9dd14ec`)

## 2026-07-25 03:03 UTC — Claude
- Client: réapprovisionnement suggéré sur l'Accueil (`a1a22f4`)

## 2026-07-25 03:19 UTC — Claude
- Docs: marquer le réapprovisionnement suggéré comme fait (`d36dbc7`)

## 2026-07-25 03:28 UTC — Claude
- Docs: plan de lancement (25/07) — checklist adressée à la session Backend/Infra pour caler un calendrier commun de publication le mois prochain (`861f16c`)

## 2026-07-25 03:33 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/AkoraHub-app (`8164ad4`)

## 2026-07-25 03:51 UTC — Claude (Client UX/Design)
- Messagerie Admin : badge non lus + marquage lu + tag Demande (23/07) (`3c5bdee`)

## 2026-07-25 03:52 UTC — Claude (Client UX/Design)
- Merge: changelog auto-généré (`4424197`)

## 2026-07-25 03:56 UTC — Claude (Client UX/Design)
- docs: marquer les migrations phase9 (categories active) et phase10 (3 nouveaux piliers) comme executees le 25/07 (`0074cb3`)

## 2026-07-25 07:48 UTC — Anju-codermad
- Backend/Infra: allow staff to manually update order payment status (cash, direct Mobile Money, 30-day invoice) while real gateway pending (`175cc51`)

## 2026-07-25 08:01 UTC — Anju-codermad
- Backend/Infra: add missing Admin quotes screen (client quote requests were invisible to staff) (`6cfd589`)

## 2026-07-25 08:16 UTC — Anju-codermad
- Backend/Infra: real quote negotiation thread (client can counter-propose, staff sees full history) instead of one-shot response (`72d9e4a`)

## 2026-07-25 09:07 UTC — Anju-codermad
- Fix critical bug: prevent duplicate product/batch creation on multi-tap; add missing product delete function; declutter admin product card actions into a menu (`45bbcbc`)

## 2026-07-25 09:13 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/AkoraHub-app (`9a25ec2`)

## 2026-07-25 09:25 UTC — Anju-codermad
- Strengthen product card border/shadow for consistent visual boundaries during image loading (`cf9ed31`)

## 2026-07-25 10:33 UTC — Anju-codermad
- Feature: dark mode toggle (client Profile + Admin settings), persisted preference (`50590de`)

## 2026-07-25 10:39 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/AkoraHub-app (`6593163`)

## 2026-07-25 10:45 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/AkoraHub-app (`c607e40`)

## 2026-07-25 11:00 UTC — Anju-codermad
- Feature: QR code traceability for production batches (Admin generates/shares, client scans to verify authenticity, manufacture date, expiry) (`9da412c`)
