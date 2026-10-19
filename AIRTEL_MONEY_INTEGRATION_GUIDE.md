# Guide d'intégration Airtel Money (Akora Pay)

Guide pratique pour intégrer l'API Collection d'Airtel Money (paiement par push USSD) dans un nouveau projet, basé sur l'intégration réelle déployée dans AkoraHub et sur la session de certification menée avec Airtel (Antsa, équipe Intégration AMCM).

Ce document couvre : le flux complet, les pièges rencontrés en conditions réelles, et comment tester/certifier une intégration auprès d'Airtel. Objectif : éviter de redécouvrir les mêmes problèmes sur le prochain projet.

## 1. Vue d'ensemble du flux

Un paiement Airtel Money ne se termine **jamais** dans la réponse de l'appel qui l'initie. Le flux a deux temps, découplés :

1. **Initiation** (synchrone) : votre backend envoie la demande de paiement à Airtel → le client reçoit un push USSD sur son téléphone pour saisir son PIN. La réponse HTTP de cet appel confirme seulement qu'Airtel a bien reçu la demande — **pas** que le client a payé.
2. **Confirmation** (asynchrone) : une fois que le client a répondu au push (payé, refusé, PIN faux, ou ignoré), Airtel notifie votre backend via un **callback webhook** signé, quelques secondes à quelques minutes plus tard.

```
Client clique "Payer"
   │
   ▼
Backend : POST /merchant/v1/payments/   ──────▶  Airtel envoie le push USSD au client
   │                                                      │
   ▼                                                      ▼
Réponse immédiate (juste "reçu")              Client saisit son PIN sur son téléphone
                                                           │
                                                           ▼
                                        Airtel appelle votre callback (webhook signé)
                                        avec le statut final : TS (succès) ou TF (échec)
                                                           │
                                                           ▼
                                        Backend met à jour la commande en base
```

Ne jamais considérer un paiement comme confirmé avant d'avoir reçu ce callback (ou, à défaut, vérifié via Transaction Enquiry — voir §5).

## 2. Prérequis côté Airtel

