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

/// Prix ET unité affichés ENSEMBLE, calculés depuis la MÊME variante la
/// moins chère (27/10, correctif — signalé par l'utilisatrice : certains
/// produits affichaient le prix pour 1 kg avec un libellé "/100 g" ou
/// "/100 ml", ou l'inverse). Cause : le prix venait de
/// `products.price_detail` (colonne du produit, mise à jour une seule
/// fois lors du backfill phase185) tandis que l'unité venait, elle, de
/// [unitLabelFromEmbeddedVariants] — recalculée à chaque chargement à
/// partir des VRAIES variantes actuelles. Si une variante est ajoutée/
/// repriced après ce backfill (ex. un format 100 g moins cher ajouté à un
/// produit qui n'avait qu'un 1 kg), `price_detail` du produit devient
/// périmé : le prix affiché ne correspond plus à l'unité affichée à côté.
/// En prenant les deux depuis la même variante, elles ne peuvent plus se
/// désynchroniser. `fallbackPrice` (le `price_detail` du produit) n'est
/// utilisé que si le produit n'a aucune variante embarquée.
({num price, String? unitSuffix}) cheapestVariantPriceAndUnit(
    dynamic variantsRaw, num? fallbackPrice) {
  if (variantsRaw is! List || variantsRaw.isEmpty) {
    return (price: fallbackPrice ?? 0, unitSuffix: null);
  }
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
  if (cheapest == null) return (price: fallbackPrice ?? 0, unitSuffix: null);
  final formats = cheapest['formats'];
  final name = formats is Map ? formats['name'] as String? : null;
  return (
    price: cheapestPrice ?? 0,
    unitSuffix: unitSuffixFromFormatName(name),
  );
}

/// Liste des formats disponibles pour un produit (ex. ["1 kg", "5 kg",
/// "25 kg"]) à partir des `product_variants` embarqués par PostgREST —
/// même source que [unitLabelFromEmbeddedVariants], mais sans se limiter
/// à la variante la moins chère (20/10, demande explicite : afficher les
/// formats disponibles directement sur la fiche du catalogue, pas
/// seulement dans le détail produit). Triés du moins cher au plus cher,
/// dédupliqués (plusieurs variantes — parfum, couleur... — peuvent
/// partager le même format).
List<String> availableFormatLabels(dynamic variantsRaw) {
  if (variantsRaw is! List || variantsRaw.isEmpty) return const [];
  final byName = <String, num>{};
  for (final v in variantsRaw) {
    if (v is! Map) continue;
    final formats = v['formats'];
    final name = formats is Map ? formats['name'] as String? : null;
    if (name == null || name.isEmpty) continue;
    final price = (v['price_detail'] as num?) ?? 0;
    final existing = byName[name];
    if (existing == null || price < existing) byName[name] = price;
  }
  final entries = byName.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return entries.map((e) => e.key).toList();
}

/// Éclate chaque produit ayant plusieurs parfums (ou, pour l'Eau de
/// Javel/Peroxyde, plusieurs concentrations — voir
/// `phase179_patch_variantes_concentration_javel_peroxyde.sql`) en
/// autant de cartes de catalogue distinctes, une par parfum/
/// concentration (26/10, demande explicite : les variantes ne doivent
/// plus être cachées derrière le sélecteur de la fiche produit, chaque
/// parfum doit apparaître directement dans la grille). Un produit sans
/// parfum/concentration multiple (un seul, ou aucun) reste une seule
/// carte, strictement inchangée.
///
/// Nécessite que `product_variants` soit embarqué avec `parfum_id,
/// parfums(name), concentration_id, concentrations(name)` en plus de
/// `price_detail, format_id, formats(name)` (voir
/// `product_catalog_tab.dart`). Chaque carte éclatée reprend :
/// - le prix le moins cher parmi SES variantes (pas celui du produit
///   entier, qui mélangerait les parfums) ;
/// - sa propre photo si une variante de ce parfum en a une (voir
///   `product_variants.image_url`, phase179), sinon la photo du produit ;
/// - un repère interne (`_heroTagSuffix`) pour que l'animation Hero ne
///   rentre pas en collision entre deux cartes du même produit affichées
///   côte à côte ;
/// - un repère de présélection (`_preselectParfumId`/
///   `_preselectConcentrationId`) lu par `ProductDetailClient` pour
///   ouvrir la fiche directement sur le bon parfum/la bonne
///   concentration, au lieu du premier variant trouvé.
List<Map<String, dynamic>> expandProductsByVariantAxis(
    List<Map<String, dynamic>> products) {
  final result = <Map<String, dynamic>>[];
  for (final product in products) {
    final variantsRaw = product['product_variants'];
    final variants = variantsRaw is List
        ? variantsRaw
            .whereType<Map>()
            .map((v) => Map<String, dynamic>.from(v))
            .toList()
        : <Map<String, dynamic>>[];

    final parfumIds = <String>{};
    final concentrationIds = <String>{};
    for (final v in variants) {
      final parfumId = v['parfum_id'] as String?;
      if (parfumId != null) parfumIds.add(parfumId);
      final concentrationId = v['concentration_id'] as String?;
      if (concentrationId != null) concentrationIds.add(concentrationId);
    }

    String? axisKey;
    Set<String>? axisIds;
    if (parfumIds.length >= 2) {
      axisKey = 'parfum_id';
      axisIds = parfumIds;
    } else if (concentrationIds.length >= 2) {
      axisKey = 'concentration_id';
      axisIds = concentrationIds;
    }

    if (axisKey == null || axisIds == null) {
      result.add(product);
      continue;
    }

    final axisTable = axisKey == 'parfum_id' ? 'parfums' : 'concentrations';
    for (final axisId in axisIds) {
      final matching = variants.where((v) => v[axisKey] == axisId).toList();
      if (matching.isEmpty) continue;

      Map<String, dynamic>? cheapestVariant;
      num? cheapestPrice;
      String? variantImage;
      for (final v in matching) {
        final price = (v['price_detail'] as num?) ?? 0;
        if (cheapestPrice == null || price < cheapestPrice) {
          cheapestPrice = price;
          cheapestVariant = v;
        }
        final img = v['image_url'] as String?;
        if (variantImage == null && img != null && img.trim().isNotEmpty) {
          variantImage = img;
        }
      }

      final axisRef = cheapestVariant?[axisTable];
      final axisName = axisRef is Map ? axisRef['name'] as String? : null;

      final entry = Map<String, dynamic>.from(product);
      entry['product_variants'] = matching;
      entry['price_detail'] = cheapestPrice ?? product['price_detail'];
      if (axisName != null && axisName.trim().isNotEmpty) {
        entry['name'] = '${product['name'] ?? ''} – $axisName';
      }
      if (variantImage != null) entry['image_url'] = variantImage;
      entry['_heroTagSuffix'] = axisId;
      if (axisKey == 'parfum_id') {
        entry['_preselectParfumId'] = axisId;
      } else {
        entry['_preselectConcentrationId'] = axisId;
      }
      result.add(entry);
    }
  }
  return result;
}
