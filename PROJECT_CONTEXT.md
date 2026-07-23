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
  (`product_management_real/`)
- Stock + lots de production avec DLC (`production_batches`)
- Facturation PDF (`invoicing/`)
- Alertes stock bas / DLC proche (`alerts_center/`)
- Commandes et Clients réels (`order_management_real/`,
  `customer_management_real/`)
- Analytics réel (`analytics_dashboard_real/`) — remplace l'ancien mock
- Profil entreprise (`business_profile_settings/`) — sauvegarde réelle dans
  `company_settings` (table singleton avec colonne JSONB)

### Phase 2 — Catalogue & Commande client
- Espace client dédié (`client_home/`) avec navigation par onglets :
  Catalogue, Panier, Commandes, Mur (social), Profil
- Catalogue avec navigation Pilier → Catégorie → Recherche
  (`client_home/catalog_tab.dart`) — design inspiré de Gojek (bannière +
  grille de piliers en icônes)
- Panier multi-produits (`client_home/cart_tab.dart`)
- Commande directe OU demande de devis (les deux créent respectivement une
  ligne dans `orders`/`order_items` ou `quotes`/`quote_items`)
- Suivi de commande à 4 statuts + "Recommander en 1 clic"
  (`client_home/orders_tab.dart`)

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

## 6. Si deux conversations Claude travaillent en parallèle sur ce projet

- Toujours faire un `git pull` avant de commencer à modifier des fichiers,
  pour éviter d'écraser le travail de l'autre conversation
- Se répartir des fichiers/fonctionnalités clairement distincts plutôt que de
  toucher aux mêmes écrans en même temps
- Mettre à jour ce document (section 3 et 4) après toute fonctionnalité
  significative ajoutée, pour que la prochaine conversation reste à jour