1. Créer un compte sur [developers.airtel.mg](https://developers.airtel.mg) et une application.
2. Récupérer **Client ID** et **Client Secret** (Mes Applications → Gestion des clés).
3. Configurer le **callback** (Mes Applications → Paramètres → Callback Authentication) : URL de votre endpoint webhook + activer pour récupérer la **clé privée de callback** (distincte du Client Secret — sert à vérifier la signature des notifications).
4. Demander l'accès à l'environnement **sandbox** (`openapiuat.airtel.mg`) pour développer, puis la **certification** (voir §6) avant le passage en production (`openapi.airtel.mg`).

## 3. Secrets / variables d'environnement

| Secret | Où l'obtenir | Usage |
|---|---|---|
| `AIRTEL_CLIENT_ID` | Portail développeur Airtel | Authentification OAuth2 |
| `AIRTEL_CLIENT_SECRET` | Portail développeur Airtel | Authentification OAuth2 |
| `AIRTEL_CALLBACK_PRIVATE_KEY` | Portail développeur Airtel (Callback Authentication) | Vérifier la signature des notifications reçues |
| `AIRTEL_API_BASE_URL` | — | `https://openapiuat.airtel.mg` (sandbox, défaut) ou `https://openapi.airtel.mg` (prod) |

Ne jamais committer ces valeurs dans le code — les stocker en secrets (Supabase : Dashboard → Edge Functions → Manage secrets, ou l'équivalent sur votre plateforme).

## 4. Étape par étape — initier un paiement

### 4.1 Authentification OAuth2

```
POST {AIRTEL_API_BASE_URL}/auth/oauth2/token
Content-Type: application/json

{ "client_id": "...", "client_secret": "...", "grant_type": "client_credentials" }
```

Récupère un `access_token` à utiliser en `Authorization: Bearer <token>` sur les appels suivants.

### 4.2 Envoyer la demande de paiement

```
POST {AIRTEL_API_BASE_URL}/merchant/v1/payments/
X-Country: MG
X-Currency: MGA
Authorization: Bearer <access_token>

{
  "reference": "CMD202610123",
  "subscriber": { "country": "MG", "currency": "MGA", "msisdn": "340874696" },
  "transaction": { "amount": 19157.5, "country": "MG", "currency": "MGA", "id": "<id généré>" }
}
```

**Contraintes à respecter (sources d'erreurs vécues) :**
- `msisdn` : **sans indicatif pays**, sans le `0` initial (`"340874696"`, pas `"+261340874696"` ni `"0340874696"`).
- `reference` : purement alphanumérique — Airtel rejette les tirets (`"CMD-2026-123"` → nettoyer en `"CMD2026123"`). La valeur affichée/stockée côté app peut garder son format lisible ; seule la valeur envoyée à Airtel doit être nettoyée.
- `transaction.id` : généré par vous (UUID), **sans tirets** — un UUID standard avec tirets a été rejeté ("ID de transaction invalide", statut TF). Utiliser `crypto.randomUUID().replace(/-/g, "")`.
- Conservez ce `transaction.id` associé à votre commande : c'est la seule clé pour relier le callback (§4.3) à la bonne commande.

Vérifiez `response.status.success === true` avant de considérer la demande comme "envoyée" — une erreur à cette étape (mauvais token, montant invalide, etc.) revient en synchrone ici, pas plus tard.

### 4.3 Recevoir la confirmation (callback webhook)

Airtel appelle votre endpoint public avec :

```json
{ "transaction": { "id": "...", "status_code": "TS", "airtel_money_id": "MP..." }, "hash": "<signature base64>" }
```

- `status_code` : `TS` = succès, `TF` = échec. Tout autre code est un état intermédiaire, à ignorer (ne rien faire avant TS/TF).
- **Vérifier la signature avant toute action** : `hash` = `Base64(HmacSHA256(JSON.stringify(transaction), AIRTEL_CALLBACK_PRIVATE_KEY))`. Comparer en temps constant (`timingSafeEqual`), jamais avec `===` direct, pour éviter les attaques par timing. Rejeter silencieusement (répondre `200 "ignored"`) toute requête dont la signature ne correspond pas — ne jamais renvoyer une erreur qui indiquerait à un attaquant ce qui a échoué, et jamais déclencher de retry infini sur une vraie requête Airtel en cas de bug de votre côté.
- Retrouvez la commande via `transaction.id` (celui que **vous** avez généré en §4.2, pas `airtel_money_id` qui est généré par Airtel) et mettez à jour son statut.

Référence complète : `supabase/functions/create-airtel-payment-request/index.ts` et `supabase/functions/airtel-payment-notification/index.ts` dans ce dépôt.

## 5. Transaction Enquiry (vérification manuelle)

En plus du callback, Airtel expose un endpoint de consultation, utile pour la réconciliation ou le diagnostic (c'est l'outil qu'on a utilisé pendant toute la certification) :

```
GET {AIRTEL_API_BASE_URL}/standard/v1/payments/{transaction_id}
X-Country: MG
X-Currency: MGA
Authorization: Bearer <access_token>
```

Retourne le même `status` (`TS`/`TF`) et un `message` lisible expliquant la raison d'un échec (PIN incorrect, solde insuffisant, compte bloqué, montant hors limites...).

**⚠️ Leçon la plus importante de toute la session de certification** : ni la réponse de l'appel d'initiation (§4.2), ni le message affiché sur le téléphone du client ("Thank you for confirming the PIN...") ne reflètent le résultat final — ce message générique apparaît **que le PIN soit correct ou non**. Le seul signal fiable est le callback (§4.3) ou, à défaut, cet appel d'Enquiry. Plusieurs cas de test qui semblaient "cassés" au premier abord (rejet non observé) se sont révélés corrects une fois vérifiés via Enquiry plutôt que via la réponse immédiate.

De même, "External application down" affiché côté téléphone au moment de la saisie du PIN est, dans notre expérience, souvent un glitch transitoire de l'appli USSD/SIM toolkit — pas forcément un échec réel. Ne jamais conclure sur ce seul message : toujours vérifier via Enquiry ou callback.

## 6. Pièges rencontrés pendant la certification

| Symptôme observé | Explication réelle |
|---|---|
| Le solde insuffisant (TC05) ne se déclenchait pas avec un "petit" montant | Ce n'est pas un seuil fixe documenté — le rejet se déclenche pour tout montant **supérieur au solde réel actuel** du compte de test. Demander le solde courant du numéro de test à Airtel plutôt que de deviner un seuil. |
| Numéro "barré" (TC02) : rejet avec message "PIN incorrect" au lieu d'un message de blocage | Le compte était en fait débloqué entre-temps (ex. après une réinitialisation de PIN) — un rejet pour mauvais PIN masque le vrai test. Toujours confirmer l'état du numéro juste avant de tester, et vérifier via Enquiry : le message explicite est bien différent ("vous ne pouvez pas effectuer cette transaction car votre compte est bloqué"). |
| Impossible de réinitialiser le PIN via `*1273#` | Le compte doit d'abord être débloqué côté Airtel avant que la réinitialisation USSD fonctionne — sinon message "visitez un Shop Airtel avec votre CIN". |
| Message de rejet différent du texte exact documenté dans la fiche de certification (ex. limites AML) | Le comportement (rejet, statut TF) peut être conforme même si le texte exact du message diffère de l'exemple de la fiche — se fier au `status_code`, pas uniquement au texte du message. |

## 7. Certification Airtel — check-list résumée

Avant la mise en production, Airtel demande de valider une série de cas de test (fiche "Developer Portal Test Case") sur l'environnement sandbox, avec un numéro de test dédié :

- **TC01** — Paiement avec solde suffisant (cas nominal)
- **TC02 / TC03** — Abonné bloqué / débloqué (nécessite qu'Airtel configure ces états sur le numéro de test, sur demande)
- **TC04** — Mauvais PIN
- **TC05** — Solde insuffisant (montant > solde réel du compte test)
- **TC06 / TC07** — Montant au-dessus / en dessous des limites autorisées
- **TC08 / TC10** — Montant zéro / négatif (doivent être rejetés immédiatement, en synchrone, par l'API elle-même)
- **TC09** — Montant décimal (doit être accepté)
- **TC12** — Abonné non enregistré sur Airtel Money
- **TC13** — Consultation de solde partenaire
- **TC14** — Push ignoré par le client (pas de saisie de PIN)

Pour chaque cas : noter le `status_code` et le message obtenus via Enquiry (pas seulement la réponse de l'appel d'initiation), avec l'`airtel_money_id` correspondant — c'est ce format qu'Airtel demande pour valider la certification.

## 8. Sécurité et bonnes pratiques

- Ne jamais committer `AIRTEL_CLIENT_SECRET` ni `AIRTEL_CALLBACK_PRIVATE_KEY` dans le dépôt.
- Les fonctions de diagnostic créées pour tester manuellement (appel direct à l'API avec un montant/numéro arbitraire, sans passer par une vraie commande) sont utiles pendant la certification mais **ne doivent jamais rester déployées en production** — à supprimer une fois la certification terminée.
- Toujours vérifier la signature du callback avant d'agir dessus (§4.3) — sans ça, n'importe qui connaissant un `transaction.id` pourrait forger une fausse confirmation de paiement.
- Utiliser `openapiuat.airtel.mg` en développement, et ne basculer sur `openapi.airtel.mg` qu'une fois l'application approuvée en production par Airtel.

## 9. Références

- Documentation officielle : developers.airtel.mg → Documentation → Collection APIs
- Implémentation de référence dans ce dépôt : `supabase/functions/create-airtel-payment-request/`, `supabase/functions/airtel-payment-notification/`
- Pour toute question de certification, contact Airtel : équipe Intégration AMCM (WhatsApp), suivi par email pour les livrables officiels (fiche de test remplie).
