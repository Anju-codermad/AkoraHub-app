/// Dérive un suffixe d'unité lisible ("kg", "L", "Pièce", "25 kg"...) à
/// partir du nom d'un format (`formats.name`), pour afficher le prix comme
/// "8 000 Ar/kg" plutôt qu'un montant seul sans quantité (26/08, demande
/// explicite — un client s'est retrouvé à devoir demander "Atao firy kg ?"
/// après avoir reçu un lien de partage sans unité).
///
/// Les formats "1 kg"/"1 L" (l'unité de base, déjà le format présélectionné
/// par défaut ailleurs dans l'app — voir `_defaultVariantInKg`) donnent
/// juste le mot d'unité ("kg", "L") ; les autres conditionnements (ex.
/// "25 kg", "Bidon 20 L") gardent leur nom complet, faute de règle de
/// conversion fiable vers un prix "au kg"/"au litre".
String? unitSuffixFromFormatName(String? formatName) {
  final name = formatName?.trim();
  if (name == null || name.isEmpty) return null;
  final match = RegExp(r'^1\s+(.+)$').firstMatch(name);
  return match?.group(1) ?? name;
}

/// Même dérivation que [unitSuffixFromFormatName], mais à partir d'une
/// liste `product_variants` embarquée par PostgREST (`select('*,
/// product_variants(price_detail, formats(name))')`, voir
/// `product_catalog_tab.dart`/`catalog_tab.dart`) — prend le format de la
/// variante la MOINS CHÈRE, pour rester cohérent avec `price_detail` du
/// produit (déjà repris de cette même variante la moins chère depuis le
/// backfill phase185).
String? unitLabelFromEmbeddedVariants(dynamic variantsRaw) {
  if (variantsRaw is! List || variantsRaw.isEmpty) return null;
  Map<String, dynamic>? cheapest;
  num? cheapestPrice;
  for (final v in variantsRaw) {
    if (v is! Map) continue;
    final price = (v['price_detail'] as num?) ?? 0;
    if (cheapestPrice == null || price < cheapestPrice) {
      cheapestPrice = price;
      cheapest = Map<String, dynamic>.from(v);
    }
  }
  final formats = cheapest?['formats'];
  final name = formats is Map ? formats['name'] as String? : null;
  return unitSuffixFromFormatName(name);
}
