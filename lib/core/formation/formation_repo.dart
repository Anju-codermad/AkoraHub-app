import '../supabase/supabase_config.dart';

/// Accès Formation "achat par produit" (voir
/// supabase/phase45_patch_formation_per_product_pricing.sql) — chaque
/// matière première s'achète individuellement, à vie (accès permanent,
/// pas de renouvellement), avec un tarif dégressif selon le nombre total
/// de produits déjà achetés (validés) par le client. Remplace l'ancien
/// modèle d'abonnement global (Phase 40, mensuel/annuel) — aucune
/// migration de données n'a été nécessaire, personne n'avait encore payé.
///
/// Paiement manuel (référence + preuve), validé par le staff — même
/// principe que les commandes et l'ancien abonnement.
class FormationRepo {
  FormationRepo._();

  /// IDs des matières premières déjà achetées (validées) par le client
  /// connecté — vide si aucun achat ou non connecté.
  static Future<Set<String>> fetchMyPurchasedIds() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('formation_purchases')
          .select('raw_material_id')
          .eq('customer_id', userId)
          .eq('status', 'validee');
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['raw_material_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// IDs déjà demandés mais pas encore validés par le staff — pour ne
  /// pas re-proposer à l'achat un produit déjà en attente.
  static Future<Set<String>> fetchMyPendingIds() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('formation_purchases')
          .select('raw_material_id')
          .eq('customer_id', userId)
          .eq('status', 'en_attente');
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['raw_material_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Historique complet des demandes d'achat du client connecté (tous
  /// statuts), avec le nom du produit — pour l'écran "Mes accès" (02/08 :
  /// l'utilisatrice ne retrouvait pas ses achats en attente ni côté
  /// client ni côté admin, cet écran donne au client une vue directe et
  /// transparente sur ce qu'il a demandé).
  static Future<List<Map<String, dynamic>>> fetchMyPurchases() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('formation_purchases')
          .select('*, raw_materials(name, category_name)')
          .eq('customer_id', userId)
          .order('requested_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  /// Paliers de prix, triés du plus petit au plus grand seuil.
  static Future<List<Map<String, dynamic>>> fetchPricingTiers() async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('formation_pricing_tiers')
          .select()
          .order('min_quantity');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  /// Prix unitaire applicable pour un achat de [quantity] produits,
  /// sachant que le client en possède déjà [alreadyOwned] (validés) — le
  /// palier se calcule sur le total cumulé (déjà possédés + ceux de cet
  /// achat), et s'applique à la totalité de l'achat en cours.
  static num unitPriceForPurchase({
    required List<Map<String, dynamic>> tiers,
    required int alreadyOwned,
    required int quantity,
  }) {
    if (tiers.isEmpty) return 0;
    final cumulative = alreadyOwned + quantity;
    num price = (tiers.first['price'] as num);
    for (final tier in tiers) {
      final minQty = tier['min_quantity'] as int;
      if (cumulative >= minQty) {
        price = tier['price'] as num;
      }
    }
    return price;
  }

  /// Soumet une demande d'achat pour un ou plusieurs produits en une
  /// seule fois (regroupés par `batch_id` pour que l'Admin les
  /// valide/refuse ensemble). `upsert` gère aussi bien un premier achat
  /// qu'une re-soumission après refus (la policy RLS
  /// `formation_purchases_resubmit_own_refused` n'autorise ce dernier cas
  /// que si la ligne existante est au statut 'refusee').
  static Future<void> requestPurchase({
    required List<String> rawMaterialIds,
    required num unitPrice,
    required String paymentMethodId,
    String? paymentReference,
    String? paymentProofPath,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non connecté.');
    final batchId = 'FORM-${DateTime.now().millisecondsSinceEpoch}';
    await SupabaseConfig.client.from('formation_purchases').upsert(
      [
        for (final id in rawMaterialIds)
          {
            'customer_id': userId,
            'raw_material_id': id,
            'batch_id': batchId,
            'amount': unitPrice,
            'status': 'en_attente',
            'payment_method': paymentMethodId,
            'payment_reference': paymentReference,
            'payment_proof_path': paymentProofPath,
          },
      ],
      onConflict: 'customer_id,raw_material_id',
    );
  }
}
