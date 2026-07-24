# AkoraHub — Document de référence du projet

> Ce document sert à mettre à niveau rapidement toute nouvelle conversation
> Claude qui reprendrait ce projet. Lis-le en entier avant de modifier quoi
> que ce soit.

## 1. Contexte général

**AkoraHub** (anciennement "Akora Fanadiovana app") est une application Flutter
pour l'entreprise malgache Akora Fanadiovana (fabrication/distribution de
produits d'entretien, hygiène, agro-industriels — plus ARCA PAINTS et
AkoraFormation comme piliers additionnels). Le projet a été initialement
généré par Rocket.new (code de démo avec données fictives), puis reconstruit
progressivement avec un vrai backend Supabase.

**Stack technique** :
- Flutter (dernière version stable) + Riverpod (state management)
- Supabase (base de données PostgreSQL, authentification, stockage fichiers)
- GitHub Actions pour compiler l'APK automatiquement à chaque push sur `main`
  (voir `.github/workflows/build-apk.yml`)

**Projet Supabase** : `lmnprtwelmmoiuygvgmf` (région eu-west)

## 2. Architecture du dépôt

- `lib/core/supabase/` : connexion Supabase (`supabase_config.dart`) et
  routage selon le rôle (`auth_helpers.dart`)
- `lib/core/providers/` : état partagé Riverpod (ex: `cart_provider.dart`)
- `lib/presentation/` : un dossier par écran. **Convention importante** :
  plusieurs écrans d'origine Rocket.new (mock, jamais connectés à Supabase)
  coexistent avec leurs équivalents réels, nommés avec le suffixe `_real`
  ou dans un nouveau dossier dédié (ex: `product_catalog_management/` est
  l'ancien mock, `product_management_real/` est le vrai, connecté). **Ne
  jamais réutiliser un écran sans suffixe `_real` en pensant qu'il est
  fonctionnel — vérifier d'abord.**
- `lib/routes/app_routes.dart` : toutes les routes de l'app. Vérifier que les
  boutons de navigation pointent bien vers les écrans `_real`, pas les mocks.
- `supabase/*.sql` : scripts SQL exécutés manuellement par l'utilisateur dans
  Supabase (SQL Editor). Chaque fichier `phaseN_schema.sql` correspond à une
  étape du projet. **Ne jamais modifier ces fichiers directement sur GitHub**
  (l'utilisateur n'a pas d'accès direct à la base depuis son navigateur en
  dehors de Supabase) — toujours passer par une conversation Claude qui édite
  puis pousse le fichier normalement via Git.

## 3. Ce qui est déjà construit (fonctionnel, testé, compilé)

### Phase 1 — Espace Admin
- Authentification réelle (connexion/inscription/déconnexion Supabase)
- Piliers d'entreprise (`business_units`) : liste VIDE par défaut, l'Admin
  crée lui-même chaque pilier (`business_units_management/`)
- Équipe & rôles (Admin/Commercial/Production/Comptable) via
  `staff_management/` — promotion d'un compte existant par email (pas de
  création de compte "admin" côté client, pour des raisons de sécurité)
- Produits avec tarification Gros/Détail par seuil de quantité
  (`product_management_real/`). **Note** : les anciens écrans fictifs
  `product_catalog_management/` et `product_detail_editor/` ont été
  **entièrement supprimés du projet** (20/07) après qu'un bug de navigation
  y ait mené depuis la barre de navigation du bas — ils n'existent plus,
  seul `product_management_real/` doit être utilisé/étendu.
- Stock + lots de production avec DLC (`production_batches`)
- Facturation PDF (`invoicing/`)
- Alertes stock bas / DLC proche (`alerts_center/`)
- Commandes et Clients réels (`order_management_real/`,
  `customer_management_real/`)
- Analytics réel (`analytics_dashboard_real/`) — remplace l'ancien mock
- Profil entreprise (`business_profile_settings/`) — sauvegarde réelle dans
  `company_settings` (table singleton avec colonne JSONB)

