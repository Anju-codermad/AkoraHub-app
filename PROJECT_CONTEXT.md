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

## 3trenteneuftrentecies. Rendre le paiement manuel plus "pro" (31/07) ✅ FAIT

Après la mise en place de Papi, l'utilisateur a demandé si le flux manuel
restant (virement bancaire, paiement à la livraison) pouvait devenir aussi
"pro" qu'un flux API. Distinction posée avant tout code : paiement à la
livraison ne pourra jamais devenir une API (argent liquide remis en main
propre) ; virement bancaire pourrait en théorie le devenir si BNI
Madagascar proposait une API entreprise, mais c'est un nouveau projet
externe (à explorer plus tard si besoin) — **l'utilisateur a choisi de
polir l'existant plutôt que d'explorer cette piste bancaire**.

Point précis identifié après relecture du code existant (déjà assez
soigné côté client — bouton copier les coordonnées, aperçu photo — et
côté admin — chips colorés, bouton rapide "Confirmer le paiement reçu",
filtre paiements en attente) : **le client n'avait aucune visibilité sur
le statut de son paiement** une fois la commande passée — `orders_tab.dart`
affichait le statut de livraison (Reçue → Expédiée → Livrée) mais jamais
`payment_status`.

- **`lib/presentation/client_home/orders_tab.dart`** : ajout d'un badge
  coloré (point + libellé) sous le mode de paiement dans chaque carte de
  commande — "Paiement en attente"/"Paiement confirmé"/"Paiement
  échoué"/etc. Pour les méthodes non-Papi en attente, ajoute
  "· vérification sous 24h ouvrées" pour fixer une attente claire.
- **`lib/presentation/client_home/cart_tab.dart`** : le message de succès
  après une commande nécessitant vérification manuelle (référence+photo)
  annonce maintenant explicitement ce délai de 24h et qu'une notification
  suivra.
- **`lib/presentation/order_management_real/order_management_real.dart`** :
  bug corrigé au passage — le statut `'echoue'` (ajouté avec Papi) n'avait
  ni libellé (`_paymentStatusLabels`) ni couleur (`_paymentColor`) côté
  admin, retombant sur un gris neutre peu visible pour un paiement Papi
  refusé.

**Estimation des frais de retrait Mvola (31/07, suite)** : l'utilisateur a
fourni la grille tarifaire officielle Mvola ("Auprès d'un Cash Point
Mvola") et a demandé qu'elle soit visible **par le client**, à titre
purement informatif (le client continue de payer le même montant — ce
n'est pas ajouté au prix, contrairement à la piste "commission Papi
répercutée sur le client" écartée plus tôt). Décision explicite via
AskUserQuestion (3 options : admin seul / transparence client / ajouté au
prix client → **transparence client** choisie).

**⚠️ Limite connue, assumée** : le palier de frais Mvola dépend du montant
**total retiré en une fois** par le marchand (qui peut cumuler plusieurs
commandes avant un seul retrait), pas du montant d'une commande isolée —
et si le paiement passe par **Papi** plutôt que par un vrai retrait Mvola
manuel, l'argent atterrit peut-être directement sur un compte bancaire
(pas via un retrait Mvola), rendant ce frais non pertinent. Le calcul
implémenté est donc une **approximation** (suppose que cette commande
serait retirée seule), affichée uniquement pour Mvola en **mode manuel**
(jamais pour Mvola via Papi) — libellé explicitement "à titre indicatif".

- **Nouveau** `lib/core/payment/mvola_withdrawal_fee.dart` :
  `MvolaWithdrawalFee.estimate(montant)`, grille de paliers (100 Ar pour
  100-1 000 Ar, jusqu'à 100 000 Ar pour 19-20M Ar) codée en dur depuis la
  capture fournie.
- **`cart_tab.dart`** : note affichée sous les coordonnées Mvola
  (uniquement si `_paymentMethod == PaymentMethod.mvola` et mode manuel
  actif), calculée sur `total + frais de livraison`.

**Notification push immédiate au staff (31/07, suite)** ✅ CODE PRÊT, PAS
ENCORE DÉPLOYÉ — l'utilisateur a validé la recommandation (réduire le
délai humain de vérification plutôt que du polish visuel supplémentaire).

**Nouveau** `supabase/phase39_patch_manual_payment_staff_notification.sql`
(**PAS ENCORE EXÉCUTÉ**) : trigger `on_order_manual_payment_submitted_push`
sur `orders`, **after insert**, `when (NEW.payment_reference is not null or
NEW.payment_proof_path is not null)` — ne se déclenche donc que pour
virement bancaire ou Mvola/Orange/Airtel en mode manuel de secours (voir
`_showManualPaymentFields` dans `cart_tab.dart`), jamais pour paiement à
la livraison ni Papi. Table synthétique `orders_manual_payment_submitted`
(même modèle que `orders_payment_status`) pour ne pas se confondre avec
les triggers existants sur la même table `orders`.

**Modifié** `supabase/functions/send-push-notification/index.ts` :
nouvelle branche `payload.table === "orders_manual_payment_submitted"`,
notifie toute l'équipe (Admin/Commercial, même modèle que la branche
`quotes`) — titre "Paiement à vérifier", corps mentionnant le numéro de
commande et le mode de paiement.

**Reste à faire** : exécuter phase39 (remplacer `<WEBHOOK_SECRET>` par la
valeur réelle) et redéployer `send-push-notification`.

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

## Phase 40-41 — "Formation" : base de matières premières + abonnement payant (01/08)

Demande de l'utilisatrice : transformer le pilier "Formation" (jusqu'ici
juste mentionné, jamais construit — voir section 1) en une vraie base de
référence des matières premières/ingrédients utilisés en fabrication
(chimiques, cosmétiques, agroalimentaires), avec une fiche détaillée par
ingrédient façon fiche technique (maquette de référence : capture d'une
fiche EDTA fournie par l'utilisatrice). Distinct du catalogue de vente
(`products`) : ces fiches ne sont **jamais commandables**. Accès : la
liste (nom/catégorie/stock/photo) reste visible par tout client connecté,
mais le détail complet (description, dosages par usage, conditionnement,
historique de prix) est réservé au staff et aux clients avec un
**abonnement Formation payant actif** (abonnement global, pas ingrédient
par ingrédient — décision explicite de l'utilisatrice).

**Schéma** (`supabase/phase40_schema.sql`) :
- `raw_materials` (fiche complète — RLS restreinte staff/abonné actif via
  `public.has_active_formation_subscription(uid)`), `raw_material_images`
  (galerie, même mécanique que `product_images`/phase8), `raw_material_usages`
  (domaine Nettoyage/Cosmétique/Agroalimentaire/Industriel + dosage,
  **lié à un vrai produit du catalogue** via `product_id` — texte libre
  `usage_label` en repli si la formule n'est pas encore un produit vendable,
  demande explicite de l'utilisatrice le 01/08), `raw_material_packaging`
  (conditionnement + prix optionnel), `raw_material_price_history`.
- Vue `raw_materials_preview` (id/pilier/catégorie/nom/stock/photo
  uniquement) — même pattern que `public_profiles` (phase9) : exécutée
  avec les droits du propriétaire, donc lisible par tout utilisateur
  connecté même si la RLS de `raw_materials` est restrictive. C'est elle
  qui alimente la liste "toujours visible" côté client.
- `formation_subscriptions` (mensuel/annuel, paiement manuel — référence +
  preuve, réutilise le bucket privé `payment-proofs` de phase29 — validé
  par le staff, même principe que les commandes) + `formation_plan_pricing`
  (tarifs modifiables par l'Admin).
- Bucket Storage `raw-materials` (public en lecture, écriture staff — même
  modèle que le bucket `products`).
- **Contenu (`supabase/phase41_patch_seed_raw_materials.sql`)** : à la
  demande explicite de l'utilisatrice ("vous avez la meilleure possibilité
  que moi pour avoir des informations complètes"), Claude a rédigé
  lui-même description + précaution de sécurité pour les ~190 matières
  premières déjà listées dans `phase33_patch_raw_material_name_suggestions.sql`
  (connaissances chimiques/cosmétiques/agroalimentaires générales et bien
  établies). **Volontairement laissés vides** : prix, usages liés à un
  produit précis, conditionnement — données opérationnelles réelles que
  seule l'utilisatrice connaît (coût fournisseur, formats réellement
  stockés, dans quel produit exact chaque matière est utilisée) ; les
  inventer aurait été dangereux dans une vraie application métier. Script
  idempotent (`on conflict do nothing`, contrainte unique ajoutée sur
  `raw_materials`).

**Admin** : `lib/presentation/raw_materials_management/` — liste
(recherche + filtre par pilier, chip stock coloré) et fiche éditeur
complète (galerie photo, Autocomplete nom avec pré-remplissage catégorie
depuis les suggestions phase33, catégorie via le cache partagé existant
+ ajout à la volée, statut de stock par puce colorée, description,
danger, prix actuel avec historique automatique à chaque changement de
prix + ajout manuel d'anciens prix, usages groupés par domaine avec
sélecteur de produit du catalogue via Autocomplete, conditionnement).
`lib/presentation/formation_subscriptions_management/` : validation des
demandes d'abonnement (Activer/Refuser, preuve de paiement via URL
signée) + édition des tarifs. Accessible depuis Menu "Plus" → "Matières
premières (Formation)" (et son bouton d'action vers les abonnements).

**Client** (`lib/presentation/client_home/formation/`) :
`FormationCatalogScreen` (liste + bandeau d'incitation à l'abonnement si
non abonné, cadenas sur les vignettes), `RawMaterialDetailClient` (fiche
complète — icônes/couleurs par famille chimique et par domaine d'usage,
badge danger, courbe d'évolution du prix dessinée à la main avec
`CustomPainter`, pas de nouvelle dépendance), `FormationSubscriptionScreen`
(choix du plan, mode de paiement manuel, référence + preuve optionnelle).
**⚠️ Correction (01/08) — la base de matières premières n'est PAS le vrai
"AkoraFormation"** : l'utilisatrice a fourni un document
("Akora_Activites_Piliers.md") détaillant les 3 piliers réels du Groupe
Akora — Produits (Akora Home/Pro/Soins/Protect + Peinture), Services
(Akora Services), Formations (AkoraFormation, vrais cours/modules e-
learning, ex: "Eau de Javel — 8 modules déjà développés"). La base de
matières premières construite ci-dessus correspond en réalité à **"Akora
Pro"** (matières premières/emballages B2B — ses 11 catégories recoupent
presque exactement celles déjà seedées), PAS à "AkoraFormation" (qui est
un système de cours à part, pas encore construit). Décision actée avec
l'utilisatrice : ne pas tout restructurer maintenant (gros chantier
séparé — Akora Home/Soins/Protect, Services, vraies Formations à créer
plus tard) ; corriger seulement le code pour qu'il ne dépende plus du mot
"formation". `catalog_tab.dart` détecte maintenant directement les 3
piliers existants par leur `slug` stable (`matieres-premieres`,
`matieres-premieres-peinture`, `anti-nuisibles`) plutôt que par mot-clé
"formation" — un rename de pilier (ex: "Matières Premières" → "Akora
Pro") ne change que `name`, jamais `slug` (voir
`business_units_management.dart`), donc renommer l'affichage ne casse
rien. L'icône 🎓 mappée sur le mot-clé `formation` (inchangée) reste prête
pour le futur vrai pilier AkoraFormation (cours), pas encore créé.

**⚠️ Action requise côté utilisatrice** : exécuter
`phase40_schema.sql` (version corrigée du 01/08 — l'ordre de création a
été corrigé, `has_active_formation_subscription()` doit exister avant les
policies qui la référencent) puis `phase41_patch_seed_raw_materials.sql`
dans Supabase SQL Editor (dans cet ordre). **Aucun nouveau pilier à
créer** : les piliers "Matières Premières", "Matières Premières Peinture"
et "Anti-Nuisibles" existent déjà (phase10) et déclenchent automatiquement
l'écran Formation au tap — juste les activer depuis "Piliers
d'entreprise" s'ils ne le sont pas déjà. Renommer "Matières Premières" en
"Akora Pro" est optionnel, purement cosmétique.

**✅ Fait (01/08)** : phase40 (corrigé) + phase41 exécutés avec succès par
l'utilisatrice — 192 matières premières confirmées en base (174 Matières
Premières / 10 Matières Premières Peinture / 8 Anti-Nuisibles).

