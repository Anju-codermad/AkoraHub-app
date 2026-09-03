# Rapport — Migration de domaine & mise à jour de marque (Groupe Akora)

*Dernière mise à jour : 03/09/2026*

Ce document résume les changements récents pour que toute personne ou tout
outil travaillant sur ce dépôt (site web, application, automatisations)
soit au courant du nouveau nom de domaine et de la nouvelle identité
visuelle du site. Voir aussi `SITE_APP_SYNC.md` pour la logique dupliquée
entre le site et l'application.

## 1. Nouveau domaine : groupe-akora.com

- **Domaine principal du site vitrine** : `https://groupe-akora.com`
  (+ `https://www.groupe-akora.com`), acheté et géré via Cloudflare
  Registrar, connecté au projet Cloudflare Pages **`akorahub-app`**
  (dossier `docs/formation-access`).
- **Ancienne adresse** `https://akorahub-app.pages.dev` : reste active en
  parallèle (ne pas la supprimer), pour ne pas casser les anciens liens
  partagés/en favoris. Ne plus l'utiliser pour du nouveau contenu.
- Mis à jour dans le code du site : balises `canonical`, `og:url`,
  `og:image`, `twitter:image`, `sitemap.xml`, `robots.txt`, et l'image de
  repli dans `functions/_produit-og.js`.
- **⚠️ Non encore fait (à faire)** : l'application Flutter contient encore
  l'ancienne adresse en dur à 4 endroits (trouvé le 03/09/2026, pas encore
  corrigé) :
  - `lib/presentation/registration_screen/registration_screen.dart:36`
  - `lib/presentation/client_home/product_detail_client.dart:278`
  - `lib/presentation/client_home/catalog_tab.dart:1638`
  - `lib/core/utils/formation_web_link.dart:27`

  Prochaine étape : remplacer `https://akorahub-app.pages.dev` par
  `https://groupe-akora.com` dans ces 4 fichiers.

- Rappel : trois projets distincts partagent ce dépôt, ne pas les confondre :
  1. **Site vitrine** (`docs/formation-access`, Cloudflare Pages
     `akorahub-app`) → maintenant sur `groupe-akora.com`.
  2. **Application mobile AkoraHub** (`.apk`/`.aab`) → distribuée par lien
     de téléchargement direct + Firebase App Distribution, indépendante du
     domaine.
  3. **Admin web** (build Flutter web, Cloudflare Pages `akorahub-admin`)
     → adresse `.pages.dev` séparée, non concernée par ce changement.

## 2. Marque affichée : "Groupe Akora"

Le nom légal actuel de l'entreprise reste **Akora Fanadiovana** — un
changement de statut juridique vers "Groupe Akora" est prévu par la
propriétaire l'année prochaine, pas encore fait. En attendant, le site
distingue clairement :

**Changé en "Groupe Akora"** (identité visuelle/marketing uniquement) :
- Logo/texte de la barre de navigation et du pied de page (7 pages)
- Balises `<title>`, `og:site_name`, `og:title`, `twitter:title`
- Badge "eyebrow" au-dessus du titre sur la page d'accueil

**Resté "Akora Fanadiovana"** (référence légale/factuelle actuelle,
à ne pas changer avant le changement de statut juridique réel) :
- Données structurées JSON-LD (`Organization.name`) — doit rester
  cohérent avec la fiche Google Business et la page Facebook, toutes
  deux encore au nom "Akora Fanadiovana"
- Mentions légales de `privacy-policy.html` (identité de l'entreprise,
  nom de la page Facebook)
- Ligne de copyright (`© Akora Fanadiovana — Antananarivo, Madagascar`)
- Nom du titulaire Mvola dans les instructions de paiement
  (`formation.html`)
- Crédit du fondateur (`a-propos.html`)

**Ne pas modifier ces points isolément** en cas de futur renommage
marketing — attendre l'annonce du changement de statut juridique avant de
toucher à la liste "resté Akora Fanadiovana" ci-dessus.

## 3. Autres tâches liées, statut

- Lien "Site web" de la page Facebook : mis à jour vers
  `https://groupe-akora.com` ✅
- Google Search Console : propriétés `groupe-akora.com` et
  `www.groupe-akora.com` ajoutées, sitemap envoyé ✅
- Fiche Google Business ("Akora Fanadiovana") : validation de propriété
  en attente côté propriétaire (bouton "Valider" dans Google), puis
  ajout du site web `groupe-akora.com` — **pas encore fait**
- E-mail professionnel `contact@groupe-akora.com` (Cloudflare Email
  Routing, gratuit) : proposé, pas encore mis en place
