/// Secteurs d'activité possibles pour un compte client (`profiles.client_type`).
/// Liste élargie le 12/08 (demande explicite, validée par l'Admin) au-delà
/// des 4 valeurs d'origine (Particulier/Hôtel/Hôpital/Entreprise), pour que
/// chaque client choisisse son secteur réel plutôt que d'être forcé dans
/// "Entreprise" par défaut. Source unique utilisée par l'inscription, le
/// profil, et les écrans admin (filtres, données démographiques) — éviter
/// toute liste dupliquée qui finirait par diverger.
const List<Map<String, String>> kClientTypeOptions = [
  {'value': 'particulier', 'label': 'Particulier'},
  {'value': 'hotel', 'label': 'Hôtel'},
  {'value': 'hopital', 'label': 'Hôpital / Clinique'},
  {'value': 'restaurant', 'label': 'Restaurant / Bar'},
  {'value': 'ecole', 'label': 'École / Université'},
  {'value': 'entreprise', 'label': 'Entreprise / Bureau'},
  {'value': 'usine', 'label': 'Usine / Industrie'},
  {'value': 'pharmacie', 'label': 'Pharmacie'},
  {'value': 'salon_beaute', 'label': 'Salon de beauté / Coiffure'},
  {'value': 'commerce', 'label': 'Supermarché / Commerce'},
  {'value': 'administration', 'label': 'Administration publique'},
  {'value': 'ong', 'label': 'ONG / Association'},
  {'value': 'autre', 'label': 'Autre'},
];

final Map<String, String> kClientTypeLabels = {
  for (final option in kClientTypeOptions) option['value']!: option['label']!,
};

/// Catégories de produits (`products.category`, pilier Akora Home —
/// voir `kProductUsageSuggestionsByCategory` dans product_management_real.dart
/// pour la liste exacte des 10 noms) mises en avant pour chaque secteur
/// (13/08, demande explicite : "pondération par secteur" sur la section
/// aléatoire "Découvrez aussi" de l'accueil client). Volontairement pas
/// exhaustif ni exclusif : sert de PRIORITÉ dans le tirage côté base
/// (random_published_products, phase171), pas de filtre strict — un
/// secteur absent d'ici (ou "particulier"/"autre", trop génériques pour une
/// vraie préférence) retombe simplement sur un tirage sans biais.
const Map<String, List<String>> kSectorPreferredCategories = {
  'hotel': [
    'Sanitaire & Salle de Bain',
    'Lessive & Textile',
    'Vitres & Surfaces',
    'Désinfectants & Hygiène',
  ],
  'hopital': ['Désinfectants & Hygiène', 'Sanitaire & Salle de Bain'],
  'restaurant': [
    'Cuisine & Vaisselle',
    'Désinfectants & Hygiène',
    'Sanitaire & Salle de Bain',
  ],
  'ecole': [
    'Désinfectants & Hygiène',
    'Sanitaire & Salle de Bain',
    'Vitres & Surfaces',
  ],
  'entreprise': [
    'Vitres & Surfaces',
    'Sanitaire & Salle de Bain',
    'Désinfectants & Hygiène',
  ],
  'usine': [
    'Produits spécialisés',
    'Entretien Véhicules',
    'Désinfectants & Hygiène',
  ],
  'pharmacie': ['Désinfectants & Hygiène', 'Sanitaire & Salle de Bain'],
  'salon_beaute': ['Soins du Corps & Cosmétiques', 'Sanitaire & Salle de Bain'],
  'commerce': [
    'Vitres & Surfaces',
    'Sanitaire & Salle de Bain',
    'Cuisine & Vaisselle',
  ],
  'administration': [
    'Vitres & Surfaces',
    'Sanitaire & Salle de Bain',
    'Désinfectants & Hygiène',
  ],
};
