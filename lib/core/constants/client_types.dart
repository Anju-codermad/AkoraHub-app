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
