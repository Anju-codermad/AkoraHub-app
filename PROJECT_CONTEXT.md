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
  **Piliers supplémentaires** (26/07) — noms finaux décidés par
  l'utilisateur (différents de la proposition initiale "Akora
  Chimie/Cosmétique/Insecticides") : **Matières Premières**, **Anti-
  Nuisibles**, **Matières Premières Peinture**. Script :
  `supabase/phase21_patch_new_business_units.sql` (insert idempotent,
  **exécuté avec succès par l'utilisateur le 30/07**). Icônes déjà mappées côté
  client (`_iconForUnit` dans `catalog_tab.dart`) via les mots-clés
  `peinture` → pinceau, `chimique` → fiole, `nuisible` → anti-nuisible
  (peinture vérifiée en premier pour éviter le faux-positif de
  "matieres-premieres-peinture" sur le mot-clé générique "premieres").
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
  **exécuté avec succès par l'utilisateur le 25/07**). Écran "Mes favoris" accessible
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
  (`supabase/phase8_patch_product_images.sql`, **exécuté avec succès par
  l'utilisateur le 25/07**) : `products.image_url` existait depuis la
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
- **✅ Fait (25/07)** : script exécuté avec succès, l'upload/affichage des
  photos produit est maintenant pleinement fonctionnel des deux côtés.

### Phase 9 — Activer / désactiver une catégorie (exécuté avec succès le 25/07)
- Contexte : les piliers (business_units) avaient déjà un champ `active` +
  interrupteur côté Admin (écran "Piliers d'entreprise",
  `business_units_management.dart`) — un pilier désactivé disparaît du
  catalogue client. L'utilisateur a demandé la même capacité pour les
  catégories, en prévision de gammes préparées à l'avance (ex:
  Anti-Nuisibles avec ses 7 sous-catégories) mais pas encore "lancées".
- `supabase/phase9_patch_categories_active.sql` : ajoute `active boolean
  default true` sur `categories`.
- Nouvel écran `category_management.dart`, accessible depuis chaque carte
  de pilier dans "Piliers d'entreprise" (icône catégorie à côté de
  l'interrupteur actif/inactif du pilier) : même pattern d'interrupteur
  par catégorie, renommage, ajout.
- Le formulaire produit (`product_management_real.dart`) ne propose plus
  que les catégories actives dans son menu déroulant (la catégorie déjà
  choisie sur un produit existant reste affichée même si désactivée
  depuis, pour ne pas casser l'édition).
- Côté client (`catalog_tab.dart`), les catégories désactivées sont
  exclues des puces de filtre du catalogue — chargement tolérant (repli
  silencieux si la migration n'est pas encore exécutée). Une catégorie
  désactivée ne supprime pas les produits déjà tagués avec elle : ils
  restent visibles et cherchables, seule la puce de filtre disparaît.

### Phase 10 — 3 nouveaux piliers dormants (exécuté avec succès le 25/07)
- `supabase/phase10_patch_new_business_units.sql` : crée 3 nouveaux
  piliers **désactivés** (`active = false`, invisibles côté client tant
  que l'Admin ne les active pas depuis "Piliers d'entreprise") avec leurs
  catégories par défaut :
  1. **Matières Premières** (12 catégories : Acides & Bases, Chélatants,
     Désinfectants, Épaississants, Charges Minérales, Colorants,
     Conservateurs & Antioxydants, Huiles & Beurres Cosmétiques, Parfums &
     Additifs, Polymères & Résines, Solvants, Tensioactifs) — remplace
     l'ancienne idée de catégorie "Agroalimentaire" séparée (un ingrédient
     alimentaire va dans sa famille chimique, ex. Acides & Bases, avec une
     note "qualité alimentaire" dans sa description produit).
  2. **Anti-Nuisibles** (7 catégories : Insecticides Maison/Extérieur,
     Anti-Fourmis & Cafards, Anti-Moustiques & Mouches, Raticides &
     Rongeurs, Anti-Puces & Tiques, Produits Agrivet — en prévision d'un
     projet de revente agricole/vétérinaire).
  3. **Matières Premières Peinture** (5 catégories : Liants & Résines,
     Pigments & Colorants, Charges & Additifs, Solvants & Diluants,
     Siccatifs & Conservateurs) — distinct du pilier ARCA PAINTS existant
     (qui vend les peintures finies) : ici les intrants pour fabriquer de
     la peinture.
- Catégories ajustables librement depuis l'écran de gestion des
  catégories une fois le pilier activé.

## Chargement du catalogue client trop lent — appels séquentiels (27/07, corrigé)

Suite demandée par l'utilisateur : "après l'initialisation, vérifier la
suite". Le premier vrai écran qu'un client voit après le splash
(`catalog_tab.dart`, onglet Accueil) faisait **9 appels réseau à la
suite** dans `_loadData()` : un premier `Future.wait` (business_units +
products + profil, déjà parallèle), puis 5 blocs indépendants enchaînés
un par un — catégories désactivées, bannières hero, badge messages non
lus, fil d'activité "Pour vous" (lui-même 3 requêtes), suggestions de
réapprovisionnement (2 requêtes). Aucun de ces 5 blocs ne dépend du
résultat d'un autre, donc rien ne justifiait de les enchaîner
séquentiellement — sur une connexion 4G moyenne, ça pouvait ajouter
plusieurs secondes de chargement inutiles avant que l'Accueil ne
s'affiche.

Corrigé : chaque bloc est maintenant une fonction async avec son propre
try/catch (repli silencieux inchangé), et les 5 sont lancées ensemble via
un second `Future.wait` — le temps total redevient celui du bloc le plus
lent, pas la somme de tous.

## Démarrage app bloqué avant le premier écran (27/07, corrigé)

L'utilisateur a demandé une vérification du "loading" de l'app. Trouvé un
vrai problème dans `main.dart` : `PushNotificationService.initialize()`
était `await`é **avant** `runApp()`. Cette initialisation inclut
`messaging.requestPermission(...)` côté Firebase, qui affiche la popup
système de demande d'autorisation de notifications — donc au premier
lancement, l'utilisateur voyait un écran blanc suivi directement de cette
popup système, **avant même le logo AkoraHub**. Tant qu'il n'y répondait
pas, rien d'autre ne s'affichait (`runApp()` n'avait pas encore été
appelé). Corrigé : l'appel n'est plus `await`é, l'app s'affiche
immédiatement et les notifications s'initialisent en arrière-plan une
fois l'UI déjà visible.

Au passage : commentaire de doc périmé sur `splash_screen.dart` corrigé
(décrivait encore les 4 fausses étapes d'initialisation supprimées le
23/07 — voir plus bas "Bug de build résolu"), et les derniers textes
anglais du splash (tagline, "Loading...", "Retry"...) traduits en
français.

## Redesign écran Profil client — style Facebook centré (25/07)

Demande explicite de l'utilisateur : reproduire la mise en page d'un
profil Facebook mobile (photo de couverture, avatar centré chevauchant,
identité/bio/localisation centrées, boutons d'action centrés, onglets
centrés), mais **adaptée aux vraies données** plutôt que de fabriquer des
sections Facebook sans base réelle (pas de système d'amis, pas de
stories "à la une", pas de table centres d'intérêt/loisirs dans ce
projet — décision actée avec l'utilisateur avant de coder, pour éviter
de recréer le genre de "fonctionnalité bidon" qu'on a nettoyé plus tôt
dans le projet).

**Table `profiles`** : 2 nouveaux champs (`supabase/phase20_patch_profile_bio_cover.sql`,
**exécuté avec succès par l'utilisateur le 30/07**) : `bio text`, `cover_url text`. Pas
de nouveau bucket Storage — la photo de couverture réutilise le bucket
`avatars` existant, juste un nom de fichier différent
(`${userId}/cover_*.jpg`), déjà couvert par la policy actuelle (dossier
= `auth.uid()`).

**`lib/presentation/client_home/profile_tab.dart`** entièrement réécrit
(`ProfileTab` passé en `ConsumerStatefulWidget` pour lire
`favoritesProvider`) :
- Cover + avatar en `Stack` chevauchant, chacun tapable → upload immédiat
  (repli tolérant si la migration n'est pas encore exécutée : le reste du
  profil continue de fonctionner, juste un SnackBar d'erreur)
- Nom, "X publications · Client depuis {année}" (remplace "X amis"),
  bio (ou bouton "+ Ajouter une bio"), localisation — tout centré
- Boutons centrés : "Modifier le profil" (sheet existante, augmentée du
  champ bio) + "Partager" (`share_plus`, partage une carte de contact
  textuelle nom/société/téléphone — pas de lien, l'app n'a pas de page
  profil web publique)
- Sélecteur d'onglets centré (Tout / Publications / Favoris) via
  `ChoiceChip`, pas de vrai `TabBarView` (évite le problème classique de
  hauteur imbriquée dans un `ListView`)
- Onglet "Tout" : Informations personnelles (email/société/téléphone/
  localisation, toutes réelles) + **"Catégories favorites"** — remplace
  Loisirs/Centres d'intérêt Facebook, calculé en interrogeant `products`
  pour les ids de `favoritesProvider` et en dédupliquant `category` ;
  section actions préservée à l'identique (Commandes récurrentes,
  Fidélité, Messagerie, Langue, Scanner produit, Mode sombre,
  Déconnexion — rien perdu du screen précédent)
- Onglets "Publications"/"Favoris" : aperçu (3 posts / 4 produits) avec
  bouton "Voir tout" vers `WallTab(initialOnlyMine: true)` /
  `FavoritesScreen` — pas d'embed direct (ces deux écrans ont leur propre
  `Scaffold`/`AppBar`, non conçus pour être imbriqués)

**Sections Facebook volontairement absentes** (pas de table, pas
fabriquées) : Amis (grille + "amis en commun"), À la une (stories),
Loisirs (tags génériques), Centres d'intérêt (vignettes films/séries),
bannière "profil verrouillé". Si l'utilisateur veut un vrai système
d'amis ou des stories un jour, ça mérite sa propre conversation (modèle
de données, écrans de demandes d'ami) — pas à fabriquer avec de fausses
données dans ce redesign.

**Terminé (30/07)** : `phase20_patch_profile_bio_cover.sql` exécuté avec
succès — bio et couverture se sauvegardent bien.

## 3septies. Menu Admin "Plus" (25/07)

Amélioration proposée dès le début de nos échanges backend, jamais faite
jusqu'ici : Facturation/Alertes/Piliers d'entreprise/Équipe & rôles/
Bannière hero n'étaient accessibles QUE depuis le bottom sheet "+" de
création rapide du dashboard — sémantiquement bizarre (gérer les piliers
n'est pas "créer quelque chose de nouveau"), et l'onglet "More" de la
barre de navigation menait directement au Profil entreprise sans jamais
montrer ces sections.

Nouvel écran `lib/presentation/more_menu/more_menu_screen.dart`,
maintenant la destination de l'onglet "More" : liste organisée par
section (Gestion : Commandes/Devis/Facturation/Alertes/Messagerie ;
Entreprise : Piliers/Équipe/Bannière/Profil entreprise ; Déconnexion avec
confirmation, même pattern que l'ancien emplacement dans Profil
entreprise).

Le bottom sheet "+" du dashboard est allégé pour ne garder que les vraies
créations rapides : Add Product, New Order, Devis, Add Customer.

## 3sexies. Écran "Profil entreprise" Admin réparé (25/07)

L'utilisateur a signalé que cet écran "ne fonctionne pas". Audit du code :
**aucun champ ne persistait réellement ses modifications**, sur les deux
fichiers `business_information_section.dart` et
`contact_details_section.dart` — un bug systémique du scaffold initial
jamais corrigé : chaque `TextFormField` utilisait `onChanged: (value) =>
widget.onChanged()`, qui prévient juste le parent qu'"il y a un
changement" (pour activer le bouton Enregistrer) SANS jamais écrire
`value` dans `widget.businessData`. Résultat : taper dans un champ semble
fonctionner, "Enregistrer" affiche même un succès, mais les anciennes
valeurs (vides) sont réenregistrées à chaque fois.

**Champs corrigés (écrivent maintenant vraiment dans `businessData`)** :
téléphone, email, site web, Facebook/Instagram/WhatsApp, adresse
(rue/ville/code postal/pays), nom d'entreprise et description (par
langue), catégorie d'activité.

**Bugs additionnels trouvés et corrigés au passage** :
- Les champs nom/description utilisaient `initialValue` sans `key` :
  changer d'onglet de langue (FR/MG/EN/AR) n'actualisait pas le texte
  affiché. Ajout de `key: ValueKey('champ_$_selectedLanguage')` pour
  forcer Flutter à recréer le champ à chaque changement de langue.
- Le Dropdown de catégorie utilisait `value:` (pas `initialValue:`) avec
  une valeur par défaut `""` qui ne correspond à aucun item de la liste →
  plantage `assert` au premier chargement de l'écran (tant que la
  catégorie n'a jamais été choisie). Passé en `initialValue:` avec repli
  sur `null` + `hint:` si la valeur ne correspond à aucun item.
- Interrupteur "jour fermé" (horaires d'ouverture) ne faisait rien non
  plus (même bug). `operatingHours` n'était même pas dans
  `_persistedKeys` du parent — ajouté.
- **Logo d'entreprise** : le bouton "changer le logo" ouvrait bien la
  galerie/caméra, mais un commentaire `// In real implementation, upload
  image and update businessData` révélait que la photo choisie n'était
  jamais uploadée ni sauvegardée. Ajout d'un vrai upload avec indicateur
  de chargement pendant l'envoi, `logo` ajouté à `_persistedKeys`.
  **Note (30/07)** : `supabase/phase11_patch_company_logo_bucket.sql`
  mentionné ici est en réalité un fichier **vide** — le vrai bucket a
  été créé plus tard sous un nom différent (`company-logo`, section
  3undecies, `phase15_schema.sql`, déjà exécuté avec succès). Fichier
  phase11 sans effet, à supprimer un jour par ménage.

**Non touché dans cette passe** : tous les textes de cet écran restent en
anglais ("Company Name", "Business Category"...) — signalé à l'utilisateur
comme amélioration possible, pas encore demandée. Le fichier
`subscription_section.dart` (407 lignes) existe dans le dossier mais
n'est importé nulle part — code mort, jamais affiché, pas touché.

## 3quinquies. Bug de build résolu (25/07) : version share_plus incompatible

Après l'ajout de "Réseau social client" (commit 35c3a9e), **tous les builds
GitHub Actions échouaient** (APK et AAB), du 23/07 au 25/07 — plusieurs
commits successifs (nettoyage Rocket.new, correctif onboarding, doc) ont
été poussés par-dessus sans que personne ne remarque que le build était
cassé depuis le commit du réseau social lui-même.

**Cause** : `pubspec.yaml` fixait `share_plus: ^10.1.4`, mais le code
utilisait l'API `SharePlus.instance.share(ShareParams(...))`, introduite
seulement en **share_plus v11+**. En v10.x, cette classe n'existe pas →
erreur de compilation `The getter 'SharePlus' isn't defined`.

**Correctif** : `share_plus` remonté à `^12.0.2` (dernière version stable
au moment du correctif). Build APK + AAB confirmés verts après correction.

**Leçon pour les prochaines sessions** : après avoir ajouté un nouveau
package à `pubspec.yaml`, vérifier que la contrainte de version choisie
correspond bien à l'API réellement utilisée dans le code (surtout pour un
package dont l'API a changé entre versions majeures) — et si possible,
attendre la confirmation d'un build GitHub Actions vert avant d'enchaîner
plusieurs commits par-dessus, pour repérer une régression tout de suite
plutôt que plusieurs commits plus tard.

## 3quater. Nettoyage traces Rocket.new (23/07, fait)

L'utilisateur a demandé une vérification complète des traces de
Rocket.new (l'outil qui a généré le scaffold initial du projet — voir
section 1). Trouvé et corrigé :
- `web/index.html` : script de tracking `static.rocket.new/rocket-shot.js`
  retiré (chargeait en direct chez chaque utilisateur de la version web).
- **Onboarding** (`onboarding_flow.dart` +
  `widgets/onboarding_page_widget.dart`, premier écran vu par tout
  nouveau client, vraiment utilisé — voir `splash_screen.dart` qui y
  redirige) : les 5 pages chargeaient des images externes (4 depuis
  `img.rocket.new`, 1 depuis Unsplash) — remplacées par une illustration
  à base d'icône sur fond dégradé, sans dépendance à un CDN externe.
- `lib/presentation/campaign_management/` **supprimé entièrement** :
  écran orphelin (aucune route, aucune navigation vers lui nulle part
  dans le code — vérifié), données 100% fictives en anglais ("Summer
  Sale 2025", "VIP Customer Exclusive", stats inventées), 2 images
  `img.rocket.new`. Reliquat de maquette jamais branché à une vraie
  fonctionnalité.

**Confirmé sans trace** : nom du package (`com.akora_fanadiovana.app`),
label affiché de l'app ("AkoraHub"), métadonnées Android/iOS. Seul faux
positif ignoré : `custom_icon_widget.dart` mappe `'rocket'`/
`'rocket_launch'` vers les icônes fusée standard de Flutter (aucun
rapport avec Rocket.new).

**Repéré et corrigé au passage** : le texte de la 5ᵉ page d'onboarding
mentionnait "seulement \$5/mois" — prix en dollars et modèle d'abonnement
qui ne correspondait pas au modèle réel de l'app (vente de produits, pas
de SaaS par abonnement). Remplacé par un texte générique sur les outils
AkoraHub disponibles.

## 3bis. Suggestions d'amélioration côté client (évoquées, pas encore décidées)

Idées discutées avec l'utilisateur, à prioriser plus tard — aucune n'est
commencée sauf mention contraire :

- **Réapprovisionnement suggéré** (23/07, **fait**) — section "Vous
  recommandez souvent" sur l'Accueil (`catalog_tab.dart`, juste après la
  bannière), calculée dans `_loadData` : produits présents dans au moins 2
  commandes distinctes du client (`order_items` joint à `orders` filtré par
  `customer_id`, comptage par `product_id` sur des `order_id` distincts),
  triés par fréquence décroissante, 5 max. Cartes horizontales réutilisant
  `_ProductCard` (favoris + ajout rapide déjà intégrés). Masquée si le
  client n'a pas encore assez d'historique — aucune donnée inventée,
  tolérante à l'échec comme les autres sections de l'Accueil.
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
  discuté avec l'utilisateur) — 5 idées proposées, **toutes faites le
  23/07** (l'utilisateur a demandé de travailler aussi côté Admin en plus
  du Client pour ce chantier) :
  1. **Fil d'activité "Pour vous"** sur l'Accueil (`catalog_tab.dart`) :
     section horizontale mélangeant les 5 dernières publications
     publiques du Mur et les 5 derniers produits ajoutés, triés par date,
     masquée si vide/échec de chargement.
  2. **Badge de notification sur la cloche** : compte les messages non
     lus du staff (`messages.read_by_client = false`, schéma déjà
     existant en phase 8) ; tap ouvre une feuille récapitulative avec
     accès direct à la messagerie. **Correctif associé** :
     `chat_screen.dart` ne marquait jusque-là JAMAIS les messages du
     staff comme lus à l'ouverture — sans ce correctif le badge ne
     serait jamais redescendu à zéro.
  3. **Profils clients publics légers** : nouvelle vue SQL
     `public_profiles` (`supabase/phase9_patch_public_profiles.sql`,
     **exécuté avec succès par l'utilisateur le 25/07**), id/full_name/company_name/
     client_type/avatar_url uniquement) + `PublicProfilesRepo` +
     `PublicProfileScreen` (`client_home/community/`). **Bug réel
     corrigé au passage** : la RLS de `profiles` limite la lecture à sa
     propre ligne (`profiles_select_own_or_staff`, phase1), donc le Mur
     et les commentaires affichaient "Utilisateur" pour TOUT LE MONDE
     sauf soi-même depuis le début — `wall_tab.dart` utilise désormais
     la vue publique, auteur cliquable vers son profil.
  4. **Partage rapide** : package `share_plus` ajouté au `pubspec.yaml`,
     bouton sur chaque post du Mur et sur la fiche produit.
  5. **Tags/mentions produit dans les posts** : la colonne
     `posts.mentioned_product_id` existait déjà côté DB (phase 3) mais
     n'était pas utilisée côté app — ajout du sélecteur de produit dans
     le formulaire de publication et du tag cliquable dans les cartes du
     Mur.

  **Décision explicite de l'utilisateur (rappel)** : aucun nouvel onglet
  dans la barre de navigation pour tout ce chantier — tout se loge dans
  Accueil/Profil/le Mur existants.
- **Filtre de recherche avancé** sur le catalogue (prix, disponibilité,
  pilier) — au-delà des chips de catégorie actuelles
- **Localisation automatique** — Niveau 1 fait, Niveau 2 (coordonnées GPS
  précises) documenté ci-dessus dans la section Profil
- **Messagerie unifiée client ↔ équipe commerciale** (23/07) : une seule
  conversation par client (pas de séparation par pilier, décision
  utilisateur). **Résolu (23/07, Backend/Infra)** : deux implémentations
  avaient été construites en parallèle sans coordination ; celle de la
  session Client UX a été retenue comme référence (plus complète : notion
  de "Demande" via `is_request` — jamais visible par les autres clients,
  contrairement à un post du Mur — + mise à jour en temps réel via
  Supabase Realtime). La version Backend/Infra concurrente a été
  entièrement supprimée (`client_home/messaging/`, `phase6_schema.sql`,
  bouton redondant dans `profile_tab.dart`).
  - Schéma final : `supabase/phase8_patch_messaging.sql` — **déjà exécuté
    avec succès par l'utilisateur**. Tables `conversations`/`messages`
    avec colonnes `sender_role` ('client'/'staff'), `is_request`,
    `read_by_staff`/`read_by_client`.
  - Écran client : `client_home/chat_screen.dart` (branché dans
    `profile_tab.dart`).
  - Écran Admin : `messaging_center_real/` — **mis à jour (23/07,
    Backend/Infra)** pour insérer `sender_role: 'staff'` sur chaque
    réponse (obligatoire dans le schéma final, sans quoi l'insertion
    échouait).
  - Ancien écran fictif `messaging_center/` (595 lignes, faux contacts
    "Sarah Johnson" etc.) **supprimé entièrement**.
  - **Fait (23/07)** : badge de messages non lus dans la liste des
    conversations (`messaging_center_real.dart`, un aller-retour groupant
    tous les messages client non lus) ; messages du client marqués lus à
    l'ouverture du fil (ne l'était pas avant — même correctif que celui
    déjà fait côté client pour son propre badge) ; tag visuel "Demande"
    (`is_request`) affiché sur les bulles de message, même style que côté
    client.
  - **Reste à faire** : notification (push ou in-app) à l'arrivée d'un
    nouveau message.

## 3ter. Connexion/Inscription — améliorations (23/07, Backend/Infra) ✅ FAIT

- **"Mot de passe oublié ?"** : remplacé par un vrai envoi d'email de
  réinitialisation via `Supabase.auth.resetPasswordForEmail()` (dialogue
  de saisie d'email + confirmation d'envoi).
  **🐛 Bug découvert et corrigé le 31/07** : l'appel n'avait pas de
  `redirectTo` (contrairement à la connexion Google) — le lien de l'email
  retombait donc sur le "Site URL" par défaut du Dashboard Supabase
  (`localhost:3000`, jamais changé pour ce projet), inaccessible depuis un
  téléphone (`ERR_CONNECTION_REFUSED`). Corrigé : `redirectTo:
  'io.supabase.akorahub://login-callback/'` (même schéma que l'OAuth) +
  nouvel écran `reset_password_screen.dart` (nouveau mot de passe +
  confirmation, `auth.updateUser`) poussé par `GlobalAuthListener` sur
  `AuthChangeEvent.passwordRecovery`. **⚠️ Reste à faire côté Dashboard** :
  ajouter `io.supabase.akorahub://login-callback/` à la liste blanche
  Authentication → URL Configuration → Redirect URLs (sinon Supabase
  refuse le `redirectTo` et retombe silencieusement sur `localhost:3000`
  comme avant).
- **Connexion Google/Facebook** : toujours des boutons non fonctionnels
  (nécessiteraient la création de comptes développeur Google Cloud/Meta,
  démarche externe hors périmètre code), mais le message au clic est
  maintenant honnête ("bientôt disponible") au lieu de laisser croire à
  une implémentation imminente.
- **Téléphone rendu obligatoire** à l'inscription, avec validation réelle
  des préfixes malgaches (Telma 034/038, Orange 032, Yas ex-Airtel 033,
  tolère le +261).
- **Confirmation du mot de passe** ajoutée + bouton afficher/masquer sur
  le champ mot de passe (`registration_screen.dart`).
- **Vérification anti-fraude** (email/SMS/validation manuelle) : toujours
  **reporté**, décision utilisateur inchangée.

## 3sexies. Plan de lancement — objectif publication le mois prochain (25/07)

**Message pour la session Backend/Infra** : l'utilisateur veut publier
AkoraHub le mois prochain et demande qu'on cale un calendrier commun. Voici
les 4 blocages identifiés (session Client UX) lors d'un état des lieux
demandé par l'utilisateur — merci de confirmer la faisabilité de chacun
d'ici la date visée, ou de signaler si l'un d'eux doit repousser le
lancement.

1. **Écran de connexion — 1 bouton non fonctionnel** (périmètre
   Backend/Infra, voir section 3ter pour le détail) : "Mot de passe
   oublié ?" est **réglé** depuis le 31/07 (email + lien + écran de
   nouveau mot de passe, bout en bout) ; les boutons de connexion sociale
   Google/Facebook ne font toujours rien. **Recommandation si le temps
   manque** : au minimum masquer les boutons sociaux non fonctionnels
   plutôt que les laisser tromper l'utilisateur.
2. **Pré-requis techniques Google Play Store** (indépendant du code
   Flutter) : icône haute résolution (512×512), feature graphic
   (1024×500), politique de confidentialité (obligatoire — l'app demande
   géolocalisation + upload de photos), formulaire "Sécurité des données"
   du Play Store, vérification d'identité du compte développeur (à lancer
   tôt, le délai de traitement Google n'est pas instantané). Point
   technique déjà en règle : `compileSdk 36` dans `android/app/build.gradle`
   respecte déjà l'exigence Google Play 2026 (cible minimale actuelle
   Android 15/API 35, Android 16/API 36 obligatoire à partir du 31 août
   2026).
3. **Mode de paiement réel** — le plus gros morceau ouvert. Actuellement
   l'app ne prend aucun paiement réel (commande/devis seulement, voir
   section 4 : piste Papi.mg identifiée mais pas intégrée, statut
   marchand MVola de l'entreprise non confirmé). **Question à trancher
   avant tout calendrier** : lance-t-on avec un paiement à la livraison en
   attendant l'intégration Mobile Money, ou est-ce bloquant pour le
   lancement ?
4. **Identité visuelle** — **en grande partie fait (25/07)** : icône
   réelle créée et intégrée sur Android/iOS/Web (vert `#085041`, concept
   panier/lettre "A" — remplace l'ancien logo Flutter par défaut), thème
   de toute l'app aligné dessus (`lib/theme/app_theme.dart` : primaire
   vert `#085041`, secondaire marine `#0B2C64`, accent orange `#FE5905`,
   extraits par échantillonnage de pixels de l'icône réelle — l'ancienne
   palette navy/teal/or créait une incohérence avec l'icône). **Reste à
   faire** : splash screen (toujours l'écran de démarrage par défaut,
   pas de logo dessus), captures d'écran préparées pour la fiche Play
   Store, feature graphic (1024×500).

**Déjà livrés depuis (25/07)** : notifications push réelles (Firebase, voir
section correspondante), mode hors-ligne, multi-langue FR/MG
(infrastructure + premiers écrans), mode sombre. **⚠️ Correction (30/07)** :
cette liste mentionnait à tort une "remise livraison par palier de
fidélité" comme livrée — cette fonctionnalité a en réalité été **rejetée
explicitement par l'utilisateur** puis retirée du code (voir 3sexdecies,
"REJETÉE par l'utilisateur") ; l'écran Fidélité reste purement informatif
(paliers Bronze/Argent/Or affichés, sans avantage concret). **Reste non
bloquant pour le lancement** : FDS, e-learning, groupes professionnels —
voir section 3bis/4 pour le détail complet de chaque idée.

## 3septies. Écran Admin des devis manquant (25/07, Backend/Infra) ✅ FAIT

L'utilisateur a testé le parcours client (demande de devis) et n'a rien vu
apparaître côté Admin — **pas un bug, un écran jamais construit**. Ajout de
`quotes_management/quotes_management.dart` : liste des devis (filtrable par
statut), détail des articles demandés, réponse avec montant proposé +
changement de statut. Bouton "Devis" ajouté au tableau de bord Admin
(`business_dashboard.dart`), route `/quotes-management`. Au passage, staff
peut maintenant aussi marquer manuellement le statut de paiement d'une
commande (espèces/Mobile Money direct/facture 30j) depuis
`order_management_real.dart`, en attendant l'intégration Papi — décision
utilisateur : ne pas bloquer le développement des fonctionnalités en
attendant le dossier marchand.

**Mise à jour (25/07)** : la réponse à un devis n'est plus un aller simple
(un seul montant figé). Nouvelle table `quote_messages` (fil de
négociation par devis, schéma `supabase/phase11_schema.sql`, **exécuté
avec succès**) : le staff propose un montant + message depuis l'écran
Admin (nouveau `_QuoteThreadScreen`, ouvert en tapant un devis dans
`quotes_management.dart`), le client voit chaque proposition côté
`client_home/quote_thread_client.dart` (accessible en tapant une carte de
devis dans l'onglet Devis de `orders_tab.dart` — léger ajout coordonné,
juste un `InkWell` autour de la carte existante) et peut **Accepter**/
**Refuser** directement ou **reproposer un autre montant** avec un
message si le prix ne convient pas (repasse alors automatiquement le
devis en statut "En attente" pour signaler au staff qu'une réponse est
attendue).

## 3octies. Traçabilité QR code (25/07) ✅ FAIT

Suite à la question "quelles suggestions d'amélioration ?", ajout de la
traçabilité par QR code sur les lots de production (différenciateur fort
pour hôpitaux/hôtels, vu l'expertise réelle de l'utilisateur sur les
normes BNM) :
- Packages `qr_flutter` (génération) + `mobile_scanner` (lecture caméra)
  ajoutés au `pubspec.yaml`. Permissions caméra ajoutées (Android
  `CAMERA`, iOS `NSCameraUsageDescription`).
- **Admin** : `product_management_real/batch_list_screen.dart` — remplace
  l'ancien comportement du menu "Lot" (qui ajoutait direct un lot sans
  jamais pouvoir les revoir) par une vraie liste des lots existants du
  produit, avec bouton QR code par lot (dialogue + partage via
  `share_plus`). La fonction `_addBatch` a été déplacée depuis
  `product_management_real.dart` vers ce nouvel écran (FAB "Lot").
- **Client** : `client_home/product_scanner_screen.dart`, accessible
  depuis "Scanner un produit" dans le Profil. Scanne le QR code (préfixe
  `akorahub:batch:` + id du lot, constante `qrBatchPrefix` exportée
  depuis `batch_list_screen.dart`), affiche le produit, la date de
  fabrication, la DLC (alerte visuelle rouge si expiré), la catégorie.
- **⚠️ RLS ouverte en lecture** : `production_batches` était
  strictement réservée au staff (`batches_staff_only`) depuis la Phase 1
  — il fallait ouvrir la lecture à tout utilisateur connecté pour que le
  scan client fonctionne, tout en gardant l'écriture réservée au staff.
  `supabase/phase13_schema.sql` — **exécuté avec succès par
  l'utilisateur**.

## 3nonies. Bug de build critique + maintenance (25/07)

En poussant la traçabilité QR, la compilation a échoué (APK **et** AAB) —
**mais le vrai coupable n'avait aucun rapport avec le QR code** : un
import manquant pour `RecurringOrdersScreen` dans `cart_tab.dart`
(fonctionnalité "commandes récurrentes" ajoutée avant la consolidation
des deux sessions, jamais testée en CI depuis). **Corrigé.**

**Leçon reconfirmée** : toujours attendre la confirmation d'un build vert
avant d'considérer une fonctionnalité "terminée" — un import manquant
peut dormir plusieurs commits avant d'être détecté si personne ne
déclenche de nouvelle compilation entre-temps.

Au passage, mise à jour préventive : Kotlin 2.1.0 → 2.2.20 (le log de
build avertissait que le support des versions plus anciennes serait
bientôt supprimé par Flutter).

**Découverte en cours de route** : le pipeline CI (`build-apk.yml`)
compile désormais aussi un **App Bundle (AAB)** en plus de l'APK, avec
reconstruction du keystore de production depuis les secrets GitHub — donc
la préparation technique pour la publication Play Store a déjà avancé
pendant la consolidation, au-delà de ce qui était documenté en section
3sexies (à vérifier/détailler dans une prochaine session si besoin).

## 3decies. Support code-barre existant en plus du QR code (25/07) ✅ FAIT

**⚠️ Note de priorité (25/07)** : le QR code par lot (Phase 13) a été
construit sur initiative de l'assistant (issu d'une liste de suggestions),
sans demande explicite préalable de l'utilisateur. Une fois interrogé
directement, **l'utilisateur a confirmé que ce n'est pas prioritaire**
pour son activité actuellement. Le code reste en place (fonctionnel,
inoffensif à laisser tel quel) mais **ne pas investir de temps
supplémentaire dessus** (pas de polish, pas de nouvelles fonctionnalités
liées au QR) sauf demande explicite future de l'utilisateur. Le
code-barre (ce paragraphe), lui, reste pertinent puisqu'il découle d'un
besoin réel signalé par l'utilisateur (ses produits en ont déjà).

