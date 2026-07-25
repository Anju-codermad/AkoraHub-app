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

### Phase 9 — Activer / désactiver une catégorie (script prêt, pas exécuté)
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
- **Reste à faire** : exécuter `phase9_patch_categories_active.sql` dans
  Supabase.

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
  jamais uploadée ni sauvegardée. Ajout d'un vrai upload vers un nouveau
  bucket Storage `company` (`supabase/phase11_patch_company_logo_bucket.sql`,
  **script prêt, pas encore exécuté** — public en lecture, écriture
  réservée au staff, même pattern que `products`/`avatars`), avec
  indicateur de chargement pendant l'envoi. `logo` ajouté à
  `_persistedKeys`.

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
     **utilisateur doit l'exécuter**, id/full_name/company_name/
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
- **Mode sombre**
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
  - **Reste à faire** : notifications à l'arrivée d'un nouveau message,
    badge de messages non lus (colonnes `read_by_staff`/`read_by_client`
    déjà présentes mais pas encore exploitées dans l'UI), afficher
    visuellement le tag "Demande" (`is_request`) dans le fil de discussion
    Admin.

## 3ter. Connexion/Inscription — améliorations demandées (23/07, à traiter par Backend/Infra)

- **Bugs UX à corriger** : "Mot de passe oublié ?" et connexion sociale
  (Google/Facebook) sont des maquettes non fonctionnelles ("sera
  implémenté" au clic) sur `authentication_screen/`.
- **Téléphone obligatoire** à l'inscription (actuellement optionnel), avec
  validation des préfixes malgaches réels (Telma 034/038, Orange 032,
  Yas ex-Airtel 033).
- **Inscription** : ajouter confirmation du mot de passe + bouton
  afficher/masquer.
- **Vérification anti-fraude** : 4 niveaux discutés (email natif Supabase
  gratuit ; validation format téléphone gratuite ; SMS OTP payant par
  fournisseur tiers, coût à confirmer pour Madagascar ; validation
  manuelle des comptes pro par le staff — le texte "en attente de
  vérification" existe déjà dans `authentication_screen.dart` mais n'est
  branché à aucune vraie logique). **Décision utilisateur : reporté à plus
  tard.** Priorité recommandée si repris : email + téléphone (gratuits)
  avant SMS OTP/validation manuelle.

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

Pour éviter les conflits, le projet était initialement divisé en deux
périmètres clairs :

- **Conversation "Backend/Infra"** : `lib/core/`, `supabase/*.sql`, tous les
  écrans Admin (`*_real` hors `client_home/`), `.github/workflows/`,
  paiement, messagerie, notifications, sécurité RLS.
- **Conversation "Client UX/Design"** : uniquement
  `lib/presentation/client_home/*` — écrans client, style visuel, mise en
  page, adaptation des références visuelles fournies par l'utilisateur.

**Élargissement (23/07)** : l'utilisateur a explicitement demandé à la
conversation "Client UX/Design" de travailler aussi côté Admin, en plus du
Client — cette conversation n'est donc plus strictement cantonnée à
`client_home/*`. Elle a par exemple déjà créé un écran Admin
(`home_banners_management.dart`) avant cet élargissement, avec accord
implicite de l'utilisateur à ce moment-là.

**Règle qui reste valable** : toute conversation qui touche un fichier
également modifié par l'autre doit vérifier l'historique Git (fetch avant
push, tester un merge si des commits distants sont apparus) plutôt que de
pousser en force — plusieurs fusions automatiques propres ont déjà eu lieu
ce jour-là sans perte de code des deux côtés.

## 6bis. Comment reprendre le fil (pour toute conversation)

1. `git pull` avant de commencer
2. Lire ce fichier en entier + les dernières entrées de `CHANGELOG.md`
3. Travailler uniquement dans son périmètre (section 7)
4. Mettre à jour ce fichier (sections 3, 4 et 7 si besoin) avant de pousser
   le dernier commit de la session