### Phase 2 — Catalogue & Commande client
- Espace client dédié (`client_home/`) avec navigation par onglets réduite
  à 3 destinations : **Accueil, Commandes, Profil** (barre du bas custom,
  `_ClientBottomNav` dans `client_home.dart` — plus le widget `NavigationBar`
  standard, pour pouvoir sauter l'index Panier). **Panier** n'a plus
  d'onglet : accessible via une icône (avec badge du nombre d'articles)
  dans l'en-tête de l'Accueil, à côté de l'icône notifications. **Mur**
  retiré du menu de navigation — le code (`client_home/wall/wall_tab.dart`)
  reste dans le repo en vue de son intégration dans le Profil (voir plan
  profil étape 3 ci-dessous), non supprimé.
- Catalogue avec navigation Pilier → Catégorie → Recherche
  (`client_home/catalog_tab.dart`) — écran renommé **Accueil** dans la
  navigation (icône maison). En-tête personnalisé (avatar + prénom du
  client + localisation + libellé **"AkoraHub"** au-dessus des icônes
  panier/notifications, cette dernière est un stub visuel sans backend) ;
  le corps du `Scaffold` (`client_home.dart`) est enveloppé dans un
  `SafeArea(bottom: false)` pour éviter que cet en-tête ne chevauche la
  barre de statut système (heure/batterie/réseau) — nécessaire car
  l'onglet Accueil n'a pas d'`AppBar`. Piliers ("Nos activités") affichés
  en **icônes rondes colorées** défilantes horizontalement (remplace
  l'ancienne grille rectangulaire — icônes mappées par mot-clé dans le
  `slug` du pilier : paint→pinceau, formation→école, chimie/chemical→
  science, cosmet→spa, insecticide/insect→pest_control, sinon icône
  générique ménage), cartes produits avec prix mis en avant et bouton
  **"+" vert d'ajout rapide au panier** (utilise les prix de base du
  produit — pour un produit à variantes, ce prix peut différer de la
  variante réellement choisie ; ouvrir la fiche produit reste nécessaire
  pour un prix exact). Design inspiré de deux références visuelles
  fournies par l'utilisateur (grocery app + service app before/after).
  **Piliers supplémentaires évoqués par l'utilisateur** (à créer par
  l'Admin via l'écran de gestion des piliers, pas encore créés) : matières
  premières chimiques, produits cosmétiques, produits insecticides — noms
  et slugs suggérés en attente de validation utilisateur.
- **Bannière hero de l'Accueil** (23/07) : la bannière promo en carrousel
  (`PageView` + indicateurs) n'est plus figée en dur — elle charge
  désormais les slides actifs depuis la table `home_banners`
  (`supabase/phase6_patch_home_banners.sql`, **exécuté avec succès par
  l'utilisateur**), avec repli silencieux sur les 3 slides par défaut si
  la table est vide. Gestion réservée **strictement à l'Admin** (RLS
  `current_role_is_admin()`, pas le reste du staff) depuis un nouvel écran
  `home_banners_management.dart` (titre, sous-titre, photo via
  `image_picker` + bucket Storage public `home-banners`, réordonnancement,
  activation/désactivation, suppression) — accessible depuis Tableau de
  bord Admin → **+** → "Bannière hero — Accueil". Si aucune photo n'est
  définie sur un slide, le dégradé + icône par défaut est conservé.
- Panier multi-produits (`client_home/cart_tab.dart`)
- Commande directe OU demande de devis (les deux créent respectivement une
  ligne dans `orders`/`order_items` ou `quotes`/`quote_items`)
- Suivi de commande à 4 statuts + "Recommander en 1 clic"
  (`client_home/orders_tab.dart`). Écran restructuré en 2 sous-onglets
  (`DefaultTabController`) : **Commandes** (inchangé) et **Devis**
  (nouveau — "Mes devis"). Les devis existaient déjà en base (table
  `quotes`, créés depuis le panier via "Demander un devis") mais n'étaient
  visibles nulle part côté client avant cet ajout. Statut affiché avec
  badge coloré (en_attente/envoyé/accepté/refusé/expiré) ; bouton
  "Commander ce devis" (ajoute les articles au panier) si le statut est
  envoyé ou accepté.