L'utilisateur a signalé que tous ses produits finis ont déjà un vrai
code-barre EAN/UPC imprimé (fabrication) — décision : garder les deux
systèmes plutôt que de choisir. Le code-barre identifie le **produit**
(générique), le QR code (Phase 13) identifie un **lot précis** (avec date
de fabrication et DLC).
- `products.barcode` (text, nullable, unique si renseigné) —
  `supabase/phase14_schema.sql`, **exécuté avec succès par
  l'utilisateur**.
- Admin (`product_management_real.dart`) : champ "Code-barre" sur le
  formulaire produit, avec bouton scanner (nouvel écran interne
  `_BarcodeCaptureScreen`, réutilise `mobile_scanner`).
- Client (`product_scanner_screen.dart`) : `_onDetect` distingue
  maintenant les deux cas — préfixe `akorahub:batch:` → recherche dans
  `production_batches` (affiche fabrication/DLC) ; sinon → recherche dans
  `products.barcode` (affiche nom/catégorie/description, sans info de
  lot puisque le code-barre n'est pas lié à un lot précis).

## 3undecies. Factures/devis PDF côté client + logo entreprise réel (25/07) ✅ FAIT

Demande groupée de l'utilisateur (notifications push, hors-ligne,
multi-langue, PDF client) — 1er des 4 chantiers traité, dans cet ordre
convenu avec l'utilisateur : PDF client → multi-langue → hors-ligne →
notifications push (la dernière nécessite un compte Firebase externe,
traitée en dernier).

- **Bug réel corrigé au passage** : le sélecteur de logo dans "Profil
  entreprise" (`business_information_section.dart`) contenait un
  commentaire `// In real implementation, upload image and update
  businessData` — jamais implémenté, l'image choisie n'était jamais
  sauvegardée nulle part. Upload réel vers le nouveau bucket Storage
  `company-logo` (`supabase/phase15_schema.sql`, **exécuté avec succès
  par l'utilisateur**), URL persistée dans `company_settings` (ajout de
  `"logo"` à `_persistedKeys` dans `business_profile_settings.dart`).
- Nouveau `lib/core/pdf/document_pdf_generator.dart` : génère un PDF
  facture/devis avec logo + nom + adresse + téléphone de l'entreprise
  (lus dynamiquement depuis `company_settings`), items, total. Logo
  récupéré via `http.get` (package `http` ajouté au `pubspec.yaml`) et
  converti en `pw.MemoryImage` — si le logo ne charge pas, le PDF reste
  généré sans (tolérant à l'échec).
- Boutons "Facture PDF" / "Devis PDF" ajoutés sur chaque carte dans
  `client_home/orders_tab.dart` (`_OrdersListState._downloadInvoice` /
  `_QuotesListState._downloadQuotePdf`), ouverture via
  `Printing.layoutPdf` (aperçu + partage/impression natif).

## 3duodecies. Multi-langue FR/MG — infrastructure + 1er passage (25/07)

2ᵉ des 4 chantiers demandés (notifications push, hors-ligne, multi-langue,
PDF client — voir 3undecies pour le 1er). Pas de package `intl`/`.arb`
(trop lourd à greffer sur un projet déjà avancé de 60+ écrans) : système
maison par clé de traduction.

- `lib/core/localization/app_translations.dart` : table `_strings`
  (clé → {fr, mg}), `AppTranslations.t(key, locale)`, `localeProvider`
  (StateNotifierProvider persistant via SharedPreferences, clé
  `app_locale`), extension `WidgetRef.tr(key)`.
- Sélecteur de langue dans Profil (`profile_tab.dart`), dialogue simple
  Français/Malagasy.
- **Traduit à ce stade** : barre de navigation du bas
  (`client_home.dart`, `_ClientBottomNav` converti en `ConsumerWidget`),
  en-têtes de l'Accueil ("Nos activités", "Pour vous", "Produits"),
  recherche, filtre "Toutes catégories" (`catalog_tab.dart`).
- **Reste à faire (gros chantier, incrémental)** : la grande majorité des
  écrans (panier, fiche produit, commandes/devis, messagerie, favoris,
  mur, tout l'Admin...) reste uniquement en français codé en dur. Pour
  continuer : repérer les `Text('...')` littéraux écran par écran, ajouter
  les clés manquantes dans `_strings`, remplacer par `ref.tr('cle')`
  (nécessite `ConsumerWidget`/`ConsumerStatefulWidget` — convertir le
  widget si besoin, comme fait pour `_ClientBottomNav`).

**⚠️ Préférence explicite de l'utilisateur (25/07)** : ne PAS traduire
plusieurs écrans d'un coup ou par anticipation. Traduire **un seul écran
à la fois, uniquement sur demande explicite** de l'utilisateur nommant
l'écran concerné. Le premier passage ci-dessus (nav du bas + en-têtes
Accueil) a été fait avant cette clarification — ne pas continuer au-delà
sans qu'on le demande précisément.

## 3terdecies. Mode hors-ligne (25/07) ✅ FAIT

3ᵉ des 4 chantiers (voir 3undecies/3duodecies pour les précédents).
Portée volontairement réaliste — discutée et validée explicitement avec
l'utilisateur avant de coder (un mode hors-ligne complet type
"édition collaborative avec résolution de conflits" serait un chantier
de plusieurs semaines, hors de portée) :
- Catalogue consultable hors-ligne (lecture seule)
- Panier composable hors-ligne (déjà le cas nativement, Riverpod = état
  local, aucun réseau nécessaire pour ajouter au panier)
- Commande/devis en file d'attente locale si pas de réseau au moment de
  valider, **envoi automatique dès le retour de connexion**
- Bannière visuelle "Mode hors-ligne" quand il n'y a pas de réseau
- **Hors périmètre, assumé** : Mur, messagerie, devis en négociation
  restent en ligne uniquement (pas de sens hors-ligne) ; rien côté Admin
  (généralement utilisé au bureau avec Wi-Fi).

Détails techniques :
- `lib/core/offline/connectivity_provider.dart` : `connectivityProvider`
  (StreamProvider basé sur `connectivity_plus`, déjà présent au
  `pubspec.yaml`) + `isCurrentlyOnline()` pour une vérification ponctuelle.
- `lib/core/offline/offline_order_queue.dart` : `OfflineOrderQueue`,
  file d'attente en JSON via `SharedPreferences` (clé
  `offline_pending_orders`). `enqueue()` pour mettre en attente,
  `trySync()` pour tenter l'envoi de tout ce qui est en attente (chaque
  élément réussi est retiré, les échecs restent pour la prochaine
  tentative).
- `client_home/cart_tab.dart` (`_submit`) : vérifie `isCurrentlyOnline()`
  avant de tenter l'appel réseau — si hors-ligne, met directement en
  file d'attente au lieu d'échouer, vide quand même le panier, message
  clair à l'utilisateur.
