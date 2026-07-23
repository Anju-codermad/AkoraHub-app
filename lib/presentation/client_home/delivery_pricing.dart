import 'dart:math' as math;

/// Configuration tarifaire des frais de livraison — modèle "taxi rapide"
/// (prise en charge fixe + tarif au km, avec un minimum garanti), comme
/// discuté avec l'utilisateur.
///
/// IMPORTANT — valeurs actuellement en dur dans le code client :
/// - `minimum` = 4000 Ar, confirmé par l'utilisateur
/// - `depotLatitude`/`depotLongitude` = coordonnées réelles du dépôt
///   Akora Fanadiovana, Rue Seimad, Antananarivo 101 (confirmées par
///   l'utilisateur le 23/07).
/// - Pour rendre ces valeurs modifiables depuis l'Admin sans nouvelle
///   version de l'app, il faudrait les déplacer dans la colonne JSONB de
///   `company_settings` (déjà utilisée par `business_profile_settings`
///   côté Admin) et les lire ici via Supabase — travail noté pour la
///   session Backend/Infra dans PROJECT_CONTEXT.md.
class DeliveryPricing {
  /// Coordonnées du dépôt/entrepôt (point de départ du calcul).
  /// Rue Seimad, Antananarivo 101.
  static const double depotLatitude = -18.900360;
  static const double depotLongitude = 47.510128;

  static const double priseEnCharge = 3000; // Ar
  static const double tarifParKm = 800; // Ar/km
  static const double minimum = 4000; // Ar
  static const double facteurCorrection =
      1.4; // compense relief/routes de Tana vs vol d'oiseau

  /// Distance à vol d'oiseau en km entre deux points (formule de Haversine).
  static double haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // rayon terrestre moyen en km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);

  /// Distance corrigée (km) utilisée pour le calcul du tarif.
  static double correctedDistanceKm(double clientLat, double clientLon) {
    final rawKm =
        haversineKm(depotLatitude, depotLongitude, clientLat, clientLon);
    return rawKm * facteurCorrection;
  }

  /// Frais de livraison (Ar) pour une distance corrigée donnée.
  static double feeForDistance(double correctedKm) {
    final fee = priseEnCharge + (tarifParKm * correctedKm);
    return fee < minimum ? minimum : fee;
  }

  /// Calcule directement les frais à partir de la position du client.
  static double computeFee(double clientLat, double clientLon) {
    return feeForDistance(correctedDistanceKm(clientLat, clientLon));
  }
}
