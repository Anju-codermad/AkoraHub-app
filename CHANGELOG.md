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

## 2026-07-25 11:14 UTC — Anju-codermad
- Fix critical build error: missing import for RecurringOrdersScreen in cart_tab.dart (broke both APK and AAB builds) (`943c8c3`)

## 2026-07-25 11:19 UTC — Anju-codermad
- Merge branch 'main' of https://github.com/Anju-codermad/AkoraHub-app (`cd7035f`)

## 2026-07-25 11:41 UTC — Anju-codermad
- Feature: support existing product barcodes (EAN/UPC) alongside QR batch traceability - Admin can scan/enter barcode on product form, client scanner recognizes both (`129a74b`)

## 2026-07-25 12:09 UTC — Anju-codermad
- Feature 1/4 (Client PDF): real company logo upload/storage + downloadable invoice/quote PDFs with logo for client (orders_tab.dart) (`6f15f85`)

## 2026-07-25 12:22 UTC — Anju-codermad
- Feature 2/4 (Multi-langue): FR/MG translation system infrastructure + language selector in Profile + apply to bottom nav and main catalog headers (first pass, more screens to come incrementally) (`32c3d93`)

## 2026-07-25 12:40 UTC — Anju-codermad
- Feature 3/4 (Mode hors-ligne): offline catalog caching (SharedPreferences), offline cart + queued order/quote submission (auto-sync on reconnect), visual offline banner (`08f196e`)

## 2026-07-25 13:08 UTC — Anju-codermad
- Feature 4/4 (Notifications push) part 1: FCM client-side infrastructure (token registration, foreground handling) - waiting on user's google-services.json before enabling native Android integration (`93a597c`)