- **Favoris** (`client_home/favorites_provider.dart` +
  `client_home/favorites_screen.dart`) — étoile (contour vide `star_border`
  si non favori, pleine `star` ambre si favori — style demandé par
  l'utilisateur) sur les cartes produit de l'Accueil et sur la fiche
  produit. Nouvelle table `favorites` (`supabase/phase7_patch_favorites.sql`,
  **à exécuter par l'utilisateur** — sans elle la liste reste vide
  silencieusement, sans erreur visible). Écran "Mes favoris" accessible
  depuis le Profil, avec bouton "Tout ajouter" au panier. Provider
  volontairement placé dans `client_home/` (pas `lib/core/providers/`) pour
  respecter le périmètre Client UX (section 7).
- Profil client réel (`client_home/profile_tab.dart`) — remplace l'ancien
  écran minimal (email + logout). Affiche nom, société, secteur, téléphone,
  localisation, avatar (table `profiles`), avec formulaire d'édition en
  bottom sheet et upload d'avatar vers le bucket Storage `avatars`
  (policies dans `supabase/phase4_patch_avatars.sql`, **script exécuté avec
  succès par l'utilisateur dans Supabase — bucket créé, fonctionnel**).
  **"Mes publications" fait (23/07)** : entrée de menu ouvrant le Mur
  pré-filtré sur les posts de l'utilisateur (voir Phase 3 — Social
  ci-dessous). **Reste à faire** : statistiques personnelles (nb
  commandes, avis, ancienneté) sur cet écran.
  **Localisation automatique (Niveau 1 — fait)** : bouton "Utiliser ma
  position actuelle" dans le formulaire d'édition (icône 📍 dans le champ
  Localisation). Récupère le GPS (packages `geolocator` + `geocoding`,
  permissions ajoutées dans `AndroidManifest.xml`/`Info.plist`), reverse-
  géocode en adresse lisible (quartier, ville, région) et remplit le champ
  texte `location` existant — aucun changement de schéma. Repli sur les
  coordonnées brutes si le reverse-géocodage échoue (ex. hors ligne).
  **Localisation automatique (Niveau 2 — fait)** : pour une livraison
  vraiment fiable, l'équipe de livraison a besoin d'un point GPS exact, pas
  seulement d'une adresse texte (peu fiable à Madagascar, adressage souvent
  imprécis). Migration exécutée avec succès par l'utilisateur
  (`supabase/phase5_patch_geolocation.sql`) : colonnes nullable
  `latitude double precision` et `longitude double precision` sur
  `profiles`, avec contraintes de validité (plages -90/90 et -180/180).
  Côté client, `profile_tab.dart` capture `position.latitude`/
  `position.longitude` dans `_useCurrentLocation`, les stocke en état
  (pré-remplis depuis le profil existant pour ne pas les écraser à une
  simple sauvegarde) et les inclut dans l'appel `.update()` du profil.
  Colonnes équivalentes ajoutées sur `orders`
  (`supabase/phase5_patch_orders_geolocation.sql`, **exécuté avec succès par
  l'utilisateur le 23/07**) pour le cas où un client livre à une adresse
  différente de son profil (nullable, repli sur les coordonnées du profil
  si absentes). Côté client, `cart_tab.dart` capture désormais les
  coordonnées (`_deliveryLat`/`_deliveryLon`, alimentées par
  `_estimateDelivery` — GPS actuel ou géocodage de l'adresse profil en
  repli) et les inclut dans l'`insert()` de la commande. **Terminé** :
  schéma + code client tous les deux en place.
- **Frais de livraison automatiques** (`client_home/delivery_pricing.dart` +
  intégration dans `cart_tab.dart`) — modèle "taxi rapide" choisi par
  l'utilisateur : `frais = max(prise_en_charge + tarif_par_km ×
  distance_corrigée, minimum)`, avec distance à vol d'oiseau (Haversine)
  × facteur de correction 1,4 pour approcher la distance routière réelle à
  Tana. Valeurs actuelles : prise en charge 3000 Ar, tarif 800 Ar/km,
  **minimum 4000 Ar (confirmé par l'utilisateur)**. Estimation automatique
  au chargement du panier (GPS live, repli sur géocodage de l'adresse texte
  du profil si GPS indisponible) ; affichée en Sous-total / Frais de
  livraison (avec distance) / Total ; incluse dans `orders.delivery_fee` et
  `orders.delivery_zone` à la commande (colonnes déjà existantes dans le
  schéma, jusqu'ici inutilisées).
  **✅ Coordonnées du dépôt confirmées et appliquées** (23/07) :
  `depotLatitude`/`depotLongitude` = -18.900360, 47.510128 (Rue Seimad,
  Antananarivo 101) — le placeholder centre-ville a été remplacé.
  **Pour le futur (Backend/Infra, si l'utilisateur le demande)** : rendre
  ces valeurs modifiables depuis l'Admin sans nouvelle version de l'app, en
  les déplaçant dans la colonne JSONB de `company_settings` (déjà utilisée
  par `business_profile_settings`) et en les lisant depuis
  `delivery_pricing.dart` via Supabase au lieu de constantes en dur.

### Phase 3 — Social
- Mur personnel : publications texte + photo (upload vers le bucket Supabase
  Storage `wall-photos`), likes, commentaires (`client_home/wall/`)
- Avis produits avec notation étoiles, affichés sur la fiche produit
- Filtre du mur par secteur (Hôtel/Hôpital/Entreprise/Particulier)
- **Intégré dans le Profil (23/07)** : le Mur (`WallTab`) est accessible
  depuis deux entrées de menu dans `profile_tab.dart` — "Mur — Communauté
  AkoraHub" (mur complet) et "Mes publications" (mur pré-filtré sur
  `author_id == utilisateur courant` via le nouveau paramètre
  `initialOnlyMine`, combiné avec le filtre de secteur existant via un
  `FilterChip` dédié). `WallTab` a désormais son propre `AppBar` (avant
  pensé pour vivre dans une barre d'onglets, donc sans en-tête). **Aucun
  nouvel onglet de navigation créé**, conformément à la décision
  explicite de l'utilisateur — voir section 3bis.
- **Messagerie privée client ↔ équipe** (`client_home/chat_screen.dart`) —
  une conversation par client (table `conversations` +`messages`,
  `supabase/phase8_patch_messaging.sql`), messages en temps réel (stream
  Supabase realtime). Inclut les **"Demandes"** (ex "Demandes & annonces") :
  un message avec `is_request=true`, badge visuel distinct, **jamais
  visible par les autres clients** — répond à la préoccupation explicite de
  l'utilisateur de ne pas exposer les besoins d'un client aux autres
  (risque de perte de clientèle). Accessible via une icône 💬 dans l'en-tête
  de l'Accueil et une entrée dans le Profil.
  **⚠️ Action requise côté Backend/Infra** : l'écran Admin
  `lib/presentation/messaging_center/messaging_center.dart` existe déjà
  mais tourne **entièrement sur des données mock** (conversations
  inventées). Pour que l'équipe commerciale puisse réellement répondre aux
  clients, cet écran doit être branché sur les tables `conversations`/
  `messages` ci-dessus (mêmes noms de colonnes : `sender_role` distingue
  `'client'`/`'staff'`, `is_request` pour les demandes). Tant que ce n'est
  pas fait, les messages envoyés par les clients sont bien enregistrés mais
  invisibles pour l'équipe.
- **Groupes professionnels** (mentionnés dans les discussions) : mis de
  côté sur demande explicite de l'utilisateur — réservés aux participants
  des formations, à traiter plus tard avec le module e-learning.

### Phase 4 — Variantes produit
- Chaque produit peut avoir des **variantes** = combinaison Format × Parfum,
  chacune avec son propre prix Gros/Détail et son propre stock
  (`product_variants` table + `product_management_real/product_variants_screen.dart`
  côté Admin, sélection en 2 menus déroulants côté client dans
  `product_detail_client.dart`)
- Formats et Parfums sont des **listes de référence pré-remplies** —
  extensibles directement depuis les écrans concernés

### Phase 6 — Sous-catégories produit
- Table `categories` (`supabase/phase6_patch_categories.sql`, **exécuté avec
  succès par l'utilisateur**) : même schéma que
  formats/parfums (liste de référence, RLS select_all/write_staff), mais
  scopée par pilier (`business_unit_id`) — une catégorie comme "Carrelage &
  Sols" n'a de sens que pour un pilier donné, contrairement aux formats qui
  sont partagés entre tous les produits.
- **8 catégories pré-remplies pour le pilier Akora Fanadiovana** (noms
  améliorés à partir d'une liste de dossiers fournie par l'utilisateur) :
  Carrelage & Sols, Cuisine & Vaisselle, Désinfectants & Hygiène, Entretien
  Véhicules, Lessive & Textile, Sanitaire & Salle de Bain, Soins du Corps &
  Cosmétiques, Vitres & Surfaces. Le script matche le pilier par
  `name ilike 'Akora Fanadiovana'` — si le pilier a été créé sous un autre
  nom exact dans l'app, adapter le `WHERE` avant exécution (le script émet
  un `RAISE NOTICE` si aucun pilier ne correspond).
- Côté Admin (`product_management_real.dart`), le champ Catégorie du
  formulaire produit est passé d'un `TextField` libre à un
  `DropdownButtonFormField` filtré par le pilier sélectionné + bouton "+"
  pour ajouter une nouvelle catégorie à la volée (même pattern que
  Format/Parfum) — évite les fautes de frappe qui créeraient une catégorie
  fantôme (le filtre côté client catalogue compare le texte exactement).
  Reste rétro-compatible : le chargement des catégories est fait dans un
  try/catch qui ne bloque pas le reste de l'écran si la table `categories`
  n'existe pas encore (migration non exécutée), et un produit dont la
  catégorie texte ne correspond à aucune entrée de la table reste affichée
  dans le Dropdown (n'écrase rien). **Terminé** : schéma + code Admin en
  place, 8 catégories confirmées visibles par l'utilisateur.

### Phase 8 — Photos produit (jusqu'à 10 par produit)
- Table `product_images` + bucket Storage `products`
  (`supabase/phase8_patch_product_images.sql`, **script prêt, pas encore
  exécuté par l'utilisateur**) : `products.image_url` existait depuis la
  Phase 1 mais n'était branché nulle part (ni upload, ni affichage) —
  l'utilisateur l'a remarqué en testant la saisie de produits. Nouvelle
  table `product_images` (product_id, image_url, position) pour une
  galerie ordonnée, RLS select_all/write_staff comme categories/formats.
  Garde-fou serveur (trigger) : jamais plus de 10 lignes par produit,
  au-delà de la limite déjà appliquée côté app. Bucket `products` public en
  lecture, écriture réservée au staff (contrairement au bucket `avatars` où
  chaque client gère son propre dossier).
- **Côté Admin** (`product_management_real.dart`) : galerie de miniatures
  dans le formulaire produit (ajout via `ImagePicker().pickMultiImage` avec
  limite dynamique = 10 − photos déjà présentes, suppression individuelle
  via un bouton "x" sur chaque miniature — existantes ou fraîchement
  choisies). À l'enregistrement : upload des nouvelles vers le bucket
  `products`, suppression storage best-effort des retirées, réécriture
  complète de `product_images` avec positions 0..n-1, et
  `products.image_url` mis à jour pour pointer vers la 1ère photo (sert de
  couverture catalogue). La gestion des photos est dans un try/catch séparé
  de celui du produit : si la migration n'est pas encore exécutée, le
  produit (nom/prix/catégorie) s'enregistre quand même, avec un message
  "photos non sauvegardées" plutôt qu'une fausse erreur globale.
- **Côté client** : couverture (`image_url`) affichée dans les cartes
  produit du catalogue (`catalog_tab.dart`) et des favoris
  (`favorites_screen.dart`), repli sur l'icône placeholder si absente.
  Fiche produit (`product_detail_client.dart`) : vrai carrousel
  (`PageView`) sur la galerie complète (`product_images`) si plusieurs
  photos, sinon couverture unique, sinon icône — avec indicateurs de
  pagination (points) si plus d'une photo.
- **Reste à faire** : l'utilisateur doit exécuter
  `phase8_patch_product_images.sql` dans Supabase pour que l'upload
  fonctionne (tant que ce n'est pas fait, le formulaire produit affiche le
  sélecteur de photos mais l'enregistrement des photos échoue
  silencieusement avec le message ci-dessus, sans bloquer le reste).

## 3bis. Suggestions d'amélioration côté client (évoquées, pas encore décidées)

Idées discutées avec l'utilisateur, à prioriser plus tard — aucune n'est
commencée sauf mention contraire :

- **Réapprovisionnement suggéré** : détecter les produits qu'un client
  recommande régulièrement et le proposer proactivement (étend le
  "Recommander en 1 clic" déjà existant dans `orders_tab.dart`)
- **Commande récurrente / abonnement** pour les consommables réguliers
- **Paiement Mobile Money au checkout** (Mvola/Orange Money/Airtel Money) —
  voir aussi la piste Papi déjà notée en section 4
- **Plusieurs adresses de livraison par compte** (pertinent pour un hôtel/
  hôpital avec plusieurs sites) — actuellement un seul champ `location` par
  profil
- **Facture/devis téléchargeable en PDF**
- **Notifications réelles** (le bouton actuel dans l'en-tête de l'Accueil
  est un stub visuel sans backend — voir section 4, "Notifications push
  réelles")
- **Renforcement du côté "réseau social" pour les clients** (23/07,
  discuté avec l'utilisateur) — idées proposées : fil d'activité "Pour
  vous" (posts du Mur + nouveaux produits + promos), badge de
  notification sur la cloche, profils clients publics légers consultables
  depuis le Mur, partage rapide d'un produit/post, tags/mentions de
  produits dans les posts. **Décision explicite de l'utilisateur : aucun
  nouvel onglet dans la barre de navigation.** Tout doit se loger dans les
  3 onglets existants. **Fait (23/07)** : Mur + "Mes publications"
  intégrés dans l'onglet Profil (voir Phase 3 — Social). **Pas encore
  commencé** : fil d'activité "Pour vous" sur l'Accueil, badge sur la
  cloche, profils clients publics, partage rapide, tags/mentions.
- **Filtre de recherche avancé** sur le catalogue (prix, disponibilité,
  pilier) — au-delà des chips de catégorie actuelles
- **Mode sombre**
- **Localisation automatique** — Niveau 1 fait, Niveau 2 (coordonnées GPS
  précises) documenté ci-dessus dans la section Profil
- **Messagerie unifiée client ↔ équipe commerciale** (23/07, Backend/Infra) :
  une seule conversation par client (pas de séparation par pilier, décision
  utilisateur), tables `conversations`/`messages` avec trigger auto pour
  `last_message_at`. Écran client : `client_home/messaging/client_chat_screen.dart`
  (accessible depuis un bouton "Messagerie" dans l'onglet Profil). Écran
  Admin : `messaging_center_real/` (liste des conversations triées par
  récence + fil de discussion), déjà branché sur les boutons existants du
  tableau de bord Admin. **L'ancien écran fictif `messaging_center/`
  (595 lignes, faux contacts "Sarah Johnson" etc.) a été supprimé
  entièrement**, comme pour les autres écrans legacy. Script SQL :
  `supabase/phase6_schema.sql` — **prêt, en attente d'exécution par l'utilisateur**.
  Pas encore fait : notifications quand un nouveau message arrive (lié au
  point "Notifications push" ci-dessous), indicateur de messages non lus.

## 4. Ce qui N'EST PAS encore fait

- **Nettoyage "fonctionnalités bidon" (audit demandé par l'utilisateur, fait)** :
  suppression des 3 écrans mock morts (customer/order/analytics management
  non-`_real`, jamais routés depuis l'UI, 4500+ lignes) ; **Campaign
  Management** débranché des menus (dashboard quick actions + bottom sheet
  "+") car 100% factice (aucune connexion Supabase, liste codée en dur,
  SnackBar de succès sans persistance) — le fichier
  `lib/presentation/campaign_management/` reste dans le repo si besoin de
  le reconstruire un jour pour de vrai, mais plus aucune route/bouton n'y
  mène ; **splash screen simplifié** — les 4 fausses étapes d'initialisation
  (`_checkSubscriptionStatus`, `_loadBusinessProfiles`,
  `_fetchConfigurations`, `_prepareCachedData`, chacune un `Future.delayed`
  sans effet réel) supprimées, temps de démarrage ramené de ~4,8s à ~1,5s.
- **Notifications push** réelles
- **Mode hors-ligne**
- **Multi-langue** Français/Malagasy
- **Fidélité par paliers**
- **Paiement Mobile Money / carte Visa** (le compte MVola de l'entreprise
  existe mais son statut "marchand" n'est pas confirmé ; piste retenue :
  Papi, papi.mg, qui unifie MVola/Orange Money/Airtel Money/Visa — voir
  historique de conversation pour le détail des échanges avec ce prestataire)
- Icône et splash screen personnalisés (nom "AkoraHub" appliqué, mais pas de
  logo graphique custom pour l'instant)

## 5. Conventions et pièges à connaître

- **Toujours vérifier la compilation** après une modification en poussant sur
  `main` et en consultant `https://github.com/Anju-codermad/akora-fanadiovana-app/actions`
  via l'API GitHub (`GET /repos/Anju-codermad/akora-fanadiovana-app/actions/runs`)
  — le jeton utilisé doit avoir les permissions Contents (RW), Metadata (R),
  Workflows (RW), Actions (R) pour pouvoir lire les logs/statuts de builds.
