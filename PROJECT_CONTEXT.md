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
  client + localisation + icônes panier/notifications, cette dernière est
  un stub visuel sans backend), bannière promo en **carrousel** (3 slides,
  `PageView` + indicateurs), piliers ("Nos activités") affichés en **icônes
  rondes colorées** défilantes horizontalement (remplace l'ancienne grille
  rectangulaire — icônes mappées par mot-clé dans le `slug` du pilier :
  paint→pinceau, formation→école, chimie/chemical→science,
  cosmet→spa, insecticide/insect→pest_control, sinon icône générique
  ménage), cartes produits avec prix mis en avant et bouton **"+"
  vert d'ajout rapide au panier** (utilise les prix de base du produit —
  pour un produit à variantes, ce prix peut différer de la variante
  réellement choisie ; ouvrir la fiche produit reste nécessaire pour un prix
  exact). Design inspiré de deux références visuelles fournies par
  l'utilisateur (grocery app + service app before/after).
  **Piliers supplémentaires évoqués par l'utilisateur** (à créer par
  l'Admin via l'écran de gestion des piliers, pas encore créés) : matières
  premières chimiques, produits cosmétiques, produits insecticides — noms
  et slugs suggérés en attente de validation utilisateur.
- Panier multi-produits (`client_home/cart_tab.dart`)
- Commande directe OU demande de devis (les deux créent respectivement une
  ligne dans `orders`/`order_items` ou `quotes`/`quote_items`)
- Suivi de commande à 4 statuts + "Recommander en 1 clic"
  (`client_home/orders_tab.dart`)
- Profil client réel (`client_home/profile_tab.dart`) — remplace l'ancien
  écran minimal (email + logout). Affiche nom, société, secteur, téléphone,
  localisation, avatar (table `profiles`), avec formulaire d'édition en
  bottom sheet et upload d'avatar vers le bucket Storage `avatars`
  (policies dans `supabase/phase4_patch_avatars.sql`, **script exécuté avec
  succès par l'utilisateur dans Supabase — bucket créé, fonctionnel**).
  **Reste à faire sur ce même écran** : section
  "Mes publications" listant les posts du Mur de l'utilisateur, et
  statistiques personnelles (nb commandes, avis, ancienneté) — voir plan en
  4 étapes discuté avec l'utilisateur, étapes 3 et 4 pas encore commencées.
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
  si absentes) — **reste à faire** : brancher la capture de
  latitude/longitude côté commande dans le flux panier/checkout
  (`cart_tab.dart`), la colonne existe mais n'est pas encore alimentée à la
  création d'une commande.
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

### Phase 4 — Variantes produit
- Chaque produit peut avoir des **variantes** = combinaison Format × Parfum,
  chacune avec son propre prix Gros/Détail et son propre stock
  (`product_variants` table + `product_management_real/product_variants_screen.dart`
  côté Admin, sélection en 2 menus déroulants côté client dans
  `product_detail_client.dart`)
- Formats et Parfums sont des **listes de référence pré-remplies** (contrairement
  aux piliers/sous-catégories qui restent vides par défaut) — extensibles
  directement depuis les écrans concernés

## 3bis. Suggestions d'amélioration côté client (évoquées, pas encore décidées)

Idées discutées avec l'utilisateur, à prioriser plus tard — aucune n'est
commencée sauf mention contraire :

- **Favoris** : marquer des produits pour les retrouver rapidement (aucune
  table ni UI actuellement)
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
- **Filtre de recherche avancé** sur le catalogue (prix, disponibilité,
  pilier) — au-delà des chips de catégorie actuelles
- **Mode sombre**
- **Localisation automatique** — Niveau 1 fait, Niveau 2 (coordonnées GPS
  précises) documenté ci-dessus dans la section Profil

## 4. Ce qui N'EST PAS encore fait

- **Sous-catégories structurées** par pilier (actuellement un simple champ
  texte libre `category` sur chaque produit) — fonctionnalité discutée mais
  reportée, l'utilisateur doit encore préciser exactement comment il la veut
- **Messagerie unifiée** client ↔ commercial (prévue dans le cahier des
  charges original, jamais construite)
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