## 2026-07-25 13:56 UTC — Anju-codermad
- Add real AkoraHub app icon (green #085041, cart/A design) across Android, iOS, and web - replaces default Flutter icon (`7ddba81`)

## 2026-07-25 14:07 UTC — Anju-codermad
- Wire google-services.json into CI (via GitHub secret, base64) + conditionally apply Google Services Gradle plugin - safe fallback if secret absent (`5969403`)

## 2026-07-25 14:09 UTC — Anju-codermad
- Bump google-services Gradle plugin to 4.5.0 (latest per Firebase setup wizard) (`1956ab6`)

## 2026-07-25 14:12 UTC — Anju-codermad
- docs: confirm google-services.json received and wired via GitHub secret (`839640d`)

## 2026-07-25 14:40 UTC — Anju-codermad
- Feature: real push notification sending via Supabase Edge Function + FCM (new message, quote response), triggered by pg_net Postgres trigger (`10385ff`)

## 2026-07-25 16:42 UTC — Anju-codermad
- Feature: extend push notifications to order shipped/delivered and quote accepted/refused (`26782e2`)

## 2026-07-25 18:53 UTC — Claude
- merge: intégrer les changements distants avant push des correctifs profil entreprise (`7a73420`)

## 2026-07-25 19:42 UTC — Claude
- Inscription: date de naissance (vérif 18+), acceptation des conditions, lien retour connexion (`f37ee03`)

## 2026-07-25 19:57 UTC — Claude
- Docs: documenter les améliorations de l'écran d'inscription (date de naissance, conditions, lien connexion) (`805831c`)

## 2026-07-25 20:05 UTC — Claude
- Connexion: sélecteur de comptes récents façon Facebook (pré-remplit l'email, sans stocker de mot de passe) (`8e58142`)

## 2026-07-26 03:05 UTC — Claude
- Docs: documenter le sélecteur de comptes récents à la connexion (`722abfa`)

## 2026-07-26 03:26 UTC — Claude
- Inscription: accepter les numéros de téléphone étrangers (`16393c5`)

## 2026-07-26 03:41 UTC — Claude
- Docs: documenter le correctif téléphone étranger (`93908a5`)

## 2026-07-26 03:52 UTC — Claude
- Inscription: sélecteur d'indicatif pays complet, Nom/Prénom séparés, société obligatoire pour les comptes pro (`399d5c8`)

## 2026-07-26 04:08 UTC — Claude
- Docs: documenter indicatif pays, Nom/Prénom, société obligatoire (`d932e22`)

## 2026-07-26 05:18 UTC — Claude
- feat(Backend/Infra): nouveau menu Admin 'Plus' (Facturation/Alertes/Piliers/Équipe enfin accessibles autrement que via le bouton +) (`9431a7f`)

## 2026-07-26 09:30 UTC — Claude
- Inscription: formulaire en 2 étapes (Identité / Coordonnées) (`704ac5b`)

## 2026-07-26 09:45 UTC — Claude
- Docs: documenter le formulaire d'inscription en 2 étapes (`ebaabd6`)

## 2026-07-26 16:15 UTC — Claude
- feat(client): redesign écran Profil style Facebook centré, adapté aux vraies données (bio+couverture, catégories favorites, publications/favoris) (`6b8bf13`)

## 2026-07-26 16:43 UTC — Claude
- Piliers: script SQL pour 3 nouveaux piliers + icônes correspondantes (`60d1491`)

## 2026-07-26 16:59 UTC — Claude
- Docs: mettre à jour les noms finaux des 3 nouveaux piliers et le script SQL (`ae18abd`)

## 2026-07-26 17:09 UTC — Claude
- Thème: corriger la couleur 'outline' trop pâle (icônes/étoiles floues) (`69eb83c`)

## 2026-07-26 17:24 UTC — Claude
- Docs: documenter le correctif de la couleur outline (texte/icônes flous) (`97f4d51`)

## 2026-07-26 23:16 UTC — Claude
- fix(Backend/Infra): _slugify translittère maintenant les accents (évite les doublons de pilier/catégorie par slug différent) + script de nettoyage du doublon Matières Premières (`86908dc`)

## 2026-07-26 23:44 UTC — Claude
- fix: ne plus bloquer le premier affichage de l'app sur l'init Firebase (popup notifications avant même le logo) + splash en français (`a9179d0`)

## 2026-07-27 03:59 UTC — Claude
- Suppression de compte (self-service, requis pour Data Safety Play Store) (`cf2187a`)

## 2026-07-27 04:15 UTC — Claude
- Merge branch 'main' of https://github.com/Anju-codermad/AkoraHub-app (`691f5f7`)

## 2026-07-27 04:37 UTC — Claude
- perf: paralléliser les 5 chargements indépendants de l'Accueil client (catégories/bannières/badge/activité/réappro), au lieu de les enchaîner à la suite (`440a8ba`)

## 2026-07-27 05:13 UTC — Claude
- chore: réduire la rétention des artifacts de build à 5 jours (quota de stockage GitHub dépassé — 168 builds/5,3 Go accumulés, nettoyés) (`a0d6d76`)

## 2026-07-27 09:19 UTC — Claude
- CI: réduire la durée de conservation des artefacts à 3 jours (évite la saturation du quota de stockage Actions) (`9c8ca10`)

## 2026-07-28 01:42 UTC — Claude
- fix(client): ne plus perdre le message tapé dans la messagerie en cas d'échec d'envoi + bouton Réessayer (`e7f67e5`)

## 2026-07-28 03:11 UTC — Claude
- CI: ne plus publier l'APK comme artefact téléchargeable (garde uniquement l'App Bundle) (`c30d561`)

## 2026-07-28 07:00 UTC — Anju-codermad
- docs: document CI storage quota failure diagnosis and fix, trigger fresh build to confirm (`7a49d43`)

## 2026-07-28 07:40 UTC — Claude (Client UX/Design)
- docs: resoudre la contradiction sur consolidation vs parallele (25/07) (`f859889`)

## 2026-07-28 07:44 UTC — Claude (Client UX/Design)
- Theme: aligner la palette de l app sur les couleurs reelles de l icone (25/07) (`747ee59`)

## 2026-07-28 07:45 UTC — Claude (Client UX/Design)
- Merge: changelog auto-généré (`23b2db6`)

## 2026-07-28 07:51 UTC — Claude
- merge: intégrer les changements distants avant push du correctif espace disque CI (`d5ba48c`)

## 2026-08-01 05:43 UTC — Claude
- Docs: documenter la décision de reporter Services/AkoraFormation (`9244669`)

## 2026-08-01 07:17 UTC — Claude
- Merge: centralise l'accès Formation dans le Profil, libère les piliers Produits (`22e644e`)

## 2026-08-01 07:37 UTC — Claude
- Merge: structure AkoraFormation (cours/modules) (`4799497`)

## 2026-08-01 08:02 UTC — Claude
- Merge: Papi + manuel simultanés au checkout (`413fd68`)

## 2026-08-01 08:06 UTC — Claude
- Merge: frais de retrait Mvola aussi en paiement automatique (`c2d3d3b`)

## 2026-08-01 08:12 UTC — Claude
- Merge: Orange Money ajouté au frais de retrait Mobile Money (`9af0ed6`)

## 2026-08-01 09:36 UTC — Claude
- Merge: onglet A-Formation dans la barre de navigation client (`f4928e0`)

## 2026-08-01 09:47 UTC — Claude
- Merge: lisibilité des piliers + dégradé icônes (`7c38a6d`)

## 2026-08-01 09:50 UTC — Claude
- Merge: renomme A-Formation en Académie (`a43a712`)

## 2026-08-01 09:59 UTC — Claude
- Merge: page de paiement dédiée et sécurisée (`7286ed5`)

## 2026-08-01 10:10 UTC — Claude
- Merge remote-tracking branch 'origin/main' (`8bdbf57`)

## 2026-08-01 10:25 UTC — Claude
- Merge: Paramètres admin remonté + double authentification (2FA) (`837e450`)

## 2026-08-01 10:51 UTC — Claude
- Merge: renommage Mur -> Communauté (`ad9aece`)

## 2026-08-01 10:58 UTC — Claude
- Merge: Communauté - modifier/supprimer sa publication + recherche (`6f9f260`)

## 2026-08-01 11:51 UTC — Claude
- Merge: Formation - abonnement remplacé par l'achat par produit (`c106a2d`)

## 2026-08-01 12:00 UTC — Claude
- Merge: Communauté - réponses, réactions emoji, notifications push (`1eb2165`)

## 2026-08-01 12:21 UTC — Claude
- Merge: Communauté - compression automatique des photos (`7e37c2d`)

## 2026-08-01 12:35 UTC — Claude
- Merge: Communauté - signaler une publication + contacter via WhatsApp (`8acac76`)

## 2026-08-01 12:48 UTC — Claude
- Merge: Communauté - demandes d'ami + messagerie privée (`80bc7ca`)

## 2026-08-01 14:07 UTC — Claude
- Merge: Formation - achat déplacé hors de l'app (conformité Google Play) (`814893f`)

## 2026-08-01 20:02 UTC — Claude
- Merge: Formation web - hébergement via GitHub Pages (`8acfc19`)

## 2026-08-01 20:50 UTC — Claude
- Merge: Formation web - URL finale Netlify (`5838dbd`)

## 2026-08-01 21:16 UTC — Claude
- Merge: Accueil - retouches design avant captures Play Store (`d1121c5`)

## 2026-08-01 21:28 UTC — Claude
- Merge: Dashboard admin - franciser les textes en anglais (`ddadf5d`)

## 2026-08-01 22:07 UTC — Claude
- Merge: AkoraFormation - achat de cours + contenu protégé (`8c81f5f`)

## 2026-08-01 22:38 UTC — Claude
- Merge: Académie - sections par catégorie + design bibliothèque vidéo (`fd4d392`)

## 2026-08-02 05:09 UTC — Claude
- Merge: Mes accès + achats de cours validables côté admin (`068b83f`)

## 2026-08-02 05:25 UTC — Claude
- Merge: logos opérateurs sur la page d'achat externe (`42b1a00`)

## 2026-08-02 06:00 UTC — Claude
- Merge: Communauté Lot 1 - blocage, masquer/enregistrer publication (`8c74a0a`)

## 2026-08-02 06:09 UTC — Claude
- Merge: Communauté Lot 2 - Commander direct, badge Officiel, publication épinglée (`a909add`)

## 2026-08-02 06:20 UTC — Claude
- Merge: correctif phase52 - share_phone_publicly manquante (`296f759`)

## 2026-08-02 06:29 UTC — Claude
- Merge: Communauté Lot 3 - mentions, hashtags, carrousel (`2e14dc3`)

## 2026-08-02 06:36 UTC — Claude
- Merge: Communauté Lot 4 - fil Tendances + filtre par pilier (`03e6749`)

## 2026-08-02 06:46 UTC — Claude
- Merge: Communauté Lot 5 - avis vérifiés + galerie Réalisations clients (`18c0013`)

## 2026-08-02 06:54 UTC — Claude
- Merge: Groupes communautaires AkoraFormation par catégorie (`90335eb`)

## 2026-08-02 07:18 UTC — Claude
- Merge: Profil client Lot 1 - nettoyage structurel (`cac5a13`)

## 2026-08-02 07:24 UTC — Claude
- Merge: Profil client Lot 2 - stats, fidélité, badge secteur, complétion (`623939c`)

## 2026-08-02 07:46 UTC — Claude
- Merge: Profil client Lot 3 - profil public, réalisations, avis, engagement, groupes (`5f59166`)

## 2026-08-02 08:49 UTC — Claude
- Merge: Profil client Lot 4 - fidélité, adresses, QR, couleur d'accent (`c574b8c`)

## 2026-08-02 08:57 UTC — Claude
- Merge: carnet d'adresses branché au checkout (`b9faf23`)

## 2026-08-02 09:08 UTC — Claude
- Merge: correctif compilation profile_tab.dart (`b4ac693`)

## 2026-08-02 10:44 UTC — Claude
- Merge: fusion des écrans Achats Formation (matières premières + cours) (`f606305`)

## 2026-08-02 10:58 UTC — Claude
- Merge: notification push staff pour demandes d'achat Formation (`dcaa4b9`)

## 2026-08-02 20:10 UTC — Claude
- Merge: intégration FiveOne Pay Lot 1 (SQL provider par opérateur) (`0c5e346`)

## 2026-08-02 20:15 UTC — Claude
- Merge: intégration FiveOne Pay Lot 2 (Edge Function create-fiveonepay-payment-link) (`c341ae8`)

## 2026-08-02 20:18 UTC — Claude
- Merge: intégration FiveOne Pay Lot 3 (webhook signé) (`09d3438`)

## 2026-08-02 20:40 UTC — Claude
- Merge: intégration FiveOne Pay Lot 4 (checkout + écran Admin) (`4eb04d6`)

## 2026-08-02 21:26 UTC — Claude
- Merge: CRM Lot 1 (fiche client 360°) (`adb8df8`)

## 2026-08-02 21:37 UTC — Claude
- Merge: CRM Lot 2 (notes, étiquettes, messages, alerte devis, relances) (`459c6a1`)

## 2026-08-02 22:13 UTC — Claude
- Merge: CRM Lot 3 (statut VIP, avantages accordés, note moyenne, signalements) (`88e0050`)

## 2026-08-02 22:26 UTC — Claude
- Merge: CRM Lot 4 (segmentation & marketing) (`b6e10fa`)

## 2026-08-02 22:36 UTC — Claude
- Merge: CRM Lot 5 (tableau de bord analytique, dernier lot) (`d544bfa`)

## 2026-08-03 04:57 UTC — Claude
- Merge: fix crash Achats Formation (embeds PostgREST tolérants) (`b916a2e`)

## 2026-08-03 05:15 UTC — Claude
- Merge: accueil client — barre de recherche + photos Pour vous (`d809480`)

## 2026-08-03 05:26 UTC — Claude
- Merge: Commandes client Lot 1 (fiche détail commande) (`63dc7af`)

## 2026-08-03 05:32 UTC — Claude
- Merge: Commandes/Accueil client Lot 2 (recherche & filtres) (`41e4e99`)

## 2026-08-03 05:49 UTC — Claude
- Merge: Commandes client Lot 3 (actions rapides) (`4b07129`)

## 2026-08-03 06:04 UTC — Claude
- Merge: Commandes/Accueil client Lot 4 : accueil enrichi (`e0ffc3e`)

## 2026-08-03 06:15 UTC — Claude
- Merge: Commandes/Accueil client Lot 5 : design & finitions (`b10a564`)

## 2026-08-03 06:59 UTC — Claude
- Merge: FiveOne Pay - activer Orange Money côté Admin (`43dd61f`)

## 2026-08-03 07:13 UTC — Claude
- Merge: nouveau menu client Services (demande de service) (`0c6b9f5`)

## 2026-08-03 07:53 UTC — Claude
- Merge: fix crash Commandes client (isolation d'erreurs) (`32f2b07`)

## 2026-08-03 08:38 UTC — Claude
- Merge: bulle de chat flottante sur tout l'espace client (`38678a0`)

## 2026-08-03 09:33 UTC — Claude
- Catalogue de services (7 catégories, 35 services) gérable depuis l'admin (`c102eb3`)

## 2026-08-03 09:46 UTC — Claude
- Fix: erreur de syntaxe Dart dans service_requests_tab.dart (`3f0b610`)

## 2026-08-03 10:24 UTC — Claude
- Barre de raccourcis Profil (Paramètres/Parrainage/Assistance/Scanner) + programme de parrainage (`ecbcd1c`)

## 2026-08-03 20:13 UTC — Claude
- Badge messages non lus sur le raccourci Assistance du profil (`5d896b5`)

## 2026-08-03 20:26 UTC — Claude
- Activer/désactiver la bulle de chat flottante (admin global + client personnel) (`717756c`)

## 2026-08-04 09:33 UTC — Claude
- fix: bouton double authentification bloqué après désactivation (`f824b2c`)

## 2026-08-04 09:37 UTC — Claude
- feat: grille 2 colonnes pour l'écran Académie (`8505712`)

## 2026-08-04 09:51 UTC — Claude
- feat: onglets soulignés + vue Débloqués dans le catalogue Formation (`b2e5aa6`)

## 2026-08-04 10:03 UTC — Claude
- feat: photo des publications dans le fil Pour vous de l'Accueil (`3534947`)

## 2026-08-04 10:08 UTC — Claude
- feat: photo de profil de l'Accueil ouvre l'onglet Profil (`83f9e0e`)

## 2026-08-04 11:02 UTC — Claude
- fix: workflow changelog cassé par guillemets/backticks dans le message de commit (`2107c23`)

## 2026-08-04 11:53 UTC — Claude
- fix: le filtre par catégorie Académie n'affichait pas que la catégorie (`c22d64d`)

## 2026-08-04 11:57 UTC — Claude
- feat: publication automatique sur Firebase App Distribution (`64ace7f`)

## 2026-08-04 12:31 UTC — Claude
- docs: documenter la mise en place de Firebase App Distribution (`8f93db9`)

## 2026-08-04 12:38 UTC — Claude
- fix: secrets.* dans un if: d'étape empêchait tout le build de démarrer (`237a41f`)

## 2026-08-04 13:05 UTC — Claude
- feat: vérification de mise à jour in-app (client + admin) (`c3615bc`)

## 2026-08-04 13:32 UTC — Claude
- chore: bump version 1.0.0+2 — teste la notification de mise à jour in-app (`c381ff5`)

## 2026-08-04 14:34 UTC — Claude
- feat: onglet Catalogue dédié dans la barre du bas, Commandes déplacé en en-tête (`7719a45`)

## 2026-08-05 04:35 UTC — Claude
- fix: texte d'onboarding neutre (AkoraHub n'est pas un SaaS multi-commerces) (`36a7aa0`)

## 2026-08-05 04:38 UTC — Claude
- fix: le bandeau flash info disparaît une fois lu par le client (`ec5989c`)

## 2026-08-05 05:50 UTC — Claude
- feat: indicateur "en train d'écrire" dans les deux messageries (`f321d6e`)

## 2026-08-05 06:00 UTC — Claude
- fix: afficher le code HTTP et la réponse réelle du webhook Supabase (`42827ce`)

## 2026-08-05 06:18 UTC — Claude
- feat: remettre une barre de recherche (raccourci) sur l'Accueil (`bec2813`)

## 2026-08-05 06:26 UTC — Claude
- merge: intégrer le changelog automatique (`0f2ce62`)

## 2026-08-05 06:27 UTC — Claude
- merge: intégrer le changelog automatique (`0d8d8dc`)

## 2026-08-05 06:58 UTC — Claude
- merge: intégrer le changelog automatique (`51fb2c4`)

## 2026-08-05 07:41 UTC — Claude
- merge: intégrer le changelog automatique (`e714df7`)

## 2026-08-05 08:53 UTC — Claude
- merge: intégrer le changelog automatique (`ac323a7`)

## 2026-08-05 09:00 UTC — Claude
- merge: intégrer le changelog automatique (`4a83d85`)

## 2026-08-05 09:18 UTC — Claude
- merge: intégrer le changelog automatique (`2a8bc72`)

## 2026-08-05 09:24 UTC — Claude
- merge: intégrer le changelog automatique (`31f985e`)