- **RLS (Row Level Security)** est activé sur toutes les tables. La fonction
  SQL `public.current_role_is_staff()` sert à autoriser Admin/Commercial/
  Production/Comptable ; les clients n'ont accès qu'à leurs propres données.
- **Ne jamais coder de clé secrète Supabase en dur** dans le code Flutter —
  seule la clé publique (`anon key`) est utilisée côté app, injectée via
  `env.json` généré par GitHub Actions à partir des secrets du dépôt
  (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- **Piliers, sous-catégories futures, etc. démarrent VIDES** — c'est un choix
  délibéré de l'utilisateur (pas de données pré-remplies fictives), à la
  différence des listes Formats/Parfums qui sont volontairement pré-remplies.
- Avant de modifier un écran, vérifier s'il existe une version `_real` /
  connectée à Supabase à côté d'un écran mock hérité de Rocket.new — préférer
  toujours créer un nouvel écran propre plutôt que de risquer de casser un
  gros fichier existant, à l'image de ce qui a été fait jusqu'ici.

## 7. Répartition des missions entre conversations Claude en parallèle

Pour éviter les conflits, le projet est divisé en deux périmètres clairs :

- **Conversation "Backend/Infra"** : `lib/core/`, `supabase/*.sql`, tous les
  écrans Admin (`*_real` hors `client_home/`), `.github/workflows/`,
  paiement, messagerie, notifications, sécurité RLS.
- **Conversation "Client UX/Design"** : uniquement
  `lib/presentation/client_home/*` — écrans client, style visuel, mise en
  page, adaptation des références visuelles fournies par l'utilisateur.

**Règle** : si une conversation doit exceptionnellement toucher au périmètre
de l'autre, elle doit le dire explicitement à l'utilisateur avant de le
faire, pour que l'autre conversation soit mise en pause le temps du
changement.

## 6bis. Comment reprendre le fil (pour toute conversation)

1. `git pull` avant de commencer
2. Lire ce fichier en entier + les dernières entrées de `CHANGELOG.md`
3. Travailler uniquement dans son périmètre (section 7)
4. Mettre à jour ce fichier (sections 3, 4 et 7 si besoin) avant de pousser
   le dernier commit de la session