**Phase 42 — alignement partiel sur le document Groupe Akora (01/08)** :
`supabase/phase42_patch_produits_categories.sql`, **écrit, pas encore
exécuté par l'utilisatrice** (à faire dans le même SQL Editor, une seule
fois). Volontairement limité au sans-risque : nouveau
pilier **Akora Soins** (cosmétique produit fini, 5 catégories, inactif
par défaut), + catégories manquantes ajoutées sur Akora Fanadiovana
(Cire & Bougie, Produits spécialisés) et Anti-Nuisibles (Traitement de
l'eau & Piscine).

**⚠️ Reste à faire (décision explicite de reporter à une session dédiée,
pas d'oubli)** :
1. **Renommage cosmétique des piliers existants** (aucun risque, mais
   laissé à l'utilisatrice via "Piliers d'entreprise" plutôt qu'un script
   SQL aveugle sur un nom non vérifié) : Akora Fanadiovana → Akora Home,
   Matières Premières → Akora Pro, Anti-Nuisibles → Akora Protect, ARCA
   PAINTS → Peinture.
2. **Recatégorisation d'Akora Pro** : les 11 catégories du document
   ("Cosmétique", "Agroalimentaire"...) classent PAR USAGE, alors que les
   12 catégories déjà en place (Tensioactifs, Solvants, Acides & Bases...)
   classent PAR FAMILLE CHIMIQUE — pas de correspondance ligne à ligne
   avec les 192 matières premières déjà seedées. À trancher consciemment
   avec l'utilisatrice avant de reclasser quoi que ce soit.
3. **Akora Services** (7 catégories, ~24 prestations) : nouveau pilier de
   type "service" (pas un produit stocké avec prix/quantité) — modèle de
   données à concevoir, probablement branché sur le système de devis déjà
   existant (`quotes`) plutôt qu'un ajout direct au panier.
4. **Le vrai AkoraFormation** (7 catégories, ~40 modules, dont 12 "déjà
   développés") : système de cours/e-learning à part entière (modules,
   suivi de progression, statut développé/à créer) — **distinct de la
   base de matières premières** (Akora Pro) construite en phase40/41,
   malgré le nom similaire. Pas commencé.

Document source complet fourni par l'utilisatrice :
`Akora_Activites_Piliers.md` (3 piliers Produits/Services/Formations,
détail des ~150 SKU produits, ~24 prestations services, ~40 modules
formation) — redemander le fichier à l'utilisatrice si une future session
doit reprendre ce chantier, il n'est pas commité dans le dépôt.

**Renommage effectué par l'utilisatrice (01/08)** : Akora Fanadiovana →
**Akora Home**, Matières Premières → **Akora Pro**, Anti-Nuisibles →
**Akora Protect**, ARCA PAINTS → **Peinture**, Matières Premières
Peinture → **Peinture Pro** (nom choisi ensemble, "Arca" écarté — pas
encore confirmé comme marque). Elle a aussi créé elle-même le pilier
**AkoraFormation** (`akoraformation`), actuellement vide (le vrai système
de cours n'existe pas encore, voir point 4 ci-dessus).

**⚠️ Refonte de l'accès Formation (01/08, faite)** : en renommant, l'utilisatrice
a repéré un vrai problème de conception, pas juste un souci de nom —
3 piliers "Produits" (Akora Pro, Peinture Pro, Akora Protect) étaient
détournés de leur rôle : taper dessus ouvrait TOUJOURS l'écran Formation
(matières premières), jamais un catalogue de produits, même si de vrais
produits finis y étaient ajoutés un jour (ex: Akora Protect doit pouvoir
vendre de vrais insecticides finis). Corrigé :
- `catalog_tab.dart` : le cas spécial par `slug` (`rawMaterialSlugs`) est
  **supprimé** — tous les piliers filtrent maintenant la grille produits
  de la même façon, sans exception.
- `FormationCatalogScreen` (`client_home/formation/formation_catalog_screen.dart`) :
  ne prend plus `businessUnitId`/`businessUnitName` en paramètre — charge
  **toute** la vue `raw_materials_preview` (tous piliers confondus), avec
  un double filtre par puces (pilier d'origine + catégorie chimique).
  Titre fixe "Formation".
- **Nouveau point d'entrée unique** : `client_home/profile_tab.dart`,
  entrée de menu "Formation" (sous "Messagerie", au-dessus de "Scanner un
  produit") → `Navigator.push(FormationCatalogScreen())` sans argument.
  C'est désormais le seul chemin pour atteindre la base Formation côté
  client — plus aucun pilier de l'Accueil n'y mène.

## Phase 43 — Première brique du vrai AkoraFormation (cours/modules, 01/08)

Suite directe du point 4 différé plus haut : l'utilisatrice a demandé
d'ajouter "les listes de modules de formation complète" pour tout
vérifier ensemble avant de relancer un build. Portée volontairement
limitée à la **structure** (catégorie, titre, statut, nombre de
modules) — pas encore le contenu réel des cours (vidéos, leçons), qui
reste un chantier à part entière pour plus tard.

- `supabase/phase43_patch_formation_courses.sql` : table
  `formation_courses` (category, title, status
  `deja_developpee`/`en_projet`/`a_creer`, module_count nullable,
  sort_order), lecture publique (pas de paywall — c'est une vitrine, pas
  du contenu sensible comme les matières premières), écriture staff.
  Seedée avec les 45 formations des 7 catégories du document
  (Entretien & Hygiène, Soins Capillaires & Beauté, Peinture, Cire &
  Bougie, Agroalimentaire, Chimie Fondamentale, Coaching Entrepreneur).
- Admin : `lib/presentation/formation_courses_management/` — liste
  groupée par catégorie, ajout/édition/suppression, changement de statut
  par puce colorée. Accessible depuis Menu "Plus" → "AkoraFormation —
  Cours & Modules".
- Client : `client_home/formation/akora_formation_screen.dart` — liste
  filtrable par catégorie avec badge de statut (Disponible/Bientôt
  disponible/À venir). **Bien distinct** de l'écran "Formation" (matières
  premières) — accessible depuis une entrée de menu séparée dans le
  Profil, "AkoraFormation", juste en dessous de "Formation". Pas de
  paywall : le contenu réel des cours "Disponible" n'est pas encore
  consultable depuis l'app, ce n'est qu'une liste/roadmap pour l'instant.

## Paiement Papi + manuel simultanés, choix du client (01/08)

Demande explicite : Mvola/Orange Money/Airtel Money doivent proposer les
deux modes de paiement **en même temps** (automatique via Papi et manuel
avec référence/preuve), au client de choisir — jusqu'ici c'était un
réglage Admin global (`manuel_fallback`, phase38) qui imposait l'un OU
l'autre à tout le monde.

`cart_tab.dart` : nouveau champ d'état `_payAutomatically` (choix du
client, pas de l'Admin, défaut `true`). Pour une méthode `isPapiCapable`,
deux `ChoiceChip` ("Paiement automatique en ligne" / "Paiement manuel
(référence)") s'affichent tant que le secours manuel Admin n'est pas
forcé — le client bascule librement, chaque choix affiche l'encart
correspondant (redirection Papi, ou coordonnées + référence + preuve).
`_manualFallback` (réglage Admin, `payment_methods_management.dart`)
garde son rôle de **secours d'urgence** : activé, il force TOUT LE MONDE
en manuel (ex: Papi en panne) — il ne représente plus le fonctionnement
normal, juste l'exception. Libellé de l'écran Admin mis à jour en
conséquence.

**Vérifié au passage (déjà correct, aucun changement nécessaire)** :
- Frais de livraison (`delivery_pricing.dart`) : formule
  `max(3000 + 800×distance_corrigée, 4000)` donne déjà ~4120 Ar à 1 km et
  ~6360 Ar à 3 km — cohérent avec la demande "1 à 3 km à partir de
  4000 Ar".
- Frais de retrait Mvola (`mvola_withdrawal_fee.dart`) : grille tarifaire
  officielle déjà en place (discutée le 31/07), affichée au client dans
  l'encart de paiement manuel Mvola (`cart_tab.dart`, ligne ~755).

**Frais de retrait aussi affiché en paiement automatique + ajout Orange
Money (01/08)** : l'estimation du frais de retrait s'affichait
uniquement en mode manuel — ajoutée aussi dans l'encart de paiement
automatique (Papi), car le staff retire l'argent de la même façon quelle
que soit la méthode utilisée par le client. L'utilisatrice a ensuite
fourni la grille tarifaire officielle Orange Money ("Infos Tarifs",
capture) : ses paliers "Retrait" sont **identiques** à ceux de Mvola sur
toute la plage confirmée (200 Ar à 1 000 000 Ar) — `mvola_withdrawal_fee.dart`
renommé en `mobile_money_withdrawal_fee.dart` (classe
`MobileMoneyWithdrawalFee`), une seule grille sert désormais aux deux
opérateurs. Affiché dans `cart_tab.dart` pour Mvola ET Orange Money
(libellé dynamique selon la méthode choisie). Au-delà de 1 000 000 Ar,
seuls les paliers Mvola ont été vus en capture ; réutilisés par
extrapolation pour Orange Money — à corriger si l'utilisatrice fournit
un jour la grille Orange Money complète au-delà de ce montant.

## Onglet "Académie" dans la barre de navigation client (01/08)

Demande explicite : rendre Formation visible directement dans la barre
du bas, pas seulement depuis le Profil. Clarification importante de
l'utilisatrice une fois la question posée : elle voit "Formation"
(matières premières) et "AkoraFormation" (cours) comme **un seul et même
concept** — "le matières premières fait partie d'autres modules de
formation" — pas deux destinations séparées.

Résultat : nouvel écran `client_home/formation/formation_hub_screen.dart`
(`FormationHubScreen`) — liste unique où les 7 catégories AkoraFormation
(Entretien & Hygiène, Peinture...) et "Matières premières" apparaissent
comme des cartes de même niveau, une de plus parmi les autres. Taper une
catégorie de cours ouvre `AkoraFormationScreen` (nouveau paramètre
`initialCategory`, pré-sélectionne la catégorie sans bloquer le
changement ensuite) ; taper "Matières premières" ouvre
`FormationCatalogScreen` (abonnement requis pour le détail).

`client_home.dart` : 4ᵉ onglet ajouté à `_ClientBottomNav`
(pageIndex 4, entre "Commandes" et "Profil" — la barre était
volontairement réduite à 3 onglets, voir doc de la classe `ClientHome`,
mais Formation est jugée assez centrale pour justifier l'exception).
Libellé initial "A-Formation" (proposé par l'utilisatrice), **remplacé
par "Académie"** le jour même — demande explicite de trouver un nom plus
attirant, proposé par Claude et choisi par l'utilisatrice parmi 3
options (Académie/Savoir/Campus).

Les deux entrées de menu "Formation"/"AkoraFormation" ajoutées plus tôt
dans le Profil ont été **retirées** (redondantes avec le nouvel onglet,
un seul chemin de navigation gardé pour éviter la confusion).

## Lisibilité des piliers "Nos activités" sur l'Accueil (01/08)

Signalé par l'utilisatrice via capture : le nom de chaque pilier
(Akora Home, Akora Pro...) apparaissait flou/peu lisible. Cause trouvée
dans `catalog_tab.dart` : le texte utilisait `theme.textTheme.labelSmall`,
qui pointe vers `textDisabled` dans `app_theme.dart` (couleur prévue pour
du texte désactivé/atténué, pas pour un libellé toujours visible) —
override explicite en `theme.colorScheme.onSurface` + graisse `w700`.
Au passage, le fond de chaque icône (auparavant une couleur plate à
alpha fixe) est passé à un dégradé (`LinearGradient`, du plus opaque au
plus transparent) pour un rendu plus "charmant" comme demandé.

## Page de paiement dédiée et sécurisée (01/08)

Demande explicite : "J'aimerais qu'on crée une nouvelle page spéciale
pour le paiement. Page bien sécurisée !" — le choix de la méthode de
paiement et la confirmation de commande étaient jusqu'ici mélangés au
reste de l'écran Panier. Nouvel écran dédié
`client_home/payment_screen.dart` (`PaymentScreen`), poussé via
`Navigator.push` depuis `cart_tab.dart` (nouveau bouton "Payer",
`Icons.lock_outline`, remplace l'ancien bouton "Commander").

Répartition des responsabilités :
- `CartTab` garde : liste des articles, estimation/adresse de livraison,
  et la demande de devis (`_submitQuote`, qui ne nécessite ni adresse ni
  paiement). Le nouveau `_goToPayment()` valide juste que l'adresse est
  renseignée puis pousse `PaymentScreen` avec le sous-total et les
  informations de livraison déjà calculées (pas besoin de repasser le
  panier lui-même : `PaymentScreen` relit `cartProvider`, état global
  Riverpod accessible depuis n'importe quel écran).
- `PaymentScreen` reçoit désormais tout ce qui concerne le paiement :
  sélection de méthode (`PaymentMethodSelector`), choix client
  automatique/manuel (`_payAutomatically`), secours admin
  (`_manualFallback`), champ référence + preuve photo, et
  `_submitOrder()` (logique de création de commande adaptée telle
  quelle depuis l'ancien `cart_tab.dart` : file d'attente hors-ligne,
  insertion `orders`/`order_items`, lien de paiement Papi, upload de la
  preuve dans le bucket `payment-proofs`).

Éléments de confiance visuelle ajoutés (l'essentiel de la demande) :
AppBar avec icône cadenas + titre "Paiement sécurisé", bandeau vert
"Connexion sécurisée..." en haut de page, récapitulatif de commande dans
une Card séparée, et un pied de page "🔒 Paiement chiffré · Opérateurs
officiels Papi, Mvola, Orange Money, Airtel Money" sous le bouton de
confirmation.

⚠️ Important à comprendre : aucune donnée bancaire sensible n'est saisie
dans l'app (Papi gère le paiement en ligne sur sa propre page externe ;
le mode manuel ne demande qu'une référence de transaction + une photo
facultative). Cette page n'ajoute donc pas de nouvelle protection
technique — c'est avant tout un travail de présentation et de
réassurance visuelle, comme expliqué à l'utilisatrice avant de
construire. Aucun script SQL n'était nécessaire pour ce changement (pur
Flutter/Dart, aucune modification de schéma).

## Checklist publication Google Play Store (01/08)

État des lieux fait suite à la question de l'utilisatrice sur ce qu'il
reste à faire pour publier l'app. Objectif : cocher au fur et à mesure,
ne pas repartir de zéro à chaque fois qu'on en reparle.

**✅ Déjà en place côté technique**
- [x] Build CI compile déjà l'**App Bundle** (`.aab`, format exigé par
  Google Play), en plus de l'APK (`build-apk.yml`).
- [x] Signature de release configurée (`android/key.properties` +
  secrets GitHub `ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD`
  / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD`) — **à confirmer** que
  ces secrets sont bien renseignés côté GitHub, sinon les builds
  actuels sont signés avec la clé debug (inutilisable pour un envoi
  Play Store, qui exige une vraie clé d'upload conservée précieusement
  d'une version à l'autre).
- [x] Icônes d'app présentes (`android/app/src/main/res/mipmap-*`),
  nom affiché "AkoraHub" dans le manifeste.
- [x] Politique de confidentialité déjà rédigée
  (`docs/privacy-policy.html`).

**🔲 Reste à faire (surtout administratif, pas du code)**
- [ ] Créer le **compte développeur Google Play** (paiement unique
  ~25$, compte Google) — à faire par l'utilisatrice, pas possible pour
  Claude de le faire à sa place.
- [x] **Héberger** `docs/privacy-policy.html` sur une URL publique — fait
  le 05/08, voir section dédiée plus bas.
- [ ] **Fiche de la boutique** : icône haute résolution (512×512), image
  de couverture (1024×500), captures d'écran réelles de l'app,
  description courte/longue en français.
- [ ] **Questionnaire de classification du contenu** + formulaire
  **"Sécurité des données"** (déclarer précisément ce qui est collecté :
  localisation pour la livraison, photos de preuve de paiement, etc. —
  directement lié au contenu de la politique de confidentialité).
- [ ] **Accès pour la review** : fournir un identifiant de test à
  Google, une bonne partie de l'app nécessitant un compte.
- [ ] ⚠️ **Point à trancher en priorité** : les abonnements
  AkoraFormation (contenu numérique déverrouillé dans l'app) tombent
  potentiellement sous l'obligation d'utiliser **Google Play Billing**
  plutôt qu'un paiement externe (Papi/Mvola) — règle réelle de Google
  Play, risque de rejet si mal géré. À clarifier avant toute
  soumission.
- [ ] Recommandé : passer d'abord par la piste **"Test interne"** avant
  "Production", pour valider l'App Bundle sur de vrais appareils.

## Menu "Paramètres" remonté au premier niveau côté Admin (01/08)

Signalé par l'utilisatrice : "il n'y a pas de paramètres... ni côté
admin !" — en réalité l'écran existait déjà (`settings_screen.dart`,
partagé Client/Admin), mais côté Admin il était enterré tout en bas du
formulaire "Profil entreprise" (`business_profile_settings.dart`), un
écran dont le nom ne laisse pas du tout deviner qu'on y trouve les
réglages personnels (langue, mode sombre, notifications, sécurité).
Corrigé en sortant l'entrée "Paramètres" de `business_profile_settings.dart`
et en l'ajoutant comme item de premier niveau dans le menu "Plus" de
l'Admin (`more_menu_screen.dart`), juste à côté de "Profil entreprise" —
même logique que côté Client où "Paramètres" est déjà une carte
indépendante dans l'onglet Profil.

## Double authentification (2FA / TOTP) (01/08)

Demande explicite : "Nous devons aussi ajouter une deuxième
authentification pour bien sécurisé chaque compte." Trois méthodes
possibles (SMS, e-mail, application d'authentification/TOTP) ont été
présentées ; l'utilisatrice a demandé "la meilleure sécurité" — le TOTP
a été retenu : contrairement au SMS (vulnérable au SIM-swap, nécessite
un fournisseur payant) ou à l'e-mail (dépend de la sécurité de la boîte
mail elle-même), le code TOTP est généré localement sur l'appareil, sans
transiter par un réseau, et c'est le seul des trois activable sans
infrastructure tierce payante — Supabase Auth le supporte nativement via
son API `auth.mfa`.

Nouveaux fichiers :
- `client_home/settings/two_factor_setup_screen.dart` — écran de gestion
  (personnel au compte, accessible Client ET Admin depuis "Confidentialité
  et sécurité") : affiche l'état actuel (activée/désactivée),
  active (`mfa.enroll` -> QR code + secret affichés -> confirmation par
  code à 6 chiffres via `mfa.challengeAndVerify`) ou désactive
  (`mfa.unenroll`) le facteur TOTP. Un facteur créé mais jamais vérifié
  (QR annulé) est nettoyé automatiquement (`unenroll`) pour ne pas laisser
  d'entrée orpheline.
- `authentication_screen/mfa_challenge_screen.dart` — écran affiché
  juste après une connexion réussie (email/mot de passe OU Google/
  Facebook) si le compte a un facteur TOTP vérifié : demande le code à 6
  chiffres avant de laisser entrer dans l'app. Annuler ou revenir en
  arrière déconnecte le compte (`PopScope` intercepte le bouton retour
  système) — jamais d'état "à moitié connecté".

Intégration dans `authentication_screen.dart` (`_onAuthenticated()`,
point de passage commun aux deux méthodes de connexion) : après succès,
vérifie `auth.mfa.getAuthenticatorAssuranceLevel()` — si `currentLevel`
est `aal1` et `nextLevel` `aal2` (facteur vérifié en attente de
challenge), pousse `MfaChallengeScreen` et n'continue vers l'accueil
qu'après validation. Le proxy de connexion `hyper-endpoint` (rate
limiting, Phase 34/35) relaie directement au vrai endpoint GoTrue
`/auth/v1/token?grant_type=password` — aucune interférence avec le
niveau d'assurance (aal), le comportement est identique à un
`signInWithPassword` classique.

**Script SQL requis : `supabase/phase44_patch_mfa_audit_log.sql`** —
ajoute uniquement les types d'événement `mfa_enabled`/`mfa_disabled` à la
liste blanche du journal de sécurité existant (Phase 34) ; les facteurs
TOTP eux-mêmes ne nécessitent aucune table, Supabase Auth les stocke déjà
dans son propre schéma.

⚠️ Limite connue, assumée pour cette première version : pas de codes de
récupération ("backup codes") — un utilisateur qui perd l'accès à son
application d'authentification (téléphone perdu/reset) n'a aujourd'hui
aucun moyen de se reconnecter seul. Il n'existe pas non plus d'écran
Admin pour désinscrire le facteur d'un autre compte : le seul déblocage
possible aujourd'hui est manuel, directement dans le Dashboard Supabase
(Authentication -> l'utilisateur concerné -> retirer le facteur MFA). À
améliorer (codes de récupération et/ou outil Admin dédié) si ce cas se
présente en pratique.

## Renommage "Mur" -> "Communauté" (01/08)

Demande : trouver un terme plus parlant que "Mur" (calque Facebook) pour
le fil de publications texte/photo avec likes et commentaires,
filtrable par secteur. Trois options proposées (Communauté / Fil Akora /
Publications) ; "Communauté" retenu.

Changements de texte visible uniquement (le fichier reste
`wall/wall_tab.dart`, la classe `WallTab` n'est pas renommée — même
logique que pour "Académie", pas de renommage de fichier en cours de
session) : titre de l'écran ("Communauté AkoraHub"), bouton "Voir la
Communauté" et texte de repli "Nouvelle publication dans la Communauté"
sur l'Accueil (`catalog_tab.dart`), message d'erreur de chargement.
Toujours accessible uniquement depuis le Profil ou le fil "Pour vous" de
l'Accueil — aucun onglet de navigation dédié (décision du 23/07,
inchangée).

## Communauté : recherche + modifier/supprimer sa publication (01/08)

Demande : rendre la Communauté "plus pratique", avec des suggestions
d'amélioration (l'utilisatrice proposait notamment une "demande d'amis").
Écarté volontairement : un système d'ami mutuel ne colle pas à l'usage
observé (les publications ressemblent à un panneau d'annonces B2B entre
inconnus organisés par secteur — Hôtellerie/Santé/Entreprises/
Particuliers — pas un réseau d'amis). Parmi les alternatives proposées
(Modifier/Supprimer sa publication, Recherche par mot-clé, Contacter via
WhatsApp opt-in, Signaler une publication), l'utilisatrice a choisi de
construire maintenant les deux premières ; les deux autres restent en
réserve (Contacter nécessite d'abord un réglage de confidentialité
"Afficher mon numéro", actuellement masqué par design — voir
`public_profile_screen.dart`).

Dans `wall/wall_tab.dart` :
- **Modifier/Supprimer sa publication** : menu ⋮ visible uniquement sur
  ses propres posts (`post['author_id'] == _myId`), à côté du nom
  d'auteur (sorti de l'`InkWell` de navigation vers le profil pour ne
  pas intercepter le tap). Aucune policy RLS à ajouter :
  `posts_update_own`/`posts_delete_own` (Phase 3) autorisaient déjà
  l'auteur à agir sur ses propres lignes, seule l'UI manquait.
- **Recherche par mot-clé** : champ de recherche en haut du fil,
  débouncé (400 ms) pour éviter une requête par frappe, filtre côté
  serveur (`ilike` sur `content`) donc compatible avec la pagination
  existante — pas de nouvel index nécessaire au volume actuel de posts.

Aucun script SQL requis pour ce changement.

## Formation : abonnement remplacé par l'achat par produit (01/08)

Chantier déclenché par la discussion Play Billing (voir plus haut,
"Checklist publication Google Play Store") : en creusant comment éviter
la commission Google sur l'abonnement Formation, l'utilisatrice a
proposé un changement de modèle plus large — "le formation peut acheté
mais pas abonnement" (accès permanent par achat, pas de renouvellement),
puis un tarif dégressif par nombre de produits achetés :
- 1 produit : 10 000 Ar
- 5 produits : 8 000 Ar/produit
- 10 produits : 5 000 Ar/produit

Confirmé par l'utilisatrice : le palier se calcule sur le total
**cumulatif** de produits déjà achetés (validés) par le client, tous
achats confondus dans le temps ; une fois atteint, il s'applique à
**tous** les produits de l'achat en cours (pas de recalcul rétroactif
sur ce qui a déjà été payé). Confirmé également : aucun client n'avait
encore payé d'abonnement, donc aucune migration de données n'était
nécessaire.

⚠️ Rappel du contexte business qui a motivé ce chantier : ça ne règle
**pas** la question Play Billing en soi (un achat unique de contenu
numérique est soumis à la même commission qu'un abonnement) — le vrai
levier pour l'éviter reste le paiement via navigateur externe, qui n'a
**pas** été construit dans ce chantier (le paiement Formation reste
manuel — référence + preuve, comme avant — l'ajout de Papi est laissé
pour une session future si besoin).

**Script SQL requis :
`supabase/phase45_patch_formation_per_product_pricing.sql`** :
- `formation_purchases` : une ligne par produit acheté par client, statut
  `en_attente`/`validee`/`refusee`, regroupées par `batch_id` (un même
  achat peut porter sur plusieurs produits à la fois). Un produit refusé
  peut être re-soumis (RLS n'autorise que refusee -> en_attente, jamais
  un client ne peut se valider lui-même son propre accès).
- `formation_pricing_tiers` : les 3 paliers ci-dessus, modifiables par
  l'Admin (nouvel écran, voir plus bas) — remplace
  `formation_plan_pricing` (Phase 40, non supprimée mais plus utilisée).
- Nouvelle fonction `has_purchased_raw_material(uid, material_id)` :
  remplace l'ancien booléen global `has_active_formation_subscription`
  dans les 5 policies RLS qui gataient l'accès (fiche complète, photos,
  dosages, conditionnement, historique de prix) — l'accès est désormais
  vérifié **par produit précis**, pas globalement.
- La table `formation_subscriptions` (Phase 40) n'est pas supprimée
  (historique), juste plus utilisée pour l'accès.

**Fichiers Dart** (renommages inclus, pas de compatibilité ascendante
gardée — l'ancien modèle n'était pas encore en production) :
- `core/formation/formation_repo.dart` : réécrit — `fetchMyPurchasedIds`,
  `fetchMyPendingIds`, `fetchPricingTiers`,
  `unitPriceForPurchase(tiers, alreadyOwned, quantity)`,
  `requestPurchase(rawMaterialIds, ...)`.
- `client_home/formation/formation_subscription_screen.dart` **supprimé**,
  remplacé par `formation_purchase_screen.dart`
  (`FormationPurchaseScreen`) : sélection multi-produits type mini-panier
  (recherche, cases à cocher), prix par unité recalculé en direct selon
  le palier, paiement manuel (référence + preuve) inchangé sinon. Accepte
  un `initialSelectedId` pour pré-sélectionner un produit précis (bouton
  "Acheter l'accès" d'une fiche verrouillée).
- `formation_catalog_screen.dart` et `raw_material_detail_client.dart` :
  cadenas par produit individuel (`_ownedIds`/`_pendingIds`) au lieu d'un
  booléen global d'abonnement ; icône sablier distincte pour "en attente
  de vérification".
- `formation_subscriptions_management/` **supprimé**, remplacé par
  `formation_purchases_management/` (`FormationPurchasesManagement`) :
  demandes groupées par achat (`batch_id`) validables/refusables en un
  clic, plus la section d'édition des 3 paliers de prix (demande
  explicite : "j'aimerais qu'on ajoute une fonction de gérer le prix
  d'accès dans le côté admin").

## Communauté : réponses aux commentaires, réactions emoji, notifications push (01/08)

Trois demandes de l'utilisatrice après avoir vu une capture de son
volet de notifications Android (TikTok en exemple) : "on ne peut pas
répondre un commentaire", "j'arrive pas avoir des notifications... quand
il y a des messages ou commentaires, réaction", "différents emoji pour
la réaction, réponse commentaire, message".

Périmètre retenu pour cette première version (à étendre si besoin) :
réactions emoji **sur les publications uniquement** — pas encore sur les
commentaires ni sur la messagerie privée (`ChatScreen`), qui resteraient
des chantiers séparés si demandés.

**Script SQL requis : `supabase/phase46_patch_communaute_replies_reactions.sql`** :
- `post_comments.parent_comment_id` (auto-référence, nullable) — fils de
  discussion limité à **un seul niveau** de profondeur côté application
  (on peut répondre à un commentaire, pas à une réponse) pour garder
  l'affichage simple, même si la colonne autoriserait techniquement plus
  de profondeur.
- `post_likes.reaction_type` (`like`/`love`/`haha`/`wow`/`sad`/`angry`,
  même jeu que Facebook) — remplace le like binaire ; changer de
  réaction se fait par suppression + réinsertion côté app (pas besoin de
  policy UPDATE supplémentaire).
- Deux nouveaux triggers (`post_comments`, `post_likes`) qui réutilisent
  la fonction générique `notify_push_on_new_message()` déjà en place
  depuis la Phase 17 (déjà utilisée pour messages/devis/commandes/
  produits/appels malgré son nom) — aucune nouvelle fonction de trigger
  à écrire.

**⚠️ Redéploiement de l'Edge Function requis, en plus du script SQL** —
particularité de ce chantier par rapport aux précédents : contrairement
à un simple script SQL, `supabase/functions/send-push-notification/index.ts`
doit être redéployé (Dashboard -> Edge Functions -> coller le nouveau
contenu -> Deploy) pour que les nouveaux triggers aient un effet visible
— sans ça, ils appellent bien la fonction mais elle ignore
silencieusement les tables `post_comments`/`post_likes` (aucune erreur,
juste aucune notification envoyée). Ajout de deux branches dans cette
fonction :
- `post_comments` : notifie l'auteur de la publication (si différent du
  commentateur) et, en cas de réponse, l'auteur du commentaire parent
  (si différent du commentateur ET déjà notifié) — jamais de doublon
  vers le même destinataire.
- `post_likes` : notifie l'auteur de la publication avec l'emoji de la
  réaction dans le corps du message.

Catégorie de son de notification réutilisée : "message" (existante,
aucune nouvelle colonne `profiles.notification_sound_*` ni nouvelle
entrée dans le sélecteur de sons côté Réglages — un commentaire/réaction
est traité comme une forme de message).

Dans `wall_tab.dart` :
- Le bouton "cœur" devient un `GestureDetector` : appui court =
  bascule la réaction "like" par défaut (retape pour retirer), appui
  long = ouvre un sélecteur des 6 emoji (`showModalBottomSheet`) façon
  Facebook. L'emoji de la réaction active remplace l'icône cœur.
- `_CommentsSheet` distingue commentaires de premier niveau et réponses
  (affichage indenté) ; bouton "Répondre" uniquement sur les
  commentaires de premier niveau, qui pré-remplit un bandeau "Réponse à
  {nom}" au-dessus du champ de saisie (annulable).

## Communauté : compression automatique des photos (01/08)

Suite logique après une capture d'écran de l'utilisatrice montrant une
connexion à **6 KB/s** — plutôt qu'une nouvelle fonctionnalité, priorité
donnée à la rapidité de chargement du fil, qui affiche potentiellement
plusieurs photos par écran.

Dans `wall_tab.dart` (`_NewPostSheet._pickImage`) : les photos jointes à
une publication passent de `imageQuality: 70, maxWidth: 1280` à
`imageQuality: 60, maxWidth: 800` — les images du fil ne s'affichent
jamais plus grandes que la largeur de la carte (~20.h de haut), un
fichier plus large que ça n'apportait aucun gain visuel, juste plus
d'octets à télécharger pour tout le monde qui consulte le fil (pas
seulement pour qui publie). Compression appliquée par `image_picker`
lui-même (redimensionnement + réencodage JPEG) avant l'upload, donc
aucun changement côté Supabase Storage.

Deux ajouts complémentaires sur l'affichage (`Image.network` du fil) :
`cacheWidth: 800` (Flutter ne décode jamais l'image plus grande que
nécessaire, économise de la mémoire même sur d'anciennes publications
antérieures à cette limite) et un `loadingBuilder` (indicateur de
chargement à la place d'un espace vide pendant le téléchargement — évite
de donner l'impression que l'app est bloquée sur une connexion lente).

Aucun script SQL, aucune migration des photos déjà publiées (elles
restent à leur taille d'origine, seules les nouvelles publications sont
concernées).

## Communauté : signaler une publication + contacter via WhatsApp (01/08)

Les deux points mis de côté lors de la discussion "améliorer la
Communauté" (voir plus haut), construits maintenant.

**Script SQL requis : `supabase/phase47_patch_report_and_whatsapp_contact.sql`** :
- `post_reports` (post_id, reporter_id, reason, status
  `en_attente`/`traite`) — un signalement par (client, publication),
  lecture réservée au staff (jamais visible par les clients, pour ne pas
  transformer ça en outil de harcèlement "untel a signalé mon post").
  Trigger de notification push vers l'équipe Admin/Commercial,
  réutilisant `notify_push_on_new_message()` (Phase 17).
- `profiles.share_phone_publicly` (`false` par défaut) + mise à jour de
  la vue `public_profiles` (Phase 9) qui exposait volontairement zéro
  info de contact — le téléphone y apparaît désormais, mais uniquement
  pour les clients ayant explicitement activé ce réglage eux-mêmes.

**Nouveaux fichiers Dart :**
- `core/utils/whatsapp_link.dart` : construit un lien `wa.me` à partir
  du format E.164 stocké par `IntlPhoneField` à l'inscription
  (`+261341234567` -> `https://wa.me/261341234567`, wa.me n'accepte pas
  le `+`).
- `post_reports_management/` (`PostReportsManagement`, Admin) : liste
  des signalements groupée par statut, aperçu de la publication
  concernée, actions "Ignorer" / "Supprimer la publication" (la
  suppression retire aussi le signalement en cascade). Lien ajouté dans
  le menu "Plus" de l'Admin.

**Fichiers modifiés :**
- `wall_tab.dart` : menu ⋮ "Signaler" sur les publications d'autrui
  (symétrique du menu Modifier/Supprimer déjà présent sur ses propres
  publications) ; icône WhatsApp verte dans la barre d'actions du post
  si l'auteur a un numéro public.
- `public_profile_screen.dart` : bouton "Contacter via WhatsApp" sous le
  nom/secteur, même condition (numéro public uniquement).
- `security_settings_screen.dart` : nouveau réglage "Numéro visible dans
  la Communauté" (`SwitchListTile`) — désactivé si aucun numéro n'est
  renseigné dans le profil (message explicite invitant à en ajouter un
  d'abord), affiche le numéro actuel une fois activé pour confirmation.

## Communauté : demandes d'ami + messagerie privée (01/08)

Demande explicite d'un vrai système d'amis + chat privé DANS l'app
(distinct de WhatsApp, qu'on venait pourtant de construire) — après
clarification : réservé aux clients ayant déjà fait **au moins un
achat** (commande classique ou abonnement Formation validé), filtre
anti-spam entre inconnus.

⚠️ Chantier volontairement scindé de la messagerie client/staff
existante (`chat_screen.dart`/`ChatComposer`) — ce sont deux systèmes
séparés, pas de code partagé. Limite assumée pour cette première
version : **aucun outil de modération Admin sur les messages privés**
(contrairement aux publications, signalables depuis la Phase 47) —
cohérent avec le principe même d'une conversation privée, mais à garder
en tête. Texte uniquement pour l'instant, pas de photo dans le chat privé.

**Script SQL requis : `supabase/phase48_patch_friends_and_private_chat.sql`** :
- `has_made_purchase(uid)` : vérifie `orders` ET `formation_purchases`
  (statut validé) — n'importe lequel des deux suffit à être éligible.
- `friendships` (requester_id, addressee_id, status
  `en_attente`/`acceptee`/`refusee`) — **un seul index unique sur la
  paire triée** (`least`/`greatest` des deux id) : empêche à la fois un
  doublon et une demande "inverse" pendant qu'une autre est en cours.
  Annuler une demande envoyée ou retirer un ami = suppression de la
  ligne (autorisée aux deux côtés). Pas de re-demande possible après un
  refus dans cette version (la paire reste "prise" par la ligne
  refusée) — limite mineure assumée.
- `friend_messages` (sender_id, recipient_id, content) — écriture
  vérifiée par `are_friends()`, pas seulement côté application. Ajoutée
  à la publication `supabase_realtime` (même principe que la messagerie
  client/staff, Phase 8) pour une conversation qui se met à jour sans
  recharger.
- Notifications push (nouvelle demande, demande acceptée — jamais sur
  un refus, pour éviter un ping désagréable —, nouveau message) via la
  fonction générique déjà en place (Phase 17).

⚠️ **Redéploiement de l'Edge Function `send-push-notification`
également requis** (nouvelles branches `friendships`/`friend_messages`),
en plus du script SQL — même remarque que pour la Phase 47.

**Nouveaux fichiers Dart :**
- `core/community/friends_repo.dart` : API complète (statut d'une
  relation, envoyer/accepter/refuser/annuler, listes amis/reçues/
  envoyées, flux de messages temps réel filtré côté app car `.stream()`
  ne supporte pas `or()`, envoi de message, marquage lu).
- `client_home/community/friends_list_screen.dart` : 3 onglets (Amis /
  Reçues / Envoyées), badge sur l'icône d'entrée si des demandes sont en
  attente.
- `client_home/community/friend_chat_screen.dart` : conversation privée
  1:1, mise à jour en direct (`StreamBuilder` + Realtime).
- `public_profile_screen.dart` : bouton "Ajouter en ami" dynamique selon
  le statut (Ajouter / Demande envoyée-Annuler / Accepter-Refuser /
  Discuter-Retirer), désactivé avec message explicite si le client n'a
  encore rien acheté.
- `wall_tab.dart` : icône "Amis" dans l'AppBar de la Communauté (badge =
  nombre de demandes reçues en attente), point d'entrée unique vers
  `FriendsListScreen`.

## Formation : achat déplacé hors de l'app (conformité Google Play) (01/08)

**Demande** : préparer AkoraHub pour la publication sur le Play Store.
Analyse du flux de paiement Formation (déblocage de fiches ingrédients,
Phase 45) : même en paiement manuel (référence + preuve), débloquer un
contenu numérique consommé dans l'app contre un paiement effectué hors
Google Play reste dans le champ de la "Payments policy" de Google — un
motif de rejet possible à la revue. Les commandes de produits physiques
(Akora Fanadiovana) ne sont, elles, pas concernées : Google n'impose
jamais Play Billing pour des biens physiques livrés.

**Solution retenue** : le modèle "reader app", déjà utilisé par de
nombreuses apps de contenu (Kindle et consorts) — sortir l'écran d'achat
de l'application Android et le déplacer sur une page web ouverte dans le
navigateur externe (jamais une WebView intégrée). Le backend
(`formation_purchases`, validation manuelle par le staff, déblocage)
reste strictement inchangé ; seul le point d'entrée du paiement change.
Rien à payer à Google avec cette approche (contrairement à Play Billing,
explicitement écarté par l'utilisatrice pour son coût).

**SQL** : `supabase/phase49_patch_formation_web_bucket.sql` — crée
uniquement le bucket Storage public `formation-web` qui héberge la page.
Le fichier HTML lui-même est déposé manuellement dans ce bucket depuis
le Dashboard (pas de mécanisme de déploiement automatique pour ça).

**Nouvelle page web** : `web/formation-access/index.html` — page
autonome (HTML/CSS/JS vanilla, aucune dépendance externe), qui
réimplémente exactement le même flux que l'ancien
`formation_purchase_screen.dart` : connexion (même email/mot de passe
que l'app, via l'API Auth Supabase), catalogue avec prix dégressif par
palier, sélection multi-produits, choix du mode de paiement manuel
(mêmes coordonnées que dans l'app), upload de preuve, envoi de la
demande (même table, même RLS que l'app — aucun accès privilégié, la clé
utilisée est la clé publique `anon`).

**Modifications Dart :**
- `core/utils/formation_web_link.dart` (nouveau) : ouvre la page dans le
  navigateur externe (`LaunchMode.externalApplication`).
- `formation_catalog_screen.dart`, `raw_material_detail_client.dart` :
  les 3 boutons "Acheter" ouvrent désormais la page web au lieu de
  naviguer vers un écran intégré.
- `formation_purchase_screen.dart` **supprimé** (plus aucune référence,
  devenu du code mort).

⚠️ **Limite assumée** : la page web est un fichier statique déposé
manuellement — toute évolution du flux d'achat (nouveau champ, nouvelle
règle de prix) devra être répercutée à la main dans ce fichier en plus
de l'app. Le formulaire "Sécurité des données" du Play Store reste à
compléter séparément (voir le guide fourni précédemment, mis de côté
pour l'instant à la demande de l'utilisatrice).

### Correctif : hébergement déplacé vers GitHub Pages (01/08)

Le bucket Supabase Storage public (`formation-web`,
`phase49_patch_formation_web_bucket.sql`) prévu pour héberger cette page
s'est révélé inutilisable : Supabase Storage force le `Content-Type`
des fichiers `.html` de ses buckets publics à `text/plain` (protection
anti-phishing côté serveur — empêche d'héberger une page web active sur
un sous-domaine `supabase.co` de confiance). Ni la métadonnée Postgres
(`storage.objects.metadata->>'mimetype'`) ni un upload avec
`Content-Type: text/html` explicite (testé via un appel direct à l'API
Storage) n'ont permis de contourner cette protection — le fichier
s'affichait toujours comme du texte brut au lieu de s'exécuter comme
une page.

**Tentative 2 — GitHub Pages**, abandonnée aussi : gratuit uniquement
pour les dépôts publics ; celui-ci doit rester privé (le fichier
`payment_methods.dart` contient des coordonnées bancaires réelles).

**Solution retenue — Netlify** : la page (`docs/formation-access/index.html`,
contenu inchangé) est déployée manuellement sur Netlify (glisser-déposer
du dossier sur netlify.app), site renommé explicitement en
`akorahub-formation` pour une adresse stable qui ne change plus.
`core/utils/formation_web_link.dart` pointe vers
`https://akorahub-formation.netlify.app/`. Au passage, deux bugs
corrigés dans la page elle-même : la protection "Visitor access —
Password protected" activée par défaut sur les nouveaux sites Netlify
(désactivée manuellement, réglage "Project visibility : Public"), et un
crash JS après un envoi réussi (`res.json()` sur une réponse vide de
PostgREST avec l'en-tête `Prefer: return=minimal`, qui renvoie un corps
vide avec un statut différent de 204 — corrigé en testant le texte brut
avant de parser en JSON).

⚠️ **Redéploiement manuel requis** à chaque future modification de
`docs/formation-access/index.html` : glisser à nouveau le dossier sur
le site Netlify existant (onglet Deploys) — rien n'est automatisé pour
l'instant (pas de connexion Git↔Netlify configurée).

Les buckets/dossiers abandonnés (bucket Supabase Storage `formation-web`,
réglage GitHub Pages non activé) sont laissés tels quels — aucune donnée
sensible dedans, pas nécessaire de les nettoyer.

## Retouches design de l'écran d'accueil (01/08)

Demande : peaufiner le design avant de prendre les captures d'écran pour
la fiche Play Store. Trois retouches sur `catalog_tab.dart`, à partir de
captures réelles de l'app fournies par l'utilisatrice :

- **Palette "Nos activités"** (`_unitColors`) : les 6 couleurs Material
  par défaut (vert/bleu/orange/violet/rouge/cyan saturés, sans tonalité
  commune) remplacées par une palette dérivée du vert de marque
  (`app_theme.dart`, `primaryLight` #085041) — 6 tons apparentés
  (marque, sauge, ocre, terracotta, ardoise, prune).
- **Mot "AkoraHub" en haut à droite de l'accueil** : supprimé (redondant
  avec l'app elle-même, ne servait à rien).
- **Badge "Recommander"** (section "Vous recommandez souvent") :
  chevauchait l'étiquette de catégorie de `_ProductCard` — les deux
  étaient positionnées au même repère (top:8/left:8) mais dans deux
  `Stack` différents (un superposé par-dessus la carte, l'autre interne
  à la carte), d'où la collision visuelle. Corrigé en passant
  `reorderBadge: true` à `_ProductCard`, qui l'affiche désormais dans
  son propre `Stack` interne, au seul coin resté libre (bas-gauche —
  catégorie en haut-gauche, favori en haut-droite, ajout rapide en
  bas-droite).

⚠️ **Point de vigilance signalé, pas un bug à corriger** : la carte
"Pour vous" de l'accueil peut afficher de vraies données d'un autre
client (nom, téléphone) — utiliser un compte de test pour les captures
d'écran finales, jamais un compte avec de vrais contacts/commandes.

## Dashboard admin : textes en anglais francisés (01/08)

À partir de captures du tableau de bord Business (`business_dashboard/`)
fournies par l'utilisatrice : plusieurs libellés étaient restés en
anglais alors que le reste de l'app est entièrement en français
("Good Morning/Afternoon/Evening", "Quick Actions", "Add Product",
"View Orders", "New Order", "Add Customer") — corrigés dans
`greeting_header_widget.dart`, `quick_actions_grid_widget.dart` et
`business_dashboard.dart`.

En creusant le bouton "Modifier" (teinte marine) et les boutons flottants
oranges signalés au premier coup d'œil comme potentiellement
incohérents : **ce sont en fait des couleurs de marque volontaires**
(`app_theme.dart` — `secondaryLight`/`secondaryDark` "Marine (icône)",
`accentLight`/`accentDark` "Orange (icône)", toutes deux calées sur
l'icône de l'app, aux côtés du vert `primaryLight`) — un vrai système à
3 couleurs, pas une incohérence. Laissées telles quelles.

## Achat de cours AkoraFormation + contenu protégé (01-02/08)

**Origine** : demande de groupes communautaires par catégorie de
Formation (voir plus bas), réservés aux "participants". Or
`formation_courses` (Phase 43) n'était qu'une vitrine — aucun système
d'achat, aucun contenu réel (le champ `module_count` était juste un
chiffre d'affichage). Construire les groupes avant d'avoir un vrai
système d'accès aurait été creux ; ce patch pose donc d'abord ce socle.

**SQL** : `supabase/phase50_patch_course_purchases_and_content.sql` —
- `formation_courses.price` (nullable — tant qu'il est vide, le cours
  n'est pas en vente, même si son statut est "Déjà développée").
- `formation_course_modules` (course_id, title, video_url, document_url,
  content_text, sort_order) : le vrai contenu. **La protection réelle
  est la RLS**, pas l'interface — sa policy de lecture ne renvoie une
  ligne que si `current_role_is_staff()` ou si un
  `course_purchases` validé existe pour ce (client, cours) précis. Un
  client qui n'a pas payé ne peut techniquement pas récupérer
  `video_url`/`document_url` depuis l'API, quel que soit le client
  utilisé.
- `course_purchases` : même principe que `formation_purchases`
  (matières premières, Phase 45) — paiement manuel, validation staff,
  re-soumission possible après refus. Pas de notification push
  automatique, cohérent avec `formation_purchases`.

**Protection anti-capture (demande explicite)** : `screen_protector`
(package Flutter, `FLAG_SECURE` Android) activé sur
`course_content_screen.dart` pendant l'affichage du contenu — bloque la
capture d'écran et l'enregistrement d'écran natifs, masque l'aperçu
dans le multitâche. **Limite expliquée à l'utilisatrice et assumée** :
rien ne peut empêcher de filmer l'écran avec un second appareil physique
(la "faille analogique") — aucune plateforme au monde ne s'en protège
techniquement, ce n'est pas un manque d'effort.

**Achat** : passe par la même page web externe que les matières
premières (`docs/formation-access/index.html`, conformité Google Play,
Phase 49) — désormais avec deux onglets ("Matières premières" / "Cours
AkoraFormation"), même flux de paiement manuel réutilisé pour les deux.

**Nouveaux fichiers Dart :**
- `core/formation/course_purchases_repo.dart` : cours possédés/en
  attente, modules d'un cours.
- `client_home/formation/course_content_screen.dart` : lecteur du
  contenu (vidéo via `video_player`, document ouvert en navigateur
  intégré, texte), protégé par `FLAG_SECURE`.
- `formation_courses_management/formation_course_modules_management.dart` :
  gestion Admin des modules (ajout vidéo/document/texte par cours).

**Modifications Dart :**
- `akora_formation_screen.dart` : prix, verrou, statut "En attente", et
  bouton "Voir" (cours possédé) ou "Acheter" (ouvre la page web externe).
- `formation_courses_management.dart` : champ prix + bouton d'accès à la
  gestion des modules.

⚠️ **Pas encore livré** : les groupes communautaires par catégorie
eux-mêmes (prochaine étape, une fois ce socle validé) — voir aussi la
limite déjà documentée plus haut sur "Matières premières" (seule
catégorie avec un vrai accès vérifiable pour l'instant côté matières
premières ; les cours ont maintenant aussi leur vrai système d'achat).

## Design Académie — sections + style bibliothèque vidéo (02/08)

Refonte de `akora_formation_screen.dart` sur inspiration d'une appli de
bibliothèque/vidéos (JW Library) montrée par l'utilisatrice : remplace la
liste plate filtrée par puces horizontales par des **sections par
catégorie** — dans chaque section, une **rangée horizontale de cartes
"affiche"** (dégradé des couleurs de marque + icône de catégorie, pas de
vraies vignettes vidéo — pas d'assets images autorisés) pour les cours
**Disponible**, et une **liste verticale sobre icône + chevron** pour les
cours pas encore programmés (tap → bottom sheet d'info). Logique
d'achat/possession inchangée, uniquement l'agencement visuel.

## Achats Formation introuvables côté client et admin — corrections (02/08)

**Signalé par l'utilisatrice** : après un achat de matière première sur
la page externe (Netlify), rien ne semblait s'être passé, et impossible
de retrouver la demande côté Admin pour la valider. Deux causes
distinctes trouvées et corrigées (pas un bug d'écriture des données — la
demande est bien enregistrée en `en_attente`, c'est normal qu'aucun
accès ne se débloque avant validation staff) :

1. **Repérage côté client** : aucun endroit dans l'app ne montrait au
   client l'état de ses demandes d'achat (juste "verrouillé"/"en
   attente" produit par produit, pas de vue d'ensemble). Ajouté : écran
   **"Mes accès"** (`client_home/formation/my_formation_access_screen.dart`),
   accessible via une icône dans l'AppBar d'Académie — liste tous les
   achats du client (matières premières + cours), tous statuts, triés
   par date, avec le statut en clair (En attente/Validé/Refusé).
   Nouvelles méthodes `FormationRepo.fetchMyPurchases()` et
   `CoursePurchasesRepo.fetchMyCoursePurchases()`.

2. **Repérage côté Admin** : "Achats Formation" (matières premières)
   n'était accessible que par une petite icône dans l'AppBar de l'écran
   "Matières premières (Formation)" — jamais listée dans le menu Plus,
   facile à manquer. Ajoutée en entrée directe du menu Plus.

3. **Bug réel trouvé au passage** : il n'existait **aucun écran admin
   pour valider les achats de cours** (`course_purchases`) — la table et
   la page d'achat externe existaient (Phase 50) mais personne côté
   staff ne pouvait passer une demande de "en_attente" à "validee". Un
   client ayant payé un cours restait bloqué indéfiniment. Créé
   `course_purchases_management/course_purchases_management.dart` (même
   principe que `FormationPurchasesManagement`), ajouté au menu Plus.

## Communauté façon Facebook — Lot 1 : confiance & sécurité (02/08)

Demande explicite : liste longue de fonctionnalités pour rendre la
Communauté "meilleure que Facebook", proposée triée en 5 lots par
impact/effort. Lot 1 construit (le plus urgent — comble un vrai manque
de modération) : **bloquer un client, masquer une publication,
enregistrer une publication, indicateur "Modifié"**.

**SQL** : `supabase/phase51_patch_block_hide_save_posts.sql` —
- `user_blocks` (blocker_id, blocked_id) + fonction `is_blocked(a,b)`.
  Lecture strictement limitée à SES PROPRES blocages (jamais qui M'A
  bloqué) — même principe que `post_reports` (Phase 47), évite qu'un
  blocage devienne un motif de confrontation.
- **La protection est dans la RLS, pas l'interface** : `posts_select`
  exclut désormais les publications d'un compte bloqué (dans les deux
  sens) ET les publications que le client a masquées lui-même
  (`hidden_posts`). `are_friends()` (Phase 48) exclut aussi les paires
  bloquées — coupe net les nouvelles demandes d'ami ET les messages
  privés (même si déjà amis avant le blocage), sans toucher à la RLS de
  `friend_messages` (elle appelle déjà `are_friends`).
- `hidden_posts`, `saved_posts` : tables strictement personnelles
  (select/insert/delete sur ses propres lignes uniquement).
- `posts.updated_at` : renseigné par `wall_tab.dart::_editPost` à chaque
  modification — affiché comme "Modifié" à côté du secteur.

**Nouveaux fichiers Dart :**
- `core/community/community_moderation_repo.dart` : bloquer/débloquer,
  masquer, enregistrer/retirer, listes pour les écrans de gestion.
  Récupère profils et publications sauvegardées en deux requêtes
  séparées plutôt qu'une jointure PostgREST imbriquée — `posts` a deux
  colonnes vers `profiles` (author_id ET mentioned_user_id), une
  jointure `profiles(...)` serait ambiguë (même limite déjà contournée
  dans `wall_tab.dart` pour les profils auteurs).
- `client_home/community/saved_posts_screen.dart`,
  `blocked_accounts_screen.dart` : écrans de gestion, accessibles
  respectivement depuis l'icône 🔖 de l'AppBar Communauté et depuis
  Confidentialité et sécurité → "Comptes bloqués".

**Modifications Dart :**
- `wall_tab.dart` : menu ⋮ enrichi — "Enregistrer/Retirer" sur toutes
  les publications, "Masquer" et "Bloquer ce client" en plus de
  "Signaler" sur celles des autres.
- `public_profile_screen.dart` : icône Bloquer/Débloquer dans l'AppBar ;
  masque la section Ami et le bouton WhatsApp si le client est bloqué.

⚠️ **Limite assumée** : les commentaires (`post_comments`) restent en
lecture ouverte (`select using (true)`, Phase 3) — un commentaire d'un
compte bloqué peut donc encore apparaître sous une publication d'un
tiers. Restreindre ça en RLS demanderait de réécrire cette policy pour
chaque lecteur potentiel (coût jugé disproportionné pour ce Lot 1) ;
seul le fil principal (l'essentiel du problème signalé) est protégé.

## Communauté façon Facebook — Lot 2 : différenciateurs commerce (02/08)

Deuxième lot : **bouton "Commander" direct sur post taggé produit, badge
"Officiel", publication épinglée** — les fonctionnalités qui exploitent
le fait qu'AkoraHub est un réseau social ADOSSÉ à une vraie boutique,
pas un clone Facebook générique.

**SQL** : `supabase/phase52_patch_official_badge_pinned_posts.sql` —
- `public_profiles` (vue, Phase 9/47) gagne `is_staff` (booléen calculé
  `role in ('admin','commercial','production','comptable')` — jamais le
  rôle précis, pas pertinent côté client).
- `posts.is_pinned` + trigger `protect_posts_pin_column` (BEFORE INSERT
  OR UPDATE) : annule silencieusement toute tentative de mise à `true`
  venant d'un compte non-staff. Nécessaire car `posts_update_own`
  (Phase 3) autorise déjà un client à modifier SA PROPRE ligne — une
  policy RLS ne peut pas distinguer "quelle colonne a changé", donc la
  protection passe par un trigger plutôt qu'une policy cette fois.

**Commander direct** : sur le tag produit d'une publication, le bouton
"Commander" ajoute directement le produit au panier (quantité 1) SAUF
si ce produit a des variantes (format/parfum, `product_variants`) — dans
ce cas impossible de deviner laquelle commander, on ouvre alors sa fiche
comme avant pour que le client choisisse. `WallTab` converti en
`ConsumerStatefulWidget` (était `StatefulWidget`) pour accéder à
`cartProvider` (déjà utilisé par `product_detail_client.dart`).

**Officiel** : icône ✓ à côté du nom d'auteur (fil ET profil public) si
`is_staff`.

**Épinglé** : option "Épingler/Désépingler" dans le menu ⋮, visible
seulement si le compte connecté est staff (vérifié une fois au chargement
via `profiles.role`, simple affichage — la vraie protection est le
trigger SQL ci-dessus). Le fil trie désormais `is_pinned` avant
`created_at` (côté serveur, `_fetchPostsPage`), donc une publication
épinglée reste en tête même en pleine pagination.

**Modifications Dart :** `wall_tab.dart` (bouton Commander, badge,
épinglage, tri), `public_profile_screen.dart` (badge Officiel).

## Communauté façon Facebook — Lot 3 : mentions, hashtags, carrousel (02/08)

Troisième lot : **mentions @, hashtags/catégories, carrousel
multi-images**.

**Choix de conception (hashtags)** : plutôt qu'une taxonomie de
catégories imposée (par pilier), implémenté en hashtags libres façon
Instagram/Twitter — analysés directement depuis `content` par regex
(`#[\p{L}\p{N}_]+`, Unicode), rendus cliquables et colorés
(`_buildPostContent`, `Text.rich` + `TapGestureRecognizer`), le tap
réutilise la recherche déjà en place (`content ilike`) plutôt qu'un
nouveau système de filtre. Aucune colonne/table nécessaire — un client
ou le staff peut inventer un hashtag à la volée (`#AkoraPro`,
`#PromoAout`...), plus flexible qu'une liste figée de piliers.

**Mentions @** : réutilise `posts.mentioned_user_id`, présente depuis la
Phase 3 mais jamais reliée à une interface jusqu'ici — aucun changement
de schéma. Nouveau `_UserPickerSheet` (recherche serveur sur
`public_profiles`, débouncée — contrairement à `_ProductPickerSheet` qui
précharge tout, trop de clients pour ça) dans le composer ; affiché dans
le fil comme "avec @Nom" sous le contenu, cliquable vers le profil
public. Portée volontairement limitée aux publications (pas les
commentaires) pour ce lot, même logique que les réactions emoji en
Phase 46.

**SQL** : `supabase/phase53_patch_post_images_carousel.sql` —
`post_images` (post_id, image_url, position), même principe que
`product_images`/`raw_material_images`. RLS : la policy de lecture
délègue entièrement à une sous-requête sur `posts` (elle-même filtrée
par la RLS `posts_select` — bloqués/masqués/visibilité, Phase 3/51),
pas de duplication de cette logique. Écriture réservée à l'auteur du
post ou au staff.

**Carrousel multi-images** : composer passé de `File? _image` à
`List<File> _images` (`image_picker.pickMultiImage`), prévisualisation
en bande horizontale avec suppression par image. À la publication,
chaque photo est uploadée séparément vers `wall-photos` puis insérée
dans `post_images` ; `posts.image_url` garde la première photo pour
rester compatible avec les affichages qui ne connaissent pas encore
cette table (aperçu du profil public — limite assumée, pas de carrousel
là-bas pour ce lot). Le fil affiche un nouveau `_PostImageCarousel`
(`PageView` + puces) uniquement si 2 photos ou plus ; sinon repli sur
l'ancien rendu `Image.network(image_url)` inchangé.

**Modifications Dart :** `wall_tab.dart` (composer multi-images +
mention, `_UserPickerSheet`, `_PostImageCarousel`, hashtags cliquables,
badge mention dans le fil).

## Communauté façon Facebook — Lot 4 : découverte (02/08)

Quatrième lot : **fil "Tendances", filtre par pilier**.

**SQL** : `supabase/phase54_patch_trending_posts.sql` — vue
`post_engagement_scores` (post_id, created_at, score = réactions +
commentaires agrégés). Sert UNIQUEMENT à classer : `_fetchTrendingPosts`
récupère d'abord les ids les plus actifs des 30 derniers jours via cette
vue, puis re-fetch les publications correspondantes depuis `posts` (RLS
complète, Phase 3/51) et ne garde que celles réellement renvoyées — une
publication bloquée/masquée/privée disparaît donc naturellement du
classement, sans dupliquer cette logique dans la vue elle-même.

**Tendances** : nouvelle puce dans le fil (à côté de "Mes publications"),
liste fixe (top 30, pas de pagination — un fil "tendances" n'a pas
vocation à défiler à l'infini) ; désélectionnée automatiquement dès
qu'un autre filtre (secteur, recherche, hashtag, pilier) est utilisé,
pour éviter une combinaison de filtres incohérente.

**Filtre par pilier** : nouvelle rangée de puces (Akora Pro, Akora
Protect, Peinture Pro...) sous le filtre secteur, réutilise
`business_units`/`products.business_unit_id` déjà en place (aucun
changement de schéma). Filtre les publications dont le produit taggé
appartient au pilier choisi — même principe que `_sectorAuthorIds`
(récupère d'abord les ids concernés, puis `inFilter` sur `posts`).

**Modifications Dart :** `wall_tab.dart` uniquement (`_fetchTrendingPosts`,
`_pilierProductIds`, `_loadBusinessUnits`, deux nouvelles rangées de
puces).

## Communauté façon Facebook — Lot 5 : preuve sociale (02/08)

Cinquième et dernier lot de la liste initiale : **avis vérifiés liés à
un achat réel, galerie "Réalisations clients"**.

**SQL** : `supabase/phase55_patch_verified_purchases_reviews.sql` — 3
fonctions SECURITY DEFINER, aucune nouvelle table (réutilisent
`orders`/`order_items`/`product_reviews`/`posts` déjà en place, même
principe que `has_purchased_raw_material`, Phase 45 : ne révèlent qu'un
booléen ou un id, jamais le détail d'une commande) :
- `has_ordered_product(uid, pid)` : le client a-t-il une commande non
  annulée contenant ce produit.
- `verified_reviewers(pid)` : parmi les auteurs d'avis sur ce produit,
  lesquels l'ont réellement commandé (1 appel par page produit).
- `verified_purchase_post_ids(post_ids[])` : parmi une liste de
  publications, lesquelles ont un auteur ayant réellement commandé le
  produit taggé (1 appel par page du fil).

**Bug trouvé et corrigé au passage** : `_ReviewsSection`
(product_detail_client.dart) utilisait `.select('*, profiles(full_name,
company_name)')` — une jointure imbriquée qui ne fonctionne JAMAIS pour
les avis d'un AUTRE client, la RLS de `profiles` limitant la lecture à
sa propre ligne (Phase 1). Tous les avis affichaient donc silencieusement
"Client" au lieu du vrai nom depuis le début. Remplacé par
`PublicProfilesRepo.fetchByIds`, le chemin déjà utilisé partout ailleurs
(Communauté, amis) pour ce même problème.

**Achat vérifié** : badge ✓ "Achat vérifié" affiché (a) sur un avis
produit dont l'auteur a réellement commandé (`product_detail_client.dart`),
(b) sur une publication taggant un produit que son auteur a réellement
commandé (`wall_tab.dart`, à côté du tag produit et du bouton Commander).

**Galerie "Réalisations clients"** : nouvel écran
`community/realisations_gallery_screen.dart` — grille de vignettes des
publications ayant à la fois une photo ET un produit taggé (aucune
nouvelle table, filtre simplement `posts` sur ces deux colonnes non
nulles). Filtrable par pilier (même pattern que le Lot 4). Tap sur une
vignette → fiche détaillée en feuille modale (photo, auteur, texte,
produit avec badge vérifié, bouton vers la fiche produit). Accessible
depuis une nouvelle icône 🖼 dans l'AppBar de la Communauté.

**Modifications Dart :** `product_detail_client.dart` (fix noms +
badge avis), `wall_tab.dart` (badge posts + icône galerie),
`community/realisations_gallery_screen.dart` (nouveau).

---

**Les 5 lots de la liste "Communauté meilleure que Facebook" du 02/08
sont maintenant tous construits.** Reste hors-liste initiale : groupes
communautaires par catégorie de Formation (chantier séparé, socle achat
de cours déjà posé — voir plus haut, maintenant construit ci-dessous),
formulaire "Sécurité des données" du Play Store (mis de côté par
l'utilisatrice).

## Groupes communautaires AkoraFormation, par catégorie (02/08)

Chantier annoncé depuis le 01/08 ("Le groupe sont spécialement pour tout
le participant des nôtres formation. Seulement pour les participants.")
— mis en pause le temps de construire l'achat de cours (choix de
l'utilisatrice via AskUserQuestion : "D'abord construire l'achat de
cours"), maintenant construit sur ce socle (`course_purchases`, Phase
50).

**Choix retenus (via AskUserQuestion)** :
- Un **fil filtré par catégorie** plutôt qu'un vrai système de groupes
  avec membres/invitations — plus léger, la catégorie fait déjà office
  de groupe.
- Version **"fil simple"** pour cette première itération : publications
  texte/photo, PAS de commentaires ni réactions (extensible plus tard si
  demandé).

**SQL** : `supabase/phase56_patch_formation_groups.sql` —
- `is_formation_group_participant(uid, cat)` : le client a-t-il un achat
  de cours VALIDÉ (`course_purchases.status = 'validee'`) dans cette
  catégorie précise. C'est la définition exacte de "participant".
- `formation_group_posts` (category, author_id, content, image_url,
  updated_at) : un fil par catégorie. **La protection ("seulement pour
  les participants") est dans la RLS** : select/insert exigent
  `is_formation_group_participant` OU le staff — un client qui n'a rien
  acheté dans cette catégorie reçoit simplement une liste vide depuis
  l'API, jamais les publications. Réutilise le bucket `wall-photos`
  (public, Phase 3) pour les photos, aucun nouveau bucket.

**Nouveaux fichiers Dart :**
- `core/formation/formation_groups_repo.dart` : catégories participées,
  toutes les catégories (pour le staff), CRUD des publications.
- `client_home/formation/formation_group_screen.dart` : le fil d'une
  catégorie (liste + composer texte/photo, modifier/supprimer ses
  propres publications) — mêmes patterns que `wall_tab.dart` en plus
  simple (pas de réactions/commentaires, choix assumé).
- `client_home/formation/my_formation_groups_screen.dart` : "Mes
  groupes", liste des catégories où le client est participant validé —
  accessible via une icône dans l'AppBar d'Académie. Liste vide avec
  message explicite si aucun achat validé.
- `formation_groups_management/formation_groups_management.dart` :
  écran Admin listant TOUTES les catégories (le staff contourne la
  vérification participant via la RLS mais doit pouvoir choisir laquelle
  ouvrir) — ajouté au menu Plus, pour la modération.

⚠️ **Limite assumée pour cette version** : pas de commentaires, réactions
ni signalement sur les publications de groupe — uniquement publier/
modifier/supprimer. Peut être étendu plus tard sur le même modèle que la
Communauté si demandé.

## Profil client — refonte par lots, Lot 1 : nettoyage structurel (03/08)

Demande explicite ("Je n'aime pas l'arrangement de chaque fonctionnalité
ici") — liste longue de 26 pistes proposée (réorganisation + nouveautés
façon Facebook), triée en 4 lots. Lot 1 construit (le plus urgent, pur
nettoyage, aucune nouvelle donnée) :

- **"Informations personnelles" (Email/Société/Téléphone/Localisation)
  retirée de la vue principale** de `profile_tab.dart` — déjà
  consultable/modifiable via "Modifier le profil" (`_EditProfileSheet`,
  qui affichait déjà ces champs pré-remplis) ; la société apparaît
  désormais en sous-titre sous le nom dans l'en-tête (identité), la
  localisation était déjà affichée là aussi. L'email n'avait nulle part
  où aller : ajouté dans **Paramètres → nouvelle carte "Compte"**
  (lecture seule, pas de changement d'email pris en charge).
- **"Commandes récurrentes / Fidélité / Scanner un produit" regroupées
  sous un titre "Mes achats"**, désormais séparées de "Messagerie" —
  celle-ci n'est PAS un doublon de la messagerie entre clients de la
  Communauté (Phase 48) : c'est la messagerie client ↔ équipe
  commerciale (`chat_screen.dart`, Phase 8). Renommée **"Contacter
  l'équipe"** pour éviter la confusion, placée sous un nouveau titre
  "Assistance".
- **Déconnexion retirée de la page Profil**, désormais uniquement dans
  **Paramètres** (nouvelle carte en bas, avec confirmation — même
  logique que `more_menu_screen.dart` côté Admin). `ProfileTab` n'a donc
  plus besoin du callback `onLogout` (retiré du constructeur ;
  `client_home.dart` simplifié en conséquence, `_handleLogout` supprimé
  car devenu mort).

**Modifications Dart :** `profile_tab.dart`, `settings_screen.dart`
(carte Compte + carte Déconnexion, autonome — fonctionne aussi pour
l'Admin qui partage cet écran), `client_home.dart` (nettoyage).

## Profil client — refonte par lots, Lot 2 : mettre en valeur l'existant (03/08)

Deuxième lot : **bandeau de stats cliquables, points fidélité en clair,
badge secteur stylé, barre de complétion de profil**. Aucune nouvelle
table — tout réutilise des données déjà en base (`profiles.loyalty_points`
déjà utilisée par `loyalty_screen.dart`, `orders.customer_id`).

- **Bandeau de stats** (`_StatItem`, façon Instagram) sous le badge
  secteur : Publications (tap → bascule l'onglet "Publications" en
  place), Commandes (tap → `OrdersTab` poussé dans un `Scaffold` ad hoc
  avec AppBar — `OrdersTab` n'a pas d'AppBar propre, il est conçu pour
  être hébergé par `client_home.dart`), Points fidélité (tap →
  `LoyaltyScreen`). Remplace l'ancienne ligne de texte
  "X publications · Client depuis Y" — le compteur de publications sort
  de ce texte pour devenir une vraie stat cliquable.
- **Badge secteur restylé** : passé d'un `Chip` texte brut à un badge
  coloré (icône + couleur par secteur : hôtel marine, hôpital rouge,
  entreprise violet, particulier vert — mêmes teintes que le reste de
  l'app).
- **Barre "Profil complété à X%"** : calculée sur 7 champs (photo,
  couverture, bio, téléphone, localisation, société, secteur) — carte
  avec `LinearProgressIndicator` + bouton "Compléter" (ouvre "Modifier
  le profil"), **disparaît automatiquement une fois à 100%**.

**Modifications Dart :** `profile_tab.dart` uniquement (`_StatItem`,
`_buildCompletionBar`, requête `orders` en `count()` ajoutée à
`_loadAll`).

## Profil client — refonte par lots, Lot 3 : connecter au reste de l'app (03/08)

Troisième lot : **lien profil public, mini-galerie "Mes réalisations",
avis laissés, engagement communautaire, raccourci groupes Formation**.
Aucune nouvelle table — connecte le Profil aux systèmes déjà construits
aujourd'hui (Communauté Lots 1-5, groupes Formation).

- **"Voir mon profil public"** : ouvre `PublicProfileScreen` avec son
  propre id. Cet écran gérait déjà proprement le cas "c'est moi"
  (section Ami masquée) — aucune modification nécessaire côté écran, et
  comme il ne charge que les publications `visibility = 'public'`,
  l'aperçu montre exactement ce que voient réellement les autres
  clients.
- **Mini-galerie "Mes réalisations"** : grille de 6 vignettes en haut de
  l'onglet "Tout" (mêmes posts que la galerie Communauté — photo +
  produit taggé — mais filtrés sur soi), avec "Voir tout" vers
  `RealisationsGalleryScreen`, qui gagne un paramètre optionnel
  `authorId` pour ce cas (titre "Mes réalisations" au lieu de
  "Réalisations clients").
- **"Mes avis laissés"** : nouvel écran `my_reviews_screen.dart` —
  liste des `product_reviews` de l'utilisateur, badge "Achat vérifié"
  (Phase 55, un appel `has_ordered_product` par produit distinct,
  toujours peu nombreux pour un seul client).
- **"Mes groupes Formation"** : raccourci direct vers
  `MyFormationGroupsScreen` (construit plus tôt aujourd'hui).
- **"Mon engagement"** : réactions + commentaires reçus sur les 30
  dernières publications (pas l'historique complet — suffisant pour un
  résumé d'activité récente, pas besoin d'une exactitude totale ici).

**Bonus au passage** : le compteur "$_postsCount publications" utilisait
`list.length` sur une requête plafonnée à 30 (`.limit(30)`) — un client
avec plus de 30 publications aurait donc vu un chiffre figé à 30.
Remplacé par un vrai `.count()`, comme déjà fait pour Commandes au Lot 2.

**Nouveaux fichiers Dart :** `my_reviews_screen.dart`.
**Modifications Dart :** `profile_tab.dart` (mini-galerie, carte
"Communauté & Formation", requêtes engagement/avis dans `_loadAll`),
`community/realisations_gallery_screen.dart` (paramètre `authorId`).

## Profil client — refonte par lots, Lot 4 : nouveautés plus lourdes (03/08)

Quatrième et dernier lot : **badges de fidélité/niveaux, adresses de
livraison multiples, QR code de contact, couleur d'accent
personnalisable**.

**SQL** : `supabase/phase57_patch_delivery_addresses.sql` —
`delivery_addresses` (customer_id, label, address, latitude, longitude,
is_default) + RLS strictement personnelle (select/insert/update/delete
own only).

⚠️ **Limite assumée** : ce carnet d'adresses est autonome pour l'instant
— le checkout (`cart_tab.dart`) garde son champ de saisie libre actuel,
**non branché** sur ces adresses enregistrées dans ce lot. Brancher les
deux touche le flux de commande en production ; laissé pour un chantier
séparé, à faire avec plus de prudence.

- **Badges de fidélité** : les paliers (Bronze/Argent/Or), jusqu'ici
  définis en privé dans `loyalty_screen.dart`, extraits vers
  `core/loyalty/loyalty_tiers.dart` (`LoyaltyTier`, `kLoyaltyTiers`,
  `currentLoyaltyTier`) pour être réutilisés sans duplication —
  `loyalty_screen.dart` refactorisé pour consommer ce fichier partagé.
  Badge "Palier X" ajouté dans l'en-tête du Profil, à côté du badge
  secteur.
- **Adresses de livraison** : nouvel écran
  `delivery_addresses/delivery_addresses_screen.dart` — liste, ajout/
  modification (avec "Utiliser ma position actuelle", même logique que
  `_EditProfileSheet`), suppression, définir par défaut (deux `update`
  successifs plutôt qu'un trigger SQL — un double défaut temporaire
  n'est qu'un détail d'affichage, pas un problème de sécurité). Entrée
  dans "Mes achats".
- **QR de contact** : nouvel écran `my_contact_qr_screen.dart` — encode
  une **vCard standard** (nom, société, téléphone) via `qr_flutter`
  (déjà utilisé pour les lots de traçabilité produit), volontairement
  PAS un id interne : une vCard est lisible par n'importe quel lecteur
  QR/appareil photo, même hors de l'app — aucun système de "scanner pour
  ajouter en ami" n'existe à ce jour. Entrée dans "Communauté &
  Formation".
- **Couleur d'accent personnalisable** : nouveau
  `core/providers/profile_accent_provider.dart` (Riverpod +
  `SharedPreferences`, même pattern que `theme_provider.dart`) —
  **volontairement locale à l'appareil**, jamais synchronisée en base ni
  appliquée au thème global de l'app. Les 3 couleurs de marque
  (`app_theme.dart`) sont délibérées et documentées comme telles ; cette
  personnalisation reste cantonnée aux stats et à la barre de complétion
  du Profil, choisie parmi une palette restreinte
  (`kProfileAccentChoices`, pas une roue de couleurs libre) via un
  nouveau bouton palette à côté de "Modifier le profil"/"Partager".

**Nouveaux fichiers Dart :** `core/loyalty/loyalty_tiers.dart`,
`core/providers/profile_accent_provider.dart`,
`delivery_addresses/delivery_addresses_screen.dart`,
`my_contact_qr_screen.dart`.
**Modifications Dart :** `profile_tab.dart`, `loyalty_screen.dart`
(refactor).

---

**Les 4 lots de la refonte du Profil client du 03/08 sont maintenant
tous construits.**

## Carnet d'adresses branché au checkout (03/08)

Limite du Lot 4 levée à la demande de l'utilisatrice : le carnet
d'adresses (`delivery_addresses`, Phase 57) était autonome, sans lien
avec `cart_tab.dart`. Ajouté un bouton 🔖 à côté du bouton "Utiliser ma
position actuelle" dans le champ "Adresse de livraison" du panier —
ouvre une feuille listant les adresses enregistrées du client (adresse
par défaut en premier), la sélection remplit le champ ET recalcule les
frais de livraison (`DeliveryPricing.correctedDistanceKm`/
`feeForDistance`, même logique que l'estimation GPS) si l'adresse a une
position enregistrée. Si l'adresse a été créée sans géolocalisation
(champ facultatif dans l'éditeur du carnet), retombe sur le même repli
"frais à confirmer par l'équipe" que l'estimation GPS quand elle échoue
— comportement cohérent, pas un cas d'erreur séparé.

Le comportement automatique existant (estimation GPS au chargement du
panier) reste inchangé — le carnet d'adresses est une alternative
explicite, pas un remplacement : la position GPS fraîche reste plus
fiable pour le calcul des frais qu'une adresse enregistrée qui peut être
obsolète.

**Modifications Dart :** `cart_tab.dart` uniquement
(`_pickSavedAddress`, bouton dans le champ d'adresse).

## Fusion des écrans admin "Achats Formation" (02/08)

Le menu Plus admin affichait deux entrées quasi-identiques
("Achats Formation — Matières premières" et "Achats Formation — Cours
AkoraFormation"), source de confusion signalée par l'utilisateur. Les
deux tables restent séparées côté Supabase (`formation_purchases` vs
`course_purchases`, deux catalogues distincts), seule la navigation est
regroupée : nouveau `formation_purchases_management/
formation_purchases_hub.dart` avec un `TabBar` (Matières premières /
Cours) hébergeant les deux écrans existants, désormais dépouillés de
leur `Scaffold`/`AppBar` propre pour servir de contenu d'onglet.
L'icône médaille dans `raw_materials_management.dart` pointe aussi vers
ce hub.

**Modifications Dart :** `formation_purchases_management.dart`,
`course_purchases_management.dart` (Scaffold retiré des deux),
`raw_materials_management.dart`, `more_menu/more_menu_screen.dart`.
**Nouveau fichier Dart :** `formation_purchases_hub.dart`.

## Notification push staff manquante sur les demandes d'achat Formation (02/08)

Bug signalé : un achat Formation (matière première ou cours) effectué
depuis la page externe Netlify (`docs/formation-access/index.html`)
s'enregistrait bien en base (`status = 'en_attente'`, visible côté
client via le bandeau "N produit(s) en attente de vérification"), mais
le staff n'était jamais notifié — contrairement aux commandes
(paiement manuel, Phase 39) ou aux devis. Aucun trigger n'existait sur
`formation_purchases`/`course_purchases`, c'était juste un oubli lors
des Phases 45/50, jamais un problème de RLS (la policy
`..._select_own_or_staff` autorise déjà le staff à tout voir).

**SQL** : `supabase/phase58_patch_formation_purchases_staff_notification.sql`
— deux triggers `after insert ... when (NEW.status = 'en_attente')`,
même principe que `on_order_manual_payment_submitted_push` (Phase 39) :
appelle `send-push-notification` avec `table: 'formation_purchases'` ou
`'course_purchases'`. ⚠️ Remplacer `<WEBHOOK_SECRET>` (deux occurrences)
avant exécution.

**Edge Function** : `send-push-notification/index.ts` — deux nouvelles
branches (catégorie `commande`, notifie `admin`/`commercial`), résolvent
le nom du produit/cours concerné pour un message précis ("Demande
d'accès : <nom>").

## Intégration FiveOne Pay — second fournisseur de paiement Mobile Money, Lot 1/4 (02/08)

Trouvé par l'utilisateur : FiveOne Pay, agrégateur Mobile Money
malgache concurrent de Papi.mg (Phase 38) — une seule API pour les 3
opérateurs (`operator: MVOLA/ORANGE_MONEY/AIRTEL_MONEY` dans le même
`POST /v1/payments`), webhooks signés HMAC-SHA256
(`X-FiveOne-Signature`, secret `whsec_...`) avec idempotence via
`X-FiveOne-Event-Id`, commission 2,75 % (plancher 100 MGA, plafond
16 500 MGA). Ajouté **en plus** de Papi, pas en remplacement — objectif
: pouvoir choisir, opérateur par opérateur, lequel des deux traite le
paiement.

**Décision d'architecture** (suite à une demande explicite de clarté
côté réglages Admin) : plutôt que de dupliquer les choix de paiement
visibles par le client (ce qui donnerait 6 boutons Mobile Money au lieu
de 3), chaque opérateur (`mvola`/`orange_money`/`airtel_money`) garde
**une seule ligne** dans `payment_method_settings` (Phase 28), avec une
nouvelle colonne `provider` (`'papi'` ou `'fiveonepay'`) qui dit lequel
des deux traite ce paiement — une seule valeur possible à la fois,
donc jamais d'ambiguïté sur qui confirme. Le client voit toujours
"MVola / Orange Money / Airtel Money / Manuel" au checkout, inchangé ;
seul l'écran Admin (Lot 4) affichera ce même réglage regroupé
visuellement par plateforme (Papi.mg / FiveOne Pay / Manuel) pour que
ce soit clair à activer/désactiver.

**SQL** : `supabase/phase59_patch_fiveonepay_payment.sql` —
- `payment_method_settings.provider` (backfill `'papi'` sur les 3
  lignes opérateur existantes, pour ne rien changer au comportement
  actuel tant que l'Admin ne bascule rien).
- `orders.fiveonepay_reference` / `orders.fiveonepay_payment_url` —
  équivalent de `papi_notification_token`/`papi_payment_link`, mais pas
  besoin d'un token par commande : FiveOne Pay signe tout le corps du
  webhook (HMAC), l'authenticité ne dépend pas d'une valeur stockée par
  commande.
- `fiveonepay_webhook_events (event_id primary key)` — déduplication
  des webhooks (retry garanti par FiveOne Pay jusqu'à un 2xx), RLS
  activée sans aucune policy (écrite uniquement par l'Edge Function via
  la service role key).

**Prochains lots** : Edge Function `create-fiveonepay-payment-link`
(Lot 2), webhook `fiveonepay-payment-notification` (Lot 3), checkout +
écran Admin regroupé par plateforme (Lot 4). Clés API FiveOne Pay
(Sandbox `sk_test_...` puis Production `sk_live_...` + `whsec_...`)
nécessaires à partir du Lot 3 pour tester réellement — compte Sandbox
déjà créé par l'utilisateur.

## Intégration FiveOne Pay, Lot 2/4 : Edge Function de création de paiement (02/08)

`supabase/functions/create-fiveonepay-payment-link/index.ts` — même
squelette que `create-papi-payment-link` (Phase 38) : vérifie la
session, charge la commande, s'assure qu'elle appartient bien à
l'appelant, appelle `POST /v1/payments` (FiveOne Pay), stocke
`fiveonepay_reference`/`fiveonepay_payment_url` sur la commande, renvoie
`paymentLink` au client. Deux différences avec Papi :
- **Double vérification serveur du `provider`** : n'appelle FiveOne Pay
  que si `payment_method_settings.provider = 'fiveonepay'` pour cet
  opérateur — évite un appel API erroné si le réglage Admin a changé
  entre le chargement de l'écran client et la validation du paiement
  (Papi n'a pas cette vérification, il n'y avait qu'un seul fournisseur
  à l'époque).
- **`Idempotency-Key: order.order_number`** — FiveOne Pay garantit
  qu'un second appel avec la même clé renvoie le paiement déjà créé
  plutôt que d'en créer un nouveau (rejouable sans risque après une
  coupure réseau) ; Papi n'offre pas cette garantie nativement.

Secret nécessaire (Supabase Dashboard -> Edge Functions -> Manage
secrets) : `FIVEONEPAY_SECRET_KEY` (Sandbox `sk_test_...`, puis
Production `sk_live_...` une fois le dossier KYC validé).

## Intégration FiveOne Pay, Lot 3/4 : webhook signé (02/08)

`supabase/functions/fiveonepay-payment-notification/index.ts` — reçoit
`payment.success`/`payment.expired` (les seuls événements pertinents
pour AkoraHub ; `payout.*`/`invoice.*`/`subscription.*` accusés de
réception sans traitement, pas utilisés par l'app aujourd'hui).

Différences avec `papi-payment-notification` (Phase 38) :
- **Signature HMAC-SHA256 sur tout le corps brut** (`X-FiveOne-
  Signature`, secret `whsec_...`, comparaison en temps constant) au
  lieu d'un token stocké par commande — Papi n'offrait pas de signature
  vérifiable, d'où le contournement par token à l'époque. Le corps est
  lu en texte brut (`req.text()`) avant tout `JSON.parse`, sinon un
  ré-encodage changerait les octets signés et invaliderait la
  vérification.
- **Déduplication via `fiveonepay_webhook_events`** (Phase 59) : un
  même événement peut arriver plusieurs fois (retry garanti par
  FiveOne Pay jusqu'à un 2xx) — insertion de l'`event_id`, traitement
  ignoré si déjà vu (conflit de clé primaire).
- Même repli sécurité que Papi sur signature invalide : jamais d'erreur
  HTTP renvoyée (`200 "ignored"` + log serveur), pour ne pas déclencher
  de retry infini sur une requête forgée.
- `payment.success` fait toujours foi même après un `payment.expired`
  déjà reçu pour la même commande (paiement Mobile Money tardif,
  documenté par FiveOne Pay) — le statut est simplement réécrasé, pas
  de verrou empêchant `paye` après `echoue`.

Secret nécessaire : `FIVEONEPAY_WEBHOOK_SECRET` (`whsec_...`, tableau
de bord FiveOne Pay -> Webhooks ou Paramètres).

⚠️ **Réglage Supabase à faire manuellement au déploiement** : la
fonction `fiveonepay-payment-notification` doit avoir **"Verify JWT
with legacy secret" désactivé** (Function -> Settings) — c'est un
endpoint public appelé directement par les serveurs de FiveOne Pay, qui
n'envoient pas de jeton Supabase ; laissé activé, la plateforme
rejetterait tous les webhooks avant même d'atteindre le code.
`create-fiveonepay-payment-link` garde ce réglage activé (elle est
appelée par l'app avec la session du client).

## Intégration FiveOne Pay, Lot 4/4 : checkout + écran Admin regroupé par plateforme (02/08)

**Checkout** (`payment_screen.dart`) : nouveau
`core/payment/fiveonepay_payment_repo.dart` (même forme que
`PapiPaymentRepo`, réponse `paymentLink` identique pour que l'UI traite
les deux fournisseurs sans distinction). `PaymentMethodSettingsRepo`
gagne `fetchProviders()`/`setProvider()`. Renommé `usesPapi` ->
`usesOnlinePayment` et `papiFailed` -> `onlinePaymentFailed` (plus
Papi-spécifique) ; au moment de créer le paiement en ligne, lit
`_providers[_paymentMethod]` pour appeler `FiveOnePayPaymentRepo` ou
`PapiPaymentRepo` selon le réglage Admin. Le client ne voit toujours
que "paiement automatique en ligne" — aucune mention du fournisseur.

**Admin** (`payment_methods_management.dart`) : entièrement
restructuré en 3 sections visuellement séparées, demande explicite de
l'utilisateur pour la clarté :
- **Papi.mg** — un interrupteur par opérateur (MVola/Orange
  Money/Airtel Money).
- **FiveOne Pay** — même 3 opérateurs, mais Orange Money et Airtel
  Money grisés/désactivés (`disabled: true`) tant que FiveOne Pay ne
  les propose pas réellement (évite un routage vers un opérateur qu'il
  ne sait pas encore traiter).
- **Manuel** — paiement à la livraison, virement bancaire, + le
  réglage "Secours manuel Mobile Money" existant (Phase 38) qui force
  tout le monde en manuel si un fournisseur tombe en panne.

Chaque opérateur reste **une seule ligne** en base
(`payment_method_settings.provider`) — activer son interrupteur sous
une plateforme fait `enabled = true` + `provider = <plateforme>` ;
le désactiver fait `enabled = false` (jamais de bascule automatique
vers l'autre fournisseur, pour éviter un changement de routage
surprise — l'Admin doit explicitement activer l'autre plateforme s'il
veut basculer).

**Nouveau fichier Dart :** `core/payment/fiveonepay_payment_repo.dart`.
**Modifications Dart :** `payment_screen.dart`,
`payment_method_settings_repo.dart`, `payment_methods_management.dart`
(réécrit).

---

**Les 4 lots de l'intégration FiveOne Pay du 02/08 sont maintenant
tous construits.** Reste à faire un vrai test de paiement Sandbox de
bout en bout une fois les 2 fonctions déployées et les 2 secrets
configurés côté Supabase.

## FiveOne Pay : activation d'Orange Money (03/08)

FiveOne Pay a activé Orange Money sur leur plateforme (au départ, seul
MVola était réellement disponible chez eux, Orange Money et Airtel
Money étaient annoncés "bientôt"). L'Edge Function
`create-fiveonepay-payment-link` gérait déjà les 3 opérateurs
(`operatorMap` : mvola/orange_money/airtel_money -> MVOLA/ORANGE_MONEY/
AIRTEL_MONEY) — seul le verrou côté Admin (Lot 4/4, 02/08) bridait
encore Orange Money par `disabled: true` "en dur". Retiré ce verrou
pour Orange Money dans `payment_methods_management.dart`
(`_providerTile(PaymentMethod.orangeMoney, 'fiveonepay')`, sans
`disabled`) — l'interrupteur est maintenant activable comme celui de
MVola. Airtel Money reste grisé ("Bientôt disponible chez FiveOne
Pay") tant que FiveOne Pay ne le propose pas réellement.

**Migration progressive vers la production FiveOne Pay** (mené avec
l'utilisateur en direct, pas de code) : compte de reversement Mobile
Money (MVola + Orange Money) validé chez FiveOne Pay, clé API
Production créée et mise dans le secret Supabase
`FIVEONEPAY_SECRET_KEY` (remplace la clé Sandbox), secret webhook
Production régénéré et mis dans `FIVEONEPAY_WEBHOOK_SECRET`. Décision
explicite de l'utilisateur : Papi.mg reste le seul fournisseur
automatique actif pour MVola/Orange Money/Airtel Money jusqu'à un vrai
test de paiement de bout en bout sous FiveOne Pay (lien de paiement +
webhook + confirmation automatique de la commande) — bascule
opérateur par opérateur via l'interrupteur Admin, pas de bascule
globale d'un coup.

## CRM — Fiche client 360°, Lot 1/5 (02/08)

Nouveau chantier CRM (5 lots, demande explicite de l'utilisateur pour
"mieux suivre ses clients") : Lot 1 regroupe en LECTURE, pour un client
donné, ce qui était jusqu'ici éparpillé entre plusieurs écrans admin —
commandes, devis, factures, avis produits, activité Communauté,
fidélité et adresses de livraison. Notes internes, étiquettes, statut
VIP, segmentation restent pour les Lots 2 à 5, gardés simples et
testables séparément.

**SQL** : `supabase/phase60_patch_customer_360.sql` —
- Nouvelle policy `delivery_addresses_select_own_or_staff` : la policy
  existante (Phase 57) ne couvrait QUE le propriétaire, contrairement à
  toutes les autres tables de la fiche (`orders`/`quotes`/`invoices`/
  `product_reviews`/`posts`/`profiles` ont déjà leur `..._select_own_or_staff`
  depuis la Phase 1) — sans ce correctif, la section Adresses serait
  revenue silencieusement vide pour l'Admin (RLS, pas d'erreur visible).
- `staff_get_customer_email(customer_id)` — l'email vit uniquement dans
  `auth.users`, jamais dupliqué sur `profiles`. Même principe que
  `find_profile_by_email` (Phase 1) mais dans le sens inverse (id ->
  email plutôt qu'email -> profil), security definer + restreint au
  staff.

**Nouveau fichier Dart** : `lib/presentation/customer_360/customer_360_screen.dart`
— en-tête (avatar, nom, type client, palier de fidélité `LoyaltyTier`
réutilisé de `core/loyalty/loyalty_tiers.dart`, téléphone, email,
ancienneté), 3 cartes stats (valeur totale/lifetime value en excluant
les commandes annulées, nombre de commandes, date de dernière
commande), liste des adresses de livraison, et une **chronologie
d'activité unifiée** fusionnant commandes/devis/factures/avis/publications
Communauté triés par date. Toutes les requêtes tournent en parallèle
(`Future.wait`), noms de produits pour les avis résolus par une requête
batch séparée (même pattern que `PublicProfilesRepo.fetchByIds`
ailleurs dans le code).

**Point d'entrée** : `customer_management_real.dart` — la liste des
clients n'avait jusqu'ici aucun `onTap` sur ses lignes ; ajout d'un
chevron + navigation vers `Customer360Screen(customerId: ...)`.

## CRM — Lot 2/5 : notes, étiquettes, historique messages, alerte devis, relances (02/08)

**SQL** : `supabase/phase61_patch_crm_lot2_a.sql` (+ partie optionnelle
`_b_cron_optional.sql`, même convention que Phase 13 pour pg_cron) :
- `customer_notes` (customer_id, author_id, content) — RLS strictement
  staff (`for all using (current_role_is_staff())`), jamais visible du
  client.
- `profiles.tags text[]` — même pattern que `business_unit_ids`
  (Phase 1), aucune nouvelle policy nécessaire (`profiles_update_own_or_staff`
  couvre déjà toutes les colonnes).
- `quotes.last_reminder_at` + fonction `process_stale_quote_reminders()`
  (devis `status='envoye'` depuis plus de 5 jours, pas relancé depuis
  plus de 3 jours) — notifie le **staff** (pas le client directement :
  jugement humain préférable à une relance automatique répétée),
  planifiée quotidiennement via `pg_cron` (partie B, optionnelle selon
  le plan Supabase).

⚠️ **"Devis accepté sans commande liée" — limite assumée et documentée** :
aucun lien formel `quotes`/`orders` n'existe dans le schéma (pas de
`quote_id` sur `orders`), et l'app n'a **aucun flux "convertir un devis
en commande"** — donc pas de vraie colonne créée pour ce lien, qui
resterait toujours vide. La fiche 360° calcule à la place une
**approximation côté app** (devis accepté sans aucune commande du même
client créée après lui), affichée comme une alerte à vérifier
manuellement, jamais comme une certitude.

**Edge Function** : `send-push-notification/index.ts` — nouvelle
branche `quotes_stale_reminder` (catégorie `devis`, notifie
`admin`/`commercial`).

**`customer_360_screen.dart` étendu** :
- Requêtes `customer_notes` et `conversations` ajoutées à la fin du
  `Future.wait` existant (indices 8/9, sans renuméroter les 8
  précédents) ; les `messages` de la conversation sont récupérés dans
  une requête séparée après (comme les noms de produits au Lot 1), et
  fusionnés dans `_timeline`.
- Bandeau d'alerte (rouge, `errorContainer`) si des devis acceptés sans
  commande visible sont détectés — texte explicite "approximation, pas
  certain".
- Section "Notes internes" : liste + champ d'ajout, jamais visible côté
  client (RLS).
- Étiquettes : `Wrap` de `Chip`s avec suppression (`onDeleted`) + champ
  d'ajout, sous l'en-tête.

## CRM — Lot 3/5 : statut VIP, avantages accordés, note moyenne, signalements (02/08)

**SQL** : `supabase/phase62_patch_crm_lot3.sql` :
- `profiles.is_vip boolean not null default false` — même principe que
  `tags` (Phase 61) : aucune policy dédiée, `profiles_update_own_or_staff`
  couvre déjà la colonne, seule l'app UI réserve le bouton au staff.
- `customer_benefits` (customer_id, granted_by, description) — journal
  manuel des avantages accordés (remise exceptionnelle, cadeau,
  livraison offerte…). Aucun système de coupons/promos automatisé
  n'existe dans le schéma, donc pas de table dérivée d'un flux existant
  — RLS strictement staff, même politique que `customer_notes`.
- Pas de nouvelle table pour la note moyenne : calculée côté app depuis
  `product_reviews` (déjà chargé depuis le Lot 1).
- Pas de nouvelle colonne pour les signalements : `post_reports`
  (Phase 47) n'a pas de colonne "personne signalée" (seulement
  `reporter_id`, qui dépose le signalement, sur un `post_id`). La fiche
  360° affiche donc deux angles distincts déduits de cette table
  existante : signalements **déposés par** ce client (`reporter_id`) et
  signalements **reçus sur les publications de** ce client (jointure
  `post_reports.post_id -> posts.author_id`, `!inner` filtré côté
  requête comme dans `alerts_center.dart`/`catalog_tab.dart`).

**`customer_360_screen.dart` étendu** :
- `Future.wait` étendu aux indices 10/11/12 (`customer_benefits`,
  signalements déposés, signalements reçus), sans renuméroter les 10
  précédents.
- `_noteAuthorNames` renommé `_staffNames` et fusionné avec les auteurs
  des avantages (`granted_by`) — une seule requête `profiles` batch
  pour les deux listes au lieu de deux requêtes séparées.
- En-tête : chip VIP (doré, `workspace_premium`) si `is_vip`, chip note
  moyenne (`★ x.x (n avis)`) si au moins un avis, et un `Switch` "Client
  VIP" pour basculer le statut.
- Section "Avantages accordés" : liste + champ d'ajout, même structure
  que les Notes internes.
- Section "Signalements liés au client" (affichée seulement si non
  vide) : les deux angles (déposés / reçus) listés séparément.
- `customer_management_real.dart` : icône couronne à côté du nom dans
  la liste des clients si `is_vip`, pour une visibilité immédiate sans
  ouvrir la fiche.

## CRM — Lot 4/5 : segmentation & marketing (02/08)

**SQL** : `supabase/phase63_patch_crm_lot4_segmentation.sql` :
- Vue `customer_segments` (customer_id, first_order_at, last_order_at,
  order_count, lifetime_value) — agrégat brut par client, commandes
  `annulee` exclues. Les segments (nouveau/récurrent/inactif/gros
  compte) ne sont volontairement PAS calculés en SQL : ils sont
  dérivés côté app à partir de ces chiffres, pour pouvoir ajuster les
  seuils (90 jours d'inactivité, seuil "gros compte") sans redéployer
  de script — même logique que l'heuristique devis/commande de la
  Phase 61.
- ⚠️ **Point de sécurité** : une vue Postgres classique n'hérite pas
  automatiquement des policies RLS de `orders`/`profiles` pour
  l'appelant (contrairement à `post_engagement_scores`, Phase 54, qui
  porte sur des données déjà publiques). La vue intègre donc un filtre
  explicite `and public.current_role_is_staff()` : elle renvoie 0 ligne
  pour un client, quels que soient les GRANTs.

**Nouvelle Edge Function** : `send-targeted-notification` — notification
push manuelle vers une liste de `customerIds` choisie par le staff
(ex : relancer tous les "inactifs"). Appelée directement par l'app
(pas par un trigger SQL), donc vérifie le JWT de l'appelant ET son
rôle staff (`admin`/`commercial`) via une requête `profiles` avec la
clé service_role — contrairement à `send-push-notification` qui ne
vérifie qu'un `x-webhook-secret` partagé. Les briques Firebase (échange
de token OAuth, envoi FCM) sont dupliquées depuis `send-push-notification`
(pas de dossier `_shared` entre Edge Functions dans ce projet, même
choix que pour `create-fiveonepay-payment-link`). Catégorie de son
réutilisée : `produit` (pas de catégorie "marketing" dédiée).

**`customer_management_real.dart` étendu** :
- Chargement parallèle de `profiles` + `customer_segments`
  (`Future.wait`), fusionné dans une map `customer_id -> agrégat`.
- `_activitySegment(id)` : nouveau (1 commande) / récurrent (2+) /
  inactif (dernière commande il y a plus de 90 jours) / `null` si
  aucune commande — mutuellement exclusif.
- `_isGrosCompte(id)` : `lifetime_value >= 1 000 000 Ar` (seuil fixe,
  posé comme hypothèse de départ faute de règle métier communiquée,
  ajustable sur demande).
- Deuxième ligne de `ChoiceChip`s (segment) sous celle du type de
  client, badges segment/gros compte affichés sous chaque ligne.
- Bouton icône "Notification ciblée" (`campaign_outlined`) dans
  l'AppBar : ouvre un dialogue titre + message, envoie à la liste
  actuellement filtrée (`_filtered`, donc combine type + segment) via
  `send-targeted-notification`.

## CRM — Lot 5/5 : tableau de bord analytique (02/08, dernier lot)

Dernier lot du chantier CRM (5/5) — entièrement dérivé de la vue
`customer_segments` (Phase 63, Lot 4) : **aucune nouvelle table/vue
SQL**, uniquement un nouvel écran Dart.

**Nouveau fichier** : `lib/presentation/customer_analytics/customer_analytics_dashboard.dart` :
- 3 cartes stats : clients actifs (commande passée, pas "inactif")
  sur total clients, taux de rétention, nombre de clients à risque.
- **Taux de rétention** = part des clients ayant commandé au moins
  deux fois parmi ceux ayant commandé au moins une fois — définition
  simple choisie faute de règle métier communiquée (pas de fenêtre
  mensuelle/cohortes, juste "recommande-t-il ou pas").
- **Top clients par valeur totale** : `customer_segments` trié par
  `lifetime_value` décroissant, top 10, nom résolu depuis `profiles`,
  tap -> `Customer360Screen`.
- **Clients à relancer en priorité** : clients "inactifs" (même seuil
  90 jours que le Lot 4) triés par valeur décroissante — priorise les
  plus gros comptes silencieux plutôt que l'ordre chronologique.

**Point d'entrée** : `more_menu_screen.dart` — nouvelle entrée
"Tableau de bord CRM" dans la section Gestion, juste après
"Messagerie".

Avec ce lot, le chantier CRM en 5 lots (Fiche 360°, Suivi commercial,
Fidélité & support, Segmentation & marketing, Analytique) est complet.

## Correctif : crash "Something went wrong" sur Achats Formation (02/08)

Le crash signalé sur l'onglet "Matières premières" de la fiche
Achats Formation (préexistant avant la fusion en hub) a été
diagnostiqué : les 36 demandes en attente n'ont AUCUNE donnée
manquante/orpheline côté base (vérifié via SQL — `amount`, `status`,
`requested_at`, `raw_material_id`, `customer_id` tous renseignés,
0 client/produit disparu). La cause est donc côté app, probablement
liée à un cas où PostgREST renvoie une relation embarquée "un seul"
(`profiles`, `raw_materials`, `formation_courses`) comme une **liste**
plutôt qu'un objet — un `as Map?` classique plante alors avec un
`TypeError` (une `List` n'est pas un sous-type de `Map?`) au lieu de
simplement donner `null`.

**Correctifs dans `formation_purchases_management.dart` et
`course_purchases_management.dart`** :
- Nouvelle méthode `_embedAsMap(dynamic value)` : accepte un objet OU
  une liste (prend le premier élément), utilisée partout à la place de
  `as Map?` pour les relations embarquées.
- `DateTime.parse(...)` remplacé par un `DateTime.tryParse(...) != null`
  avant affichage (une date malformée n'empêche plus le rendu).
- La construction de la liste des batches/demandes est maintenant
  entourée d'un `try/catch` au niveau de `build()` (erreur globale
  affichée en texte plutôt que crash) ET au niveau de chaque
  carte individuelle (`...batches.map((batch) { try {...} catch (e) {
  return Card(Text('Erreur d'affichage...: $e')); } })`) — une seule
  demande malformée n'empêche plus l'affichage des autres.
- Objectif secondaire : si le problème n'est pas entièrement résolu,
  le message d'erreur affiché à l'écran donnera enfin le détail exact
  de l'exception (au lieu de l'écran générique "Something went wrong"
  sans information), permettant un diagnostic précis au prochain test.

## Accueil client : barre de recherche + photos "Pour vous" (03/08)

**`catalog_tab.dart`** :
- Barre de recherche : le hint et l'icône héritaient de la couleur
  `textDisabledLight`/`textDisabledDark` du thème global (même couleur
  que les vrais widgets désactivés), d'où l'aspect "flou"/lavé. Fix :
  `hintStyle`/icône de la recherche fixés explicitement sur
  `theme.colorScheme.onSurfaceVariant` (muet mais lisible), sans
  toucher au thème global (qui reste correct pour les widgets
  réellement désactivés).
- Carrousel "Pour vous" : les cartes produit n'affichaient aucune
  photo (juste icône "Nouveau produit" + nom + prix). Ajout d'une
  vignette (`_productImage`, `enableHero: false` — un même produit
  peut déjà apparaître dans la grille principale avec le même Hero
  tag, réutiliser le tag ici casserait l'animation, voir le
  commentaire existant sur "Vous recommandez souvent").

**Point important sur "SLES" (prix à 0 Ar signalé par l'utilisateur,
qui affirme avoir bien saisi un prix)** : PAS un bug de sauvegarde.
`products` a deux colonnes prix distinctes, `price_detail` et
`price_gros` (`phase1_schema.sql:96-97`), avec deux champs côte à côte
dans le formulaire admin ("Prix Détail (Ar)" / "Prix Gros (Ar)",
`product_management_real.dart:488-503`). L'affichage client (carte
catalogue, "Pour vous") lit `price_detail`. Si seul "Prix Gros" a été
rempli, `price_detail` reste à son défaut (0), d'où le "0 Ar" côté
client malgré un prix réellement saisi quelque part. Pas de correctif
de code proposé pour l'instant — à confirmer avec l'utilisateur lequel
des deux champs il a rempli avant d'envisager un changement d'UX
(fusionner les deux champs ? rendre "Prix Détail" obligatoire ?).

## Commandes client — Lot 1/5 : fiche détail commande (03/08)

Premier lot du chantier "amélioration Commandes/Accueil client" (5
lots proposés, ordre validé par l'utilisateur) : jusqu'ici une
commande n'était pas cliquable dans `_OrdersList` (contrairement aux
devis, qui ouvrent déjà `QuoteThreadClient`).

**`orders_tab.dart`** — helpers remontés au niveau du fichier (pas
propres à `_OrdersListState`) pour être réutilisables par le nouvel
écran de détail sans dupliquer :
- `orderStatusLabels`/`orderStatusIcons`/`orderStatusStep` (avant :
  propres à `_OrdersListState`).
- `orderPaymentStatusLabels`/`orderPaymentStatusColor` (idem).
- Nouveau widget public `OrderProgressBar` : même barre à 4 étapes
  qu'avant, mais avec une icône par étape (reçu/prépa/expédition/
  livraison) au-dessus de la barre colorée, plutôt qu'un texte seul.
- La `Card` de chaque commande est maintenant enveloppée dans un
  `InkWell` (`onTap` -> `OrderDetailScreen`) ; les boutons internes
  (Facture PDF, Recommander, Suivre sur la carte) restent cliquables
  indépendamment (Flutter donne priorité au bouton sur l'InkWell
  englobant).

**Nouveau fichier** : `lib/presentation/client_home/order_detail_screen.dart`
— reçoit l'`order` déjà chargé (avec `order_items` imbriqués et
`delivery_address`, Phase 31) en paramètre, **aucune nouvelle
requête** : en-tête (numéro, total, date, mode/statut paiement),
`OrderProgressBar`, adresse de livraison (si renseignée), liste des
articles (nom, quantité × prix unitaire, sous-total), total, et les
mêmes actions que la liste (Facture PDF/Recommander/Suivre sur la
carte). `_downloadInvoice`/`_reorder` dupliqués depuis
`_OrdersListState` (mêmes signatures, adaptées à un widget sans
state) plutôt que partagés — cohérent avec le style du reste du code
(petite duplication acceptée plutôt qu'une abstraction pour ~30
lignes).

Import croisé `orders_tab.dart` <-> `order_detail_screen.dart` :
volontaire, Dart gère nativement les imports mutuels entre fichiers
d'un même package.

## Commandes/Accueil client — Lot 2/5 : recherche & filtres (03/08)

**`orders_tab.dart`** (`_OrdersListState`) :
- Filtres 100% côté app (`_filteredOrders` getter) — pas d'aller-retour
  serveur, le volume de commandes d'un client reste modeste.
- Filtre statut : `ChoiceChip`s (Tous/Reçue/En préparation/Expédiée/
  Livrée/Annulée).
- Filtre période : Toute période / 30 derniers jours / 90 derniers
  jours, basé sur `created_at`.
- Recherche par numéro de commande (`order_number`, insensible à la
  casse).
- État "Aucune commande ne correspond à ces filtres" distinct de
  "Aucune commande pour le moment" (liste vraiment vide) — évite de
  confondre les deux cas.

**`catalog_tab.dart`** — barre de recherche de l'accueil enrichie :
- Historique de recherche local (`SharedPreferences`, clé
  `recent_product_searches`, 6 entrées max, même mécanisme de cache
  déjà utilisé sur cet écran pour le catalogue hors-ligne) — affiché
  sous forme de `Chip`s quand le champ a le focus et est vide, avec un
  bouton "Effacer".
- Suggestions de noms de produits : filtrées localement depuis
  `_allProductsForReference` (déjà chargé en mémoire pour les puces de
  catégorie/le cache hors-ligne) — **aucune requête réseau
  supplémentaire**, juste un `.where(name.contains(query))`, top 5
  résultats.
- Un historique n'est enregistré qu'à la validation d'une recherche
  (`onSubmitted` ou tap sur une suggestion/un historique), pas à
  chaque frappe — évite de polluer l'historique avec des saisies
  incomplètes.
- Bouton "Effacer" (x) dans le champ une fois du texte saisi.

## Commandes client — Lot 3/5 : actions rapides (03/08)

**SQL** : `supabase/phase64_patch_client_order_cancel.sql` — nouvelle
policy `orders_update_own_cancel_if_recue` : jusqu'ici la seule policy
UPDATE sur `orders` était `orders_update_staff` (staff uniquement), un
client ne pouvait donc jamais annuler sa propre commande. Policy
étroite à dessein : `using (auth.uid() = customer_id and status =
'recue')` + `with check (... and status = 'annulee')` — un client ne
peut annuler que depuis "reçue" précisément, jamais se donner un autre
statut.

⚠️ **Limite assumée** : le staff n'est pas notifié automatiquement
quand un client annule sa propre commande (pas de trigger ajouté) —
à surveiller manuellement pour l'instant, ou à ajouter dans un lot
ultérieur si ça devient un problème en pratique.

**`chat_screen.dart`** : nouveau paramètre optionnel `initialMessage`
— pré-remplit `_textController` sans rien envoyer automatiquement (le
client garde la main). Pas de fonction repo dédiée pour
récupérer/créer la conversation du client (logique restée inline dans
`_init()`) — donc pas de moyen plus propre de passer un message
initial sans modifier ce widget directement.

**`order_detail_screen.dart`** — 2 nouvelles actions dans la rangée de
boutons :
- **"Contacter le support"** : ouvre `ChatScreen` avec un message
  pré-rempli citant le numéro de commande.
- **"Annuler la commande"** (visible seulement si `status == 'recue'`,
  en rouge) : confirmation puis `update({'status': 'annulee'})
  .eq('status', 'recue')` (double garde-fou : policy RLS + condition
  applicative) ; en cas de succès, ferme l'écran de détail — la liste
  se recharge au retour (voir `orders_tab.dart` ci-dessous).

**`orders_tab.dart`** :
- Le `onTap` d'une commande recharge désormais la liste au retour de
  `OrderDetailScreen` (`await Navigator.push(...); _loadOrders();`) —
  même principe déjà utilisé par `_QuotesList` pour ses devis.
- Bouton "Réessayer" ajouté sur l'état d'erreur réseau, pour Commandes
  ET Devis (jusqu'ici seul le pull-to-refresh existait, peu visible).

## Commandes/Accueil client — Lot 4/5 : accueil enrichi (03/08)

**`orders_tab.dart`** : `OrdersTab` accepte désormais un paramètre
optionnel `initialTabIndex` (défaut 0), passé au
`DefaultTabController(initialIndex: ...)` — permet d'ouvrir directement
l'onglet Devis depuis un lien externe (voir bannière ci-dessous) sans
que le client ait à cliquer une seconde fois.

**`catalog_tab.dart`** — deux nouvelles sections sur l'accueil,
alimentées par deux requêtes ajoutées au `Future.wait` existant de
`_loadData()` (silencieuses en cas d'erreur, comme le reste des blocs
de la page d'accueil) :

- **Bannière "en attente"** (juste après "Flash info", avant la barre
  de recherche) : remonte en haut de l'accueil la chose la plus urgente
  à traiter côté client — priorité à un **devis envoyé en attente de
  réponse** (`quotes` où `status = 'envoye'`), sinon un **paiement de
  commande en échec** (`orders` où `payment_status = 'echoue'`).
  Volontairement **exclu** `payment_status = 'en_attente'` : ce statut
  correspond en général à une vérification manuelle en cours côté
  staff, pas à une action requise du client — l'afficher aurait ajouté
  une fausse urgence. Tap → ouvre `OrdersTab` sur le bon onglet
  (Devis/Commandes) via un `Scaffold` local (pas de route nommée pour
  ce cas d'usage ponctuel).
- **"Nouveautés Formation"** (juste avant "Produits populaires"), un
  carrousel horizontal des 6 derniers cours `formation_courses` avec
  `status = 'deja_developpee'`, triés par date de création. C'est un
  **teaser vers l'onglet Académie existant** (`AkoraFormationScreen`,
  déjà dans la barre de navigation basse) — pas une nouvelle surface de
  navigation, juste de la découvrabilité croisée depuis l'accueil.
  Chaque carte pointe vers `AkoraFormationScreen(initialCategory:
  category)`, un paramètre de deep-link qui existait déjà. Pas de
  colonne prix dans `formation_courses` (schéma `phase43`), donc les
  cartes n'affichent que titre + catégorie.

⚠️ **Filtre rapide par pilier** (prévu dans la proposition initiale du
Lot 4) : jugé déjà couvert par la section existante "Nos activités"
(tap sur une icône de pilier → `_selectedUnitId` + rechargement du
catalogue filtré) — pas de nouvelle UI ajoutée pour éviter de dupliquer
une fonctionnalité qui existe déjà sous une autre forme.

## Commandes/Accueil client — Lot 5/5 : design & finitions (03/08)

Dernier lot du chantier "amélioration Commandes/Accueil client" (5
lots). Sur les 6 idées d'origine, 2 étaient déjà satisfaites avant même
de commencer ce lot : la pagination du carrousel de bannières
(`_bannerIndex` + points animés, catalog_tab.dart) et le skeleton
loading de l'accueil (`_CatalogSkeleton`/`_ShimmerBox`) existaient déjà
— seuls les 4 points suivants restaient à construire.

**`orders_tab.dart`** — regroupement par période sur Commandes ET
Devis : nouvelles fonctions top-level `periodGroupLabel(DateTime)`
("Aujourd'hui"/"Hier"/"Cette semaine"/"Ce mois-ci", sinon "Juillet
2026" etc.) et `groupRowsByPeriod(List<Map>)` qui aplatit une liste
déjà triée par `created_at` décroissant en une suite de `String`
(en-tête) / `Map` (élément) — permet de garder un simple
`ListView.builder` avec un `itemBuilder` qui distingue les deux types,
sans sous-widget de section dédié. `_OrdersListState` et
`_QuotesListState` appellent chacun `groupRowsByPeriod` sur leur liste
déjà filtrée/chargée (aucune requête supplémentaire).

**Skeleton loading Commandes/Devis** : `_ShimmerBox` (rectangle à
dégradé animé) et `_OrdersSkeleton` (3 cartes fantômes) ajoutés à
`orders_tab.dart`, dupliqués depuis le même principe que
`_CatalogSkeleton` côté accueil (`catalog_tab.dart`) plutôt que
partagés — ces classes sont privées à leur fichier respectif, pas de
fichier `widgets/` commun jusqu'ici pour ce genre d'aperçu. Remplace le
`CircularProgressIndicator` plein écran au premier chargement des deux
onglets.

**Badge stock bas (catalogue client)** : `_ProductCard`
(catalog_tab.dart) affiche désormais un badge rouge "Stock bas" (0 <
`stock_quantity` ≤ `low_stock_threshold`) ou "Rupture de stock"
(`stock_quantity` ≤ 0), empilé sous le tag de catégorie en haut à
gauche de la photo — même seuil que côté admin
(`alerts_center.dart`). **Purement informatif** : n'empêche pas
d'ajouter le produit au panier (pas de logique de blocage de commande
ajoutée — changement de comportement plus large, hors scope de ce
lot).

⚠️ **Harmonisation visuelle / dark mode** : revue des écrans
Commandes/Accueil modifiés dans les Lots 1 à 5 — aucune couleur codée
en dur problématique trouvée (les `Colors.white`/`Colors.black54`
existants sont toujours sur un fond dégradé ou une image, donc
indépendants du thème clair/sombre). Les quelques couleurs fixes
préexistantes hors de ce chantier (ex. `Colors.green`/`Colors.blue`
dans `orderPaymentStatusColor`, la teinte des icônes "Nos activités")
n'ont pas été retouchées : elles prédatent ces 5 lots et aucun problème
concret n'a été signalé sur elles.

## Nouveau menu client "Services" : demande de service (03/08)

Demande explicite de l'utilisateur ("ajouter une nouvelle menu :
services"), clarifiée par deux questions avant de coder : (1)
emplacement → **5ᵉ onglet** de la barre de navigation du bas côté
client (Accueil, Commandes, Académie, Services, Profil — le Panier n'a
toujours pas d'onglet dédié) ; (2) contenu → une **vraie demande de
service** (installation, intervention, consultation...) avec un
formulaire et un workflow de traitement côté Admin, pas juste une vue
des piliers existants.

**SQL** : `supabase/phase65_patch_service_requests.sql` — nouvelle
table `service_requests` (customer_id, business_unit_id optionnel,
title, description, preferred_date, address, status
`nouvelle/en_cours/traitee/refusee`, staff_notes, created_at,
updated_at). RLS : le client peut créer et lire ses propres demandes,
mais **ne peut pas les modifier après envoi** (pas de bouton
"annuler", contrairement aux commandes — premier lot volontairement
minimal) ; seul le staff met à jour statut/notes. Trigger
`on_new_service_request_push` réutilise `notify_push_on_new_message`
(Phase 17).

**Edge Function** : nouveau cas `service_requests` dans
`send-push-notification/index.ts` — notifie Admin/Commercial avec le
nom du pilier + l'objet de la demande, même modèle que `post_reports`.

**Nouveaux fichiers Dart** :
- `core/services/service_request_repo.dart` — `fetchMine()`,
  `submit({businessUnitId, title, description, preferredDate,
  address})`.
- `presentation/client_home/service_requests_tab.dart` — liste des
  demandes du client (statut coloré, note staff si présente) + feuille
  modale "Nouvelle demande" (dropdown pilier actif, titre, description,
  adresse optionnelle, date souhaitée optionnelle via `showDatePicker`).
  Exporte `serviceRequestStatusLabels`/`serviceRequestStatusColor`,
  réutilisés côté Admin.
- `presentation/service_requests_management/service_requests_management.dart`
  — liste Admin filtrable par statut, actions "Prendre en charge" /
  "Marquer traitée" / "Refuser" selon l'état courant, + note interne
  éditable (dialog) transmise au client. Entrée ajoutée dans le menu
  "Plus" de l'Admin.

**Défense embeds PostgREST** : les deux écrans (client et Admin)
utilisent un helper `_embedAsMap()` sur les relations `business_units`/
`profiles` — même précaution que le fix Achats Formation (un embed à-un
peut parfois revenir en `List` plutôt qu'en `Map`), appliquée dès la
construction cette fois plutôt qu'en correctif après coup.

**`client_home.dart`** : nouvel index de page 5, nouvelle entrée dans
`_ClientBottomNav` (icône `miscellaneous_services_outlined`), nouvelle
clé de traduction `nav_services` (fr: "Services", mg: "Serivisy").

## Crash "Something went wrong" sur l'onglet Commandes client (03/08)

Signalé par l'utilisateur (capture) juste après avoir testé le menu
Services — probablement la première ouverture de l'onglet Commandes
depuis les Lots 1 à 5 (fiche détail, filtres, actions rapides, accueil
enrichi, regroupement par période). Root cause exacte non confirmée
(pas d'accès direct aux logs de l'appareil) — deux casts directs
repérés comme suspects dans `orders_tab.dart` :
`(order['payment_status'] ?? 'en_attente') as String` et
`PaymentMethodX.fromId(order['payment_method'] as String?)`, plus
`groupRowsByPeriod`/`periodGroupLabel` (Lot 5, jamais exercés en
production avant cette capture).

**Fix défensif** (même pattern que le crash Achats Formation,
02-03/08) dans `_OrdersListState.build()` et `_QuotesListState.build()` :
le calcul `groupRowsByPeriod(...)` est maintenant dans un try/catch
(erreur affichée en texte simple au lieu de l'écran générique), et la
construction de chaque `Card` de commande/devis dans `itemBuilder` est
elle-même isolée par un try/catch (une commande malformée affiche
"Erreur d'affichage sur une commande : $e" au lieu de faire planter
tout l'onglet). Objectif double : ne plus perdre tout l'écran pour une
seule ligne à problème, ET faire apparaître le vrai message
d'exception si le problème se reproduit, pour un diagnostic précis
(le `CustomErrorWidget` global de l'app ne donne aucun détail).

⚠️ **Pas encore confirmé résolu** — demander à l'utilisateur de
retester l'onglet Commandes et, si un message d'erreur détaillé
apparaît au lieu de "Something went wrong", de le partager pour cibler
le vrai correctif.

## Vraie cause des crashs "Something went wrong" (Commandes, puis Services) (03/08)

Le fix défensif ci-dessus n'a pas suffi : le même crash générique est
réapparu sur l'onglet **Services**, un écran neuf (`service_requests_tab.dart`)
qui n'a rien de commun avec `orders_tab.dart` niveau code — signe que la
cause n'était pas les casts suspectés, mais quelque chose de partagé par
les deux écrans.

Point commun trouvé : les deux utilisent `DateFormat(pattern, 'fr_FR')`
(package `intl`) pour afficher une date, et **`initializeDateFormatting`
n'était appelé nulle part dans l'app** (vérifié par recherche globale).
Sans cet appel, `intl` ne connaît que les données de la locale par défaut
(`en_US`) ; construire un `DateFormat('...', 'fr_FR')` ne plante pas (le
package accepte silencieusement une locale inconnue à la construction),
mais **`.format(date)` lève une `LocaleDataException`** dès que le motif a
besoin d'un nom de mois/jour localisé (`MMM`, `MMMM`...) et qu'il y a une
vraie date à formater. D'où le symptôme observé : ça ne plante jamais sur
un état vide, seulement une fois qu'il existe au moins une ligne réelle à
afficher (une commande sur plusieurs mois pour `groupRowsByPeriod`
côté Commandes, une demande de service existante côté Services) — cohérent
avec "jamais exercé en production avant cette capture" noté plus haut.

**Correctif dans `main.dart`** : import de
`package:intl/date_symbol_data_local.dart` + `await
initializeDateFormatting('fr_FR')` juste après
`WidgetsFlutterBinding.ensureInitialized()`, avant tout le reste. Une
quinzaine d'écrans utilisent `DateFormat(..., 'fr_FR')` (Commandes,
Services, Achats Formation/Matières, CRM Fiche 360°/Analytique,
Signalements, Mes accès, Groupes Formation...) — un seul point
d'initialisation global les couvre tous, pas de correctif par écran
nécessaire.

⚠️ **À reconfirmer** — demander à l'utilisateur de retester Commandes ET
Services après ce build.

## Bulle de chat flottante (03/08)

Demande explicite de l'utilisateur (capture d'une bulle façon "chat
head" Messenger dans une autre app), clarifiée par deux questions avant
de coder : emplacement → **toutes les pages de l'espace client** (pas
juste l'accueil) ; action au tap → **ouvrir le chat support existant**
(`ChatScreen`, déjà utilisé ailleurs — conversation unique client ↔
équipe).

**`core/chat/unread_support_messages.dart`** (nouveau) :
`fetchUnreadSupportMessagesCount()` — extrait de la fonction
`loadUnreadCount()` qui existait déjà en local dans `catalog_tab.dart`
(badge de l'accueil), pour que la bulle flottante puisse réutiliser
exactement la même requête sans dupliquer la logique.
`catalog_tab.dart` a été mis à jour pour appeler cette fonction
partagée à la place de sa version locale.

**`presentation/client_home/floating_chat_bubble.dart`** (nouveau) :
`FloatingChatBubble` enveloppe tout `ClientHome` dans un `Stack` —
visible sur les 5 onglets puisqu'elle vit au-dessus du `Scaffold`
plutôt que dans chaque page, donc pas besoin de la répéter par écran.
Bulle circulaire draggable (`GestureDetector.onPanUpdate`, position
bornée à l'écran via `clamp`), badge de messages non lus rafraîchi par
polling toutes les 25s (même principe que le badge existant de
l'accueil — pas de flux temps réel dédié, pas nécessaire pour une
pastille). Tap → ouvre `ChatScreen`, rafraîchit le badge au retour.
Disparaît naturellement dès qu'un écran est poussé par-dessus (fiche
détail, chat lui-même...) puisque `Navigator.push` remplace tout
l'écran — aucune logique de masquage à gérer.

Volontairement **redondante** avec l'icône messagerie déjà présente
dans l'en-tête de l'Accueil : celle-ci reste inchangée, la bulle est un
raccourci supplémentaire visible même en dehors de l'Accueil (Commandes,
Académie, Services, Profil).

**`client_home.dart`** : le `Scaffold` retourné par `_ClientHomeState.build()`
est maintenant enveloppé dans `FloatingChatBubble(child: ...)`.

## Catalogue de services (Lot post-menu Services, 03/08)

Après le lancement du menu "Services" (phase65), l'utilisateur a fourni
une vision détaillée de son offre (7 catégories, 35 services précis) et
veut pouvoir l'activer/désactiver progressivement depuis l'admin,
plusieurs services de la liste n'étant pas encore réellement proposés.
Deux décisions produit validées avec l'utilisateur (recommandation
suivie telle quelle, l'utilisateur ayant délégué le choix) :
- Un service **désactivé est masqué complètement** côté client — même
  logique que `active` sur `business_units`/`categories`.
- Choisir un service dans le catalogue **remplace** l'ancien menu
  déroulant "Pilier concerné" (chaque service est déjà rattaché à une
  catégorie en interne, pas besoin de redemander un pilier séparément).

**`supabase/phase66_patch_service_catalog.sql`** : deux nouvelles
tables `service_categories` (nom, ordre) et `service_catalog_items`
(catégorie, nom, description, **`available` boolean, défaut `false`**).
RLS : catégories visibles de tous, services visibles seulement si
`available = true` OU staff (pour que l'admin voie aussi les inactifs à
activer) ; écriture réservée au staff (`current_role_is_staff()`,
même fonction que partout ailleurs). `service_requests` gagne une
colonne `service_catalog_item_id` (nullable — `business_unit_id` reste
en base pour les anciennes demandes déjà envoyées avant ce lot).
Seed : les 7 catégories et 35 services fournis par l'utilisateur,
**tous `available = false` au départ** — à l'admin d'activer ceux
réellement disponibles aujourd'hui depuis le nouvel écran.

**`core/services/service_catalog_repo.dart`** (nouveau) :
`fetchCategoriesWithItems({onlyAvailable})` renvoie les catégories avec
leurs services imbriqués (`items`), filtre les indisponibles et retire
les catégories devenues vides quand `onlyAvailable: true` (client) ;
`onlyAvailable: false` (admin) renvoie tout. CRUD catégories/services +
`setAvailable` pour le toggle.

**`core/services/service_request_repo.dart`** : `submit()` prend
maintenant `serviceCatalogItemId` (plus `businessUnitId`) ; `title`
est renseigné automatiquement avec le nom du service choisi (le champ
"Objet de la demande" en texte libre a disparu du formulaire — un
service précis en tient lieu). `fetchMine()` embarque
`service_catalog_items(name, service_categories(name))`.

**`presentation/client_home/service_requests_tab.dart`** : le
formulaire "Nouvelle demande" devient Catégorie → Service (deux
`DropdownButtonFormField` en cascade, le second reconstruit via une
`ValueKey(categoryId)` pour éviter une valeur sélectionnée qui
n'existe plus dans la nouvelle liste) + Description/Adresse/Date
inchangés. L'affichage de chaque demande récupère la catégorie via le
service catalogué si présent, sinon retombe sur `business_units`
(anciennes demandes pré-catalogue).

**`presentation/service_catalog_management/service_catalog_management.dart`**
(nouveau, entrée "Catalogue de services" dans le menu Plus admin, juste
après "Demandes de service") : catégories en `ExpansionTile`, chaque
service avec un `Switch` (disponible/non) + éditer/supprimer ; ajout de
catégorie (FAB) et de service (bouton dans chaque catégorie dépliée).
Même pattern que `category_management.dart` (catégories produit).

`presentation/service_requests_management/service_requests_management.dart`
(vue staff des demandes) mis à jour pour afficher la catégorie via le
service catalogué en priorité, avec repli sur `business_units` pour
compatibilité avec les demandes envoyées avant ce lot.

## Barre de raccourcis Profil + Programme de parrainage (03/08)

Suite à la vision "barre de menu dans le profil" proposée par l'utilisateur :
décision validée après échange — **seules 4 actions "utilitaires"**
(pas du contenu à parcourir) rejoignent une barre de raccourcis en haut
du profil, le reste (Mes achats, Communauté & Formation) reste en
cards en dessous, juste débarrassé des entrées désormais dupliquées.

**`profile_tab.dart`** : nouvelle `_buildShortcutsBar()` — 4 icônes
(Paramètres, Parrainage, Assistance, Scanner un produit) insérée juste
sous les boutons Modifier le profil/Partager/Personnaliser, avant la
barre "Profil complété à X%". Volontairement limitée à 4 pour rester
lisible d'un coup d'œil (au-delà, une rangée d'icônes perd son intérêt
de raccourci rapide). "Scanner un produit" retiré de la card "Mes
achats", "Assistance" et "Paramètres" retirés de leurs cards dédiées en
bas de page pour ne pas les dupliquer.

**Programme de parrainage** (nouveau, un des 4 raccourcis) — décision
utilisateur explicite : **pas de récompense automatique** pour l'instant,
juste un suivi parrain/filleul, le staff décide manuellement quoi
offrir en dehors de l'app.

**`supabase/phase67_patch_referral_program.sql`** : `profiles` gagne
`referral_code` (unique, généré automatiquement par trigger
`before insert` — couvre aussi bien les inscriptions via
`handle_new_user` que tout futur insert direct) et `referred_by`
(uuid, nullable, FK vers profiles). Fonction `resolve_referral_code(code)`
— `security definer`, callable en `anon` (avant toute session, à
l'inscription) — ne renvoie qu'un id, jamais d'autres colonnes. La vue
`public_profiles` (Phase 9/47/52, déjà utilisée pour le nom/avatar des
autres clients côté Communauté) gagne `referred_by`/`created_at` pour
que l'écran Parrainage liste les filleuls sans nouvelle policy RLS sur
la table de base.

**`core/services/referral_repo.dart`** (nouveau) : `fetchMyCode()`,
`fetchMyReferrals()` (via `public_profiles`, filtré `referred_by = moi`),
`resolveCode(code)` (RPC, utilisé à l'inscription).

**`presentation/client_home/referral_screen.dart`** (nouveau) : code
personnel affiché en gros + copier/partager (`SharePlus`, même pattern
que la carte de contact), liste des filleuls avec date d'inscription.

**`registration_screen.dart`** : champ "Code de parrainage (optionnel)"
ajouté en étape 2 (juste avant les conditions d'utilisation). À la
soumission, résolution du code via `ReferralRepo.resolveCode()` **avant**
`signUp()` — un code saisi mais invalide bloque l'inscription (erreur
affichée) plutôt que d'être ignoré silencieusement ; `referred_by`
rejoint `pendingProfileUpdate`, déjà appliqué génériquement après
confirmation email par `email_otp_verification_screen.dart` (aucune
modif nécessaire sur cet écran).

⚠️ Migration `phase67_patch_referral_program.sql` à exécuter dans
Supabase avant de tester le raccourci Parrainage.

## Crash "Something went wrong" sur le Tableau de bord CRM (03/08)

Signalé par l'utilisateur (capture), avec la demande explicite de
vérifier le code plus largement avant le prochain test plutôt que de
corriger réactivement écran par écran.

**Cause probable** : `customer_segments` (Phase 63) expose `order_count`
via `count(o.id) filter (...)` — un agrégat Postgres dont le type
sérialisé par PostgREST peut ne pas être un JSON number selon le
contexte, alors que `customer_analytics_dashboard.dart` le castait en
dur (`as num?`) plutôt que de le convertir, plantant l'écran entier au
tout premier calcul de `build()` (avant même l'affichage du
`Scaffold`/`AppBar` — cohérent avec la capture, aucun titre visible).
Un second point trouvé en relisant le fichier : `DateTime.parse(...)`
(non défensif) sur `last_order_at` à l'affichage d'un client à risque.

**Correctifs** (`customer_analytics_dashboard.dart` ET
`customer_management_real.dart`, qui consomment la même vue avec le
même risque) :
- Nouveau helper `_asNum(dynamic)` : accepte un `num` OU une `String`
  numérique, converti via `num.tryParse`, à la place de tout `as num?`
  sur les champs venant de `customer_segments`.
- `DateTime.parse` remplacé par `DateTime.tryParse` partout sur
  `last_order_at`.
- `customer_analytics_dashboard.dart` : calcul des listes dérivées
  (`withOrders`/`atRisk`/`topClients`...) entouré d'un `try/catch` au
  niveau de `build()` (message d'erreur affiché plutôt que crash), et
  chaque ligne de la liste "Top clients"/"Clients à risque" isolée par
  son propre `try/catch` (une ligne malformée n'empêche plus l'affichage
  des autres) — même pattern que les fix Commandes/Achats Formation.

Vérifié par la même occasion : la vue `post_engagement_scores` (fil
Tendances, Phase 54) n'expose qu'un `score` agrégé utilisé uniquement
côté serveur (`.gt()`/`.order()`), jamais casté côté Dart — pas de
risque similaire à corriger là.

## Badge de messages non lus sur la barre de raccourcis Profil (03/08)

Suite à une capture de la barre d'icônes Facebook (badges rouges sur
Messenger/notifications), l'utilisateur a demandé comment améliorer la
barre de raccourcis du Profil dans le même esprit. Décision : un seul
badge, sur **Assistance** (messages support non lus) — la seule icône
avec une vraie "file d'attente" ; Paramètres/Parrainage/Scanner sont des
actions ponctuelles, pas de badge pertinent à leur mettre (même logique
que Facebook, qui ne badge pas Marketplace).

**`profile_tab.dart`** : `_buildShortcutsBar()` réutilise
`fetchUnreadSupportMessagesCount()` (`core/chat/unread_support_messages.dart`,
même source que la bulle de chat flottante — pas de requête dupliquée),
chargé au `initState()` et rafraîchi au retour de l'écran Assistance
(`.then(...)` sur le `Navigator.push`). Chaque raccourci est maintenant
un tuple `(icône, libellé, compteur de badge, action)` — un badge rouge
façon Facebook (cercle avec bordure couleur fond, "9+" au-delà de 9)
s'affiche uniquement si le compteur est > 0.

## Activer/désactiver la bulle de chat flottante (admin + client) (03/08)

Demande utilisateur : pouvoir couper la bulle de chat flottante des
deux côtés, chacun indépendamment ("les deux côtés peuvent choisir ce
qu'ils veulent").

**`supabase/phase68_patch_chat_bubble_toggle.sql`** :
- `company_settings.floating_chat_bubble_enabled` (colonne à part de
  `data` jsonb — volontairement, pour ne pas risquer d'être écrasée par
  le prochain enregistrement du formulaire "Profil entreprise" qui ne
  réécrit que `id`/`data`) : réglage **global admin**, coupe la bulle
  pour tous les clients.
- `profiles.hide_chat_bubble` : réglage **personnel client**, cache la
  bulle juste pour lui.
- Vue `app_feature_flags` (même principe que `public_profiles`) expose
  uniquement le booléen global aux clients — `company_settings` reste
  par ailleurs réservé au staff en lecture (Phase 4).

**`core/chat/chat_bubble_settings_repo.dart`** (nouveau) :
`isEnabledGlobally`/`setEnabledGlobally` (via la vue + upsert sur
`company_settings`), `isHiddenByClient`/`setHiddenByClient` (sur son
propre profil).

**`floating_chat_bubble.dart`** : charge les deux réglages au
`initState()`, ne s'affiche que si global ET pas masqué par le client
(`_visible = enabledGlobally && !hiddenByClient`) ; si masquée,
`build()` renvoie directement `widget.child` sans le `Stack`.

**`business_profile_settings.dart`** (admin) : nouveau `SwitchListTile`
"Bulle de chat flottante" après la section Contact — écriture
immédiate au changement, indépendante du bouton "Enregistrer" du
formulaire.

**`settings_screen.dart`** (Paramètres, partagé client/admin) :
nouveau `_ChatBubbleVisibilityTile` (widget à état dédié) juste après
"Mode sombre" — personnel, écriture immédiate. Reste affiché côté admin
aussi (l'écran est documenté comme générique/non lié au rôle) mais sans
effet visible puisque la bulle n'existe que côté client.

## Distribution gratuite en attendant Play Store : Firebase App Distribution (04/08)

Suite à la question de l'utilisateur sur les plateformes gratuites pour
publier en attendant le budget Google Play (25$) : mise en place de
**Firebase App Distribution** comme canal de bêta-test, en plus des
Releases GitHub existantes — avantage : les testeurs reçoivent un email
+ une notification à chaque nouvelle version, sans avoir à connaître le
lien GitHub à chaque fois.

**`build-apk.yml`** : nouvelle étape "Publier sur Firebase App
Distribution" (action `wzieba/Firebase-Distribution-Github-Action@v1`)
après la compilation de l'APK, purement optionnelle — ne s'exécute que
si le secret `FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT` est configuré
(même logique conditionnelle que `google-services.json`/keystore).
L'ID d'app Firebase est extrait automatiquement de
`google-services.json` (`jq '.client[0].client_info.mobilesdk_app_id'`)
via une nouvelle étape dédiée — pas de secret supplémentaire à saisir
pour ça.

**Mise en place (compte de service dédié, projet Firebase
`akorahub-7ee66`)** — guidée pas à pas avec l'utilisateur :
1. Compte de service créé dans Google Cloud Console IAM
   (`github-actions-distribution@akorahub-7ee66.iam.gserviceaccount.com`)
2. Rôle **Firebase App Distribution Admin** attribué — a nécessité
   d'activer l'API Firebase App Distribution au préalable (le rôle
   n'apparaît pas dans le sélecteur tant que l'API n'est pas activée
   sur le projet — piège rencontré en direct).
3. Clé JSON générée pour ce compte de service, collée dans le secret
   GitHub `FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT`.
4. Groupe de testeurs `testeurs` créé dans Firebase Console → App
   Distribution → Testeurs et groupes, nom renseigné dans le secret
   optionnel `FIREBASE_APP_DISTRIBUTION_GROUPS`.

**Note technique (piège rencontré)** : `secrets.*` référencé
directement dans un `if:` de step fonctionne bien pour les runs
déclenchés par un `push`, mais fait échouer la validation d'un
déclenchement manuel via l'API `workflow_dispatch`
(`Unrecognized named-value: 'secrets'`) — limitation connue de GitHub
Actions (validation stricte au moment du dispatch manuel, contexte
`secrets` non résolu à ce stade). Sans impact sur l'usage réel du
déclenchement automatique à chaque push sur `main`.

## Vérification de mise à jour in-app (04/08)

Demande explicite de l'utilisateur : proposer une mise à jour depuis
l'app elle-même, côté client ET admin, en attendant la publication sur
le Play Store (pas de mécanisme de mise à jour automatique natif tant
qu'on distribue par GitHub Releases/Firebase App Distribution).

**SQL (`phase70_patch_app_latest_version.sql`)** : table
`app_latest_version`, une seule ligne (id=1) contenant
`version_name`/`build_number`/`download_url`/`release_notes`. Lecture
ouverte à tous (y compris avant connexion), aucune policy d'écriture —
seule l'Edge Function (clé service role) la met à jour.

**Edge Function `update-latest-version`** : appelée par la CI après
chaque build réussi, protégée par un secret partagé
`UPDATE_VERSION_WEBHOOK_SECRET` (même pattern que les autres webhooks
de ce projet — header `x-webhook-secret`). À configurer à la fois côté
Supabase (secrets Edge Functions) et côté GitHub Actions (secrets du
dépôt) avec la même valeur.

**`build-apk.yml`** : nouvelle étape "Notifier Supabase de la nouvelle
version disponible" — extrait `version_name`/`build_number` de
`pubspec.yaml`, appelle l'Edge Function avec le lien vers la Release
GitHub du build (`releases/tag/build-<run_number>`). Volontairement
sans `if:` sur un secret (voir plus haut, ce jour même : `secrets.*`
n'est pas lisible dans un `if:` d'étape) — `curl -f` échoue simplement
si le secret est absent, capté par un `||` sans casser le build.

**Client (`core/updates/update_checker.dart`)** : au démarrage,
compare `PackageInfo.buildNumber` (package `package_info_plus`,
ajouté) au `build_number` enregistré ; si plus récent, affiche un
dialogue "Mise à jour disponible" avec un bouton qui ouvre le lien de
téléchargement (page de la Release GitHub pour l'instant, remplaçable
par un lien Play Store plus tard sans changer le mécanisme). Appelé
depuis `main.dart` sans `await` (comme les notifications push) pour ne
jamais retarder le premier écran ; utilise le `navigatorKey` global
(`GlobalAuthListener`) pour afficher le dialogue quel que soit l'écran
affiché, donc fonctionne à l'identique côté client et admin sans
câblage séparé dans chaque écran d'accueil.

## Réponse du support Papi.mg — versement automatique et retraits (04/08)

Suite à la question envoyée le 30/07 sur le versement des fonds collectés
via Papi (Mvola/Orange Money/Airtel Money), réponse du support
(support@papi.mg, 04/08) :

1. **Seuil de versement automatique** : le versement est automatique,
   gratuit et sans frais de retrait à partir de **2 000 000 MGA**
   (2 millions d'ariary) collectés. En dessous de ce seuil, le versement
   se fait **sur demande** et des frais de retrait s'appliquent selon le
   compte de réception. Détail des frais dans les Conditions
   d'utilisation Papi (en cours de réévaluation à la baisse, "d'ici
   quelques semaines" au 04/08).
2. **Process actuel des demandes de retrait** : par email uniquement.
   Papi prévoit de déployer cette fonctionnalité directement sur leur
   plateforme "d'ici fin août" (2026) — pas d'action côté AkoraHub en
   attendant, juste à garder en tête que la demande manuelle par email
   restera nécessaire jusque-là.
3. Détail des frais également accessible depuis Conditions d'utilisation
   > Méthode de règlement (profil du compte marchand Papi).

Complète la section "Grille tarifaire Papi" du 31/07 (recherche
"Grille tarifaire Papi" plus haut dans ce document) — aucun changement
de code nécessaire, information à usage de suivi/négociation côté
gestion du compte marchand Papi.

## Onglet Catalogue dédié + Commandes déplacé dans l'en-tête (04/08)

Demande explicite de l'utilisateur : un onglet séparé pour parcourir le
catalogue produit (au lieu qu'il ne vive que noyé dans l'Accueil), sans
pour autant dépasser 5 destinations dans la barre du bas (déjà pleine).
Solution retenue après discussion : Commandes quitte la barre du bas
pour une icône dans l'en-tête d'Accueil (comme Panier/Messagerie/
Notifications), ce qui libère une place pour le nouvel onglet Catalogue.

**Nouvelle barre du bas (5 onglets)** : Accueil, **Catalogue**, Académie,
Services, Profil. Commandes et Panier sont désormais tous les deux des
icônes dans l'en-tête d'Accueil (`catalog_tab.dart`), ouverts en `push`
(`Navigator.push(OrdersTab())`) — même mécanisme que Messagerie.

**`lib/presentation/client_home/product_catalog_tab.dart`** (nouveau) :
contient tout ce qui a été extrait d'Accueil — barre de recherche +
historique/suggestions, filtre par activité (piliers colorés), puces de
catégorie, abonnement aux nouveautés d'une catégorie, grille produits en
**2 colonnes** avec pagination infinie (20 par page), cache hors-ligne du
catalogue complet. Réutilise `ProductCard` (rendu public dans
`catalog_tab.dart`, était `_ProductCard`) pour ne pas dupliquer la fiche
produit — seule cette classe est partagée entre les deux fichiers, le
reste de la logique de filtrage/pagination est un code propre à ce
nouvel onglet (a nécessité de dupliquer certains petits helpers comme
`_iconForUnit`/`_iconForCategory`, trop couplés à l'état local pour être
extraits sans plus de cérémonie).

**`catalog_tab.dart` (Accueil) simplifié** : ne garde plus que les
raccourcis — en-tête (avatar/salutation/localisation + icônes Panier/
Commandes/Messagerie/Notifications), flash info, raccourci "en attente"
(devis/paiement), bannières, "Vous recommandez souvent", "Pour vous",
"Nouveautés Formation", et un bouton "Voir tout le catalogue" en bas qui
bascule vers le nouvel onglet (`widget.onOpenCatalog`, comme
`onOpenCart`/`onOpenProfile`). Le bloc "Nos activités" (piliers colorés)
et le chargement du catalogue complet (`_loadData` ne fetch plus
`business_units`/`products`) ont été retirés d'Accueil : ils vivent
maintenant exclusivement dans l'onglet Catalogue, pour éviter de
dupliquer deux fois la même UI de filtrage.

**Piège corrigé au passage** : deux points d'entrée vers `OrdersTab`
(le raccourci "en attente" d'Accueil et "Commandes" dans les stats du
Profil) l'enveloppaient dans un second `Scaffold(appBar: AppBar(...))`
alors qu'`OrdersTab` a déjà sa propre AppBar — corrigé pour éviter un
double bandeau visuel (probablement jamais remarqué parce que discret,
mais réel).

**`client_home.dart`** : nouveaux index (0 Accueil, 1 Catalogue,
2 Académie, 3 Services, 4 Profil, 5 Panier masqué) — Panier et Commandes
n'ont plus d'entrée dans `_ClientBottomNav`.

## Texte d'onboarding corrigé — AkoraHub n'est pas un SaaS multi-commerces (04/08)

En discutant du remplacement des icônes de l'onboarding par de vraies
photos, l'utilisateur a rappelé un point de fond mal reflété par
l'ancien texte : **AkoraHub est l'app dédiée d'Akora Fanadiovana**,
pas une plateforme où n'importe qui crée sa propre entreprise/catalogue
("Personne ne peut pas créer son page dedans"). L'ancien texte
("Créez Votre Profil d'Entreprise", "Gérez Votre Catalogue Produits",
"Développez Votre Activité"...) donnait l'impression trompeuse d'un
onboarding façon SaaS multi-commerces (comme Shopify), alors qu'un
nouvel utilisateur — client ou staff — arrive dans l'app d'une seule
entreprise déjà existante.

**`onboarding_flow.dart`** : les 5 titres/descriptions ont été réécrits
en neutre, décrivant ce qu'AkoraHub fait réellement (parcourir le
catalogue, échanger avec l'équipe/la communauté, suivre ses commandes,
accéder à l'Académie) plutôt que ce qu'un propriétaire d'entreprise
configurerait lui-même. **Les icônes n'ont volontairement pas été
touchées** (demande explicite : changer le texte, pas l'icône) — la
question des vraies photos reste ouverte, en attente que l'utilisateur
fournisse des photos réelles de sa boutique/ses produits/son équipe
(pistes proposées : boutique, étagère de produits, échange client,
suivi de commande, formation — voir la proposition d'illustrations
générée ce même jour, non retenue, dans le chat).

## Flash info : disparaît une fois lue par le client (04/08)

Constat de l'utilisateur (capture de l'Accueil) : le bandeau flash info
("Tongasoa daholo ô!") restait affiché indéfiniment tant que l'Admin ne
le désactivait pas manuellement, sans mémoire côté client. Demande :
une fois qu'un client a consulté l'annonce (tap sur le bandeau, qui
ouvre `FlashInfosScreen`), elle ne doit plus réapparaître sur son
Accueil.

**`catalog_tab.dart`** : `loadFlashInfo()` récupère maintenant `id` en
plus de `message` (au lieu du seul texte) — l'id sert de repère stable
pour la mémorisation, indépendant du contenu (deux annonces différentes
pourraient techniquement avoir le même texte). Au chargement,
comparaison avec l'id mémorisé localement
(`SharedPreferences`, clé `dismissed_flash_info_id`, chargé en
parallèle des autres données via `loadDismissedFlashInfoId()`) : si ça
correspond, le bandeau reste caché. Au tap sur le bandeau
(`_dismissFlashInfo()`) : masquage immédiat (`setState`) + écriture de
l'id en local, avant la navigation vers `FlashInfosScreen`.

Pas de nouvelle colonne SQL nécessaire (`flash_infos` a déjà `id`) : la
mémorisation "lu/pas lu" est volontairement locale à l'appareil (pas de
table de lecture par utilisateur) — suffisant ici puisqu'il n'y a
qu'une seule annonce active à la fois (voir `phase26_patch_flash_infos.sql`).
Une nouvelle annonce publiée par l'Admin (nouvel id) réapparaît
normalement pour tout le monde, y compris ceux qui avaient lu la
précédente.

## Indicateur "en train d'écrire" (05/08)

Demande explicite de l'utilisateur, pour les deux messageries de
l'app : la privée entre amis (`friend_chat_screen.dart`) et
client/staff (`chat_screen.dart`).

**`lib/core/chat/typing_presence.dart`** (nouveau) : classe
`TypingPresence`, partagée entre les deux écrans. Basée sur le
**Broadcast** de Supabase Realtime — canal éphémère (pas une table SQL,
rien n'est stocké) : `notifyTyping()` diffuse un événement `typing`
throttlé (max 1 toutes les 300 ms tant qu'on tape en continu, pas un
debounce classique — sinon l'indicateur mettrait du retard à
apparaître chez le destinataire). Pas de message explicite "j'ai
arrêté d'écrire" (peu fiable si l'app passe en arrière-plan) : le
destinataire considère simplement que l'autre a arrêté si aucun nouvel
événement n'arrive pendant 3s (`_remoteExpiry`). Le topic du canal doit
être identique des deux côtés d'une conversation :
- `friend_chat_screen.dart` : paire d'ids (le mien + celui de l'ami)
  **triée** — `typing:friend:{id1}_{id2}` — pour aboutir au même canal
  quel que soit celui qui ouvre la conversation en premier.
- `chat_screen.dart` : id de la conversation (déjà stable) —
  `typing:conversation:{conversationId}`.

**`lib/core/chat/typing_dots.dart`** (nouveau) : widget `TypingDots`,
3 points qui pulsent en boucle (`AnimationController` répété, déphasage
d'un tiers de cycle par point) — réutilisé tel quel dans les deux
écrans, affiché dans une bulle alignée à gauche juste au-dessus du
champ de saisie quand `_remoteIsTyping == true`.

**Limite connue, assumée** : côté `chat_screen.dart`, seul le client
diffuse (`_textController` a un listener qui appelle `notifyTyping()`).
L'écran Admin correspondant (`lib/presentation/messaging_center/`) est
encore 100% mock (voir en-tête de `chat_screen.dart`) — tant qu'il
n'est pas branché sur ce même schéma de conversations, personne
n'enverra jamais l'événement "staff en train d'écrire", donc le client
ne verra jamais la bulle apparaître de son côté. Le code est prêt et
fonctionnera automatiquement dès que l'Admin sera branché, sans rien
changer côté client. Pour `friend_chat_screen.dart` en revanche, les
deux côtés sont déjà de vraies apps client — l'indicateur fonctionne
intégralement dans les deux sens dès maintenant.

## Premier test réel d'appel Agora : échec, message d'erreur trop générique (05/08)

Le "reste à tester" noté le 31/07 (appel réel de bout en bout, jamais
fait) vient d'être tenté par l'utilisateur — échec avec seulement
"Impossible de démarrer l'appel." affiché, sans indication de la cause
réelle (le `catch` de `call_screen.dart` avalait l'exception, ne
gardait le détail que dans `debugPrint`, invisible en dehors d'un
`flutter logs` branché).

**`lib/presentation/calls/call_screen.dart`** : le message affiché
inclut maintenant `$e` — la vraie exception (token Agora indisponible,
App ID invalide, échec réseau vers `super-endpoint`, etc.) apparaît
directement dans l'app, sans avoir besoin des logs Supabase à chaque
nouvel essai.

**Cause identifiée** : logs de `super-endpoint` — `worker boot error:
Uncaught SyntaxError`. Même symptôme que le piège déjà rencontré avec
`update-latest-version` (04/08) : du code résiduel du template
Supabase resté mélangé au contenu collé dans l'éditeur en ligne, la
fonction ne démarre même pas. Corrigé en redemandant à l'utilisateur de
tout sélectionner (Ctrl+A) et supprimer avant de recoller le contenu
exact de `supabase/functions/super-endpoint/index.ts`, puis Deploy —
**à confirmer par un nouveau test d'appel après redéploiement**.

## Webhook de notification de version : toujours en échec malgré des secrets corrects (05/08)

Après avoir corrigé `FIREBASE_APP_DISTRIBUTION_GROUPS` (run 299,
build-apk.yml) — la distribution Firebase fonctionne enfin
("distributed to testers/groups successfully"). Mais l'étape "Notifier
Supabase" échoue encore, alors que :
- le header `x-webhook-secret` n'est plus vide dans les logs (masqué
  `***`, preuve que le secret GitHub `UPDATE_VERSION_WEBHOOK_SECRET`
  est bien renseigné, contrairement à avant) ;
- le digest SHA256 affiché côté Supabase pour ce secret correspond
  exactement à `sha256sum` de la valeur donnée à l'utilisateur.

Donc les deux secrets sont vraisemblablement corrects des deux côtés,
mais `curl -sf` avale complètement la réponse HTTP en cas d'échec — on
ne sait pas si Supabase répond 401 (vrai mismatch malgré tout, ex.
espace/retour à la ligne collé par erreur), 500 (bug dans la fonction),
ou si la requête n'atteint même pas Supabase.

**`.github/workflows/build-apk.yml`** : l'étape n'utilise plus
`curl -sf ... || echo "..."` (qui masque tout) mais capture le code
HTTP (`-w "%{http_code}"`) et affiche la réponse complète du corps —
prochain build : le vrai diagnostic sera visible directement dans les
logs GitHub Actions, plus besoin de deviner. Toujours non bloquant
(`exit 0` systématique en fin d'étape).

## Vraie cause de l'échec `super-endpoint` (appels Agora) trouvée : mauvais nom d'export (05/08)

Le redéploiement du 05/08 (copier-coller propre, plus de code résiduel)
n'a pas suffi — logs Supabase toujours "worker boot error". Message
complet obtenu cette fois (l'utilisateur a cliqué sur la ligne
d'erreur) : *"The requested module 'https://esm.sh/agora-token@2.0.5'
does not provide an export named 'Role'"*, à la ligne de l'import.

**Cause racine, confirmée en consultant le code source réel du package
sur GitHub** (`AgoraIO/Tools`, `DynamicKey/AgoraDynamicKey/nodejs/index.js`) :
l'export s'appelle **`RtcRole`**, pas `Role`. Le fichier
`supabase/functions/super-endpoint/index.ts` contenait cette erreur
**depuis sa toute première écriture (31/07)** — la fonction n'a donc
**jamais fonctionné une seule fois**, y compris avant ce chantier de
diagnostic (le "reste à tester" du 31/07 n'avait en réalité aucune
chance d'aboutir tel quel).

**Corrigé** : `import { RtcRole, RtcTokenBuilder } from "...";` et
`RtcRole.PUBLISHER` au lieu de `Role.PUBLISHER`. **À redéployer sur
Supabase** (remplacer tout le contenu de l'éditeur en ligne comme pour
les fois précédentes) — ce correctif ne fait pas partie du code Flutter,
aucun nouveau build APK n'est nécessaire pour qu'il prenne effet.

## Barre de recherche remise sur l'Accueil, en raccourci (05/08)

Suite à la restructuration Catalogue (04/08) qui avait déplacé toute la
recherche/filtres vers l'onglet Catalogue, l'utilisateur a remarqué
l'absence de barre de recherche sur l'Accueil et a demandé qu'elle
revienne.

**`catalog_tab.dart`** : ajout d'un bloc visuellement identique à une
barre de recherche (icône loupe + texte d'invite `search_hint`), placé
juste sous l'en-tête. Ce n'est **pas une vraie recherche locale** — un
tap bascule directement vers l'onglet Catalogue via
`widget.onOpenCatalog` (même callback que le bouton "Voir tout le
catalogue" déjà présent en bas de l'Accueil), où vit la vraie logique
de recherche/pagination. Volontairement pas de duplication de cette
logique sur deux écrans — pattern courant sur les apps e-commerce
(barre "raccourci" sur l'accueil, recherche réelle sur un écran dédié).

## Sonnerie côté appelant manquante (05/08)

Une fois le bug `RtcRole`/`Role` corrigé, l'appel fonctionne (confirmé
par l'utilisateur) mais reste totalement silencieux pendant "Appel en
cours..." côté appelant — seul l'écran d'appel **entrant**
(`incoming_call_screen.dart`) jouait une sonnerie (`notif_radar.wav` en
boucle via `audioplayers`).

**`call_screen.dart`** : ajout d'un `AudioPlayer` de "ringback" — démarre
en boucle dès `onJoinChannelSuccess` (le canal local est rejoint, en
attente du distant), s'arrête dès `onUserJoined` (le distant a rejoint)
ou à la fin de l'appel (`_endCall`)/`dispose`. Même asset que la
sonnerie d'appel entrant, pour la cohérence.

## Nom et prénom séparés dans le profil client (05/08)

Le formulaire "Modifier mon profil" (`profile_tab.dart`) n'avait qu'un
champ unique "Nom complet" — repéré par l'utilisateur sur le profil
client existant. Le formulaire d'**inscription**, lui, demandait déjà
Nom et Prénom séparément (`registration_screen.dart`) mais ne stockait
que leur concaténation dans `profiles.full_name` (pas de colonnes
dédiées) : les deux écrans étaient incohérents entre eux.

**SQL phase71** (`supabase/phase71_patch_profile_first_last_name.sql`) :
ajoute `profiles.first_name` / `profiles.last_name`, backfill au mieux
des lignes existantes (1er mot = prénom, reste = nom — non garanti
fiable vu l'absence de convention dans les données déjà en base) et un
trigger qui recalcule `full_name` automatiquement dès que l'un des deux
champs change, pour ne pas casser les ~28 écrans qui lisent encore
`full_name` (fiche produit, avis, PDF, admin...). Un update qui ne
touche que `full_name` directement (aucun autre écran modifié) continue
de fonctionner sans y toucher, le trigger ne se déclenche que sur
`first_name`/`last_name`.

**`profile_tab.dart`** (`_EditProfileSheet`) : le champ "Nom complet"
devient deux champs "Prénom" / "Nom" côte à côte, sauvegardés dans les
nouvelles colonnes. **`registration_screen.dart`** : les champs déjà
existants sont maintenant aussi écrits dans `first_name`/`last_name`
(en plus de `full_name` via les métadonnées d'inscription, géré par
`handle_new_user()`).

**À exécuter une seule fois sur Supabase** (SQL Editor) avant que les
nouveaux champs du profil ne fonctionnent : `phase71_patch_profile_first_last_name.sql`.

## Vraie cause du webhook `update-latest-version` qui échouait toujours trouvée (05/08)

Le diagnostic HTTP mis en place au run 301 a immédiatement révélé la
vraie cause, invisible jusque-là (avalée par `curl -sf`) : **`Code HTTP :
401`**, réponse **`{"code":"UNAUTHORIZED_NO_AUTH_HEADER","message":"Missing
authorization header"}`**.

Ce n'était **pas** le `x-webhook-secret` (jamais atteint, malgré des
heures passées à vérifier les deux secrets un par un) : c'est la
**passerelle Supabase elle-même** qui exige par défaut un en-tête
`Authorization: Bearer <JWT valide>` sur toute Edge Function déployée
depuis le Dashboard (vérification JWT activée par défaut, indépendante
du code de la fonction). La requête `curl` de la CI n'envoyait que
`x-webhook-secret`, jamais `Authorization` — elle était donc rejetée
avant même d'atteindre le code de `update-latest-version`.

**Corrigé** (`.github/workflows/build-apk.yml`) : ajout de l'en-tête
`Authorization: Bearer $SUPABASE_ANON_KEY` (secret déjà présent, utilisé
par ailleurs pour `env.json`) en plus de `x-webhook-secret`. Les deux
sont nécessaires : `Authorization` pour passer la passerelle Supabase,
`x-webhook-secret` pour l'autorisation applicative propre à la fonction.

## Lien de mise à jour stable (bucket Supabase Storage public) (05/08)

La popup "Mise à jour disponible" (phase70) invite à cliquer sur un
lien de téléchargement — mais ce lien pointait jusqu'ici vers la page
Release GitHub, **inutilisable par un vrai client puisque le dépôt est
privé** (même piège identifié en discutant du partage de l'APK sur
Facebook). Un client qui verrait cette popup et cliquerait "Mettre à
jour" tombait sur une erreur 404.

**SQL phase72** (`supabase/phase72_patch_app_releases_bucket.sql`) :
nouveau bucket Storage public `app-releases` (limite de taille 500 Mo,
type MIME restreint à l'APK). Écriture réservée à la CI via la clé
`service_role` (contourne RLS) : aucune policy d'upload ouverte aux
clients, seulement une policy de lecture publique.

**`.github/workflows/build-apk.yml`** : nouvelle étape "Uploader l'APK
sur Supabase Storage" qui dépose l'APK **toujours sous le même nom de
fichier** (`akorahub-latest.apk`, réécrit à chaque build via
`x-upsert: true`) — contrairement au tag `build-XXX` unique par build
utilisé pour les Releases GitHub, ce nom fixe donne un **lien qui ne
change jamais d'un build à l'autre**. L'étape "Notifier Supabase" utilise
désormais ce lien (`$SUPABASE_URL/storage/v1/object/public/app-releases/akorahub-latest.apk`)
comme `downloadUrl`, avec repli automatique sur l'ancien lien GitHub
tant que le nouveau secret n'est pas configuré. Les deux étapes sont
optionnelles (`if: env.SUPABASE_SERVICE_ROLE_KEY != ''`), donc le build
ne casse jamais si le secret n'est pas encore en place.

**Bénéfice secondaire notable** : ce même lien stable peut aussi servir
directement pour un post Facebook — plus besoin de re-télécharger et
re-partager un lien Google Drive à chaque nouvelle version, le lien
Supabase reste identique et sert toujours la dernière build.

**À faire une seule fois, côté utilisateur** :
1. Exécuter `phase72_patch_app_releases_bucket.sql` sur Supabase (SQL Editor).
2. Ajouter le secret GitHub `SUPABASE_SERVICE_ROLE_KEY` (valeur trouvée
   dans Supabase Dashboard -> Settings -> API -> "service_role" secret) —
   Settings -> Secrets and variables -> Actions sur le dépôt GitHub.

Tant que ce secret n'est pas ajouté, tout continue de fonctionner comme
avant (repli sur le lien GitHub) — rien n'est cassé en attendant.

### Échec réel de l'upload : plan Supabase Free plafonné à 50 Mo (05/08)

Une fois le secret ajouté (voir ci-dessus) et le premier vrai build
lancé (run 308), l'upload échoue avec **`413 Payload too large` /
`EntityTooLarge`** : le **plan Supabase Free plafonne la taille
d'upload à 50 Mo**, très en dessous des ~300 Mo de l'APK. Ce plafond
est indépendant du `file_size_limit` du bucket (phase72, 500 Mo) —
c'est une limite de plan, pas de bucket, et rien côté SQL/config du
bucket ne peut la contourner.

**Bug additionnel repéré et corrigé dans la foulée** : l'étape
"Notifier Supabase" décidait du `downloadUrl` en vérifiant seulement
si le secret `SUPABASE_SERVICE_ROLE_KEY` était configuré — pas si
l'upload avait réellement réussi. Résultat : avec le secret présent
mais l'upload en échec (413), elle construisait quand même un lien
Supabase Storage vers un fichier **jamais déposé**, remplaçant l'ancien
lien GitHub (au moins valide en intention) par un lien totalement mort.
**Corrigé** : le code HTTP réel de l'upload est propagé via
`STORAGE_UPLOAD_STATUS` (variable d'environnement inter-étapes,
`$GITHUB_ENV`) ; le lien Supabase Storage n'est utilisé que si ce code
vaut exactement `200`, sinon repli sur le lien GitHub comme avant.

**Conséquence** : tant que ce plafond de plan n'est pas levé
(upgrade payant Supabase Pro) ou que l'APK n'est pas hébergé ailleurs,
le lien de mise à jour stable via Supabase Storage ne peut **jamais**
fonctionner pour ce fichier — le mécanisme retombe systématiquement sur
le lien GitHub (toujours inutilisable par un vrai client, dépôt privé).

### Pivot vers Netlify : l'upload Supabase Storage abandonné (05/08)

Trois options présentées à l'utilisatrice (Netlify automatisé / rester
en Google Drive manuel / upgrade payant Supabase Pro) — **Netlify
recommandé et retenu** : gratuit, infrastructure déjà en place et
fonctionnelle (2 pages déjà hébergées dessus), aucun coût récurrent
contrairement à l'upgrade Supabase.

**`.github/workflows/build-apk.yml`** : l'étape "Uploader l'APK sur
Supabase Storage" est **remplacée** par "Déployer l'APK + les pages
publiques sur Netlify" — copie l'APK compilé et les pages
`docs/formation-access/*.html` dans un dossier temporaire, puis
`npx netlify-cli deploy --prod` vers le site `akorahub-formation`
existant (secrets `NETLIFY_AUTH_TOKEN` + `NETLIFY_SITE_ID`, optionnels
— ignoré tant qu'ils ne sont pas configurés, comme les autres étapes
optionnelles du workflow). L'APK est déposé sous un nom fixe
(`akorahub-latest.apk`), donnant un lien stable :
`https://akorahub-formation.netlify.app/akorahub-latest.apk`. Le
`downloadUrl` envoyé à `update-latest-version` n'utilise ce lien que si
le déploiement a réellement réussi (`NETLIFY_DEPLOY_OK`), sinon repli
sur le lien GitHub — même principe de propagation de statut réel que
le correctif Supabase Storage juste au-dessus, pour ne plus jamais
répéter ce bug.

**Bénéfice secondaire** : `index.html` et `privacy-policy.html` se
déploient désormais automatiquement à chaque build (contenu du dépôt),
le glisser-déposer manuel sur Netlify décrit plus haut n'est donc
requis que si le format d'une page change en dehors d'un build APK.

Le bucket `app-releases` (phase72) et sa policy de lecture restent en
place, inutilisés — abandon sans nettoyage, même logique que pour le
bucket `formation-web` délaissé au profit de Netlify le 01/08.

**À faire une seule fois, côté utilisateur** :
1. Créer un jeton d'accès personnel Netlify (User settings -> Applications
   -> New access token).
2. Récupérer l'ID du site `akorahub-formation` (Site configuration ->
   General -> Site details -> Site ID — un UUID, pas le nom du site).
3. Ajouter les deux comme secrets GitHub : `NETLIFY_AUTH_TOKEN` et
   `NETLIFY_SITE_ID`.

## Politique de confidentialité hébergée publiquement (checklist Play Store) (05/08)

Reprise de la checklist publication Play Store (voir section dédiée
plus haut, 01/08) : premier item coché, "héberger `privacy-policy.html`
sur une URL publique" — requis par la Play Console (Data Safety /
fiche boutique), qui exige un vrai lien, pas un fichier dans un dépôt
privé.

**Pourquoi pas Supabase Storage** (déjà tenté et documenté pour
`formation-web`, 01/08) : les buckets publics Supabase forcent le
Content-Type des fichiers `.html` à `text/plain` (protection
anti-phishing côté serveur) — la page s'afficherait comme du texte brut
avec des balises visibles, inutilisable.

**Solution retenue — réutilisation du site Netlify existant** (déjà en
place pour `docs/formation-access/index.html`, voir section Formation
01/08) : `docs/privacy-policy.html` copié dans
`docs/formation-access/privacy-policy.html`, pour être servi sur
`https://akorahub-formation.netlify.app/privacy-policy.html` au
prochain redéploiement (glisser-déposer manuel du dossier sur
Netlify, comme pour toute mise à jour de ce site — voir tutoriel donné
séparément).

**`registration_screen.dart`** : le texte "politique de
confidentialité" dans la case à cocher CGU (étape 2 de l'inscription)
est désormais cliquable et ouvre cette URL dans le navigateur — attendu
par la review Play Store en plus du lien fourni dans la fiche boutique
elle-même.

⚠️ **Redéploiement Netlify manuel requis** pour que le lien fonctionne
(glisser à nouveau `docs/formation-access/` sur le site Netlify
existant, onglet Deploys) — sinon `privacy-policy.html` n'existe pas
encore en ligne malgré le lien déjà actif dans l'app.

**Confirmé en ligne le 05/08** (première mise à jour) :
`https://akorahub-formation.netlify.app/privacy-policy.html` s'affiche
correctement (testé par l'utilisatrice).

## Politique de confidentialité complétée : sous-traitants manquants (05/08)

En croisant la politique de confidentialité avec le guide "Sécurité des
données" (voir ci-dessous), un vrai trou a été repéré : **Agora**
(appels audio/vidéo), **Firebase** (notifications push) et les
**opérateurs mobile money** (Mvola, Orange Money, Airtel Money)
n'étaient mentionnés nulle part dans `docs/privacy-policy.html` — seul
Supabase l'était. Or le guide Sécurité des données réclamait justement
que la politique confirme ces sous-traitants.

**Corrigé** : nouvelle sous-section « 4.1 Prestataires techniques
(sous-traitants) » avec un tableau des 4 prestataires et leur usage
précis (dont la clarification que le flux audio/vidéo Agora n'est
**jamais reçu ni stocké** par les serveurs AkoraHub, uniquement
relayé en direct entre les deux appareils). Date de mise à jour
affichée passée au 5 août 2026. Fichier synchronisé dans
`docs/formation-access/privacy-policy.html` (même redéploiement
Netlify manuel requis pour que la version en ligne reflète ce
correctif — **redéploiement supplémentaire nécessaire** après celui
déjà fait pour la mise en ligne initiale).

## Guides Play Store remis à jour (v2.0) (05/08)

Deux guides de soumission avaient été préparés le 01/08 (build #228)
puis mis de côté. Remis à jour avant réutilisation, pour refléter tout
ce qui a été ajouté depuis (appels audio/vidéo, messagerie privée avec
pièces jointes, groupes Formation, tableaux de bord CRM admin) :

- **Guide "Sécurité des données"** (v2.0, build #304) : nouvelle
  catégorie *Audio* documentant les appels (non collectés — relayés en
  direct via Agora), pièces jointes de messagerie ajoutées à la ligne
  Photos, note sur les tableaux de bord CRM (finalité "Analytics" à
  considérer en plus de "Fonctionnalité de l'application").
- **Guide "Fiche produit Play Store"** (v2.0) : description complète
  enrichie (appels audio/vidéo, groupes Formation), lien de politique
  de confidentialité renseigné avec la vraie URL Netlify.

Publiés comme Artifacts pour consultation par l'utilisatrice ; fichiers
sources conservés dans le répertoire scratchpad de la session (pas des
fichiers livrables de l'app, pas commités au dépôt).

## Nom complet sur l'Accueil + fermeture de la bulle de chat par glissement (05/08)

Deux retours utilisatrice sur l'Accueil :

**1. "Bonjour, A." au lieu du nom complet** — `catalog_tab.dart`
tronquait volontairement le nom (`.split(' ').first`, ne gardant que le
premier mot) ; changé pour afficher `_clientName` en entier.

**2. Fermer la bulle de chat flottante en la glissant sur un ❌** —
capture d'une bulle similaire (Messenger) à l'appui. La bulle
(`floating_chat_bubble.dart`) était déjà draggable mais sans zone de
suppression. Ajout :
- pendant le glissement (`onPanStart`), un ❌ apparaît en bas, centré
  horizontalement ;
- si la bulle est relâchée à moins de 50px du centre du ❌
  (`onPanEnd`), la bulle se masque et une confirmation courte
  s'affiche ; le ❌ grossit légèrement et passe en rouge quand la bulle
  est au-dessus, pour un retour visuel avant le lâcher (`AnimatedScale`
  sur la bulle, `AnimatedContainer` sur le ❌) ;
- réutilise le masquage personnel déjà existant
  (`ChatBubbleSettingsRepo.setHiddenByClient`, phase68) plutôt qu'un
  nouvel état — réactivable depuis Paramètres, comme le
  "masquer/afficher" déjà proposé là-bas.

## Usages produit (badges Savonnerie/Industriel/Nettoyage...) (05/08)

Demande à partir de visuels marketing existants (ex. "Soude
Caustique") qui listent toujours les usages possibles du produit en
badges (Savonnerie, Industriel, Nettoyage...) : reproduire ça dans
l'app, choisi par l'admin **au moment de publier le produit** (pas de
saisie libre uniquement — une liste de suggestions prêtes à cocher).

**SQL phase73** : `products.use_cases text[]` (défaut `'{}'`).

**`product_management_real.dart`** : nouvelle constante
`kProductUsageSuggestions` (15 usages de départ : Savonnerie,
Industriel, Nettoyage, Construction & BTP, Détergents, Médical,
Cosmétique, Lessive, Désinfection, Agriculture, Traitement de l'eau,
Textile, Papier, Métallurgie, Alimentaire). Dans le formulaire produit,
section "Usages" sous "Pilier d'entreprise" : `FilterChip` multi-
sélection sur ces suggestions (+ les usages déjà choisis sur ce produit
mais absents de la liste, pour ne jamais en perdre à l'édition) + un
champ texte libre pour ajouter un usage hors liste. Sauvegardé dans
`use_cases`.

**`product_detail_client.dart`** : les usages cochés s'affichent en
badges (icône ✓ + libellé) juste après la puce de catégorie, sur la
fiche produit côté client — même esprit visuel que les infographies
marketing fournies en référence.

### Les usages ajoutés hors liste deviennent réutilisables partout (05/08)

Suite : l'utilisatrice voulait que le champ "Autre usage" ne soit pas
qu'un ajout ponctuel pour un seul produit, mais vienne enrichir la
liste de suggestions pour **tous** les futurs produits.

**`product_management_real.dart`** : `_loadData()` charge désormais
aussi tous les `use_cases` déjà utilisés sur l'ensemble des produits
(juste cette colonne, sans pagination) et les fusionne avec les 15
suggestions de départ dans `_knownUsages` — c'est cette liste (pas la
constante statique `kProductUsageSuggestions`) qui alimente les puces
du formulaire. Un usage tapé une fois sur un produit apparaît donc
comme suggestion cochable sur tous les produits suivants, dès le
prochain chargement de la liste (rechargée après chaque sauvegarde).
Pas de nouvelle table : simple agrégation de la colonne `text[]`
existante.

### CI de secours sur Codemagic + carte de profil client (05/08)

Le quota gratuit GitHub Actions (2000 min/mois) a été épuisé ce jour
(constaté via `github.com/settings/billing`, plusieurs dizaines de
builds complets enchaînés) — reset dans ~27 jours. En attendant, le
`codemagic.yaml` déjà présent dans le dépôt (compte Codemagic existant,
quota séparé) a été étendu pour retrouver la parité fonctionnelle avec
GitHub Actions : déploiement Netlify (APK + pages publiques, lien
stable `akorahub-latest.apk`), notification Supabase
(`update-latest-version`), et publication Firebase App Distribution
(groupe "testeurs").

Deux pièges rencontrés et corrigés en configurant Firebase App
Distribution côté Codemagic :
- `FIREBASE_APP_ID` doit être une variable **statique** (déclarée dans
  `environment.vars`), pas générée dynamiquement par un script via
  `$CM_ENV` — Codemagic valide/résout la section `publishing` avant
  d'exécuter le moindre script, donc une variable créée en cours de
  build lui est invisible (erreur "is not accessible").
- Sans `artifact_type: apk` explicite dans `publishing.firebase.android`,
  Codemagic publie par défaut l'AAB (présent lui aussi dans les
  artefacts du build) plutôt que l'APK — or distribuer un AAB via
  Firebase App Distribution exige que le projet Firebase soit lié à un
  compte Google Play, ce qui n'est pas notre cas ("This project is not
  linked to a Google Play account"). L'APK n'a pas cette contrainte.

Build #23 confirmé entièrement vert (Netlify + Supabase + Firebase) —
Codemagic est désormais le pipeline de secours pleinement fonctionnel
tant que le quota GitHub Actions n'est pas reconstitué.

**Carte de profil client (`profile_tab.dart`)** : nouvel habillage
visuel façon "carte de visite" (bandeau + avatar à cheval sur la
jonction + carte blanche arrondie en dessous), sur demande explicite
avec une image de référence — en gardant la photo de couverture
existante (contrairement à l'option alternative proposée, qui aurait
remplacé la couverture par un aplat de couleur d'accent). Le bandeau
(`_buildCoverAndAvatar`) est réduit (18h → 15h) ; juste en dessous, le
bloc identité (nom, société, badges, stats, bio…) est désormais enrobé
dans un `Container` à coins arrondis en haut (`surface` + ombre légère)
remonté via `Transform.translate` d'exactement `_avatarOverlap` (47,
= rayon avatar 44 + liseré 3) — une constante partagée avec le
positionnement de l'avatar dans `_buildCoverAndAvatar`, pour que
celui-ci reste toujours centré pile sur la jonction bandeau/carte,
quel que soit l'appareil.

### Icônes panier/commandes/messagerie/notifications en carré arrondi (05/08)

Sur demande, avec une image de référence : les 4 icônes de la barre du
haut de l'accueil (`catalog_tab.dart`) avaient déjà un fond gris clair
et un badge de compteur, mais en cercle parfait (`CircleBorder`). Passé
à `RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))`
pour le look "carré arrondi" (squircle) demandé — changement purement
cosmétique, sans toucher aux deux autres boutons circulaires du même
fichier (superposition sur carte produit, bouton flottant) qui n'étaient
pas concernés par la demande.

### Barre de navigation du bas : indicateur arrondi + effet flottant (05/08)

Suite logique du changement précédent, sur demande explicite : la barre
du bas (`_ClientBottomNav` dans `client_home.dart`) n'avait qu'un
changement de couleur pour marquer l'onglet actif (pas de fond). Ajouté
une pastille carrée arrondie (rayon 14, même style que les icônes du
haut) derrière l'icône de l'onglet sélectionné, avec un léger zoom
(`AnimatedScale`, x1.15) et une transition de couleur/graisse du texte
(`AnimatedDefaultTextStyle`), le tout animé sur 200ms. La barre elle-
même passe d'une fine ligne de séparation à des coins arrondis en haut
+ une ombre légère (mêmes valeurs que la carte de profil), pour un effet
"flottant" cohérent avec le reste du nouveau style visuel. Un
`ClipRRect` évite que l'effet d'encre des onglets aux extrémités
déborde des coins arrondis.

### Usages suggérés par catégorie plutôt qu'une seule liste générique (05/08)

Suite au constat que la liste unique de 15 suggestions (pensée pour les
matières premières industrielles : Savonnerie, Métallurgie, Agriculture...)
ne collait pas à un produit fini comme "Gel Sol Universel" (catégorie
"Carrelage & Sols") : ajout de `kProductUsageSuggestionsByCategory`
dans `product_management_real.dart`, un mapping catégorie → usages
pertinents, couvrant les 10 catégories du pilier "Akora Fanadiovana"
(celui avec les vrais produits déjà vendus — Carrelage & Sols, Cuisine
& Vaisselle, Désinfectants & Hygiène, Entretien Véhicules, Lessive &
Textile, Sanitaire & Salle de Bain, Soins du Corps & Cosmétiques,
Vitres & Surfaces, Cire & Bougie, Produits spécialisés). Les clés
doivent matcher exactement les noms stockés dans `categories`/
`products.category` (voir phase6_patch_categories.sql et
phase42_patch_produits_categories.sql).

Dans le formulaire produit, les chips "Usages" affichent désormais en
priorité la liste de la catégorie sélectionnée, puis `_knownUsages`
(liste générique + tout usage déjà tapé sur n'importe quel produit) en
repli — jamais l'un OU l'autre : les deux sont toujours mélangés
(`Set` qui déduplique), pour ne perdre ni la pertinence par catégorie
ni la réutilisation globale des usages personnalisés. Les 4 piliers pas
encore activés (Matières Premières, Anti-Nuisibles, Peinture, Akora
Soins) ne sont pas couverts pour l'instant — ils retombent sur la
liste générique, à étendre plus tard si besoin.

### Correctif : l'avatar de profil était peint DERRIÈRE la carte blanche (05/08)

Signalé par capture d'écran ("le photo de profil doit être en premier
plan") : la carte de profil ajoutée plus tôt aujourd'hui utilisait deux
éléments SÉPARÉS de la ListView (le bandeau+avatar dans un `Stack`,
puis la carte blanche juste après, translatée pour chevaucher vers le
haut) — or une ListView peint ses enfants dans l'ordre, donc la carte
(peinte en second) recouvrait la moitié basse de l'avatar au lieu de
l'inverse.

**Correction dans `profile_tab.dart`** : fusion de `_buildCoverAndAvatar`
et de la carte dans une seule méthode `_buildProfileHeader`, avec un
seul `Stack` où l'avatar est désormais le DERNIER enfant (donc peint en
dernier, par-dessus tout). La carte (contenu variable : nom, stats,
bio, boutons...) reste le seul enfant NON positionné du `Stack` — c'est
lui qui donne sa hauteur réelle au bloc dans la ListView (repoussé vers
le bas via un simple `Padding`, plutôt qu'un `Transform.translate` sur
un élément séparé comme avant).

### Défilement automatique de la bannière d'accueil (05/08)

Question posée : pourquoi la bannière (carrousel promo en haut de
l'accueil) n'animait pas toute seule ? Réponse : le `PageView` existant
n'avait qu'un swipe manuel, aucun timer d'avancement automatique.

**`catalog_tab.dart`** : ajout de `_bannerAutoplayTimer` (`Timer?`) et
`_scheduleBannerAutoplay()`, qui programme un `animateToPage` vers la
slide suivante (boucle) 5 secondes après le dernier changement de page —
qu'il vienne du timer lui-même ou d'un swipe manuel (`onPageChanged`
reprogramme systématiquement), donc un swipe manuel repousse
naturellement le prochain défilement auto sans logique de pause/reprise
séparée. Reprogrammé aussi après le chargement des vraies bannières
(`home_banners`), qui peuvent différer en nombre des 3 slides de repli
affichées pendant le chargement. Pas de défilement auto si une seule
slide.

### Photos de couverture multiples pour le profil client (05/08)

Sur demande : jusqu'à 5 photos de couverture (optionnel, pas obligatoire
d'en avoir plusieurs), affichées en fondu automatique toutes les 5
secondes — réservé aux clients ayant déjà passé au moins une commande.

**`supabase/phase74_patch_profile_cover_photos.sql`** : nouvelle colonne
`profiles.cover_urls text[]`, avec reprise automatique de l'ancienne
`cover_url` (singulier, gardée en base mais plus écrite — vérifié
qu'aucun autre écran ne la lit) comme première photo pour les profils
existants.

**`profile_tab.dart`** :
- `_uploadCoverPhoto()`/`_removeCoverPhoto()` remplacent l'ancien
  `_pickAndUploadCover` (une seule photo) — ajoutent/retirent une URL
  dans le tableau `cover_urls`.
- `_openCoverPhotosManager()` : ouvre une feuille de gestion (miniatures
  + bouton retirer, tuile "+" si moins de 5 photos) au tap sur la
  couverture — **bloquée avec un message explicite si `_ordersCount ==
  0`** (compteur déjà chargé pour la stat "Commandes" du profil, même
  logique que `has_ordered_product` utilisée ailleurs pour les avis
  vérifiés). Un client sans commande peut toujours VOIR sa couverture
  existante, seule la gestion (ajout/retrait) est restreinte.
- `_buildProfileHeader` : `coverUrl` (singulier) devient `coverUrls`
  (liste) ; l'image affichée change via `AnimatedSwitcher` (fondu 600ms)
  piloté par `_coverPhotoIndex`, avancé par `_scheduleCoverAutoplay`
  (`Timer.periodic` 5s, pas de logique de pause/reprise comme la
  bannière de l'accueil : le tap sur la couverture ouvre la gestion,
  pas un swipe manuel à ménager). Repli automatique sur `cover_url`
  (singulier) tant que la migration phase74 n'a pas tourné.

### 3 algorithmes de personnalisation (06/08)

Suite à la question sur l'algorithme Facebook : 3 fonctions SQL dans le
même esprit que `post_engagement_scores` (phase54, déjà en place pour
le fil Tendances) — classer par un score plutôt qu'un seul critère brut.
Tout dans **`supabase/phase75_patch_personalization_algorithms.sql`**.

1. **`personalized_feed_post_ids(uid, days_back, max_results)`** — fil
   "Pour toi" de la Communauté. Score = (engagement + bonus d'affinité
   si le client a déjà commandé dans le pilier du produit taggé par le
   post) / (1 + âge_en_jours)^1.2 — décroissance façon Hacker News/
   Reddit, pour que les posts récents restent visibles même sans encore
   beaucoup d'engagement. **`wall_tab.dart`** : nouvelle puce "Pour toi"
   (icône ✨) avant "Tendances", mutuellement exclusive avec elle (et
   remise à zéro par tous les autres filtres, même logique que
   `_isTrending`) ; `_fetchForYouPosts()` retombe sur Tendances si le
   client n'est pas connecté (l'affinité n'a pas de sens sans lui) ou en
   cas d'erreur (migration pas encore exécutée).

2. **`products_bought_together(pid, max_results)`** — "Vous pourriez
   aussi aimer" sur la fiche produit : produits achetés dans la même
   commande que celui-ci, par n'importe quel client (panier-jumelage
   classique, pas de personnalisation par client ici, contrairement au
   fil Pour toi). **`product_detail_client.dart`** : nouvelle section
   `_BoughtTogetherSection`, juste avant les avis clients, réutilise
   `ProductCard` (déjà utilisé pour "Vous recommandez souvent" sur
   l'accueil) — masquée si vide.

3. **`client_top_categories(uid)`** — catégories que CE client achète le
   plus souvent, classées par fréquence. **`product_catalog_tab.dart`** :
   les puces de catégorie (`_categories`) sont désormais triées selon cet
   ordre en premier (alphabétique pour le reste / repli complet si le
   client n'a pas encore de commande), au lieu du tri alphabétique fixe.

Les 3 fonctions excluent les commandes annulées (`status <> 'annulee'`),
même convention que `has_ordered_product` (phase55, avis vérifiés).

### Profil verrouillé (privé) (06/08)

Suite à la question soulevée en cours de session : par défaut, tout
client peut voir le profil public de n'importe quel autre. Choix acté
avec l'utilisatrice pour ce que voit un visiteur NON ami d'un profil
verrouillé : **juste nom + avatar + bouton "Ajouter en ami"** (comme un
compte Instagram privé) — société, secteur, numéro et publications
restent masqués tant que la demande d'ami n'est pas acceptée. Réutilise
le système d'amis déjà en place plutôt que d'inventer un nouveau
mécanisme d'accès.

**`supabase/phase76_patch_profile_lock.sql`** : `profiles.profile_locked
boolean default false` + vue `public_profiles` redéfinie pour l'exposer.

**`public_profile_screen.dart`** : `showFullProfile = !isLocked ||
isFriend (status == 'acceptee') || isSelf` — masque le secteur, le
bouton WhatsApp et la liste des publications si faux, remplacés par un
message "Ce profil est privé" + invitation à ajouter en ami (le bouton
"Ajouter en ami" reste toujours visible via `_buildFriendSection`,
c'est le seul moyen de débloquer l'accès).

**`security_settings_screen.dart`** : nouveau `SwitchListTile` "Profil
verrouillé", même emplacement/pattern que "Numéro visible dans la
Communauté" juste en dessous.

### "M'alerter quand disponible" sur un produit en rupture (06/08)

Suite de la liste "praticable" — "Recommander en un clic" existait déjà
(bouton "Recommander" par commande dans `orders_tab.dart`, vérifié avant
de coder quoi que ce soit d'inutile). Celui-ci était vraiment manquant.

**`supabase/phase77_patch_product_stock_alerts.sql`** : table
`product_stock_alerts` (customer_id, product_id) + trigger
`on_product_back_in_stock`, qui se déclenche UNIQUEMENT quand
`stock_quantity` passe de ≤0 à >0 (`after update of stock_quantity`),
et appelle `send-push-notification` avec `table: 'product_back_in_stock'`
— même plomberie que l'abonnement par catégorie (phase36), mais un nom
de table synthétique différent pour ne pas entrer en collision avec le
cas `"products"` existant (notification de nouveau produit).

**Edge Function `send-push-notification/index.ts`** : nouveau cas
`payload.table === "product_back_in_stock"` — lit les abonnés dans
`product_stock_alerts`, notifie, PUIS supprime ces abonnements (dans
l'Edge Function, pas dans le trigger SQL, pour éviter une course : le
trigger déclenche juste l'appel HTTP asynchrone, il ne sait pas quand
l'Edge Function l'aura traité). Une alerte est donc à usage unique — se
réabonner si le produit repasse en rupture. **Nécessite un redéploiement
manuel de l'Edge Function** (Dashboard -> Edge Functions ->
send-push-notification -> redéployer avec le nouveau code), le SQL seul
ne suffit pas ici.

**`lib/core/notifications/product_stock_alert_repo.dart`** : même
pattern que `CategorySubscriptionRepo` (isSubscribed/subscribe/
unsubscribe).

**`product_detail_client.dart`** : `outOfStock` calculé comme
`ProductCard` (catalog_tab.dart). Si vrai : bouton "Ajouter au panier"
désactivé (texte "Rupture de stock") et nouveau `_StockAlertButton`
au-dessus (toggle, se change en "Vous serez alerté (toucher pour
annuler)" une fois abonné).

### Carte de profil appliquée au profil des autres clients + amis en commun (06/08)

Suite logique, avec une image de référence (planche de cartes de
profil) : le style bandeau + avatar chevauchant + carte blanche arrondie
(déjà sur "Mon profil", 05/08) s'applique maintenant à
`public_profile_screen.dart` (le profil qu'on ouvre en tapant sur un
autre client dans la Communauté), qui était resté en simple liste plate.

**`supabase/phase79_patch_public_profile_card_style.sql`** : la vue
`public_profiles` expose désormais `cover_photo_url` (première photo de
`cover_urls`, avec repli sur l'ancienne `cover_url`) — jusqu'ici
seulement visible par le propriétaire du profil. Ajoute aussi
`mutual_friends(uid, other_uid)` : amis communs entre le client connecté
et le profil consulté (intersection des deux listes d'amis acceptés).

**`public_profile_screen.dart`** :
- `_buildCardHeader` : même Stack (bandeau → carte → avatar en dernier
  enfant/premier plan) que `_buildProfileHeader` dans profile_tab.dart,
  mais en lecture seule (pas d'upload, une seule photo de couverture).
- `_buildMutualFriendsRow` : jusqu'à 3 avatars superposés + "X amis en
  commun" (repli silencieux si vide ou migration pas encore exécutée),
  sous le nom, au-dessus du secteur.
- Le profil verrouillé (phase76) reste inchangé dans son comportement,
  juste replacé dans la nouvelle mise en page.

### Rotation du secret webhook terminée + Airtel Money activé chez FiveOne Pay (06/08)

- **Rotation `WEBHOOK_SECRET`** : les 3 étapes (secret Edge Function
  mis à jour, script `phase78` exécuté, Edge Function
  `send-push-notification` redéployée avec le nouveau code du cas
  `product_back_in_stock`) ont été confirmées faites par
  l'utilisatrice. Toutes les notifications push (messages, devis,
  commandes, produits, rupture de stock...) sont de nouveau
  fonctionnelles avec le secret à jour.

- **Airtel Money chez FiveOne Pay** : marqué "Bientôt disponible"
  (interrupteur désactivé) dans `payment_methods_management.dart`
  depuis l'intégration initiale, faute de support à l'époque.
  L'utilisatrice a confirmé que ses 3 comptes Mobile Money (Mvola,
  Orange Money, Airtel Money) sont désormais validés côté FiveOne Pay —
  et la Edge Function `create-fiveonepay-payment-link` supportait déjà
  `AIRTEL_MONEY` côté code (juste jamais activable depuis l'Admin). Le
  blocage retiré : Airtel Money est maintenant sélectionnable comme les
  deux autres opérateurs sous "FiveOne Pay".

### Filtrer le catalogue par usage (06/08)

Suite de la liste "praticable" : nouvelle rangée de puces "Usages"
(Marbre, Carrelage, Désinfection...) dans `product_catalog_tab.dart`,
juste sous les catégories — sur la colonne `use_cases` déjà en place
(phase73). Filtre côté serveur (`.contains('use_cases', [usage])` sur
la requête paginée) + repris côté client dans `_filteredProducts` pour
cohérence avec les autres filtres (pilier/catégorie/recherche).

`_usages` (liste des usages disponibles) est scopée au pilier
sélectionné mais PAS à la catégorie — un usage comme "Nettoyage" reste
utile pour comparer plusieurs catégories d'un même pilier plutôt que de
disparaître dès qu'une catégorie précise est choisie. Réinitialisé à
"Tous les usages" en même temps que la catégorie quand le pilier change
(même logique de repli que l'existant).

### "Mon panier habituel" (06/08)

Dernier point de la liste "praticable" : une liste de produits +
quantités que le client compose une fois et recharge en un clic, sans
repasser par tout le catalogue. Distincte des **favoris** (juste une
étoile, aucune quantité) et des **commandes récurrentes** (entièrement
automatiques, sur un intervalle) — ici rien n'est automatique, c'est un
raccourci manuel que le client alimente lui-même.

**`supabase/phase80_patch_usual_cart.sql`** : nouvelle table
`usual_cart_items` (customer_id, product_id, quantity par défaut 1,
paire unique) + RLS (chacun ne voit/modifie que ses propres lignes).

**`usual_cart_provider.dart`** (nouveau) : `UsualCartNotifier`/
`usualCartProvider`, clone structurel de `FavoritesNotifier` — ne gère
que la présence/absence d'un produit (mise à jour optimiste, annulée si
l'appel Supabase échoue) ; la quantité vit uniquement côté table, lue
directement par l'écran dédié.

**`usual_cart_screen.dart`** (nouveau) : liste avec, par produit, un
stepper de quantité `[-] qty [+]` et un bouton supprimer, plus un
bouton "Tout ajouter" qui reprend la quantité sauvegardée de chaque
produit (pas toujours 1) pour remplir le panier en un clic.

**Câblage** : icône panier (`Icons.shopping_bag_outlined` /
`Icons.shopping_bag` si déjà ajouté) sur la fiche produit
(`product_detail_client.dart`), à côté de l'étoile favoris ; entrée
"Mon panier habituel" ajoutée dans le menu Profil, section "Mes
achats", juste après "Mes favoris" (`profile_menu_drawer.dart`).

### Académie Matières Premières (fiche technique payante, revenu distinct) (06/08)

Sur demande explicite : un second onglet "Académie" sur la fiche d'une
matière première, réservé à un **achat payant SÉPARÉ** de l'achat de la
fiche produit (`formation_purchases`) — une nouvelle source de revenus
à part entière. Avoir acheté la fiche produit ne donne PAS accès à
l'Académie ; il faut un second achat, produit par produit, avec ses
propres paliers dégressifs. Tout reste verrouillé sans achat (aucun
teaser gratuit, même pas nom_chimique/niveau_danger) — décision
explicite de l'utilisatrice pour maximiser cette source de revenus.
Modèle générique, applicable à toute catégorie chimique.

**`supabase/phase81_patch_academie_matieres_premieres.sql`** :
- `academie_purchases` : même flux que `formation_purchases` (paiement
  manuel référence + preuve, validé par le staff, regroupé par
  `batch_id`), table et fonction d'accès (`has_purchased_academie_access`)
  entièrement indépendantes.
- `academie_pricing_tiers` : paliers dégressifs propres à l'Académie
  (1 produit : 15 000 Ar, 5 : 12 000 Ar, 10 : 8 000 Ar — modifiables
  côté Admin), indépendants des paliers Formation.
- `matieres_premieres_academie` (FK -> `raw_materials`, PAS une
  nouvelle table "matieres_premieres" comme demandé initialement — la
  table existante s'appelle `raw_materials`) : nom_chimique, synonymes,
  grade, aspect, ph_solution, solubilite, particularite,
  difference_produit_similaire, niveau_danger, epi_requis (tableau),
  premiers_secours, incompatibilites, stockage, statut_verification.
- `matieres_premieres_usages` : usages détaillés répétables (domaine
  d'application, technique/méthode, dosage/concentration, à vérifier en
  labo), sans limite de blocs.
- RLS des deux tables de contenu : lecture réservée à qui a un achat
  Académie validé pour CETTE matière première (ou au staff) ; écriture
  réservée au staff.

**Client (`raw_material_detail_client.dart`)** : la fiche (déjà
réservée aux acheteurs de base) devient un `TabBar` à 2 onglets —
"Fiche produit" (contenu existant, inchangé) et "Académie" (cadenas si
pas acheté, avec CTA "Débloquer l'accès Académie" vers la même page web
d'achat externe). Une fois débloqué : tous les champs de
`matieres_premieres_academie` + la liste des usages détaillés, avec un
badge "⚠️ À vérifier en labo" si `statut_verification`/`a_verifier_labo`
l'indique. Nouveau `AcademieRepo` (`fetchMyPurchasedIds`,
`fetchMyPendingIds`, `fetchSheet`) mirroir de `FormationRepo`.

**Admin** : bouton "Fiche Académie" (icône éprouvette) dans l'AppBar de
`raw_material_editor_screen.dart`, visible UNIQUEMENT en modification
d'une fiche existante (jamais à la création, jamais depuis un produit
fini) — ouvre `academie_editor_screen.dart` (nouveau), formulaire
complet + "+ Ajouter un usage" sans limite. Validation des demandes
d'achat : nouvel onglet "Académie" dans `formation_purchases_hub.dart`
(`academie_purchases_management.dart`, clone de la gestion Formation
existante) — le hub passe de 2 à 3 onglets.

**Achat** : comme Formation et Cours, l'achat se fait sur la page web
externe (`docs/formation-access/index.html`, conformité Google Play —
pas de paiement in-app pour du contenu numérique), qui gagne un
troisième onglet "Académie" : liste UNIQUEMENT les matières premières
déjà débloquées côté fiche produit (il faut la base pour situer la
fiche), sélection multiple, paliers dégressifs propres, mêmes moyens de
paiement. Cette page est redéployée automatiquement sur Netlify à
chaque build CI (déjà en place depuis le 05/08), aucune étape manuelle
supplémentaire.

### Fusion "Matières premières (Formation)" + "Achats Formation" dans le menu Plus (06/08)

Sur retour explicite : ces deux entrées séparées du menu Plus admin
créaient de la confusion. Fusionnées en un seul point d'entrée
**"Formation"**, avec deux onglets — **"Fiches"** (gestion du contenu,
`RawMaterialsManagement`, inchangé sinon retrait de son AppBar propre)
et **"Achats"** (la file de validation, `FormationPurchasesHub`, qui
garde ses 3 sous-onglets Matières premières/Cours/Académie mais perd
son titre — `toolbarHeight: 0` — puisqu'il n'est plus jamais poussé
seul). Nouveau `formation_hub.dart` (`FormationHub`) : un
`DefaultTabController` de 2 onglets qui les embarque tous les deux,
chacun gardant son propre état/Scaffold (FAB "+" toujours visible
uniquement sur l'onglet Fiches, comme avant). `more_menu_screen.dart`
ne pointe plus que vers ce hub unique.

### Ajout de "AkoraFormation — Cours & Modules" au même hub (06/08)

Suite logique : `FormationHub` passe de 2 à **3 onglets** —
**"Matières"** (renommé, ex-"Fiches"), **"Cours"**
(`FormationCoursesManagement`, même traitement que Matières — AppBar
propre retirée, FAB "+ Formation" conservé) et **"Achats"** (inchangé).
Le menu Plus admin perd donc une entrée supplémentaire
("AkoraFormation — Cours & Modules"). "Groupes Formation" (modération
des fils communautaires par catégorie) reste volontairement une entrée
séparée — ce n'est pas de la gestion de catalogue/contenu, mélanger les
deux aurait rendu le hub confus.

### Champs obligatoires sur la fiche Académie (06/08)

Sur demande explicite (avec un modèle de fiche déjà rédigé en
référence) : nom chimique, nom commun, aspect, pH en solution et
solubilité doivent être renseignés sur CHAQUE fiche technique Académie —
les autres champs (grade, particularité, différence avec un produit
similaire, sécurité, usages détaillés) restent optionnels.

**`academie_editor_screen.dart`** : le champ "Synonymes" est renommé
"Nom commun" (correspond au vocabulaire du modèle de fiche). Les 5
champs obligatoires sont marqués d'un `*` dans leur label et validés via
un `Form`/`GlobalKey<FormState>` — `_save()` refuse d'enregistrer et
affiche un message clair tant qu'un des 5 n'est pas rempli.

**`supabase/phase82_patch_academie_champs_obligatoires.sql`** :
renforce la même règle au niveau de la base (`set not null` sur les 5
colonnes de `matieres_premieres_academie`) — empêche toute fiche
incomplète même en cas d'insertion hors app.

### Domaines d'application suggérés pour les usages Académie (06/08)

Même principe que `kProductUsageSuggestions` (usages produit, 05/08) :
une liste de départ (`kAcademieUsageDomains` — Savonnerie
(Saponification), Traitement de l'eau, Ajustement pH, Nettoyage,
Nettoyage industriel, Dégraissage, Débouchage canalisation) enrichie
dynamiquement (`_knownDomains`, `academie_editor_screen.dart`) avec tout
domaine déjà tapé sur N'IMPORTE QUELLE fiche Académie (toutes matières
premières confondues) — un domaine ajouté une fois devient réutilisable
partout, dès le prochain chargement du formulaire. Le champ "Domaine
d'application" de chaque bloc d'usage passe d'un simple champ texte à
un `Autocomplete<String>` (même pattern que le champ Nom de
`raw_material_editor_screen.dart`) : suggestions visibles dès qu'on
touche le champ (liste complète si vide, filtrée en tapant), tout en
restant du texte libre — pas de table de référence séparée, un usage
non prévu reste saisissable.

### Liste étendue des domaines d'usage Académie (06/08)

Sur demande ("suggérez-moi des listes très longues") : `kAcademieUsageDomains`
passe de 7 à 45 entrées, regroupées par thème en commentaires (cosmétique
& hygiène, entretien & détergence, agroalimentaire & pharmaceutique,
textile & cuir, papier/peinture/construction, agriculture &
environnement, industrie lourde) — couvre notamment cosmétique,
dentifrice, parfumerie, désinfection, agroalimentaire, pharmaceutique,
textile, cuir, papier, peinture, BTP, agriculture, métallurgie,
plasturgie, caoutchouc, mines, imprimerie, verre/céramique, automobile.
Volontairement large puisqu'une même matière première (ex : soude
caustique) sert souvent à plusieurs domaines très différents. Reste une
liste de DÉPART : `_knownDomains` continue de l'enrichir avec tout
domaine tapé manuellement.