- `client_home/client_home.dart` : `OfflineOrderQueue.trySync()` appelé
  à l'ouverture de l'app (`initState`) et à chaque transition hors-ligne
  → en ligne détectée via `connectivityProvider` (détection par
  comparaison avec l'état précédent, champ `_wasOnline`) ; bannière
  orange affichée en haut de l'écran quand `isOnline == false`.
- `client_home/catalog_tab.dart` (`_loadData`) : catalogue mis en cache
  (JSON, `SharedPreferences`, clé `offline_catalog_cache`) à chaque
  chargement réussi ; en cas d'échec réseau, repli automatique sur ce
  cache avec message indiquant la date des données affichées.
- **Reste à faire / limites connues** : pas de gestion de conflit (non
  nécessaire ici, chaque client ne crée que ses propres commandes) ; les
  photos produit ne sont pas mises en cache (seuls les champs texte/prix
  le sont — les images restent chargées à la demande via le réseau,
  échouent silencieusement si hors-ligne, ce qui est un compromis
  acceptable pour l'instant).

## 3quaterdecies. Notifications push réelles (25/07) ✅ FAIT — bout en bout

**✅ Chaîne complète fonctionnelle** : nouveau message (`messages` ou
`quote_messages`) → trigger Postgres (`pg_net`) → Edge Function
`send-push-notification` → API FCM → notification réelle sur l'appareil.
- Compte de service Firebase (`akorahub-7ee66-firebase-adminsdk-*.json`)
  stocké **uniquement** comme secret Edge Function
  `FIREBASE_SERVICE_ACCOUNT` (jamais commité, jamais dans l'app cliente —
  différent de `google-services.json` qui lui est public/embarqué dans
  l'app).
- `WEBHOOK_SECRET` (secret partagé, généré aléatoirement) protège l'URL
  publique de l'Edge Function contre des appels tiers.
- `supabase/functions/send-push-notification/index.ts` : signe lui-même
  un JWT RS256 (Web Crypto API native de Deno, aucune librairie externe)
  pour échanger le compte de service contre un token d'accès FCM, puis
  appelle `fcm.googleapis.com/v1/projects/{id}/messages:send`.
  - Message client → notifie **tout le staff** (Admin/Commercial) ayant
    un `fcm_token`.
  - Message staff → notifie le client concerné.
  - Réponse de devis (staff) → notifie le client, avec le montant proposé
    dans le corps de la notification si présent.
- `supabase/phase17_schema.sql` (**exécuté avec succès**) : trigger
  `AFTER INSERT` sur `messages`/`quote_messages`, appelle l'Edge Function
  via `net.http_post` (extension `pg_net`).
- Déployé via Supabase Dashboard → Edge Functions → éditeur navigateur
  (pas de CLI utilisée) — voir `functions/send-push-notification/index.ts`
  dans le dépôt pour le code source de référence si besoin de le
  redéployer.
- **✅ Fait (25/07)** : notifications étendues aux commandes
  (expédiée/livrée → notifie le client) et aux devis (accepté/refusé par
  le client → notifie toute l'équipe Admin/Commercial).
  `supabase/phase18_schema.sql` (**exécuté avec succès**) : triggers
  `AFTER UPDATE` avec clause `WHEN` sur `orders`/`quotes` — ne se
  déclenchent que sur un vrai changement vers l'un de ces statuts précis
  (pas à chaque modification, ex. changer juste le montant d'un devis ne
  déclenche rien). Edge Function mise à jour et redéployée avec succès
  pour gérer ces deux nouveaux types de payload.

`google-services.json` reçu de l'utilisateur (projet Firebase
`akorahub-7ee66`), intégré via secret GitHub
`GOOGLE_SERVICES_JSON_BASE64` (jamais commité en clair — voir
`.github/workflows/build-apk.yml`), plugin Gradle
`com.google.gms.google-services` (4.5.0) appliqué conditionnellement
dans `android/app/build.gradle` (uniquement si le fichier existe,
sécurité contre un build cassé si le secret venait à manquer). Fichier
gitignoré (`android/app/google-services.json`).

4ᵉ et dernier des chantiers demandés groupés (voir 3undecies/3duodecies/
3terdecies pour les précédents). Nécessite une action externe de
l'utilisateur (création d'un projet Firebase, gratuit) — infrastructure
client posée en attendant le fichier de config.

- Packages ajoutés : `firebase_core`, `firebase_messaging`,
  `flutter_local_notifications`.
- `supabase/phase16_schema.sql` : ajoute `profiles.fcm_token` — **statut
  d'exécution à confirmer par l'utilisateur**.
- `lib/core/notifications/push_notification_service.dart` :
  `initialize()` (appelé dans `main.dart` après `SupabaseConfig.initialize()`)
  demande la permission notifications, enregistre le token FCM de
  l'appareil dans `profiles.fcm_token`, affiche une notification locale
  si un message arrive pendant que l'app est ouverte (sinon Android/iOS
  l'affichent nativement). `onUserSignedIn()` appelé après connexion
  (`authentication_screen.dart`) et inscription
  (`registration_screen.dart`) pour ré-associer le token au bon compte.
  **Tout est protégé par try/catch** : sans `google-services.json`,
  `Firebase.initializeApp()` échoue silencieusement et l'app continue de
  fonctionner normalement (juste sans notifications) — aucun risque de
  casser le reste en attendant.
- **⚠️ Volontairement PAS FAIT à ce stade** : le plugin Gradle
  `com.google.gms.google-services` n'a pas été appliqué dans
  `android/build.gradle`/`android/app/build.gradle` — l'appliquer sans le
  fichier `google-services.json` présent ferait échouer TOUT build
  Android ("File google-services.json is missing"). À faire dès réception
  du fichier de l'utilisateur.
- **Reste à faire, dans l'ordre** :
  1. Recevoir `google-services.json` de l'utilisateur (guidé pas à pas :
     console Firebase → créer projet → ajouter app Android avec le
     package `com.akora_fanadiovana.app` → télécharger le fichier).
  2. L'ajouter au dépôt (`android/app/google-services.json`) — probablement
     comme secret GitHub encodé en base64 décodé pendant le build CI,
     même pattern que `env.json`/keystore, plutôt que commité en clair.
  3. Appliquer le plugin Gradle (`android/build.gradle` +
     `android/app/build.gradle`).
  4. **L'ENVOI réel des notifications reste un chantier séparé** : le
     service ci-dessus ne fait qu'ENREGISTRER l'appareil pour recevoir —
     il faut ensuite un déclencheur côté serveur (Supabase Database
     Webhook → Edge Function Deno → appel à l'API FCM HTTP v1 avec un
     compte de service Firebase) pour effectivement notifier un client
     ("nouveau message", "devis répondu", "commande expédiée"). Ce
     compte de service (clé privée JSON, différente de
     `google-services.json`) sera à générer depuis Firebase Console →
     Paramètres du projet → Comptes de service, une fois l'étape 1-3
     confirmée fonctionnelle.

## 3quindecies. Icône réelle de l'application (25/07) ✅ FAIT

Logo final (généré via ChatGPT après plusieurs itérations, voir
historique de conversation) intégré à la place de l'icône Flutter par
défaut : "A" vert `#085041` en dégradé transformé en chariot, 2 formes
géométriques (rectangle orange, cylindre bleu marine) à l'intérieur.
- **Android** : toutes les densités remplacées
  (`android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`).
  Pas d'icône adaptative (`mipmap-anydpi-v26`) sur ce projet — uniquement
  des PNG legacy par densité, donc pas de config supplémentaire
  nécessaire au-delà du remplacement des fichiers.
- **iOS** : les 15 tailles de `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
  remplacées (20x20 à 1024x1024).
- **Web** : `web/favicon.png` + `web/icons/Icon-{192,512}.png` et
  variantes "maskable" remplacées.
- `store_assets/play_store_icon_512.png` : version 512×512 conservée à
  part pour la future fiche Google Play Store (section 3sexies, point 2).
- Génération faite avec Pillow (redimensionnement direct depuis le PNG
  1254×1254 fourni par l'utilisateur, `Image.LANCZOS`) — pas de package
  `flutter_launcher_icons` utilisé (plus simple d'agir directement sur les
  fichiers pour un remplacement ponctuel).

## 3sexdecies. Inscription : date de naissance, conditions, lien connexion (25/07) ✅ FAIT

Suite à une demande de l'utilisateur de vérifier les informations
manquantes du formulaire d'inscription (`registration_screen.dart`) :

- **Date de naissance** : nouveau champ avec sélecteur natif
  (`showDatePicker`), obligatoire, avec vérification d'âge minimum 18 ans
  (`_validateBirthDate`) — justifié par la vente de produits chimiques/
  insecticides sur la plateforme. Stockée dans une nouvelle colonne
  `profiles.birth_date` (`supabase/phase19_patch_birth_date.sql`,
  **exécuté avec succès par l'utilisateur**).
- **Case "J'accepte les conditions d'utilisation et la politique de
  confidentialité"** : obligatoire pour créer un compte. **La page de
  politique de confidentialité elle-même reste à écrire/héberger** (voir
  plan de lancement, section 3sexies, point 2 — bloquant pour la
  publication Play Store).
- **Lien "Déjà un compte ? Se connecter"** sous le bouton d'inscription
  (`Navigator.pop`) — auparavant seul le bouton retour de l'AppBar
  permettait ce chemin.

**Note pour la suite** : l'utilisateur a envoyé par erreur une capture
d'écran de l'étape 6 du tutoriel de création de token GitHub (sans lien
avec l'inscription) en même temps que cette demande — probablement une
pièce jointe laissée par mégarde, sans conséquence sur le travail effectué.

## 3septdecies. Sélecteur de comptes récents à la connexion (25/07) ✅ FAIT

Demandé par l'utilisateur en référence à l'UX de sélection de profil de
Facebook (capture d'écran fournie). Implémenté avec une nuance de sécurité
volontaire :

- `authentication_screen/recent_accounts_store.dart` : stockage local
  (`shared_preferences`) des derniers comptes utilisés sur l'appareil
  (email, nom, avatar) — **jamais de mot de passe ni de jeton de session
  stocké**.
- Liste affichée au-dessus du formulaire de connexion (avatar + nom +
  email, bouton "Oublier ce compte"). Taper sur un compte pré-remplit
  l'email et bascule vers le formulaire — **le mot de passe reste
  toujours obligatoire**.
- **Différence assumée avec Facebook** : ce n'est PAS un vrai "1 tap, sans
  mot de passe". Un vrai switch instantané comme Facebook nécessiterait de
  garder plusieurs sessions Supabase actives en parallèle sur l'appareil
  (jetons de session stockés localement pour chaque compte) — plus
  complexe et plus sensible en sécurité (un jeton volé = accès direct sans
  mot de passe). Pas fait sans décision explicite de l'utilisateur ; à
  reconsidérer s'il confirme vouloir cette version plus poussée.

## 3duodevicies. Téléphone étranger accepté à l'inscription (26/07) ✅ FAIT

L'utilisateur a soulevé un vrai trou dans la validation : `_validatePhone`
n'acceptait QUE les préfixes malgaches (032/033/034/038), rejetant tout
client étranger (touriste, expatrié, hôtel à propriétaire étranger...).
Corrigé : accepte maintenant soit un numéro malgache valide, soit un
format international générique (commence par `+`, 8 à 14 chiffres), sans
validation précise par pays étranger. Indice de saisie mis à jour pour
mentionner le cas étranger (`+33...`).

## 3undevicies. Sélecteur d'indicatif pays, Nom/Prénom séparés, société obligatoire (26/07) ✅ FAIT

Trois demandes de l'utilisateur traitées ensemble sur l'inscription :

- **Sélecteur d'indicatif pays** (`intl_phone_field` package) : menu
  déroulant avec tous les indicatifs (drapeau + code), saisie manuelle
  toujours possible, Madagascar par défaut. La validation stricte par
  préfixe d'opérateur (Telma/Orange/Yas) ne s'applique que si "Madagascar"
  est sélectionné dans le menu ; sinon validation générique par longueur.
- **Nom/Prénom séparés** : le champ unique "Nom complet" devient deux
  champs côte à côte. Recombinés en `full_name` ("Prénom Nom") au moment
  de l'envoi — **aucun changement de schéma**, la logique existante de
  salutation "Bonjour, {prénom}" sur l'Accueil (`.split(' ').first`)
  continue de fonctionner sans modification.
- **Société rendue obligatoire** pour Hôtel/Hôpital/Entreprise (elle
  n'avait pas de validateur auparavant, malgré le champ affiché) ; ajoutée
  en option pour les Particuliers ("si vous achetez pour un compte
  professionnel"). **Confirmé à l'utilisateur** : `company_name` alimente
  déjà les factures PDF et devis générés (`invoicing/invoicing_screen.dart`,
  `quotes_management/quotes_management.dart`) — pas de travail
  supplémentaire nécessaire pour que ça apparaisse sur les documents.

## 3sexdecies. Remise fidélité sur la livraison — REJETÉE par l'utilisateur (25/07)

Une session Claude Code avait construit sur une branche séparée
(`claude/akorahub-project-context-9zk67o`, jamais fusionnée dans `main`)
une remise sur les frais de livraison selon le palier de fidélité
(Argent -50%, Or gratuite). **L'utilisateur a explicitement refusé cette
fonctionnalité** ("Je veux pas cette fonctionnalité pour le moment,
effacer le!") après l'avoir vue expliquée. La branche a été **supprimée
du dépôt GitHub** — le code n'existe donc plus nulle part. **Ne pas
reconstruire cette fonctionnalité sans demande explicite renouvelée de
l'utilisateur.**

## 3vicies. Formulaire d'inscription en 2 étapes (26/07) ✅ FAIT

`registration_screen.dart` réécrit en `PageView` à 2 pages (non
swipeable, boutons uniquement) avec barre de progression en haut :
- **Étape 1 — Identité** : secteur, nom, prénom, société, date de
  naissance. Validée (`_step1FormKey` + `_validateBirthDate`) avant de
  passer à l'étape 2 via "Suivant".
- **Étape 2 — Coordonnées** : email, téléphone (indicatif pays), mot de
  passe, confirmation, conditions. Bouton "Retour" revient à l'étape 1
  sans perdre les données déjà saisies (les contrôleurs persistent).
  La flèche retour de l'AppBar fait de même à l'étape 2, ou quitte l'écran
  à l'étape 1.
Aucun changement de logique métier — même validateurs, même appel
Supabase, uniquement la présentation.

## 3unvicies. Correctif thème : couleur "outline" trop pâle (26/07) ✅ FAIT

L'utilisateur a signalé que beaucoup de texte/icônes paraissaient "flou"
(l'étoile favoris, les libellés des piliers...). Diagnostic confirmé via
capture d'écran + lecture du thème : **pas un bug de police** (les icônes
Material ne dépendent pas de Google Fonts, donc si elles aussi paraissent
floues, la cause est ailleurs). Cause réelle trouvée dans
`lib/theme/app_theme.dart` : `colorScheme.outline` était réglé sur
`dividerLight`/`dividerDark` (`0xFFE5E7EB` / `0xFF374151`, commentées
"Minimal separation" — prévues pour de simples traits de séparation à
peine visibles), alors que ce rôle sémantique (Material 3) doit rester
lisible puisqu'il est utilisé pour des icônes/bordures visibles (étoile
non-favorite, icônes de piliers, tags...). Corrigé : `outline` utilise
maintenant `textSecondaryLight`/`textSecondaryDark` (gris moyen, déjà
utilisé pour le texte secondaire) ; `outlineVariant` récupère l'ancienne
couleur pâle, pour les vrais séparateurs discrets. **Un seul changement au
niveau du thème corrige d'un coup les 18 usages de
`colorScheme.outline`** repérés dans `client_home/` (favorites, catalog,
cart, orders, profile, product_detail, chat, loyalty) sans toucher
fichier par fichier.

## 3duodevicies. Panne CI — quota de MINUTES Actions épuisé, PAS résolu (28/07) ⚠️ BLOQUANT

**⚠️ Ceci bloque activement tous les builds — première chose à vérifier
dans une nouvelle session.**

Chronologie du diagnostic (deux fausses pistes avant la vraie cause) :
1. **1ère théorie (fausse piste partiellement utile)** : quota de
   **stockage** Actions dépassé (168 builds accumulés, 5,3 Go). Corrigé
   par une autre session (rétention réduite à 3 jours, nettoyage,
   suppression de la publication APK en plus de l'AAB) — stockage
   redescendu à 115 Mo. **N'a pas réglé le problème : les builds ont
   continué à échouer après ce correctif.**
2. **2ᵉ tentative** : remplacement du système de publication
   (`actions/upload-artifact`, limité à 500 Mo partagés sur tout le
   compte) par **GitHub Releases** (`softprops/action-gh-release@v2`,
   stockage séparé et bien plus généreux) — voir
   `.github/workflows/build-apk.yml`. Bonne pratique en soi (gardée),
   **mais n'a pas non plus réglé le problème**.
3. **Vraie cause identifiée (28/07)** : le job échoue en **2 secondes,
   sans exécuter aucune étape** (`"steps": []` dans l'API GitHub) — signature
   caractéristique d'un **quota de MINUTES Actions épuisé** (2000
   min/mois gratuites, partagées sur tout le compte GitHub, pas
   seulement ce dépôt), et non un problème de stockage. Confirmé par
   recherche : le message d'erreur typique dans ce cas est *"The job was
   not started because recent account payments have failed or your
   spending limit needs to be increased"*, et le correctif standard est
   de régler une **limite de dépenses ("Actions spending limit")** sur
   1-5 $ dans **github.com/settings/billing/summary** (ou
   `/settings/billing/budgets`) — même 1 $ suffit à débloquer les
   minutes gratuites restantes, sans que ce soit un abonnement récurrent
   (facturation à l'usage réel au-delà du gratuit, remise à 0 $ possible
   à tout moment).

**Mise à jour (30/07)** : l'utilisateur a essayé de régler la limite de
dépenses — **carte refusée par GitHub** (Orange Money prépayée). Le budget
de 5$ existe côté GitHub mais reste inopérant tant qu'aucun moyen de
paiement n'est accepté. **Décision** : ne pas s'acharner sur ce point —
on attend la **réinitialisation naturelle du quota de minutes gratuites,
prévue vers le 1er août** (cycle mensuel standard GitHub). Reconfirmé (via
l'API `actions/runs`) que le run déclenché par le commit `codemagic.yaml`
(30/07) échoue toujours avec la même signature (job de 2-3 secondes, aucun
runner assigné) — le quota n'est donc pas encore revenu au moment de ce
test.

**Solution de contournement en place et fonctionnelle** : **Codemagic**
(`codemagic.yaml` à la racine du dépôt, commit `e62a2de`) sert de CI
alternative pendant l'attente — **premier APK compilé avec succès**
confirmé par l'utilisateur (30/07). Config : recrée `env.json` et restaure
`google-services.json`/keystore de prod depuis les variables d'environnement
Codemagic (groupe `akorahub_secrets`, mêmes valeurs que les secrets GitHub
actuels), compile APK + AAB, notifie par email. Déclenchement automatique
sur chaque push vers `main` (comme le workflow GitHub Actions).

**Prochaine étape pour toute session qui reprend** : vérifier si on est
passé le 1er août — si oui, retester un push simple vers `main` et
consulter `actions/runs` pour voir si le job dépasse enfin "Set up job".
Si le quota est bien revenu, Codemagic peut rester en place comme CI de
secours (aucune raison de le retirer) ou être désactivé, au choix de
l'utilisateur.

## 3duovicies. Mode sombre (25/07) ✅ FAIT

**⚠️ Écart de documentation constaté** (même cause que la fidélité ci-dessus
avant sa suppression : une fonctionnalité fusionnée sur `main` sans jamais
être consignée ici). Commit `50590de`, toujours en place et fonctionnel
(contrairement à la remise fidélité livraison ci-dessus, celle-ci n'a pas
été remise en cause) :
- `lib/core/providers/theme_provider.dart` : `themeModeProvider`
  (StateNotifierProvider Riverpod), préférence clair/sombre/système
  persistée via `SharedPreferences` (clé `theme_mode`).
- Interrupteur ajouté à deux endroits : Profil client
  (`client_home/profile_tab.dart`) et paramètres Admin
  (`business_profile_settings/business_profile_settings.dart`).

## 3trevicies. Rupture de stock prévue — analytics prédictif (25/07) ✅ FAIT

**⚠️ Autre fonctionnalité retrouvée non documentée** (commit `f7143b6`,
toujours en place sur `main`). Étend les alertes existantes
(`alerts_center/alerts_center.dart`, Phase 1) avec une 3ᵉ section
**"Rupture prévue"**, au-dessus de "Stock bas" et "DLC proche" :
- Calcule la **vitesse de vente réelle des 30 derniers jours** par produit
  (somme des quantités dans `order_items` jointes à `orders.created_at`),
  divisée par 30 pour un rythme quotidien.
- Compare ce rythme au stock actuel (`stock_quantity`) pour estimer le
  nombre de jours restants avant rupture ; produits affichés si ce nombre
  est **≤ 14 jours**, triés du plus urgent au moins urgent.
- Estimation simple (moyenne linéaire sur 30 jours) — explicitement pas une
  vraie prévision statistique, mais suffisante pour une alerte utile à
  l'Admin. Aucune table/colonne supplémentaire nécessaire.

**Note méthodologique importante**, qui explique aussi comment la remise
fidélité ci-dessus a pu être reconstruite par erreur après son rejet : la
GitHub Action `changelog.yml` capture le message du dernier commit poussé
pour remplir `CHANGELOG.md`. Quand un commit de fonctionnalité est
immédiatement suivi d'un commit de fusion (deux pushes proches dans le
temps), c'est le message générique **"Merge branch 'main'..."** qui
atterrit dans le changelog — le vrai message disparaît silencieusement, et
une session qui ne lit que `CHANGELOG.md` (au lieu de ce document +
l'historique Git complet) peut manquer une fonctionnalité déjà construite
**ou déjà rejetée**. **À faire en début de session** : comparer
`git log --oneline` contre ce document, pas seulement lire
`CHANGELOG.md`.

## 3quatervicies. Suppression de compte self-service (30/07) ✅ FAIT

**⚠️ Encore une fonctionnalité retrouvée non documentée**, trouvée en
comparant l'arborescence du dépôt (`supabase/functions/delete-account/`)
contre ce document. Répond directement à une exigence du plan de
lancement (section 3sexies, point 2 — formulaire "Sécurité des données"
du Play Store, qui demande si les utilisateurs peuvent demander la
suppression de leurs données) :
- `supabase/functions/delete-account/index.ts` (Edge Function) : un
  client authentifié appelle cette fonction pour supprimer
  **définitivement et immédiatement** son propre compte. Nécessaire côté
  serveur car la clé `anon` d'un client ne peut ni supprimer sa ligne
  `auth.users` ni contourner les policies RLS — seule la
  `service_role_key` (disponible automatiquement dans toute Edge
  Function Supabase, aucun secret à configurer) le peut. Supprime
  explicitement la ligne `profiles` avant `auth.admin.deleteUser` (la
  plupart des tables liées — orders, quotes, favorites, conversations,
  posts — ont déjà un `on delete cascade` vers `profiles(id)`, mais la
  suppression explicite sert de filet de sécurité).
- Côté client (`client_home/profile_tab.dart`, `_confirmDeleteAccount`) :
  bouton "Supprimer mon compte" dans le Profil, dialogue de confirmation
  listant explicitement ce qui sera perdu (profil, commandes, devis,
  favoris, messages, publications), déconnexion + redirection vers
  l'écran de connexion une fois la suppression confirmée par le serveur.

## 3quinvicies. Nettoyage doublon pilier "Matières Premières" (30/07) ✅ FAIT

Bug réel trouvé (pas documenté) : deux sessions différentes ont créé le
pilier "Matières Premières" avec des slugs différents
(`matieres-premieres` vs `matieres-premieres-chimiques`), donc la
contrainte d'unicité sur le slug ne l'a pas détecté comme doublon.
`supabase/phase22_patch_cleanup_duplicate_pilier.sql` : garde le pilier
avec ses 12 catégories déjà attachées (`matieres-premieres`), migre vers
lui toute catégorie/produit qui aurait été accroché par erreur au
doublon (normalement rien), puis supprime le doublon vide. **Exécuté
avec succès par l'utilisateur le 30/07** — vérification finale confirme
une seule ligne "Matières Premières" (slug `matieres-premieres`, actif).

**Cause racine corrigée** (`business_units_management.dart`, `_slugify`) :
la fonction ne translittérait pas les accents avant de générer le slug —
"Matières Premières" créé deux fois à des moments différents (par deux
sessions) pouvait donc produire deux slugs différents et échapper à la
contrainte d'unicité. Ajout d'une table de translittération
accents→lettres simples (français/malgache) avant slugification —
empêche la récidive pour tout futur pilier/catégorie au nom accentué.

## 3sexvicies. Chat client : message tapé plus jamais perdu en cas d'échec (28/07) ✅ FAIT

Bug UX réel trouvé (pas documenté) dans `client_home/chat_screen.dart` :
le champ de saisie était vidé **avant** la tentative d'envoi réseau —
en cas d'échec (hors-ligne, RLS, etc.), le client perdait le message
tapé et devait tout retaper. Corrigé : le champ n'est vidé qu'après
confirmation du succès ; en cas d'échec, message d'erreur plus explicite
("vérifie ta connexion et réessaie") avec un bouton **"Réessayer"**
directement dans le SnackBar (rappelle `_send`, pas besoin de retaper).
Log technique (`debugPrint`) ajouté en cas d'échec pour diagnostiquer une
éventuelle récidive, jamais montré au client. **Cette récidive est
justement arrivée le lendemain — voir section suivante.**

## 3septvicies. Bug critique : messagerie 100% cassée — colonnes manquantes sur `messages` (30/07) ✅ CORRIGÉ ET CONFIRMÉ

**Signalé par l'utilisateur** : impossible d'envoyer un message côté
client, échec systématique (100% des tentatives) avec "Message non
envoyé — vérifie ta connexion et réessaie."

**Diagnostic** (requête de test dans une transaction annulée, exécutée
par l'utilisateur dans le SQL Editor) : erreur
`column "sender_role" of relation "messages" does not exist`.

**Cause racine** : conséquence directe du doublon de messagerie déjà
documenté en section 3bis. `phase6_schema.sql` (l'implémentation
"Backend/Infra" concurrente, depuis supprimée du dépôt) créait déjà
`public.messages`, mais **sans** les colonnes `sender_role`, `is_request`,
`read_by_staff`, `read_by_client` (juste `id, conversation_id, sender_id,
content, created_at, read_at`). Ce script a été exécuté sur ce projet
Supabase avant la consolidation. Plus tard, `phase8_patch_messaging.sql`
(l'implémentation retenue) a été exécuté à son tour — mais il utilise
`create table **if not exists** public.messages (...)` : comme la table
existait déjà (créée par phase6), cette instruction n'a **rien fait**,
et les 4 colonnes qu'il ajoute normalement ne sont jamais apparues. Le
code de l'app (et le trigger de notification push, Phase 17) suppose
depuis le début que ces colonnes existent — d'où l'échec à 100% dès le
premier message envoyé.

**Correctif prêt** : `supabase/phase23_patch_messages_missing_columns.sql`
— ajoute les 4 colonnes manquantes via `alter table ... add column if
not exists`, comble les lignes déjà existantes (`sender_role = 'client'`
par défaut, faute de mieux vu que l'ancien schéma ne distinguait pas
client/staff), puis réapplique la contrainte `not null` + le check
`sender_role in ('client','staff')`. **Exécuté et confirmé par
l'utilisateur (30/07)** : les 4 colonnes apparaissent bien désormais,
l'envoi de message côté client fonctionne, et le staff reçoit bien le
message côté Admin (`messaging_center_real/`).

**Leçon pour les prochaines sessions** : `create table if not exists`
est silencieux et trompeur en cas de schéma legacy conflictuel — quand
un script de "patch" ajoute des colonnes à une table qui pourrait déjà
exister sous une forme antérieure (cas fréquent ici vu l'historique de
sessions parallèles, section 7), préférer systématiquement `alter table
... add column if not exists` colonne par colonne, même pour un script
qui se veut "self-contained" avec sa propre `create table`.

## 3octovicies. Design chat client : ancrage en bas + regroupement des horodatages (30/07) ✅ FAIT

Suite au test réussi de la messagerie (section précédente), l'utilisateur
a demandé des suggestions de design côté client. Repéré sur capture
d'écran, deux corrections apportées à `client_home/chat_screen.dart` :
- **Ancrage en bas de l'écran** : la liste utilisait un `ListView`
  classique (haut → bas) avec un scroll forcé manuellement vers le bas
  au chargement (`addPostFrameCallback` + `jumpTo`) — avec peu de
  messages, ils "flottaient" en haut avec un grand vide en dessous au
  lieu de rester ancrés près du champ de saisie, contrairement à
  WhatsApp/Messenger/Telegram. Remplacé par le pattern standard
  `ListView.builder(reverse: true, ...)` (index 0 = message le plus
  récent, ancrage automatique en bas quel que soit le nombre de
  messages) — plus besoin du `ScrollController` manuel, supprimé.
- **Horodatage regroupé** : chaque bulle affichait son heure, y compris
  pour des messages consécutifs du même expéditeur envoyés à quelques
  secondes d'intervalle (répétitif). L'horodatage ne s'affiche
  maintenant que sur la **dernière bulle d'une série consécutive** du
  même expéditeur (`isLastOfGroup`, calculé en comparant `sender_role`
  avec le message chronologiquement suivant). Changement volontairement
  limité à l'affichage de l'horodatage (pas de modification des marges/
  espacement entre bulles) pour rester sur une correction à faible
  risque, non vérifiable visuellement dans cet environnement (pas de
  Flutter/émulateur installé — à confirmer par l'utilisateur en testant
  l'app réelle).

**Reste à faire, si l'utilisateur le demande** : audit du mode sombre
écran par écran (jamais revérifié depuis son ajout), micro-interactions
(ex: animation du badge panier à l'ajout).

## 3neuvicies. Sons de notification personnalisables par catégorie (30/07) ✅ FAIT (script exécuté, Edge Function redéployée)

Demande de l'utilisateur : pouvoir personnaliser le son des notifications
push, avec un choix laissé à **chaque utilisateur** (client ou staff),
séparément pour chaque catégorie de notification.

- **Catégories** (calquées sur les distinctions déjà faites par l'Edge
  Function `send-push-notification`) : `message` (chat client ↔ équipe),
  `devis` (réponse/négociation), `commande` (expédiée/livrée).
- **Réservoir de sons commun** (choix explicite de l'utilisateur, plutôt
  qu'une liste figée par catégorie) : `lib/core/notifications/notification_sounds.dart`
  (`kNotificationSounds`, `NotificationCategory`) — **20 sons** au total :
  - 15 générés mathématiquement par Claude (aucun droit d'auteur, voir
    plus haut dans la conversation) : 5 variantes par catégorie
    d'origine (`notif_message_*`, `notif_devis_*`, `notif_commande_*`),
    dont une variante "fun" par groupe (ludique, pas le style
    "inquiétant" un temps évoqué puis abandonné par l'utilisateur).
  - 5 sons "bulles/radar" fournis par l'utilisateur (Mixkit, licence
    libre sans attribution) : `notif_bulle_eau`, `notif_bulle_savon`,
    `notif_bulle_liquide`, `notif_bulles_profondes` (original 5,85s,
    raccourci à 1,3s — trop long pour une notification), `notif_radar`.
    Thématiquement cohérent avec la marque (Akora Fanadiovana = produits
    de nettoyage).
- **Fichiers son présents à DEUX endroits** (nécessaire, pas une
  duplication accidentelle) :
  1. `android/app/src/main/res/raw/*.wav` — requis par Android pour
     qu'un canal de notification puisse référencer le son par nom de
     ressource.
  2. `assets/*.wav` (racine du dossier `assets/`, pas de nouveau
     sous-dossier — respecte la règle du pubspec "ne pas ajouter de
     nouveau dossier d'assets") — requis pour l'aperçu audio jouable
     dans l'app via le package `audioplayers` (nouvelle dépendance).
- **Écran de sélection** : `client_home/notification_sounds_screen.dart`
  — une liste par catégorie, bouton ▶ pour prévisualiser chaque son
  avant de choisir, sélection sauvegardée immédiatement. Accessible
  depuis le Profil client (entrée "Sons de notification", à côté de
  "Messagerie") **et** depuis les paramètres Admin
  (`business_profile_settings.dart`, à côté de "Mode sombre") — le
  staff reçoit aussi des push (nouveau message client, devis accepté/
  refusé), donc doit pouvoir personnaliser son propre son.
- **Stockage** : `supabase/phase24_patch_notification_sound_prefs.sql`
  (**script prêt, pas encore exécuté**) — 3 colonnes
  `profiles.notification_sound_{message,devis,commande}`, défaut = les
  sons "classiques" d'origine.
- **Canaux Android** : un canal est **immuable une fois créé** (son figé
  pour toujours sur cet appareil) — d'où un canal par combinaison
  (catégorie, son choisi), nommé `akorahub_<catégorie>_<son>`
  (`androidChannelId()` côté Dart, dupliqué à l'identique côté Edge
  Function pour que les deux calculent le même nom). Créé/confirmé à 3
  moments : au démarrage de l'app (préférences en cache local ou
  défauts), à la connexion (resynchronisation depuis le serveur, utile
  si l'utilisateur a changé de préférence depuis un autre appareil), et
  immédiatement quand l'utilisateur choisit un son dans l'écran dédié.
- **`push_notification_service.dart`** entièrement retravaillé : cache
  local des 3 préférences (`SharedPreferences`, lecture rapide sans
  aller-retour réseau à chaque notification reçue en premier plan),
  `getSoundPreference()`/`setSoundPreference()` exposés pour l'écran de
  sélection, `ensureAndroidChannel()` pour la création de canal.
- **Edge Function mise à jour** (`send-push-notification/index.ts`) :
  détermine la catégorie selon la table qui a déclenché l'appel, lit la
  préférence de son du **destinataire** (`notification_sound_<catégorie>`,
  repli sur le son par défaut si colonne vide/migration pas encore
  faite), et l'inclut dans l'appel FCM (`android.notification.channel_id`
  + `sound`, `apns.payload.aps.sound` pour iOS, `data.category` pour que
  l'app sache quel canal utiliser si la notification arrive pendant que
  l'app est ouverte au premier plan).

**Terminé (30/07)** : script `phase24` exécuté avec succès, Edge Function
redéployée avec le nouveau code. Fusionné sur `main`, nouveau build
Codemagic déclenché. Reste à tester en conditions réelles (choisir un
son différent par catégorie, recevoir une vraie notification).

## 3trentecies. Nettoyage "App Preferences" factice — écran Profil entreprise Admin (30/07) ✅ FAIT

L'utilisateur a signalé que le bas de l'écran "Business Profile" (Admin)
"n'a pas fonctionné". Diagnostic : contrairement au haut de l'écran
(Informations, Identité visuelle, Contact — réparés en 3sexies), le bloc
**"App Preferences"** (`widgets/app_preferences_section.dart`) était un
reste de maquette Rocket.new **jamais connecté à rien de réel** :
- Sélecteur de langue : état local factice, sans rapport avec le vrai
  système de langue (`localeProvider`) déjà utilisé côté client — un
  doublon fantôme qui affichait un SnackBar de confirmation sans effet
  réel.
- Toggles Notifications (Orders/Messages/Promotions/Analytics) et
  Confidentialité (Show Phone/Email/Address) : la clé `"preferences"`
  n'était **même pas dans `_persistedKeys`** — jamais sauvegardée, même
  en appuyant sur "Save". Vérifié en plus : **aucun autre endroit du
  code ne lit ces valeurs**, donc même sauvegardées elles ne changeraient
  rien de réel.
- 4 boutons (Data & Storage/Security/Help & Support/About) : `onTap`
  littéralement vide (juste un commentaire `// Navigate to...`).

**Corrigé** : widget `app_preferences_section.dart` supprimé
entièrement (mort, plus aucune référence). Remplacé par le **vrai**
sélecteur de langue (même `localeProvider` que côté client, cohérent
avec le reste de l'app). Les toggles Notifications/Confidentialité et
les 4 boutons morts retirés — pas reconstruits "pour de vrai" (aurait
demandé un vrai système d'activation par catégorie, un vrai flux de
sécurité, un vrai centre d'aide : hors du périmètre demandé). Clé
`"preferences"` retirée de `_businessData` (plus utilisée nulle part).
**Décision explicite de l'utilisateur** : supprimer le factice plutôt
que de tout reconstruire pour de vrai.

## 3untrentecies. Suivi de livraison — Google Maps (30/07) ✅ FAIT

Demande de l'utilisateur : intégration Google Maps pour le suivi de
livraison — le staff indique la position du livreur, le client voit un
itinéraire sur la carte. Portée délibérément simple, discutée avant de
coder :
- **Position du livreur : mise à jour manuelle**, pas de suivi GPS
  continu (décision utilisateur — plus simple, pas de service en
  arrière-plan, pas de consommation batterie/données, pas de question de
  vie privée du livreur type Uber/Yango).
- **Ligne directe entre le livreur et l'adresse**, pas un itinéraire
  routier réel — évite l'API Directions payante (au-delà d'un crédit
  gratuit mensuel), cohérent avec le calcul de distance à vol d'oiseau
  déjà utilisé pour les frais de livraison (`delivery_pricing.dart`).
- Le **Maps SDK Android/iOS lui-même est gratuit et illimité** (contrairement
  à l'API JavaScript web) — mais nécessite quand même un projet Google
  Cloud avec la facturation activée (carte bancaire enregistrée) pour
  obtenir une clé API. **Contrairement à GitHub, la carte de l'utilisateur
  a été acceptée sans problème** par Google Cloud Billing (30/07).

**Compte Google Cloud créé et configuré (30/07)** : projet dédié
`AkoraHub` (ID `akorahub-504010`), facturation activée, **Maps SDK for
Android** activé, clé API créée (nommée "AkoraHub Maps"), **restreinte à
cette seule API** (principe du moindre privilège — limite les dégâts en
cas de fuite, même si d'autres API venaient à être activées plus tard sur
ce projet). Pas de restriction par application Android pour l'instant
(nécessiterait l'empreinte SHA-1 du keystore de production — à faire
plus tard en durcissement si besoin, pas bloquant). Clé ajoutée comme
secret `MAPS_API_KEY` dans **GitHub Actions** et dans le groupe
**`akorahub_secrets`** sur **Codemagic**.

**Schéma** : `supabase/phase25_patch_orders_driver_position.sql`
(**exécuté avec succès par l'utilisateur le 30/07**) — 3 colonnes sur `orders` :
`driver_latitude`, `driver_longitude`, `driver_position_updated_at`.
Aucun changement RLS nécessaire (les policies existantes sur `orders`
couvrent déjà toutes les colonnes).

**Côté Admin** (`order_management_real.dart`) : dans le dialogue de
commande (déjà utilisé pour statut/paiement), nouvelle section "Position
du livreur" avec un bouton "Mettre à jour ma position maintenant"
(capture le GPS du staff via `geolocator`, sauvegarde immédiate —
indépendant du bouton "Mettre à jour" du reste du dialogue, pour que le
client voie la nouvelle position tout de suite même si le staff annule
le reste).

**Côté Client** : nouvel écran `client_home/delivery_tracking_screen.dart`
— carte avec marqueur livreur + marqueur adresse de livraison + ligne
pointillée entre les deux, horodatage relatif de la dernière mise à jour
("il y a X min"). Accessible via un bouton "Suivre sur la carte" sur
chaque commande au statut **Expédiée** (`orders_tab.dart`). Message
explicite si la position n'a pas encore été renseignée, plutôt qu'une
carte vide silencieuse.

**Infrastructure clé API** (package `google_maps_flutter` ajouté à
`pubspec.yaml`) : même pattern que le keystore de production — clé lue
depuis la variable d'environnement `MAPS_API_KEY` au moment du build
(`android/app/build.gradle`, `manifestPlaceholders`), injectée dans
`AndroidManifest.xml` (`com.google.android.geo.API_KEY`). **Build réussit
même sans clé** (chaîne vide par défaut) — la carte affiche juste un fond
gris tant qu'une vraie clé n'est pas fournie, aucun crash. iOS non câblé
(pas de pipeline CI iOS actif actuellement, voir section 5 — à faire le
jour où un build iOS est mis en place).

**Terminé (30/07)** : les 4 prérequis sont faits — projet Google Cloud +
facturation + clé API restreinte, secrets `MAPS_API_KEY` ajoutés
(GitHub + Codemagic), script `phase25` exécuté.

**Bug de build corrigé (30/07)** : le tout premier build Codemagic après
fusion a échoué — `Manifest merger failed`,
`Attribute application@name ... requires a placeholder substitution but
no value for <applicationName> is provided`. Cause : dans
`android/app/build.gradle`, `manifestPlaceholders = [mapsApiKey: ...]`
(affectation directe avec `=`) **remplace toute la map** au lieu de la
compléter — ça a effacé le placeholder `applicationName` que le plugin
Gradle de Flutter y ajoute déjà lui-même. Corrigé avec
`manifestPlaceholders.put("mapsApiKey", ...)`, qui ajoute la clé sans
toucher au reste. **Leçon** : ne jamais faire `manifestPlaceholders = [...]`
dans un projet Flutter — toujours `.put(...)` ou `+=`.

Fusionné sur `main`, nouveau build déclenché. Reste à tester en
conditions réelles (le staff met à jour sa position, le client vérifie
que la carte s'affiche avec les 2 marqueurs).

## 3duotrentecies. Écran "Paramètres" dédié — Client + Admin (30/07) ✅ FAIT

L'utilisateur a montré l'écran Paramètres de Telegram comme référence :
chez nous, ces réglages étaient éparpillés dans le menu du Profil (client)
et du Profil entreprise (Admin), sans écran dédié, et deux catégories
n'existaient pas du tout (Confidentialité/sécurité, Aide/support).

**Nouveau dossier `client_home/settings/`**, réutilisé à l'identique côté
Client et Admin (réglages personnels à l'utilisateur connecté, pas liés
à son rôle) :
- **`settings_screen.dart`** : écran principal — Notifications (→
  `NotificationSoundsScreen`, inchangé), Langue/Fiteny, Mode sombre
  (déplacés depuis le Profil, logique identique), puis 2 nouvelles
  entrées : Confidentialité et sécurité, Aide et support.
- **`security_settings_screen.dart`** (nouveau) :
  - **Changer le mot de passe** : formulaire (nouveau mot de passe +
    confirmation), `Supabase.auth.updateUser()` — fonctionne directement
    car l'utilisateur est déjà connecté, pas besoin de repasser par
    l'email de réinitialisation (`resetPasswordForEmail`, toujours en
    place par ailleurs pour le cas "mot de passe oublié" à la connexion).
  - **Supprimer mon compte** : logique **déplacée telle quelle** depuis
    `profile_tab.dart` (Edge Function `delete-account`, phase 30/07) —
    regroupée ici avec les autres réglages de sécurité plutôt que perdue
    au milieu du Profil.
- **`help_support_screen.dart`** (nouveau) :
  - **Contacter le support** → redirige vers la Messagerie déjà
    existante (pas de nouveau canal de support construit).
  - **FAQ** : 5 questions/réponses réelles sur le fonctionnement de l'app
    (suivi de commande, devis, fidélité, paiement à la livraison,
    contact équipe) — pas de contenu générique inventé.
  - **À propos** : `showAboutDialog` standard Flutter (nom, version,
    mention légale).

**Nettoyage au passage** : `profile_tab.dart` et
`business_profile_settings.dart` perdent leurs imports/état devenus
inutiles (`themeModeProvider`, `localeProvider`, `NotificationSoundsScreen`,
`_isDeleting`/`_confirmDeleteAccount`) — tout vit maintenant uniquement
dans `settings/`, une seule source de vérité au lieu de dupliquée entre
Client et Admin.

## 3tritrentecies. Flash infos (30/07) ✅ CODE PRÊT, SCRIPT SQL PAS ENCORE EXÉCUTÉ

Demande de l'utilisateur : annonces courtes affichées sur l'Accueil
client. Distinct de la bannière hero existante (`home_banners` — photo +
titre/sous-titre, carrousel) : ici du **texte seul**, pensé pour publier
une annonce en quelques secondes sans upload d'image (promo, rupture de
stock temporaire, nouveauté...).

**Décision de conception (recommandation validée)** : un **bandeau
compact** sur l'Accueil affichant la dernière annonce active, tapable
pour ouvrir l'historique complet — plutôt qu'un vrai bandeau défilant
animé (moins lisible, peu idiomatique sur mobile). Écriture réservée à
l'Admin, lecture publique des annonces actives (même modèle de
permissions que `home_banners`).

- **Schéma** : `supabase/phase26_patch_flash_infos.sql` (**script prêt,
  pas encore exécuté**) — table `flash_infos` (`message`, `active`,
  `created_by`, `created_at`), RLS identique à `home_banners`.
- **Admin** : nouvel écran `flash_infos_management.dart` — liste
  triée par date, bouton "Publier" (texte seul, 200 caractères max),
  interrupteur actif/inactif, suppression. Accessible depuis le menu
  "Plus" → section "Entreprise", à côté de "Bannière hero — Accueil".
- **Client** : bandeau compact inséré dans `catalog_tab.dart` (juste
  au-dessus de la barre de recherche), affiche la dernière annonce active
  uniquement si elle existe (rien affiché sinon — pas de bandeau vide).
  Tap → nouvel écran `client_home/flash_infos_screen.dart` avec
  l'historique complet des annonces actives.
- Chargement parallélisé avec les autres données de l'Accueil (même
  `Future.wait` que bannières/badge/activité/réappro), échec silencieux
  tolérant comme le reste de l'écran.

**Reste à faire** : exécuter `phase26_patch_flash_infos.sql` dans
Supabase avant que l'Admin puisse publier une première annonce.

## 3quatretrentecies. Badge manquant sur l'icône Messagerie de l'Accueil (30/07) ✅ FAIT

L'utilisateur a remarqué qu'aucun des 3 icônes de l'en-tête Accueil
(panier/messagerie/cloche) n'affichait de nombre. Vérification : le
badge existait déjà pour le **panier** (`cartCount`) et la **cloche**
(`_unreadMessagesCount`, messages non lus du staff) — juste invisibles
sur sa capture car aucun n'était `> 0` à ce moment (`isLabelVisible`).
**Vrai trou trouvé** : l'icône **messagerie** (bulle de chat) n'avait
**aucun badge**, alors que la cloche juste à côté compte déjà exactement
les mêmes messages non lus. Corrigé dans `catalog_tab.dart` : même
`Badge(label: '$_unreadMessagesCount', isLabelVisible: ... > 0)` ajouté
autour de l'icône bulle de chat — les 3 icônes sont maintenant cohérentes.

## 3quintrentecies. Nombre de messages non lus au tableau de bord Admin (30/07) ✅ FAIT

Suite au test utilisateur (capture d'écran : tableau de bord Admin affichait
"Messages : —"), deux trous trouvés par inspection directe du code :
- `metrics_cards_widget.dart` : la carte "Messages" affichait un `'—'`
  **codé en dur**, jamais reliée à une vraie requête.
- `business_dashboard.dart` : `GreetingHeaderWidget` était instancié
  **sans** passer `notificationCount` — la logique d'affichage du badge
  de la cloche était pourtant déjà correcte dans ce widget
  (`greeting_header_widget.dart`), juste jamais alimentée (défaut à 0
  silencieux).

Corrigé dans les deux fichiers avec le **même filtre** déjà utilisé par
`messaging_center_real.dart` (`sender_role='client'`, `read_by_staff=false`)
pour rester cohérent partout : carte "Messages" et badge de cloche du
tableau de bord Admin affichent maintenant le vrai nombre de messages
client non lus par le staff.

## 3sextrentecies. Notifications silencieuses — permission POST_NOTIFICATIONS manquante (30/07) ✅ FAIT

L'utilisateur a signalé après test réel : notifications sans son, et
aucun signe dans les icônes des deux côtés. Le trou de badges a été
traité en 3quatretrentecies/3quintrentecies. Pour le son : vérification
complète de la chaîne (fichiers `.wav` présents et nommés correctement
dans `android/app/src/main/res/raw/`, canaux Android créés avec le bon
son via `ensureAndroidChannel`, payload FCM correct côté
`send-push-notification/index.ts`) — tout était correct côté code.

**Vraie cause** : `AndroidManifest.xml` ne déclarait pas
`android.permission.POST_NOTIFICATIONS`, obligatoire depuis Android 13
(API 33). Sans cette déclaration, Android **bloque silencieusement
toute notification** (avec ou sans son) — la plupart des appareils de
test en 2026 tournent sous Android 13+.

- Ajout de `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
  dans `android/app/src/main/AndroidManifest.xml`.
- Ajout en complément d'un appel explicite
  `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`
  dans `push_notification_service.dart` (au cas où
  `FirebaseMessaging.requestPermission()` seul ne déclenche pas la
  demande sur certains appareils).

**Important pour le prochain test** : si l'app a déjà été installée sur
l'appareil de test avant ce correctif, **désinstaller complètement
l'app** avant de réinstaller le nouveau build — sinon Android peut avoir
mémorisé un refus de permission ou des canaux de notification déjà créés
sans son, et un simple "remplacer l'APK" ne suffit pas à réinitialiser
ni la permission ni les canaux (immuables une fois créés, voir
3neuvicies).

## 3septtrentecies. Modes de paiement manuels — virement bancaire + Mobile Money (30/07) ✅ FAIT

En attendant le dossier marchand (BNI P@y et/ou marchand Mobile Money,
toujours en cours — voir email envoyé à BNI), demande explicite de
l'utilisateur : proposer un mode de paiement manuel par virement/transfert
en plus du paiement à la livraison implicite existant. **Confirmé avec
l'utilisateur** : compte BNI utilisé est un **compte personnel** (pas
encore de compte professionnel), à traiter comme solution de pont
temporaire (risque CGU banque/fiscal si le volume grossit — signalé à
l'utilisateur) ; même logique pour les numéros Mobile Money personnels
(plafonds de transaction plus bas qu'un compte marchand).

- **Nouveau module partagé** `lib/core/payment/payment_methods.dart` :
  enum `PaymentMethod` (paiementLivraison/virementBancaire/orangeMoney/
  mvola/airtelMoney) avec `id` (valeur stockée en base), `label`, `icon`,
  et `instructions` (coordonnées réelles à afficher, fournies par
  l'utilisateur — RIB/IBAN BNI, ou numéro Mobile Money selon le mode).
- **Schéma** : `supabase/phase27_patch_orders_payment_method.sql` — colonne
  `orders.payment_method` (texte, défaut `paiement_livraison`, contrainte
  CHECK sur les 5 valeurs). **Exécuté avec succès par l'utilisateur (30/07).**
- **Client** (`cart_tab.dart`) : sélecteur visuel (avatars circulaires,
  voir 3neuftrentecies) sous le total, affichant les coordonnées de
  paiement (bancaire ou Mobile Money choisi) dans un encadré dès qu'un
  mode autre que "livraison" est sélectionné — texte sélectionnable pour
  copier-coller facilement. Valeur incluse dans la commande (insertion en
  ligne ET file d'attente hors-ligne). `orders_tab.dart` affiche aussi le
  mode choisi sur chaque commande du client.
- **Admin** (`order_management_real.dart`) : mode de paiement choisi par
  le client affiché en lecture seule dans la fiche commande (sous-titre de
  la liste + dialogue de mise à jour de statut), juste au-dessus du statut
  de paiement — le staff vérifie manuellement la réception (relevé
  bancaire/SMS opérateur) puis marque `payment_status = 'paye'` comme
  avant (aucun changement de ce mécanisme).
- **Coordonnées actuellement affichées** (fournies par l'utilisateur,
  30/07) :
  - Virement bancaire : BNI Madagascar, agence Analakely, titulaire
    ANDRINIRINA, IBAN `MG46 0000 5000 8175 0487 0000 141`, BIC `CLMDMGMG`.
  - Orange Money : 037 34 786 84 (ANDRINIRINA Julio).
  - Mvola : 034 08 746 96 (Akora Fanadiovana).
  - Airtel Money : 033 19 581 85 (ANDRINIRINA Julio).
- **Mise à jour (30/07, voir 3neuftrentecies)** : les vrais logos Orange
  Money/Mvola/Airtel Money sont finalement utilisés (fournis directement
  par l'utilisateur en fichiers image, récupérés d'une session parallèle
  lors de la réconciliation) — remplace l'icône générique initialement
  prévue par prudence droits d'auteur.

**Terminé (30/07)** : script exécuté avec succès par l'utilisateur.

## 3octotrentecies. Activation/désactivation de chaque mode de paiement par l'Admin (30/07) ✅ FAIT

Demande de l'utilisateur juste après l'ajout des modes manuels
(3septtrentecies) : pouvoir activer/désactiver chaque mode de paiement
depuis l'Admin (utile si un numéro Mobile Money personnel devient
temporairement indisponible, ou pour retirer les modes manuels une fois
un vrai paiement en ligne en place).

- **Schéma** : `supabase/phase28_patch_payment_method_settings.sql`
  (**exécuté avec succès par l'utilisateur, 30/07**) — table
  `payment_method_settings` (`method_id`, `enabled`), lecture publique,
  écriture réservée à l'Admin (même modèle que `home_banners`/
  `flash_infos`). Les 5 modes sont pré-remplis activés par défaut
  (`on conflict do nothing`, sans danger si rejoué).
- **Nouveau repo** `lib/core/payment/payment_method_settings_repo.dart` :
  `fetchEnabled()` (repli tolérant — tous les modes actifs si la table
  n'existe pas encore/hors-ligne, jamais de checkout bloqué) et
  `setEnabled()`.
- **Admin** : nouvel écran `payment_methods_management.dart` — un
  `Switch` par mode, garde-fou intégré (impossible de désactiver le
  dernier mode encore actif, message explicite à la place). Accessible
  depuis le menu "Plus" → section "Entreprise" → "Modes de paiement".
- **Client** (`cart_tab.dart`) : le sélecteur de paiement n'affiche
  désormais que les modes activés par l'Admin (chargés au `initState`, en
  parallèle de l'estimation de livraison) ; si le mode actuellement
  sélectionné vient d'être désactivé, bascule automatiquement sur le
  premier mode encore disponible.

**Terminé (30/07)** : script exécuté avec succès par l'utilisateur — les
2 modes de paiement (3septtrentecies/3octotrentecies) sont maintenant
pleinement fonctionnels côté serveur.

## 3neuftrentecies. Collision détectée avec une session parallèle — sélecteur de paiement (30/07) ✅ RÉCONCILIÉ

Une **autre conversation Claude**, travaillant en parallèle sur ce même
projet (voir section 7 — accès complet des deux côtés, risque de
collision connu), a construit **indépendamment** un premier sélecteur de
mode de paiement pendant que celui documenté ci-dessus
(3septtrentecies/3octotrentecies) était en cours ici. Poussée directement
sur `main` (commits `50fb383`..`384505f`), **jamais consignée dans ce
fichier** — retrouvée uniquement parce que l'utilisateur l'a signalée
avant qu'on ne fusionne notre propre travail, évitant ainsi d'écraser
l'un ou l'autre.

**Ce que l'autre session avait fait** : `lib/presentation/client_home/
payment_method.dart` (classe `PaymentMethod` limitée à 3 opérateurs
Mobile Money, sans paiement à la livraison ni virement bancaire) +
`payment_method_selector.dart` (jolis avatars circulaires cliquables avec
le **vrai logo** de chaque opérateur) + 3 fichiers images réels
(`assets/images/payment_{orange_money,mvola,airtel_money}.jpg`) +
intégration dans `cart_tab.dart` (validation bloquante si aucun mode
choisi). Pas de schéma serveur, pas de visibilité Admin, pas d'affichage
des coordonnées de paiement au client.

**Réconciliation retenue** (les deux systèmes ne pouvaient pas cohabiter
— même nom de classe `PaymentMethod`, même case de fusion `git merge`
dans `cart_tab.dart`) :
- Le système déjà construit ici (enum `core/payment/payment_methods.dart`,
  schéma `orders.payment_method` + `payment_method_settings`, activation
  Admin, affichage des coordonnées réelles, visibilité Admin/historique
  client) est conservé comme base — plus complet.
- **Récupéré de l'autre session** : les 3 fichiers logos réels (bon
  ajout, meilleur rendu que l'icône générique) et l'idée d'un sélecteur à
  avatars circulaires. `PaymentMethod` (enum) gagne un getter
  `logoAsset` (chemin d'image pour Orange Money/Mvola/Airtel Money,
  `null` pour paiement à la livraison/virement bancaire → icône
  générique en repli).
- Nouveau widget partagé `lib/core/payment/payment_method_selector.dart`
  (remplace celui de l'autre session, supprimé) : avatars circulaires
  pour les 5 modes, image réelle quand disponible, icône sinon. Utilisé
  à la fois dans `cart_tab.dart` et dans l'écran Admin
  `payment_methods_management.dart`.
- Fichiers de l'autre session supprimés car entièrement remplacés :
  `lib/presentation/client_home/payment_method.dart` et
  `payment_method_selector.dart` (le validation bloquante "choisissez un
  mode" a aussi été retirée — plus nécessaire, "Paiement à la livraison"
  reste toujours un choix par défaut valide).

**Rappel pour toute session qui reprend** : toujours lire ce fichier +
comparer `git log` avec `origin/main` avant de fusionner un travail en
cours — cette collision n'a été détectée que parce que l'utilisateur l'a
signalée manuellement, pas par une vérification automatique.

## 3dixtrentecies. Nettoyage des traces Rocket.new (30/07) ✅ FAIT

L'utilisateur a demandé une vérification qu'aucune trace de Rocket.new
(l'outil ayant servi à générer le squelette initial du projet) ne
subsiste. Audit complet du dépôt (grep `rocket`/`Rocket` sur tout le
code, package name, manifestes, ressources) :

- **Aucune trace dans l'APK Android lui-même** : `applicationId` déjà
  propre (`com.akora_fanadiovana.app`), icône/splash/écran "À propos"
  affichent déjà "AkoraHub"/"Akora Fanadiovana" (voir `help_support_screen.dart`).
- **`README.md`** : réécrit entièrement — c'était encore le gabarit
  générique de Rocket.new ("# Flutter", structure de dossiers inventée,
  crédit "Built with Rocket.new" en pied de page). Remplacé par un vrai
  README décrivant AkoraHub (contexte, prérequis, installation avec
  `env.json`, structure réelle du projet, renvoi vers
  `PROJECT_CONTEXT.md`).
- **Identifiant de bundle iOS** : `com.akora_fanadiovana.app.testProject`
  (suffixe générique hérité du gabarit) nettoyé en
  `com.akora_fanadiovana.app`, cohérent avec l'`applicationId` Android
  (`ios/Runner.xcodeproj/project.pbxproj`). N'affecte pas les builds
  Android, mais nécessaire avant toute publication iOS.
- Un commentaire de code anodin dans `onboarding_page_widget.dart`
  mentionnant d'anciennes images `img.rocket.new` déjà supprimées a été
  laissé tel quel — c'est une note historique sur une suppression déjà
  faite, pas une trace active.

## 3onziemetrentecies. Référence et preuve de paiement (30/07) ✅ FAIT

Suite au test du sélecteur de paiement (capture d'écran envoyée par
l'utilisateur, virement bancaire bien affiché avec les vraies
coordonnées), demande d'amélioration : aujourd'hui le staff doit deviner
manuellement quelle commande correspond à quel virement/transfert reçu.
Ajout d'un champ de référence + upload optionnel d'une capture d'écran de
transaction, pour les modes de paiement manuels (pas pour "paiement à la
livraison").

**Décision de conception (précisée par l'utilisateur après la première
implémentation)** : la **capture d'écran reste facultative** (upload
optionnel, le staff relance par message si besoin), mais la **référence
de paiement — ou le nom du kiosque si le client a payé via un agent
Mobile Money — est obligatoire** pour tout mode autre que "paiement à la
livraison". Validation bloquante côté client (`cart_tab.dart`) avant
envoi de la commande (en ligne et hors-ligne).

- **Schéma** : `supabase/phase29_patch_payment_proof.sql` (**exécuté avec
  succès par l'utilisateur, 30/07**) — colonnes `orders.payment_reference`
  (texte) et
  `orders.payment_proof_path` (chemin dans le bucket). Bucket **privé**
  `payment-proofs` (contrairement à `avatars`, public) : ce sont des
  documents financiers — RLS : le client ne peut lire/écrire que dans son
  propre dossier (`storage.foldername(name)[1] = auth.uid()`), le staff
  peut tout lire via `current_role_is_staff()`.
- **Client** (`cart_tab.dart`) : quand un mode autre que "livraison" est
  choisi, un champ **"Référence de paiement ou nom du kiosque *"**
  (obligatoire — bloque l'envoi de la commande si vide, message explicite)
  et un bouton "Joindre une capture" (facultatif, `image_picker`, aperçu +
  bouton retirer) apparaissent sous les coordonnées. Upload de la capture
  vers le bucket juste avant l'insertion de la commande (chemin
  `<user_id>/<order_number>.jpg`) ; repli tolérant si l'upload échoue
  (commande envoyée quand même, sans preuve jointe — la référence, elle,
  est déjà garantie présente). Hors-ligne : la référence texte part
  normalement dans la file d'attente, la capture ne peut pas être jointe
  (pas de réseau) — message explicite à l'utilisateur si une photo avait
  été sélectionnée. Ajout au passage d'un **bouton "copier"** sur
  l'encadré des coordonnées de paiement (`Clipboard.setData`).
- **Admin** (`order_management_real.dart`) : référence et bouton "Voir la
  capture de paiement" (URL signée temporaire, 1h) affichés dans la fiche
  commande ; icône trombone dans la liste si une preuve/référence existe.
  Nouveau filtre rapide **"Paiement à vérifier"** (`FilterChip`) : ne
  montre que les commandes en mode de paiement manuel pas encore marquées
  payées.

**Terminé (30/07)** : script exécuté avec succès par l'utilisateur — la
référence/preuve de paiement et le verrouillage du statut
(3douzetrentecies) sont maintenant pleinement fonctionnels côté serveur.

## 3douzetrentecies. Verrouillage du statut tant que le paiement manuel n'est pas confirmé (30/07) ✅ FAIT

Demande de l'utilisateur : le staff doit **vérifier le paiement puis
valider la commande** — pas l'inverse. Auparavant, rien n'empêchait de
faire passer une commande en virement/Mobile Money à "Expédiée" alors que
le paiement n'avait jamais été confirmé.

**Décision de conception (recommandation validée)** : pour les modes de
paiement manuels (tout sauf "paiement à la livraison"), le statut de la
commande reste **verrouillé sur "Reçue"/"Annulée"** tant que le paiement
n'est pas confirmé (`payment_status = 'paye'` ou `'facture_30j'`) —
"En préparation"/"Expédiée"/"Livrée" sont grisés.

- **`order_management_real.dart`** : le bloc paiement (mode, référence,
  capture) est remonté **en premier** dans le dialogue, avec un bandeau
  d'alerte "⚠ Paiement non confirmé" et un bouton dédié **"Confirmer le
  paiement reçu"** (raccourci qui sélectionne "Payée" dans le statut de
  paiement). Le bloc "Statut de la commande" apparaît ensuite, avec un
  message explicite ("Débloqué une fois le paiement confirmé ci-dessus")
  et les options non pertinentes désactivées (`onChanged: null`) tant que
  non confirmé. Rien ne change pour "paiement à la livraison" (jamais
  verrouillé) ni pour les commandes déjà marquées payées/facturées.

## 3treizetrentecies. Nouvelle icône Android poussée directement par l'utilisateur (30/07) ⚠️ INCOHÉRENCE ENTRE PLATEFORMES

Découverte lors d'un audit demandé par l'utilisateur : 5 commits
(`2d88033`..`65ef5dc`) poussés **directement sur `main` par l'utilisateur
lui-même** (pas une autre session Claude — auteur `Anju-codermad
<julioandrinirina95@gmail.com>`, vraisemblablement via l'interface web
GitHub), jamais documentés ici. Remplacent les 5 densités
`android/app/src/main/res/mipmap-*/ic_launcher.png` par un nouveau
design : lettre "A" verte conservée, mais le chariot à l'intérieur est
redessiné (silhouette de caddie vert avec 3 rectangles colorés inclinés
au-dessus, façon "produits" — voir discussion sur un nouveau logo dans
cette session) à la place de l'ancien chariot en "swoosh" + rectangle
orange + cylindre bleu marine (design de 3quindecies).

**⚠️ Résultat actuel : incohérence entre plateformes** — seul **Android**
a la nouvelle icône. **iOS** (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
et **Web** (`web/icons/`, `web/favicon.png`) affichent toujours
**l'ancien design**. Store assets (`store_assets/play_store_icon_512.png`)
également pas mis à jour.

**Reste à faire** : soit répliquer le nouveau design sur iOS/Web/store
assets pour la cohérence (demander à l'utilisateur le fichier source
haute résolution du nouveau caddie), soit revenir sciemment sur cette
décision si le changement Android n'était qu'un test.

## 3quatorzetrentecies. Écran de connexion : logo générique, faux boutons sociaux, "Se souvenir de moi" inactif (30/07) ✅ FAIT

L'utilisateur a signalé (capture d'écran de l'écran de connexion) que
plusieurs éléments ne fonctionnaient pas correctement. Audit du fichier +
corrections :

- **Logo générique au lieu de la vraie icône** (`app_logo_widget.dart`) :
  affichait une icône Material `business` (silhouette d'immeuble) dans un
  encadré coloré, pas le logo réel d'AkoraHub. Remplacé par la vraie
  icône de l'app (copie de `android/.../mipmap-xxxhdpi/ic_launcher.png`
  vers `assets/images/app_icon.png`, affichée via `Image.asset`).
- **"Professional Business Platform" en anglais**, incohérent avec le
  reste de l'écran en français — traduit en "Plateforme professionnelle".
- **Boutons Google/Facebook avec de mauvaises icônes** — trouvé en lisant
  le code : Google utilisait l'icône Material `g_translate` (Google
  *Traduction*, pas Google Sign-In) et Facebook utilisait un nom d'icône
  `'facebook'` qui **n'existe pas** dans la table d'icônes custom de
  l'app, tombant silencieusement sur l'icône de repli
  `Icons.help_outline` (point d'interrogation gris — exactement ce que
  montrait la capture d'écran). Les deux icônes trompeuses retirées ;
  boutons texte seul "Google"/"Facebook" (toujours des stubs honnêtes
  "bientôt disponible" au clic, décision déjà actée en 3ter — pas de
  changement sur ce point).
- **"Se souvenir de moi" ne faisait strictement rien** : la case à cocher
  changeait un état local (`_rememberMe`) jamais lu nulle part —
  l'ajout au carrousel "comptes récents" se faisait **systématiquement**
  à chaque connexion réussie, qu'elle soit cochée ou non. Corrigé :
  l'ajout aux comptes récents est maintenant conditionné à cette case
  (cochée par défaut, pour ne pas changer le comportement pratique
  existant ; utile à décocher sur un appareil partagé/public pour ne pas
  laisser le compte visible au prochain lancement).
- Au passage, suppression d'un fichier SVG mort et non lié
  (`assets/images/img_app_logo.svg`) : ce n'était pas un logo AkoraHub
  mais le **logo Firebase** (téléchargé depuis svgrepo.com, résidu du
  gabarit de départ), jamais référencé dans le code.

**Non traité, signalé mais pas corrigé** : le sélecteur de langue de cet
écran (FR/MG/EN/AR, `_currentLanguage`) est un système de traduction
**local à cet écran uniquement**, complètement séparé du système
d'internationalisation utilisé dans le reste de l'app
(`localeProvider`/`app_translations.dart`, FR/MG uniquement). Changer la
langue ici n'a aucun effet après la connexion. Incohérence
architecturale réelle, mais pas un "bug" au sens propre — à signaler à
l'utilisateur avant d'entreprendre une unification, gros chantier hors
du périmètre de cette demande.

## 3quinzetrentecies. Connexion Google réelle (30/07) ✅ FAIT, code Facebook ajouté le 31/07 (reste la config Meta)

Suite à 3quatorzetrentecies (nettoyage des faux boutons sociaux), demande
explicite de l'utilisateur : rendre la connexion Google réellement
fonctionnelle. Guidé pas à pas (captures d'écran successives) pour créer
les identifiants OAuth côté Google Cloud Console, en réutilisant le
projet "AkoraHub" déjà existant (créé pour la clé Maps).

- **Google Cloud Console** : écran de consentement OAuth configuré (type
  Externe), client OAuth 2.0 créé (type **Application Web** — c'est le
  bon type même pour une app mobile, Supabase gère la redirection),
  redirect URI = `https://lmnprtwelmmoiuygvgmf.supabase.co/auth/v1/callback`.
  **⚠️ L'app reste en mode "Testing"** côté Google — seuls les comptes
  Google ajoutés explicitement comme utilisateurs de test peuvent se
  connecter pour l'instant. Passage en production (pour que n'importe
  quel client puisse se connecter) **reste à faire**.
- **Supabase** (Authentication → Providers → Google) : Client ID + Client
  Secret renseignés, "Enable Sign in with Google" activé — confirmé
  ("Successfully updated settings").
- **Code** (`authentication_screen.dart`) : refactor important — la
  logique de succès de connexion (mémorisation du compte, association du
  token FCM, message de succès, routage vers l'accueil) était uniquement
  déclenchée après un `signInWithPassword` réussi. Extraite dans une
  nouvelle méthode `_onAuthenticated()`, déclenchée par une écoute
  `SupabaseConfig.client.auth.onAuthStateChange` (posée dans `initState`)
  sur l'évènement `AuthChangeEvent.signedIn` — **commune** aux connexions
  email ET OAuth, puisqu'une connexion Google se termine par une
  redirection externe qui ne repasse jamais par `_handleLogin()`.
  `_handleSocialLogin('google')` appelle désormais
  `SupabaseConfig.client.auth.signInWithOAuth(OAuthProvider.google,
  redirectTo: 'io.supabase.akorahub://login-callback/')` ; Facebook reste
  sur le message "bientôt disponible" en attendant sa propre
  configuration (Meta for Developers).
- **Redirection mobile (deep link)** : schéma personnalisé
  `io.supabase.akorahub` enregistré des deux côtés — nouvel
  intent-filter (`android:scheme="io.supabase.akorahub"`) dans
  `AndroidManifest.xml`, et `CFBundleURLTypes` correspondant dans
  `ios/Runner/Info.plist`. Doit être exactement identique au `redirectTo`
  dans le code Dart, sinon la redirection après connexion échoue.
- **Pas de nouveau code pour "capter" le retour du navigateur** :
  `supabase_flutter` (déjà en v2.8.0) écoute lui-même les deep links une
  fois le schéma enregistré côté natif — aucune configuration
  supplémentaire nécessaire.
- Vérifié au passage : `public.handle_new_user()` (trigger sur
  `auth.users`, phase1) crée déjà un profil `client` par défaut pour
  **tout** nouvel utilisateur, quel que soit le mode d'inscription — donc
  aucun risque qu'un premier login Google (sans passer par l'écran
  d'inscription) se retrouve sans ligne dans `profiles`.

**Reste à faire (31/07)** — l'utilisateur a demandé de rendre Google/Facebook
réellement fonctionnels avant publication (au lieu de masquer les boutons,
l'autre option proposée) :
1. **Code Facebook ajouté** (31/07) : `_handleSocialLogin()` gérait
   auparavant uniquement `'google'` (Facebook tombait toujours sur le
   message "bientôt disponible"). Refactor minimal — un `switch` mappe
   `'google'`/`'facebook'` vers `OAuthProvider.google`/`.facebook`, le
   reste de la fonction (déjà générique) est inchangé. Aucun SDK Facebook
   natif nécessaire : le flux passe par le navigateur externe + Supabase,
   comme Google.
2. **Reste à faire côté comptes externes** :
   - **Google** : passer l'app de "Testing" à "Production" dans Google
     Cloud Console (OAuth consent screen) pour que n'importe quel client
     puisse se connecter, pas seulement les testeurs ajoutés manuellement.
   - **Facebook** : créer une app Meta for Developers, produit "Facebook
     Login", Redirect URI = `https://lmnprtwelmmoiuygvgmf.supabase.co/auth/v1/callback`
     (même URI que Google), App ID + App Secret → Supabase (Authentication
     → Sign In/Providers → Facebook).
3. Tester les deux connexions de bout en bout sur un vrai build (déjà fait
   pour Google le 31/07 via `GlobalAuthListener`, voir section suivante ;
   Facebook reste à tester une fois configuré).

## 3seizetrentecies. Pièces jointes dans la messagerie — photo/vidéo/vocal/fichier (30/07) ✅ FAIT

Demande de l'utilisateur : pouvoir envoyer des photos/vidéos/fichiers et
des messages vocaux dans la messagerie (auparavant texte seul). Décisions
de conception validées par l'utilisateur :
- **Vocal** : maintenir le bouton micro pour enregistrer (style
  WhatsApp), relâcher pour envoyer.
- **Vidéo** : lecture **intégrée dans la bulle** de chat (pas juste une
  miniature qui ouvre le lecteur externe).
- **Périmètre** : disponible des **deux côtés**, client ET staff.

- **Schéma** : `supabase/phase30_patch_message_attachments.sql`
  (**exécuté avec succès par l'utilisateur, 30/07**) — `messages.content`
  devient nullable (un
  message peut être une pièce jointe seule, sans texte), + colonnes
  `attachment_url`, `attachment_type` (check : image/video/audio/file),
  `attachment_name`, `attachment_duration_ms`. Bucket **privé**
  `chat-attachments` (comme `payment-proofs`, pas comme `avatars`) : RLS
  basée sur le participant à la conversation (client propriétaire ou
  staff), chemin `chat-attachments/<conversation_id>/<fichier>`.
- **Nouveau module partagé** `lib/core/chat/` (utilisé par `chat_screen.dart`
  côté client ET `messaging_center_real.dart` côté staff — évite de dupliquer
  cette logique conséquente deux fois) :
  - `chat_attachment_service.dart` : upload vers le bucket + génération
    d'URL signée temporaire (1h) pour l'affichage.
  - `chat_attachment_bubble.dart` : rendu de la pièce jointe selon son
    type — image (tap → visionneuse plein écran avec zoom), vidéo (lecture
    intégrée via `video_player`, bouton play/pause superposé), audio
    (bouton play/pause + durée via `audioplayers`), fichier (icône + nom,
    tap → ouverture externe via `url_launcher`).
  - `chat_composer.dart` : barre de saisie complète — bouton "+"
    (bottom sheet Photo/Vidéo/Fichier via `image_picker`/`file_picker`),
    bouton micro/envoi qui bascule selon la présence de texte (micro si
    vide, envoi si texte tapé), enregistrement vocal par appui long
    (`record` package) avec minimum 0,8s (sinon message "trop court"),
    annulation possible pendant l'enregistrement.
- **Nouvelles dépendances** : `record`, `video_player`, `file_picker`,
  `url_launcher`, `path_provider`.
- **Permissions ajoutées** : `RECORD_AUDIO` (Android manifest),
  `NSMicrophoneUsageDescription` + `NSPhotoLibraryUsageDescription` (iOS
  Info.plist).

**Terminé (30/07)** : script exécuté avec succès. **Reste à faire** :
tester de bout en bout sur un vrai build (nouvelles permissions
natives — micro, galerie — pas testables en hot-reload).

**⚠️ Correctif build Codemagic (30/07)** : le premier build a échoué
(`Target kernel_snapshot_program failed`) — le package `record` épinglé
en `^5.x` laissait `pub` résoudre `record_platform_interface` jusqu'à sa
version 1.6.0, plus récente que ce que l'implémentation Dart embarquée
dans `record` 5.x avait été écrite pour gérer (ajout d'un paramètre
`recorderId` à `hasPermission` pour le support multi-enregistreur) —
un vrai décalage de versions entre deux paquets de la même famille, pas
une erreur dans notre code. Recherché sur pub.dev (historique des
versions + changelogs) pour confirmer : `record` **6.2.1** est la
dernière version compatible avec le SDK Dart du projet (`^3.6.0` — la 7.x
exige `^3.12.0`) dont la contrainte propre sur `record_platform_interface`
(`^1.6.0`) ne laisse aucune place à ce décalage (seule la 1.6.0 la
satisfait). Épinglé en version exacte (`record: 6.2.1`, pas de `^`) pour
empêcher toute résolution future vers une version cassée. API publique
(`AudioRecorder`, `hasPermission()`, `start()`, `stop()`) vérifiée
identique — aucun changement de code nécessaire.

## 3dixseptrentecies. Animations — 1ère étape : Hero catalogue/favoris → fiche produit (30/07) ✅ FAIT

Demande de l'utilisateur : ajouter des animations dans l'app ("comme la
photo hero"), à faire **étape par étape**. Première étape choisie
(recommandation validée) : une animation **Hero** Flutter (transition
d'élément partagé) sur l'image produit, entre les vignettes (catalogue,
favoris) et l'ouverture de la fiche produit — parcours le plus fréquent
de l'app. **Première utilisation de `Hero` dans tout le projet** (aucun
autre écran n'en avait avant).

- **Sources** : `_ProductCard` dans `catalog_tab.dart` (grille catalogue
  + section "Vous recommandez souvent") et `_FavoriteCard` dans
  `favorites_screen.dart` — l'image produit (`Image.network`) est
  enveloppée dans un `Hero(tag: 'product-image-${product['id']}', ...)`,
  uniquement quand une vraie image existe (pas sur l'icône de repli, pour
  ne pas animer icône → icône).
- **Destination** : `product_detail_client.dart` — la fiche produit
  affiche potentiellement plusieurs photos dans un `PageView` ; seule la
  **première photo** partage le tag `'product-image-${p['id']}'` (celle
  visible juste avant l'ouverture) ; les photos suivantes du carrousel
  ont un tag unique (`-$i`) pour ne jamais entrer en conflit avec le
  premier Hero au sein du même `PageView`.
- **Non couvert** (pas d'image affichée à la source, donc pas de Hero
  possible sans ajouter une image d'abord) : le fil "Pour vous" (cartes
  texte seul) et les produits tagués dans les posts du Mur (icône
  générique, pas de vraie photo). L'aperçu favoris dans le Profil n'est
  aujourd'hui pas cliquable du tout (aucune navigation), donc hors
  périmètre également.

**Prochaines étapes possibles** (à valider une par une avec
l'utilisateur avant de les faire) : transitions de page personnalisées,
écrans de chargement squelettes.

## 3dixhuittrentecies. Animations — 2ème étape : retour visuel à l'ajout au panier (30/07) ✅ FAIT

Suite de 3dixseptrentecies. Le bouton "+" d'ajout rapide au panier (sur
chaque carte produit du catalogue) ne donnait comme retour qu'un
SnackBar discret d'une seconde — facile à manquer. Ajout d'un petit
**effet de rebond** (scale 1 → 1,35 → 1 sur 220ms, `AnimationController` +
`TweenSequence`) au tap, en plus du SnackBar existant (inchangé).

- Nouveau widget privé `_QuickAddButton` (`catalog_tab.dart`), remplace
  le `Material`/`InkWell` codé en dur précédemment inline dans
  `_ProductCard`.
- Limité à ce seul bouton — les favoris (`favorites_screen.dart`) n'ont
  pas de bouton d'ajout rapide équivalent, rien à changer là-bas.

**Prochaines étapes possibles restantes** : écrans de chargement
squelettes.

## 3dixneuftrentecies. Animations — ralenties après retour de test réel (30/07) ✅ FAIT

Suite au test sur appareil réel des deux animations précédentes
(3dixseptrentecies/3dixhuittrentecies) : les deux fonctionnaient bien,
mais étaient trop rapides pour être clairement perçues ("comme avant" au
premier retour, puis précisé : juste trop rapide, pas absentes).

- **Rebond du bouton "+"** (`_QuickAddButton`, `catalog_tab.dart`) :
  durée 220ms → **500ms**, amplitude 1,35 → **1,4**, courbe `easeOut` →
  **`easeOutBack`** (léger dépassement avant de se stabiliser, effet
  "classique" plus marqué).
- **Transition Hero vers la fiche produit** : le `MaterialPageRoute` par
  défaut (~300ms, transition zoom de Material 3 qui a tendance à
  recouvrir/masquer le vol du Hero) remplacé par une route personnalisée
  **`productDetailRoute()`** (nouveau `lib/core/navigation/
  product_detail_route.dart`, `PageRouteBuilder` avec un simple fondu,
  **500ms** à l'aller/400ms au retour — un fondu plutôt qu'un zoom pour
  ne pas concurrencer visuellement le Hero). Appliquée aux 4 endroits qui
  ouvrent la fiche produit : grille catalogue, "Vous recommandez
  souvent", fil "Pour vous", et favoris.

## 3vingttrentecies. Connexion Google : diagnostic + correctif de fond via écouteur global (31/07) ✅ FAIT

Après 3quinzetrentecies (mise en place initiale), l'utilisateur a signalé
que le flux OAuth Google atteignait bien l'écran de consentement, revenait
bien dans l'app automatiquement après validation (confirmant que le lien
profond Android était correctement délivré), mais **sans aucun effet
visible** — écran de connexion inchangé, aucune erreur.

**Diagnostic** : les logs Supabase (`/logs/auth-logs`, consultés par
l'utilisateur sans accès à l'appareil) montraient des entrées `Login` et
`/token | request completed` en `INFO` sans aucune erreur — la preuve que
Supabase créait bien la session côté serveur (l'échange PKCE aboutissait).
Le problème était donc **côté client Flutter**, pas dans le flux OAuth
lui-même.

**Cause réelle identifiée** : `authentication_screen.dart` n'écoutait
`onAuthStateChange` que localement, dans son propre `initState`. Or,
pendant le long délai de consentement Google (souvent 10-20s en usage
réel), Android tue fréquemment le processus Flutter en arrière-plan pour
libérer de la mémoire. Le retour du lien profond relance alors l'app **à
froid** sur `SplashScreen`, qui vérifie `currentSession` de façon
synchrone après un délai fixe (1200ms + 300ms) — mais l'échange PKCE du
lien de redirection (appel réseau asynchrone déclenché par
`supabase_flutter` à l'initialisation) n'est pas forcément terminé à ce
moment-là. Résultat : `SplashScreen` ne voit encore aucune session,
retombe sur `/authentication-screen`, dont l'écouteur local — monté après
coup — arrive trop tard pour l'événement `signedIn` qui suit quelques
instants plus tard sur un flux diffusé (`Stream.broadcast`) qui ne rejoue
jamais les événements passés aux nouveaux abonnés.

**Correctif** : nouveau `lib/core/auth/global_auth_listener.dart` —
`GlobalAuthListener`, initialisé une seule fois dans `main()` juste après
`SupabaseConfig.initialize()` (donc bien avant `runApp()`, avant même que
`SplashScreen` existe), reste abonné à `onAuthStateChange` **pendant toute
la durée de vie de l'app**. Sur un événement `signedIn`, s'il détecte
(via un `NavigatorObserver` dédié qui garde en mémoire le nom de la route
active) que l'app est encore sur un écran "pré-connexion" (`/`,
`/splash-screen`, `/authentication-screen`, `/onboarding-flow`), il
redirige lui-même vers l'accueil (`AuthRouting.homeRouteForCurrentUser()`)
via un `GlobalKey<NavigatorState>` désormais posé sur le `MaterialApp`
(`navigatorKey:`/`navigatorObservers:` dans `main.dart`). Une revérification
juste avant la navigation évite un double redirect si l'écouteur local de
`authentication_screen` (toujours présent, utile pour "se souvenir de
moi"/notification de bienvenue quand l'app n'a pas été tuée) a déjà agi
entre-temps.

Ce correctif élimine la dépendance à un timing precis : peu importe
combien de temps prend l'échange PKCE après un redémarrage à froid,
l'écouteur global sera déjà abonné et ne peut pas rater l'événement.

⚠️ **Pas encore confirmé sur appareil réel** — prochain test à faire par
l'utilisateur après le prochain build Codemagic.

## 3vingtuntrentecies. Adresse de livraison précisée par le client (31/07) ✅ FAIT (script exécuté)

Constat de l'utilisateur (capture d'écran du détail commande côté Admin) :
le staff ne voyait que "Position du livreur" (sa propre position, mise à
jour manuellement) — rien n'indiquait **où livrer**. `orders.latitude`/
`longitude` (phase5) existaient déjà et étaient bien envoyées à la
commande, mais détectées **silencieusement** (GPS → profil → géocodage du
texte du profil) sans jamais être montrées ni au client ni au staff sous
forme lisible, et sans que le client puisse la corriger.

- **Nouvelle colonne** `orders.delivery_address` (texte) —
  `supabase/phase31_patch_orders_delivery_address.sql`, aucun changement
  RLS nécessaire (déjà couvert par les policies existantes sur `orders`).
- **Côté client** (`cart_tab.dart`) : `_estimateDelivery()` fait maintenant
  un géocodage inverse (`placemarkFromCoordinates`, package `geocoding`
  déjà présent) de la position détectée et pré-remplit un nouveau champ
  texte "Adresse de livraison", modifiable par le client avant de valider.
  Une icône 📍 ("Utiliser ma position actuelle") permet de relocaliser et
  ré-écrire le champ à tout moment. **Obligatoire** pour toute commande
  (pas pour un devis) — même validation bloquante que la référence de
  paiement (3onziemetrentecies). Champ envoyé sur l'insertion `orders`
  (en ligne) et dans le payload de la file d'attente hors-ligne.
- **Côté staff** (`order_management_real.dart`) : nouvelle section
  "Adresse de livraison indiquée par le client" dans le dialogue détail
  commande (avant "Position du livreur"), avec un bouton "Ouvrir dans
  Google Maps" (`url_launcher`, déjà présent) construit à partir de
  `latitude`/`longitude`. Si l'adresse texte est absente (anciennes
  commandes créées avant cette migration), repli sur un message explicite
  + le bouton Maps reste disponible si des coordonnées existent.

✅ Script exécuté par l'utilisateur ("Success. No rows returned") et
fusionné dans `main`.

## 3vingtdeuxtrentecies. Messagerie : indicateur "Nouveau message" + styles de bulles au choix (31/07) ✅ FAIT

Retour utilisateur sur capture d'écran (messagerie client, plusieurs
pièces jointes envoyées d'affilée) : aucun horodatage visible sur les
bulles. Diagnostic — ce n'était pas un bug d'affichage de l'heure
(3octovicies groupe déjà l'horodatage sur la dernière bulle d'une série
du même expéditeur, logique correcte), mais l'absence totale
d'auto-scroll/notification : `chat_screen.dart` utilisait un
`ListView.builder(reverse: true)` sans `ScrollController`, donc si le
client n'était pas physiquement tout en bas au moment où un nouveau
message arrivait via le flux temps réel, rien ne l'avertissait ni ne
l'y ramenait — il restait sur d'anciens messages, jamais sur "la dernière
bulle du groupe" qui porte l'horodatage.

- **Correctif** (`chat_screen.dart`) : ajout d'un `ScrollController`.
  `_handleIncomingMessages()` compare le nombre de messages à chaque
  émission du flux ; si le client est déjà en bas (offset ≤ 80, liste
  inversée), défilement automatique vers le nouveau message ; sinon,
  affichage d'une pastille flottante "Nouveau message ↓" (au-dessus du
  composeur) qui ramène en bas au tap. La pastille se masque aussi
  automatiquement si le client revient en bas manuellement.
  Périmètre : côté client uniquement (le fil admin,
  `messaging_center_real.dart`, n'a pas encore de flux temps réel — reste
  un chargement ponctuel avec `jumpTo` manuel, hors périmètre de ce
  correctif).

- **Styles de bulles au choix** (nouveau
  `lib/core/chat/chat_bubble_style.dart`) : enum `ChatBubbleStyle`
  (`classique`/`compact`/`confort`) avec padding/rayon/taille de police/
  espacement propres à chacun, persistés via `SharedPreferences`
  (même schéma que `theme_provider.dart`/langue — préférence personnelle,
  pas liée au rôle). Nouveau réglage "Style des messages" dans l'écran
  Paramètres (`settings_screen.dart`), au même endroit que Langue/Mode
  sombre. Appliqué aux deux fils de discussion — client
  (`chat_screen.dart`) et staff (`messaging_center_real.dart`,
  `_AdminConversationThread` converti en `ConsumerStatefulWidget`) — donc
  client ET staff choisissent chacun le style qui leur convient,
  indépendamment l'un de l'autre.

## 3vingttroistrentecies. Vraie cause du Hero catalogue qui n'animait jamais (31/07) ✅ FAIT

Retour utilisateur : après le ralentissement des animations
(3dixneuftrentecies), le rebond du bouton "+" fonctionnait, mais le Hero
photo (catalogue/favoris → fiche produit) n'animait toujours pas du tout —
pas juste trop rapide, réellement absent.

**Cause réelle** : `catalog_tab.dart` réutilise le même widget
`_ProductCard` (avec son `Hero(tag: 'product-image-<id>')`) à la fois
pour la grille principale ET pour le carrousel horizontal "Vous
recommandez souvent" juste au-dessus. Ce carrousel n'étant qu'un
sous-ensemble du même catalogue, un produit y apparaît quasi toujours
aussi dans la grille — donc **deux `Hero` avec le même tag visibles sur
le même écran en même temps**. Flutter interdit ça
(`There are multiple heroes that share the same tag`), mais via un
`assert()` **compilé hors des builds release** — donc aucune erreur
visible sur un APK réel, juste le vol qui ne se déclenche silencieusement
plus. Exactement le genre de bug invisible en dev mais présent sur
appareil réel.

- **Correctif** : nouveau paramètre `_ProductCard.enableHero` (`true` par
  défaut). La grille principale (entrée canonique) garde le Hero ; l'appel
  du carrousel "Vous recommandez souvent" passe `enableHero: false`. Le
  rendu de l'image extrait dans une fonction `_productImage()` partagée
  (loader/repli d'erreur communs, Hero conditionnel) pour éviter la
  duplication de code entre les deux chemins.
- Vérifié que les onglets client (`client_home.dart`) sont bien échangés
  (`pages[_currentIndex]`), pas gardés vivants via `IndexedStack` — donc
  pas de risque de collision équivalente entre Catalogue et Favoris (deux
  routes différentes, jamais montées simultanément).

## 3vingtquatretrentecies. Catalogue de sons de notification géré par l'Admin (31/07) ✅ FAIT (script exécuté)

Demande utilisateur : pouvoir "ajouter et organiser manuellement les sons
pour chaque notification... supprimer le son que je n'aime pas", côté
Admin.

**Contrainte technique expliquée à l'utilisateur avant d'implémenter** :
un vrai "ajout" de fichier son personnalisé (ex: importer un MP3 depuis
le téléphone) est **impossible** pour une notification push, sur Android
ET iOS — le son d'un canal de notification doit être une ressource
intégrée à l'app à la compilation (`res/raw/...` Android, bundle iOS),
jamais un fichier arbitraire déposé après coup, sans reconstruire et
publier une nouvelle version de l'app. Ce n'est pas un choix, c'est une
limite des deux OS.

**Ce qui est réellement construit** — réordonner/masquer les 20 sons déjà
intégrés (3neuvicies), PAR catégorie, décision validée par l'utilisateur
("Curation globale par l'Admin") :

- **Nouvelle table** `notification_sound_catalog` (catégorie, sound_id,
  sort_order, enabled) —
  `supabase/phase32_patch_notification_sound_catalog.sql`. Même modèle
  RLS que `payment_method_settings` (phase28) : lecture publique
  (`current_role_is_admin()` en écriture uniquement), tout le monde doit
  pouvoir lire pour afficher son propre sélecteur. Seedée avec les 20 sons
  × 3 catégories (60 lignes), ordre initial = ordre actuel du réservoir
  commun.
- **Repo** `lib/core/notifications/notification_sound_catalog_repo.dart` :
  `visibleSounds()` (sons actifs triés, pour le sélecteur personnel —
  repli sur la liste complète si la table est vide/inaccessible),
  `fullCatalog()` (avec les masqués, pour l'écran Admin), `setEnabled()`,
  `reorder()`.
- **Sélecteur personnel** (`notification_sounds_screen.dart`, partagé
  client/staff comme avant) : n'affiche plus `kNotificationSounds` brut
  mais `NotificationSoundCatalogRepo.visibleSounds(category)` — respecte
  donc désormais la curation de l'Admin.
- **Nouvel écran Admin**
  `lib/presentation/notification_sounds_catalog_admin/notification_sounds_catalog_admin_screen.dart` :
  un onglet par catégorie, `ReorderableListView` (glisser pour réordonner)
  + `Switch` par son (masquer/réafficher) + aperçu ▶. Accessible depuis le
  menu "Plus" du staff (`more_menu_screen.dart`, section Entreprise, entre
  "Modes de paiement" et "Profil entreprise") — visible pour tous les
  rôles staff comme les autres entrées de gestion, la vraie barrière
  restant la RLS `current_role_is_admin()` côté serveur (même logique que
  "Modes de paiement").

⚠️ **Script SQL à exécuter avant fusion vers main** — sans la table,
`fullCatalog()`/`visibleSounds()` échoueraient côté Admin (le sélecteur
personnel a un repli silencieux sur la liste complète, donc pas
bloquant pour les utilisateurs classiques, mais l'écran de gestion Admin
ne fonctionnerait pas).

## 3vingtcinqtrentecies. Suggestions de noms de matières premières (chimiques + alimentaires) (31/07) ✅ FAIT (script exécuté)

L'utilisateur a fourni un fichier HTML (prototype Rocket.new antérieur,
`Akora_Hub_Complet_INTEGRE_1.html`) contenant deux grosses bases de
données jamais utilisées par l'app réelle : `LAB_PRODUCTS_BASE` (268
fiches, dont 165 ingrédients cosmétiques INCI génériques hors-sujet — y
compris des colorants capillaires **interdits en Europe**, volontairement
exclus) et un catalogue "Ingrédients Agroalimentaires" encodé en base64
dans `CAT_AGRO_B64` (129 ingrédients alimentaires, 18 catégories,
decodé pour extraction). Demande : intégrer cette liste dans l'app comme
suggestions, organisées par catégorie, pour que le staff puisse
sélectionner un nom au lieu de le taper, avant d'ajouter prix/stock/
photos/format et publier.

**Clarification du concept avant d'implémenter** : la table `raw_materials`
(schema phase1) existe mais n'est utilisée nulle part dans l'app (aucun
écran, 0 référence Flutter) — code mort. Le concept qui correspond
réellement à "prix, stockage, photos, format... publié" est celui déjà en
place : les matières premières sont des **`products`** (table catalogue
standard) rattachés au pilier **"Matières Premières"** (12 catégories :
Acides & Bases, Chélatants, Désinfectants, Épaississants, Charges
Minérales, Colorants, Conservateurs & Antioxydants, Huiles & Beurres
Cosmétiques, Parfums & Additifs, Polymères & Résines, Solvants,
Tensioactifs — phase10), avec aussi une partie mappée sur "Matières
Premières Peinture" (peinture/encre) et "Anti-Nuisibles" (biocides/
insecticides). Convention déjà actée avec l'utilisateur (phase10) : un
ingrédient alimentaire va dans sa famille chimique avec une note "qualité
alimentaire", pas dans une catégorie "Agroalimentaire" séparée — appliquée
ici aussi.

**Tri effectué avant intégration** (192 noms retenus sur ~400 candidats) :
- Exclus entièrement : les 165 fiches INCI cosmétiques génériques (dossier
  de référence type "ingrédient de shampoing/coloration capillaire", sans
  rapport avec l'activité réelle de l'entreprise, plusieurs marqués
  "INTERDIT EN EUROPE" dans leur propre description) ; la catégorie
  "Analyse & Contrôle Qualité" du catalogue alimentaire (réactifs de
  laboratoire — soude étalon, réactif de Fehling, nitrate d'argent... —
  pas des matières premières stockables/revendables) ; "Ferments &
  Cultures Microbiennes" et une poignée d'intrants très spécifiques à la
  vinification/fromagerie (présure, colle de poisson, tanins œnologiques,
  ferments yaourt...) hors du métier de l'entreprise.
- Conservé et réparti par catégorie chimique la plus proche (mapping
  manuel item par item, pas un mapping en bloc, pour éviter les
  contresens) : 98 matières premières chimiques/industrielles
  (détergents, acides/bases, solvants, cires, colorants, biocides,
  traitement de l'eau, peinture) + 105 ingrédients alimentaires
  (édulcorants, acidifiants, conservateurs, épaississants, émulsifiants,
  colorants, arômes...) répartis dans les mêmes 12 catégories + Anti-
  Nuisibles + Matières Premières Peinture.
- **Relecture demandée par l'utilisateur avant exécution** : audit
  programmatique (noms identiques ou quasi-identiques désignant la même
  substance) a trouvé 11 doublons — 2 cas du même nom exact rangé dans
  deux catégories différentes (`Sulfate de sodium`, `Tripolyphosphate de
  sodium STPP`) et 9 cas de la même substance listée deux fois sous un nom
  simple et une variante E-number/cas d'usage (ex : `Acide ascorbique` /
  `Acide ascorbique (Vitamine C)`, `Gomme xanthane` / `Gomme xanthane
  (E415)`). Tous retirés, un seul exemplaire gardé à chaque fois. Un faux
  positif détecté et volontairement gardé : `Sirop de glucose-fructose
  (HFCS)` et `Sirop de glucose (DE 38–42)` sont deux produits réellement
  différents malgré un nom proche.

**Implémentation** :
- Nouvelle table `raw_material_name_suggestions`
  (`supabase/phase33_patch_raw_material_name_suggestions.sql`) :
  `business_unit_slug`, `category_name`, `name`, `note` (description/
  dosage d'origine + "qualité alimentaire" pour les ingrédients
  alimentaires). Lecture staff, écriture Admin (même schéma RLS que
  `payment_method_settings`/`notification_sound_catalog`). Ce ne sont que
  des **suggestions** — rien n'est retiré, le nom reste un champ texte
  libre, modifiable à tout moment.
- `lib/presentation/product_management_real/product_management_real.dart` :
  le champ "Nom du produit" (jusqu'ici un `TextField` 100% libre) devient
  un `Autocomplete<String>`, scopé au pilier actuellement sélectionné dans
  le formulaire (filtré par `business_unit_slug`). Sélectionner une
  suggestion pré-remplit aussi la catégorie correspondante si aucune n'est
  encore choisie (gain de temps, reste modifiable).

⚠️ **Script SQL à exécuter avant fusion** — sans la table, l'écran
continue de fonctionner en champ 100% libre (repli silencieux), donc pas
bloquant, mais les suggestions n'apparaîtront pas tant que la migration
n'est pas passée.

## 3vingtsixtrentecies. Audit performance/sécurité + correctif N+1 sur le Mur (31/07) ✅ FAIT (1er chantier)

L'utilisateur a proposé une checklist de 6 points (Performance :
optimisation réseau, pagination, cache des données de référence ;
Sécurité : rate limiting, journalisation, RLS). Audit du code réel
(pas de suppositions) avant tout correctif :

1. **Optimisation réseau** ⚠️ partiel — `catalog_tab.dart` bien
   parallélisé (confirmé), mais dashboard Admin
   (`metrics_cards_widget.dart`, `recent_activity_feed_widget.dart`,
   `analytics_dashboard_real.dart`) et `product_management_real.dart`
   enchaînent des requêtes indépendantes en séquentiel. **Pire cas
   trouvé : `wall_tab.dart`** — pour chaque post du Mur (jusqu'à 50), 2
   requêtes séparées (likes puis commentaires) l'une après l'autre → 
   jusqu'à ~100 allers-retours réseau séquentiels par ouverture. Corrigé
   dans la foulée (voir plus bas).
2. **Pagination** ❌ pas fait — produits, commandes chargés sans limite ;
   Mur plafonné à 50 (`.limit(50)`) mais pas de "charger plus".
3. **Cache formats/parfums/catégories** ❌ pas fait — requêtés à neuf à
   chaque écran (4+ points d'appel pour `categories` seul), aucune
   couche de cache (SharedPreferences/Riverpod).
4. **Rate limiting connexion/reset** ❌ pas fait — dépend entièrement des
   limites par défaut de la plateforme Supabase Auth.
5. **Journalisation des actions sensibles** ❌ pas fait — aucune table
   d'audit log nulle part dans le schéma.
6. **RLS sur toutes les tables** ✅ fait — 31 tables créées au total sur
   tous les fichiers `supabase/*.sql`, toutes ont RLS activé + au moins
   une policy, vérifié une par une. Seule exception notable : la vue
   `public_profiles` (phase9) contourne volontairement RLS par design
   (documenté dans son propre commentaire), pas un oubli.

**Discussion complémentaire** (organisation de l'app / "zone de confort
pour la communauté", demandée avant d'exécuter) : suggestions données —
regrouper les 12 entrées à plat du menu "Plus" Admin (Bannière hero,
Flash infos, Modes de paiement, Sons de notification → un seul sous-menu
"Vitrine & réglages") ; miser sur le Mur comme vraie fonctionnalité
communauté (réactions, post épinglé) ; visage humain dans la messagerie
staff (avatar/nom plutôt que "Support" anonyme) ; visibilité humaine du
suivi de livraison. Pas encore implémenté, l'utilisateur a demandé de
continuer sur les correctifs techniques.

**Correctif appliqué — `wall_tab.dart`** : la boucle "1 requête like + 1
requête commentaire PAR post" remplacée par un seul `inFilter` groupé
pour chacun (2 requêtes au total au lieu de jusqu'à ~100), lancés en
parallèle avec les profils auteurs et les produits mentionnés via
`Future.wait` (même style que `catalog_tab.dart` : fonctions locales avec
repli silencieux individuel). Comptage des likes/commentaires reconstruit
côté client à partir des lignes groupées.

**Reste à faire de cette checklist** (items 1 restant partiellement,
2, 3, 4, 5) — voir section 4.

## 3vingtseptrentecies. Parallélisation des requêtes séquentielles restantes (item 1 de l'audit) (31/07) ✅ FAIT

Suite de 3vingtsixtrentecies : les 3 autres écrans identifiés avec des
requêtes indépendantes enchaînées en séquentiel (au lieu d'un
`Future.wait`) sont maintenant corrigés, même style que
`catalog_tab.dart`/`wall_tab.dart` :

- `business_dashboard/widgets/metrics_cards_widget.dart` : 4 `.count()`
  (produits, commandes en attente, clients, messages non lus)
  parallélisés.
- `business_dashboard/widgets/recent_activity_feed_widget.dart` :
  commandes récentes + nouveaux clients parallélisés.
- `analytics_dashboard_real.dart` : commandes, nouveaux clients, articles
  vendus (même filtre "depuis N jours") parallélisés.
- `product_management_real.dart` : produits, piliers, catégories,
  suggestions de matières premières (phase33) — 4 requêtes
  parallélisées ; catégories et suggestions gardent chacune leur repli
  silencieux individuel (fonctions locales, comme dans
  `catalog_tab.dart`) si leur table n'est pas encore créée.

Item 1 de la checklist perf/sécurité (31/07) désormais entièrement traité
pour tous les écrans audités.

## 3vingthuittrentecies. Pagination / infinite scroll — Commandes, Mur, Produits Admin (31/07) ✅ FAIT (item 2 de l'audit, partiel)

Item 2 de la checklist perf/sécurité (31/07) : les listes longues
chargeaient la table entière sans limite. Chargement par pages de 20
(scroll vers le bas = page suivante automatique) implémenté pour :

- **Commandes** (`order_management_real.dart`) : le filtre de statut
  (Toutes/Reçue/.../Annulée) passe désormais **côté serveur**
  (`.eq('status', ...)`), compatible avec la pagination. Le filtre
  "Paiement à vérifier" reste côté client car sa logique (valeurs
  nulles traitées comme 'paiement_livraison'/'en_attente') ne se traduit
  pas proprement en filtre Postgrest simple (`<>` exclut les NULL, alors
  que le code traite un NULL comme la valeur par défaut) — dans ce mode
  précis, tout est chargé sans pagination pour ne rater aucune commande à
  vérifier (sous-ensemble nettement plus petit en pratique).
- **Mur** (`wall_tab.dart`) : le plafond fixe de 50 posts (sans suite
  possible) remplacé par une vraie pagination. Les filtres secteur/"mes
  publications" passent aussi côté serveur — le filtre secteur (basé sur
  `profiles.client_type`, une autre table) via une résolution en 2 temps :
  requête sur la vue `public_profiles` pour obtenir les `author_id` du
  secteur, puis `inFilter` sur `posts.author_id`. Les deux filtres se
  combinent correctement (ET logique, comme avant).
- **Produits Admin** (`product_management_real.dart`) : pas de filtre de
  recherche sur cet écran (contrairement au catalogue client), donc cas
  simple — pagination directe sans complication. Piliers/catégories/
  suggestions de matières premières restent chargés en entier (petites
  tables de référence pour les menus déroulants, pas concernées par la
  pagination).

⚠️ **Catalogue client (`catalog_tab.dart`) volontairement pas encore
traité** — contrairement aux écrans ci-dessus, il a une recherche texte
ET un filtre catégorie appliqués en mémoire sur la liste complète. Le
convertir en pagination correcte nécessite de passer la recherche et le
filtre catégorie côté serveur (recherche avec debounce au lieu
d'instantanée à chaque frappe) — un changement d'UX sur l'écran le plus
critique de l'app (l'écran d'achat principal des clients), à valider
avec l'utilisateur avant de l'implémenter plutôt que de le faire
silencieusement.

## 3vingtneuftrentecies. Pagination du catalogue client (31/07) ✅ FAIT — item 2 de l'audit désormais complet

Suite de 3vingthuittrentecies : le catalogue client (`catalog_tab.dart`),
volontairement laissé de côté car plus complexe (recherche texte +
filtre catégorie + filtre pilier appliqués en mémoire, ET dépendance du
mode hors-ligne + des puces de catégorie sur la liste complète). Deux
options proposées à l'utilisateur — paginer quand même (2 requêtes au
lieu d'une) vs laisser tel quel — **l'utilisateur a choisi de paginer**.

- **Grille visible** (`_products`) : chargée par pages de 20,
  filtrée **côté serveur** (pilier `.eq('business_unit_id', ...)`,
  catégorie `.eq('category', ...)`, recherche `.ilike('name', '%...%')`),
  suite automatique en scrollant vers le bas.
- **Recherche** : passée d'instantanée (une requête par lettre tapée) à
  différée de 400ms après la dernière frappe (validé avec l'utilisateur
  au préalable) — imperceptible à l'usage, évite une requête réseau par
  caractère.
- **Puces de catégorie + cache hors-ligne** : nouveau champ
  `_allProductsForReference`, alimenté par un chargement complet du
  catalogue **en arrière-plan** (`_refreshFullCatalogReference`, ne
  bloque pas l'affichage de la première page). Les puces de catégorie et
  `_cacheCatalogOffline` utilisent désormais ce champ plutôt que
  `_products` (paginé), pour ne jamais perdre en cohérence au fil du
  scroll infini.
- **Mode hors-ligne** : au chargement depuis le cache local (pas de
  réseau disponible), `_products` ET `_allProductsForReference` reçoivent
  directement tout le catalogue mis en cache (pas de pagination possible
  sans réseau pour charger la suite) — `_filteredProducts` (filtre
  client existant, inchangé) s'applique alors normalement dessus, exactement
  comme avant ce chantier.
- La logique de filtre client-side existante (`_filteredProducts`) a été
  **conservée telle quelle** plutôt que supprimée : en ligne, elle
  ré-applique un filtre déjà satisfait par le serveur (no-op, sans
  risque) ; hors-ligne, elle redevient la seule ligne de défense sur
  l'ensemble complet mis en cache — un seul getter qui marche
  correctement dans les deux cas, sans dupliquer la logique de filtre.

Item 2 de la checklist perf/sécurité (31/07) maintenant entièrement traité
pour toutes les listes longues identifiées (Commandes, Mur, Produits
Admin, Catalogue client).

## 3trentetrentecies. Cache local des données de référence — formats/parfums/catégories (31/07) ✅ FAIT — item 3 de l'audit complet

Item 3 de la checklist perf/sécurité (31/07) : `formats`, `parfums`,
`categories` étaient requêtées à neuf à chaque écran qui en avait besoin
(jusqu'à 7 points d'appel différents cumulés). Ces 3 tables n'ont pas de
colonne `updated_at` pour détecter un changement à distance, donc la
fraîcheur repose sur une durée de vie (TTL) + invalidation explicite
après une écriture faite depuis l'app — pas de diff ligne par ligne
possible.

**Nouveau** `lib/core/reference_data/reference_table_cache.dart` :
`ReferenceTableCache` (un `StateNotifier` générique, même schéma
Riverpod + `SharedPreferences` que `theme_provider.dart`/langue) —
hydratation immédiate depuis `SharedPreferences` au démarrage (affichage
instantané, pas d'attente réseau), puis rafraîchissement en arrière-plan
si la dernière donnée connue a plus de 6h. `refresh(force: true)` permet
d'ignorer ce délai juste après une écriture (ajout/renommage/activation),
pour que l'Admin voie son changement immédiatement plutôt que d'attendre
jusqu'à 6h. Trois providers : `formatsCacheProvider`,
`parfumsCacheProvider`, `categoriesCacheProvider` (ce dernier contient
TOUTES les catégories tous piliers confondus, avec leur `business_unit_id`
et `active` — chaque écran filtre côté client selon son besoin, comme
c'était déjà fait avant ce chantier).

**Écrans mis à jour** (tous convertis en `ConsumerStatefulWidget` pour
accéder au cache) :
- `catalog_tab.dart` : la requête dédiée "catégories désactivées"
  (`loadInactiveCategories`) supprimée, dérivée à la place du cache
  partagé dans le getter `_categories`.
- `product_management_real.dart` : la requête `categories` dans
  `_loadData` remplacée par un `refresh()` du cache ; `_addNewCategory`
  invalide le cache (`force: true`) après l'insertion au lieu de gérer sa
  propre copie locale.
- `product_variants_screen.dart` (formats/parfums) : mêmes principes —
  `_loadAll` ne recharge plus que les variantes (spécifiques au produit,
  pas cacheables globalement) + rafraîchit les 2 caches en parallèle ;
  `_addNewReference` invalide le cache concerné (formats OU parfums)
  après l'insertion.
- `category_management.dart` (écran Admin dédié à la gestion des
  catégories d'un pilier) : garde sa propre requête directe (c'est
  l'écran de référence pour cette donnée, la fraîcheur prime sur
  l'économie de requête ici), mais invalide désormais le cache partagé
  après chaque écriture (ajout/renommage/activation) pour que les autres
  écrans (formulaire produit, catalogue client) voient le changement sans
  attendre.

Item 3 de la checklist perf/sécurité maintenant traité. Il reste les 2
items sécurité : rate limiting connexion/reset, et journalisation des
actions sensibles.

## 3trenteuntrentecies. Rate limiting connexion + journal de sécurité (31/07) ⚠️ CODE PRÊT, SCRIPT SQL PAS ENCORE EXÉCUTÉ + ÉTAPE MANUELLE DASHBOARD REQUISE

Items 4 et 5 (derniers) de la checklist perf/sécurité (31/07) : rate
limiting sur la connexion, et journalisation des actions sensibles
(connexions échouées/réussies, changements de mot de passe/rôle).

**Contrainte technique importante** : `signInWithPassword` et
`resetPasswordForEmail` appellent directement le service GoTrue managé de
Supabase, pas une table ou fonction qu'on contrôle — impossible d'y
brancher un simple trigger Postgres. La seule façon officielle d'agir
AVANT qu'une tentative de connexion soit acceptée est le mécanisme
"Auth Hooks" de Supabase, en particulier le "Password Verification
Attempt" hook (contrat exact vérifié via la doc officielle GitHub, la
doc web ayant renvoyé une 403 lors de la vérification).

**Nouveau** `supabase/phase34_patch_security_audit_log.sql` (**PAS ENCORE
EXÉCUTÉ**) :
- Table `security_audit_log` (event_type, user_id, metadata jsonb,
  created_at) — RLS : lecture réservée à l'Admin (`current_role_is_admin()`),
  aucune policy d'insert : seules les fonctions `SECURITY DEFINER`
  ci-dessous peuvent écrire.
- `log_security_event(p_event_type text)` : appelée par l'app pour
  journaliser `password_changed` (après succès de
  `security_settings_screen.dart`) et `password_reset_requested` (après
  succès de `authentication_screen.dart`, **avant** connexion — d'où le
  grant à `anon` en plus de `authenticated`).
- `log_role_change()` (trigger `after update on profiles`) : journalise
  tout changement de `role`, quelle que soit son origine (écran Admin,
  SQL Editor...) — plus robuste qu'un appel explicite depuis un seul
  écran.
- `hook_password_verification_attempt(event jsonb)` : la fonction Auth
  Hook elle-même. Journalise `login_success`/`login_failed` à CHAQUE
  tentative, et renvoie `{"decision": "reject"}` après 5 échecs en 15
  minutes pour un même utilisateur. **Fail-open volontaire** : tout le
  corps est enveloppé dans `EXCEPTION WHEN OTHERS THEN return 'continue'`
  — un bug interne ne doit jamais pouvoir verrouiller l'accès à toute
  l'app, y compris pour l'Admin.

**⚠️ Étape manuelle obligatoire après exécution du script** (ne peut pas
être faite en SQL) : Dashboard Supabase → Authentication → Hooks →
"Password Verification Attempt" → Enable → choisir la fonction
`public.hook_password_verification_attempt`. Sans cette activation, le
rate limiting ne fait rien (mais rien ne casse : la fonction reste
inutilisée). À tester après activation : se tromper de mot de passe une
fois (doit encore fonctionner), puis se reconnecter avec le bon mot de
passe (doit toujours marcher).

**Nouveau** `lib/presentation/security_audit_log/security_audit_log_screen.dart` :
écran Admin "Journal de sécurité" (paginé, même schéma que les autres
listes de ce chantier), affiche chaque événement avec libellé FR, icône,
nom de la personne (via `profiles`) et horodatage — ajouté au menu
"Plus" → section Entreprise, sous "Sons de notification".

Checklist perf/sécurité (31/07) entièrement traitée côté code. **Ne pas
merger sur `main` avant confirmation d'exécution du script par
l'utilisateur, et lui rappeler explicitement l'étape manuelle du
Dashboard.**

**Script phase34 exécuté avec succès par l'utilisateur (31/07).**

## 3trentedeuxtrentecies. Hook Auth réservé au plan Team/Enterprise — proxy de connexion via Edge Function (31/07) ✅ FAIT (script exécuté, reste à déployer l'Edge Function)

En tentant d'activer le hook "Password Verification Attempt" dans
Authentication → Hooks, l'utilisateur a découvert qu'il est grisé avec la
mention **"Team or Enterprise Plan required"** — indisponible sur le plan
Supabase actuel. La fonction `hook_password_verification_attempt` créée
par phase34 reste dans la base mais ne sera jamais appelée par GoTrue tant
que ce hook n'est pas activable (upgrade de plan, ou suppression plus
tard) — elle ne gêne pas, elle est juste inerte.

**Solution alternative retenue** (choisie par l'utilisateur parmi 3
options proposées : proxy Edge Function / rester sans blocage / upgrader
le plan) : une Edge Function fait office de proxy de connexion.

**Nouveau** `supabase/phase35_patch_login_rate_limit.sql` (**exécuté avec
succès par l'utilisateur, 31/07**) : table `login_rate_limit` (email,
failed_count, last_attempt_at, locked_until) — RLS activée SANS AUCUNE
policy, donc invisible pour `anon`/`authenticated`, seule la clé
service_role (utilisée par l'Edge Function) peut y accéder.

**Nouveau** `supabase/functions/hyper-endpoint/index.ts` (contenu
"secure-login", **nom déployé imposé par le Dashboard**) : reçoit
`{email, password}`, vérifie d'abord `login_rate_limit` (si verrouillé,
renvoie directement un message d'erreur sans même contacter GoTrue),
sinon relaie la tentative au vrai endpoint GoTrue
(`/auth/v1/token?grant_type=password`) avec la clé anon — c'est bien
Supabase Auth qui valide le mot de passe, cette fonction ajoute
uniquement la vérification avant et la journalisation après (insert dans
`security_audit_log`, réutilise la table du phase34). Verrouille 15
minutes après 5 échecs pour un même email. Répond toujours en HTTP 200
avec `{ok: true/false, ...}` pour simplifier la lecture côté client (sauf
erreur interne inattendue → 500).

**⚠️ Nom réel de la fonction (31/07)** : déployée via l'éditeur en ligne du
Dashboard sur mobile, qui a assigné un nom aléatoire à la création malgré
plusieurs tentatives explicites pour taper `secure-login` — d'abord
`rapid-worker`, puis `hyper-endpoint` (supprimé/recommencé une fois,
sans succès sur le nommage). Décision : garder `hyper-endpoint` tel
quel plutôt que de continuer à lutter contre cette UI — le dossier local
et l'appel `functions.invoke` ont été renommés en conséquence. Si une
future conversation redéploie proprement sous `secure-login` via la CLI,
renommer le dossier + l'appel `functions.invoke` en conséquence (ou
inversement, ne pas être surpris par ce nom qui ne correspond pas au
contenu si on retombe dessus).

**Modifié** `lib/presentation/authentication_screen/authentication_screen.dart` :
`_handleLogin()` appelle désormais `functions.invoke('hyper-endpoint', ...)`
au lieu de `auth.signInWithPassword` directement ; en cas de succès,
`auth.setSession(refresh_token)` établit la session côté client.

**🐛 Bug découvert le 31/07 (après merge/test réel) et corrigé** :
l'hypothèse ci-dessus était fausse — `setSession()` restaure une session
existante, GoTrue émet `tokenRefreshed`, **jamais** `signedIn`. Or
`_onAuthenticated()` n'était déclenché que sur `signedIn` (écoute
`onAuthStateChange` de `initState()`, commune avec la connexion OAuth).
Résultat : la connexion email/mot de passe réussissait bien côté serveur
(token obtenu, session posée) mais l'app ne réagissait pas du tout —
aucune erreur, aucune navigation, écran de connexion qui reste figé.
**Corrigé** en appelant `_onAuthenticated()` directement après un
`setSession()` réussi dans `_handleLogin()`, au lieu de compter sur
`onAuthStateChange` (qui reste nécessaire uniquement pour Google/Facebook,
dont le flux se termine par une vraie redirection externe et émet bien
`signedIn`).

**Terminé (31/07)** : script phase35 exécuté avec succès, Edge Function
déployée (sous le nom `hyper-endpoint`, voir ci-dessus) — reste à
désactiver "Verify JWT with legacy secret" dans ses Settings (recommandé
par Supabase pour une fonction avec sa propre logique d'auth) et à tester
une connexion réelle avant de merger sur `main`.

**Volontairement laissé de côté** : `resetPasswordForEmail` continue
d'appeler directement GoTrue (pas de proxy) — Supabase applique déjà une
limitation par défaut sur l'envoi d'emails d'authentification au niveau
du projet, et l'abus possible (spam d'emails) est moins critique qu'une
attaque par force brute sur un mot de passe. La journalisation
`password_reset_requested` (phase34) reste en place.

## 3trentetroistrentecies. Code de vérification manquant à l'inscription (31/07) ⚠️ CODE PRÊT, 2 RÉGLAGES MANUELS SUPABASE REQUIS

L'utilisateur a remarqué qu'aucun code de vérification n'était envoyé
lors de la création d'un compte — normal : `auth.signUp` connectait
directement l'utilisateur (`response.session` non nul), signe que
"Confirm email" est désactivé côté Supabase. Aucune notion de code
n'existait avant dans l'app.

**⚠️ 2 réglages manuels obligatoires** (ne peuvent pas être faits en
SQL) :
1. Dashboard → Authentication → Providers → Email → activer **"Confirm
   email"**.
2. Dashboard → Authentication → Email Templates → **"Confirm signup"** →
   ajouter `{{ .Token }}` dans le corps du template (le template par
   défaut n'affiche que le lien `{{ .ConfirmationURL }}`, pas de code à 6
   chiffres, tant qu'on ne l'ajoute pas explicitement).

**Nouveau** `lib/presentation/registration_screen/email_otp_verification_screen.dart` :
écran de saisie du code à 6 chiffres, `auth.verifyOTP(type: OtpType.signup,
email, token)`, bouton "Renvoyer le code" avec cooldown 60s
(`auth.resend(type: OtpType.signup, email)`). C'est seulement APRÈS ce
succès (une fois la session établie) que le profil est complété
(`client_type`/`company_name`/`phone`/`birth_date`) — impossible de le
faire avant, RLS refuse toute écriture sans session valide.

**Modifié** `lib/presentation/registration_screen/registration_screen.dart` :
`_handleRegister()` vérifie `response.session == null` après `signUp()` —
si oui (confirmation requise), redirige vers `EmailOtpVerificationScreen`
avec l'email + les champs de profil en attente ; sinon (confirmation
désactivée), ancien comportement inchangé (connexion immédiate).

**Terminé (31/07)** : "Confirm email" activé, template modifié avec
`{{ .Token }}`. Un blocage supplémentaire est apparu en cours de route :
le template "Confirm signup" n'est éditable qu'avec un SMTP personnalisé
connecté (le mailer par défaut de Supabase ne l'autorise pas) — **Gmail
SMTP configuré** (Authentication → Emails → SMTP Settings :
`smtp.gmail.com:587`, mot de passe d'application Google généré côté
Dashboard Google, pas le mot de passe du compte). Sender : AkoraHub
`<julioandrinirina95@gmail.com>`.

**Changé (31/07, plus tard)** : expéditeur passé du Gmail personnel du
gérant à une adresse dédiée à l'entreprise —
`akorafanadiovana@gmail.com` (Sender email + SMTP username), avec son
propre mot de passe d'application Google (validation en 2 étapes activée
sur ce compte pour l'occasion). Host/port/Sender name inchangés.

## 3trentequatretrentecies. Vérification du téléphone par SMS après l'email (31/07) ⚠️ CODE PRÊT, PROVIDER PHONE + TWILIO PAS ENCORE CONFIGURÉS

Suite logique du point précédent : l'utilisateur a remarqué que le
téléphone saisi à l'inscription n'était jamais vérifié (n'importe qui
peut taper un faux numéro), et a demandé une vraie vérification par SMS
pour limiter les faux comptes — implémentée comme **étape obligatoire
après l'email**, pas seulement pour les comptes Google (choix explicite
de l'utilisateur parmi 2 options proposées).

**Nouveau** `lib/presentation/registration_screen/phone_otp_verification_screen.dart` :
utilise le flux "changement de téléphone" de Supabase Auth
(`auth.updateUser(UserAttributes(phone: ...))` déclenche l'envoi du SMS,
puis `auth.verifyOTP(type: OtpType.phoneChange, phone, token)` confirme)
plutôt que le flux de connexion par téléphone — l'utilisateur a déjà une
session (email vérifié juste avant), on ne fait qu'attacher et confirmer
son numéro à ce compte existant. `profiles.phone` n'est écrit qu'après
ce succès (pas avant, contrairement à avant ce chantier).

**Modifié** `lib/presentation/registration_screen/email_otp_verification_screen.dart` :
n'écrit plus `phone` dans le profil immédiatement après la vérification
email (retiré du map avant l'update) ; redirige vers
`PhoneOtpVerificationScreen` avec le numéro saisi au formulaire au lieu
d'aller directement au client-home. Filet de sécurité (ne devrait pas
arriver, le téléphone est obligatoire au formulaire) : si jamais aucun
téléphone n'est disponible, va directement au client-home comme avant.

**⚠️ Réglage manuel obligatoire, PAS ENCORE FAIT** : Dashboard Supabase
→ Authentication → Providers → **Phone** → activer, choisir **Twilio**
comme fournisseur SMS, renseigner Account SID + Auth Token + un numéro/
Messaging Service capable d'envoyer vers Madagascar (+261). Nécessite un
compte Twilio (externe, payant à l'usage — coût par SMS envoyé). Sans ce
réglage, `updateUser(phone: ...)` échouera et l'écran affichera une
erreur au lieu d'envoyer un SMS.

**⏸️ Twilio mis en pause (31/07)** : blocage sur la validation MFA du
compte Twilio (SMS non reçu). Pour ne pas bloquer complètement les
inscriptions en attendant, **la vérification SMS est devenue
optionnelle** : bouton **"Passer pour l'instant"** ajouté sur
`PhoneOtpVerificationScreen` (visible que l'envoi du SMS échoue ou
réussisse) qui envoie directement vers `/client-home` sans écrire
`profiles.phone` — mesure temporaire, explicitement documentée dans le
code (`_skip`) pour être retirée une fois Twilio opérationnel, sinon
l'étape ne protège plus vraiment contre les faux comptes.

**Non déterminé** : le nombre de chiffres du code SMS (l'écran accepte
jusqu'à 8 chiffres sans vérifier une longueur exacte, contrairement à
l'écran email qui avait dû être corrigé une fois la vraie longueur
connue — volontairement laissé flexible cette fois pour éviter de refaire
la même erreur).

**Reste à faire** : configurer Twilio + le provider Phone côté Dashboard,
puis tester une inscription réelle de bout en bout (email → SMS → les
deux vérifiés → compte activé) avant de merger sur `main`.

**⏸️ Mis en pause (31/07)** : blocage rencontré sur la validation MFA du
compte Twilio de l'utilisateur (SMS de vérification Twilio non reçu,
malgré plusieurs tentatives dont un appel vocal). Reporté à plus tard sur
demande explicite de l'utilisateur — le code applicatif ci-dessus reste
en l'état, prêt à être repris dès que Twilio sera configurable. **Le
provider Phone Supabase n'est toujours pas activé** : tant que ce n'est
pas fait, toute nouvelle inscription reste bloquée à l'écran de
vérification SMS (aucune façon de terminer une inscription) — raison de
plus pour NE PAS merger cette branche sur `main` avant que Twilio soit
opérationnel et testé.

## 3trentecinqtrentecies. Abonnement aux notifications par catégorie de produit (31/07) ⚠️ CODE PRÊT, SCRIPT SQL PAS ENCORE EXÉCUTÉ (secret webhook à renseigner)

3e des nouvelles fonctionnalités notées plus tôt dans la session
(parrainage / export RGPD / abonnement notifications — les deux premières
restent non commencées). Un client peut s'abonner à une catégorie précise
d'un pilier (ex: Anti-nuisibles → Insecticides) et reçoit une notification
push quand un nouveau produit y est ajouté.

**Nouveau** `supabase/phase36_patch_product_category_subscriptions.sql`
(**PAS ENCORE EXÉCUTÉ**) :
- Table `product_category_subscriptions` (customer_id, business_unit_id,
  category_name, unique sur le triplet) — RLS : chacun ne gère que ses
  propres abonnements (select/insert/delete, pas d'update nécessaire).
- 4e catégorie de notification **"produit"** (même plomberie que
  message/devis/commande, phase24+phase32) : colonne
  `profiles.notification_sound_produit` (défaut `notif_bulle_eau`,
  réservoir commun de sons déjà intégrés, pas de nouveau fichier audio
  nécessaire), contrainte `notification_sound_catalog` élargie, 20 lignes
  seedées pour cette catégorie.
- Trigger `on_new_product_push` (`after insert on products, when
  (NEW.visibility = true)`) — même modèle que phase17/phase18, réutilise
  l'Edge Function `send-push-notification` existante.

**⚠️ Avant d'exécuter ce script** : remplacer `<WEBHOOK_SECRET>` dans le
fichier par la même valeur secrète déjà utilisée pour les triggers
messages/commandes/devis (Edge Functions → send-push-notification →
Manage secrets → WEBHOOK_SECRET).

**Modifié** `supabase/functions/send-push-notification/index.ts` :
`Category` élargi à `"produit"` ; nouvelle branche `payload.table ===
"products"` — résout les abonnés via
`product_category_subscriptions.eq(business_unit_id,
category_name).select(customer_id)`, construit `recipientIds` à partir de
ça (contrairement aux autres branches qui connaissent déjà un destinataire
unique), rejoint la boucle d'envoi générique existante.

**Modifié** `lib/core/notifications/notification_sounds.dart` : ajout de
`NotificationCategory.produit` (label "Nouveaux produits", son par défaut
`notif_bulle_eau`) — se propage automatiquement à l'écran de choix des
sons (`notification_sounds_screen.dart`, déjà piloté par l'énumération) et
à la création des canaux Android au démarrage
(`push_notification_service.dart`, boucle déjà pilotée par l'énumération).
Seul point non piloté par l'énumération et corrigé manuellement : la
liste de colonnes codée en dur dans
`_syncSoundPreferencesFromServer()` (ajout de
`notification_sound_produit`).

**Nouveau** `lib/core/notifications/category_subscription_repo.dart` :
`isSubscribed`/`subscribe`/`unsubscribe`, CRUD simple sans cache (faible
fréquence d'utilisation).

**Modifié** `lib/presentation/client_home/catalog_tab.dart` : un
`ActionChip` "S'abonner aux nouveautés" / "Abonné aux nouveautés" apparaît
sous les puces de catégorie, **uniquement quand un pilier ET une
catégorie précis sont sélectionnés** (pas "tous piliers"/"toutes
catégories") — une catégorie choisie sans pilier précis pourrait exister
dans plusieurs piliers différents, ambigu pour l'abonnement. Statut
rechargé (`_refreshSubscriptionStatus`) à chaque changement de pilier/
catégorie.

**Terminé (31/07)** : script exécuté, `WEBHOOK_SECRET` créé comme secret
Edge Function (il n'existait pas du tout auparavant — découverte au
passage : les triggers phase17/phase18 utilisaient déjà une valeur
"réelle" trouvée en lisant `pg_proc.prosrc` du trigger messages existant,
réutilisée ici pour cohérence), fonction `send-push-notification`
redéployée avec la 4e catégorie. **Reste à tester** (s'abonner à une
catégorie, publier un produit dedans depuis l'Admin, vérifier la
notification) avant de merger sur `main`.

## 3trentesixtrentecies. Améliorations de l'accueil client (31/07) ✅ FAIT (pas de SQL)

Suite à une session de retours visuels sur l'accueil client (capture
d'écran fournie par l'utilisateur), 5 pistes ont été proposées puis
validées (sauf la bannière hero, volontairement laissée telle quelle —
contenu de test, pas un problème de design). Constat en cours de route :
2 des 5 étaient **déjà implémentées** (badge panier avec compteur, badge
"notifications" avec compteur — ce dernier réutilise en fait le nombre de
messages non lus, il n'existe pas de flux de notifications distinct).
Seuls 3 points restaient réellement à faire :

- **Salutation dynamique** : "Bonjour"/"Bonsoir" selon `DateTime.now().hour`
  (avant 5h ou après 18h → "Bonsoir") au lieu de "Bonjour" figé.
- **Icônes par catégorie** : nouvelle fonction `_iconForCategory` (mots-clés
  sur le nom, ex: "peinture"→pinceau, "carrelage"→grille, "insecticide"→
  anti-nuisible), même principe que `_iconForUnit` déjà existant pour les
  piliers — appliquée via `avatar:` sur les `ChoiceChip` de catégorie.
- **Bouton "Recommander" visible** : la carte "Vous recommandez souvent"
  avait déjà un bouton d'ajout rapide (icône "+" seule) — ajout d'un
  badge "🔁 Recommander" en haut à gauche de chaque carte, plus visible
  et explicite, qui ajoute directement au panier en 1 tap (même logique
  `_quickAddToCart`).
- **Écran de chargement (skeleton)** : remplace le spinner plein écran par
  un aperçu de la mise en page (en-tête, bannière, piliers, grille de
  produits) avec des rectangles qui pulsent doucement — fait main
  (`_ShimmerBox`/`_CatalogSkeleton` dans `catalog_tab.dart`) plutôt qu'un
  package tiers (`shimmer`), pour ne pas ajouter de dépendance non
  testable sans SDK Flutter local dans cet environnement.

Tout dans `lib/presentation/client_home/catalog_tab.dart`, aucun
changement SQL — mergeable indépendamment du reste de la branche dès
que testé visuellement.

## 3trentesepttrentecies. Appels audio/vidéo dans la messagerie — Agora (31/07) ⚠️ CODE PRÊT, SCRIPT SQL PAS ENCORE EXÉCUTÉ, `flutter pub get` NÉCESSAIRE

Demandé par l'utilisateur en même temps que les améliorations d'accueil.
Compte Agora créé par l'utilisateur (mode "Secure", 10 000 min gratuites/
mois), secrets `AGORA_APP_ID`/`AGORA_APP_CERTIFICATE` déjà ajoutés dans
Edge Functions → Manage secrets.

**⚠️ Limite MVP assumée** (documentée dans le script SQL) : sans
intégration CallKit (iOS)/ConnectionService (Android), l'appel ne sonne
pas comme un vrai appel téléphonique tant que l'app est fermée — une
notification push classique arrive, l'écran d'appel entrant et la
sonnerie ne s'affichent qu'au tap dessus ou si l'app est déjà ouverte.
Suffisant pour un usage normal, pas un remplacement d'un appel GSM.

**Nouveau** `supabase/phase37_patch_calls.sql` (**PAS ENCORE EXÉCUTÉ**) :
table `call_invitations` (conversation_id, caller_id, callee_id, call_type
'audio'|'video', channel_name, status 'ringing'|'accepted'|'declined'|
'ended'|'missed') — signalisation uniquement, aucun flux audio/vidéo n'y
transite (ça, c'est Agora directement entre les 2 téléphones). RLS : les
2 parties (appelant/appelé) peuvent lire/mettre à jour, seul l'appelant
peut créer. Trigger `after insert` réutilise `send-push-notification`
(même schéma que phase17/18/36) — **remplacer `<WEBHOOK_SECRET>`** par la
valeur réelle avant d'exécuter (Edge Functions → send-push-notification →
Manage secrets → WEBHOOK_SECRET — retrouvée cette fois-ci en lisant
`pg_proc.prosrc` du trigger messages existant, faute de secret déjà
enregistré nommé ainsi côté Dashboard).

**Nouveau** `supabase/functions/super-endpoint/index.ts` (contenu
"generate-agora-token", **nom déployé imposé par le Dashboard** — même
situation que hyper-endpoint/secure-login plus tôt dans la session) :
seule fonction ayant accès à `AGORA_APP_CERTIFICATE` (jamais côté
client) — génère un token via le package npm `agora-token` (importé
directement depuis esm.sh, pas de réimplémentation de l'algorithme de
signature Agora). `uid=0` volontairement (laisse le SDK choisir un uid à
la connexion) plutôt qu'un uid par utilisateur, pour simplifier — l'accès
au canal reste conditionné à une ligne `call_invitations` valide et à une
session Supabase authentifiée. "Verify JWT with legacy secret" désactivé
dans ses Settings, comme pour hyper-endpoint.

**Modifié** `supabase/functions/send-push-notification/index.ts` :
nouvelle branche `payload.table === "call_invitations"` — n'utilise PAS
le système de son par catégorie personnalisable (message/devis/commande/
produit) puisqu'un appel doit toujours sonner de façon reconnaissable,
pas selon une préférence ; construit `data: {type: 'call_invite', ...}`
consommé côté client pour afficher l'écran d'appel entrant plutôt qu'une
notification classique.

**Nouveau** côté app :
- `lib/core/calls/agora_token_repo.dart` — appelle `super-endpoint`.
- `lib/core/calls/call_repo.dart` — `createInvitation`/`updateStatus`.
- `lib/presentation/calls/call_screen.dart` — écran d'appel en cours
  (`agora_rtc_engine`), vue vidéo locale/distante ou avatar pour l'audio,
  contrôles (micro, haut-parleur/caméra selon le type, raccrocher).
- `lib/presentation/calls/incoming_call_screen.dart` — écran "appel
  entrant", sonnerie en boucle (réutilise l'asset son `notif_radar.wav`
  déjà intégré, pas de nouveau fichier), accepter/refuser, expire après
  45s sans réponse ("missed").

**Modifié** `lib/core/notifications/push_notification_service.dart` :
canal Android dédié `akorahub_calls` (en dehors du système de son
personnalisable) ; détection `data.type == 'call_invite'` dans les 3 états
possibles de l'app — `onMessage` (ouverte, pousse directement
`IncomingCallScreen` au lieu d'une notification classique via le
`navigatorKey` global `GlobalAuthListener`), `onMessageOpenedApp`
(arrière-plan, tap sur la notification) et `getInitialMessage()` (app
totalement fermée). Pas de canal Realtime Postgres séparé : le message
FCM en premier plan (`onMessage`) suffit déjà à couvrir le cas "app
ouverte", inutile de dupliquer avec un flux Realtime.

**Modifié** `lib/presentation/client_home/chat_screen.dart` (client) et
`lib/presentation/messaging_center_real/messaging_center_real.dart`
(`_AdminConversationThread`, staff) : boutons appel audio/vidéo dans
l'AppBar. Côté client, comme une conversation n'a pas de membre du staff
assigné (`conversations` n'a pas de colonne `staff_id`), l'appel cible en
priorité le dernier membre du staff ayant répondu dans cette conversation,
sinon n'importe quel Admin/Commercial (`_resolveCalleeStaffId`). Côté
staff, `_AdminConversationThread` a gagné un paramètre `customerId`
(absent avant ce chantier — seuls `conversationId`/`customerName`
existaient) passé depuis la liste des conversations qui l'avait déjà en
base (`conversations.customer_id`).

**Modifié** `pubspec.yaml` : ajout de `agora_rtc_engine: ^6.6.3`.
**`flutter pub get` (ou un build Codemagic) est nécessaire** — pas
vérifiable localement dans cet environnement (pas de SDK Flutter/Dart
installé ici).

**Modifié** permissions : `AndroidManifest.xml` (ajout
`MODIFY_AUDIO_SETTINGS`, `BLUETOOTH`, `BLUETOOTH_CONNECT`, `WAKE_LOCK` —
`CAMERA`/`RECORD_AUDIO`/`INTERNET` existaient déjà) ; `Info.plist`
(descriptions `NSCameraUsageDescription`/`NSMicrophoneUsageDescription`
élargies pour mentionner aussi les appels, en plus du scan QR/messages
vocaux déjà couverts).

**Terminé (31/07)** : script phase37 exécuté avec succès (secret
substitué avec la vraie valeur), Edge Function de génération de token
déployée (sous le nom `super-endpoint` — même situation de nommage
imposé par le Dashboard que hyper-endpoint/secure-login, "Verify JWT with
legacy secret" désactivé). **Reste à tester** : un appel réel de bout en
bout (audio ET vidéo, dans les 2 sens client→staff et staff→client).

## 3trentehuittrentecies. Paiement en ligne automatique — Papi.mg (31/07) ✅ DÉPLOYÉ ET MERGÉ SUR MAIN, TEST SANDBOX EN COURS

L'utilisateur a reçu un accès (clé API test) à **Papi.mg**, agrégateur de
paiement malgache (MVola/Orange Money/Airtel Money/Visa via BRED),
identifié comme piste depuis longtemps (voir sections 4 et 3trentecies —
"statut marchand MVola non confirmé"). Doc technique complète fournie en
PDF (flux de paiement par lien + webhook de confirmation).

**Décision utilisateur sur l'intégration** (parmi 2 options proposées) :
Mvola/Orange Money/Airtel Money passent maintenant par Papi
**automatiquement** (le client est redirigé vers une page de paiement
sécurisée, confirmation automatique par webhook) — **plus besoin** de
taper une référence ni d'uploader une preuve, plus de vérification
manuelle par le staff pour ces 3 méthodes. Nouveau réglage Admin **"Mode
manuel (secours)"**, désactivé par défaut : permet de revenir
temporairement à l'ancien flux manuel (référence + photo) si Papi est
indisponible. Virement bancaire et paiement à la livraison restent
toujours manuels (Papi ne les gère pas).

**Nouveau** `supabase/phase38_patch_papi_payment.sql` (**PAS ENCORE
EXÉCUTÉ**) :
- `orders.papi_notification_token`/`orders.papi_payment_link` (nouvelles
  colonnes).
- `orders_payment_status_check` élargi avec `'echoue'` (paiement Papi
  rejeté — différent de "en_attente" qui veut dire "jamais tenté").
- `payment_method_settings` : nouvelle ligne `manuel_fallback` (pas un
  `PaymentMethod` de l'app — un interrupteur Admin, invisible du
  sélecteur client, désactivé par défaut).
- Trigger `on_order_payment_confirmed_push` (table synthétique
  `orders_payment_status`, même modèle que phase17/18/36/37) — notifie
  le client dès que Papi confirme/rejette (réutilise la catégorie de son
  "commande" existante).

**⚠️ Avant d'exécuter** : remplacer `<WEBHOOK_SECRET>` par la valeur
réelle (`ABwYFNXH_gey3LMR2hMVpLb_NQn41aEXuJFzOHiepu8`, la même que pour
tous les autres triggers push cette session).

**Nouveau** `supabase/functions/create-papi-payment-link/index.ts`
(**PAS ENCORE DÉPLOYÉ**) : reçoit `{orderId}`, vérifie que la commande
appartient bien à l'appelant, appelle
`POST https://app.papi.mg/dashboard/api/payment-links` avec la clé API
Papi (secret `PAPI_API_KEY`, jamais côté client), stocke le
`notificationToken` reçu sur la commande (nécessaire pour vérifier
l'authenticité du webhook plus tard), retourne le `paymentLink` à
l'app.

**Nouveau** `supabase/functions/papi-payment-notification/index.ts`
(**PAS ENCORE DÉPLOYÉ**) : endpoint public appelé directement par Papi
(pas par l'app) à la fin du paiement. Vérifie que `paymentReference`
correspond à une commande ET que `notificationToken` correspond à celui
stocké — sans ça, n'importe qui connaissant un numéro de commande
pourrait forger une fausse confirmation. Met à jour `payment_status`
('paye' ou 'echoue'). Répond toujours HTTP 200 même en cas de rejet
d'authenticité (pour ne pas déclencher de réessais infinis côté Papi) —
les tentatives suspectes sont seulement journalisées dans les Logs de
la fonction.

**Modifié** `supabase/functions/send-push-notification/index.ts` :
nouvelle branche `payload.table === "orders_payment_status"`.

**Nouveau/Modifié côté app** :
- `lib/core/payment/papi_payment_repo.dart` — appelle
  `create-papi-payment-link` (nom réel à vérifier après déploiement, vu
  le précédent avec hyper-endpoint/super-endpoint).
- `lib/core/payment/payment_methods.dart` — nouveau getter
  `isPapiCapable` (true pour mvola/orange_money/airtel_money).
- `lib/core/payment/payment_method_settings_repo.dart` —
  `isManualFallbackEnabled`/`setManualFallbackEnabled`.
- `lib/presentation/payment_methods_management/payment_methods_management.dart` —
  nouvelle carte "Mode manuel (secours)" sous la liste des méthodes.
- `lib/presentation/client_home/cart_tab.dart` — `_showManualPaymentFields`
  détermine si l'encadré référence+photo s'affiche ; sinon, message
  "vous serez redirigé..." ; après création de la commande, si Papi
  s'applique, génère le lien et l'ouvre via `url_launcher`
  (`LaunchMode.externalApplication`) — un échec à cette étape n'annule
  pas la commande (déjà créée, payment_status reste "en_attente", le
  client peut réessayer plus tard).

**Limite connue (offline)** : si le client passe commande hors-ligne
avec Mvola/Orange/Airtel et Papi actif, la commande est mise en file
d'attente normalement mais **aucun lien de paiement n'est généré**
(impossible sans réseau) — elle nécessitera un suivi manuel une fois
synchronisée. Cas marginal, non traité pour l'instant.

**Fait** : secret `PAPI_API_KEY` créé, phase38 exécuté, les 2 nouvelles
Edge Functions déployées (avec leurs vrais noms cette fois, pas de
renommage nécessaire) + `send-push-notification` redéployé, branche
mergée sur `main` (commit `40b8aaf`, build Codemagic relancé).

**Précision du support Papi (mail du 31/07, à retenir pour la mise en
prod)** : une "boutique" Papi n'a qu'**une seule clé API**, valable à la
fois en test et en production — c'est le **Mode de la boutique**
(Test/Production) qui détermine si l'argent bougé est réel, pas la clé
elle-même. Papi recommande **deux boutiques séparées** (une "Test", une
"Production") plutôt qu'un simple bouton bascule sur une boutique
unique. Concrètement : la clé `PAPI_API_KEY` actuellement configurée
correspond à la boutique "Akora Fanadiovana" en **Mode test** — elle ne
traitera donc jamais de vrai argent, seulement les scénarios simulés
(numéros de test documentés). Le jour de la mise en prod : créer une
**seconde** boutique en Mode production sur le dashboard Papi, récupérer
sa clé API dédiée, et **remplacer** la valeur du secret `PAPI_API_KEY`
par celle-ci (pas de bascule de mode sur la boutique existante).

**Reste à faire** : tester un paiement complet en sandbox (numéros de
test documentés par Papi, ex: `0341230001` pour un succès Mvola,
`0341230002` pour un échec) via le build Codemagic, puis vérifier le
toggle "Mode manuel (secours)".

**⚠️ Build Codemagic cassé après le merge (31/07)** : `agora_rtc_engine
^6.6.3` exige `ffi ^1.1.2`, incompatible avec `share_plus ^12.0.2` qui
exige `ffi ^2.1.2` — pub échoue à résoudre les dépendances
("version solving failed"). Corrigé en plafonnant
`agora_rtc_engine: ^6.5.4` (suggestion de `pub` lui-même) ; le code
d'appel (`call_screen.dart`) n'utilise que des API stables présentes
dans cette version, aucun changement de code nécessaire.

**Grille tarifaire Papi (PDF fourni par l'utilisateur, 31/07)** — frais
côté **marchand**, déduits de ce qui est reversé à AkoraHub, **pas**
ajoutés à ce que le client paie au checkout :
- **Mode Direct** (AkoraHub a déjà ses propres comptes marchands
  Mvola/Orange/Airtel/banque — statut non confirmé à ce jour, voir
  section 3trentecies) : **1,20 %** quel que soit le moyen de paiement
  (Visa/Mastercard, Mvola, Orange Money, Airtel Money), + les frais de
  l'opérateur/de la banque facturés séparément par eux.
- **Mode Transit** (Papi encaisse d'abord, puis reverse à AkoraHub —
  c'est très probablement le mode actuel, faute de comptes marchands
  propres) : Visa/Mastercard 4,20 %, Mvola 3,80 %, Orange Money 3,60 %,
  Airtel Money 3,60 % — tout compris (opérateurs inclus).
- Exemple concret : commande de 11 000 MGA en Mode Transit/Mvola (3,80%)
  → le client paie bien 11 000 MGA, mais AkoraHub ne reçoit que
  ~10 582 MGA net (Papi garde 418 MGA).
- **Contexte** : l'utilisateur a remarqué (sans chiffres précis à
  l'appui) que "le total d'achat est plus élevé en utilisant Papi" —
  cette grille ne l'explique probablement pas telle quelle (frais
  marchand, pas surcharge client), l'hypothèse retenue reste que le
  "Total" affiché inclut déjà les frais de livraison (`total +
  delivery_fee`, même formule quel que soit le mode de paiement, voir
  `cart_tab.dart`) — à confirmer avec un exemple chiffré précis
  (Total panier vs montant demandé par Papi) si le doute persiste.
- **Reste à vérifier** : si le dashboard Papi permet de répercuter ces
  frais sur le client plutôt que de les déduire du versement — non vu
  dans cette documentation, à checker si le doute persiste après un
  test chiffré.

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
- **Multi-langue** Français/Malagasy : infrastructure + 1er passage faits
  (nav du bas, en-têtes Accueil — voir 3duodecies), la grande majorité des
  écrans reste en français codé en dur. **Préférence explicite de
  l'utilisateur : ne traduire qu'un seul écran à la fois, sur demande
  explicite nommant l'écran** — ne pas continuer par anticipation.
- **Paiement en ligne réel** (carte bancaire / marchand Mobile Money) :
  toujours pas intégré — dossier BNI P@y (compte marchand) en attente de
  réponse, statut marchand Mobile Money non confirmé. **Solution de pont
  ajoutée en attendant (30/07, voir 3septtrentecies/3octotrentecies)** :
  4 modes de paiement manuels sélectionnables au checkout (paiement à la
  livraison, virement bancaire BNI, Orange Money, Mvola, Airtel Money),
  chacun activable/désactivable par l'Admin — le staff vérifie la
  réception manuellement, ce n'est pas un vrai paiement en ligne
  automatisé.

## 5. Conventions et pièges à connaître

- **Toujours vérifier la compilation** après une modification en poussant sur
  `main` et en consultant `https://github.com/Anju-codermad/AkoraHub-app/actions`
  via l'API GitHub (`GET /repos/Anju-codermad/AkoraHub-app/actions/runs`)
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

**⚠️ Dépôt renommé (23/07)** : `Anju-codermad/akora-fanadiovana-app` →
**`Anju-codermad/AkoraHub-app`**. L'ancien nom redirige encore
automatiquement (GitHub le fait par défaut après un renommage), mais
utiliser le nouveau nom pour tout nouveau clone/remote/lien.

**⚠️ Contradiction détectée et résolue (25/07)** : une note plus ancienne
dans ce fichier indiquait que l'utilisateur avait demandé de tout
consolider dans une seule conversation. Une autre conversation, menée en
parallèle le même jour, a reçu l'instruction inverse : les deux
conversations **continuent bien en parallèle**, confirmé explicitement par
l'utilisateur après qu'on lui ait signalé la contradiction. **C'est cette
version qui fait foi** — si un futur fil trouve encore une mention
"consolidé en une seule conversation" quelque part, elle est obsolète.

**Périmètre complet des deux côtés** : les deux conversations ont un accès
complet et non restreint à tout le dépôt (plus de partition par dossier
depuis le 23-25/07). N'importe quelle conversation peut modifier
n'importe quel fichier, y compris `lib/core/`, `supabase/*.sql`, les
écrans Admin, et `lib/presentation/client_home/*`.

**Conséquence directe : le risque de collision de fichiers est réel**,
puisqu'il n'y a plus de "chacun son dossier" comme garde-fou. Discipline
Git impérative pour toute conversation qui reprend ce projet :
1. `git fetch` systématique avant tout push, jamais de push en force
2. Si des commits distants sont apparus entre-temps (ça arrive
   régulièrement — plus de 80 commits sont arrivés en quelques jours lors
   d'une session parallèle) : ne pas essayer de fusionner à la main un
   historique périmé. Réinitialiser sur l'état distant (`git reset --hard
   origin/main`) si son propre travail local n'a pas encore été poussé,
   puis relire ce fichier à jour avant de continuer — plutôt que de
   raisonner sur une version obsolète du projet.
3. Documenter tout changement significatif dans ce fichier avant de
   pousser le dernier commit de la session, pour que l'autre conversation
   le voie à sa prochaine lecture. En cas de doute sur une décision déjà
   prise (comme cette contradiction), la signaler explicitement à
   l'utilisateur plutôt que de trancher seul.

Plusieurs fusions automatiques propres ont déjà eu lieu entre le 23 et le
25/07 sans perte de code d'aucun côté, et un doublon fonctionnel (deux
systèmes de messagerie construits indépendamment) a été détecté et résolu
— voir section 3bis. Cette discipline fonctionne, à condition de la
suivre à chaque fois, même pour un fichier qu'on pense être "le sien".

## 6bis. Comment reprendre le fil (pour toute conversation)

1. `git pull` (ou `git fetch` + `git reset --hard origin/main` si son
   propre historique local est périmé) avant de commencer
2. Lire ce fichier en entier + les dernières entrées de `CHANGELOG.md`
3. Accès complet à tout le dépôt des deux côtés (section 7) — vérifier
   l'historique Git avant de toucher un fichier qui pourrait avoir été
   modifié récemment par l'autre conversation
4. Mettre à jour ce fichier (sections 3, 4 et 7 si besoin) avant de pousser
   le dernier commit de la session

