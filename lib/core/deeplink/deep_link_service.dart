import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../presentation/client_home/product_detail_client.dart';
import '../supabase/supabase_config.dart';
import '../auth/global_auth_listener.dart';

/// Gère les liens produit partageables (`akorahub://produit/{id}`, 24/08)
/// — ouverts depuis la page publique docs/formation-access/produit.html
/// (bouton "Ouvrir dans l'app") quand l'app est déjà installée, ou depuis
/// n'importe quel lien collé/partagé (WhatsApp, Messenger...) une fois
/// l'app installée. Volontairement limité à ce seul cas pour l'instant —
/// pas de retour automatique sur le produit après une INSTALLATION
/// fraîche (nécessiterait Firebase Dynamic Links / Play Store, pas en
/// place), voir la discussion avec l'utilisatrice du 24/08.
class DeepLinkService {
  DeepLinkService._();

  static final _appLinks = AppLinks();
  static bool _listening = false;

  static void init() {
    if (_listening) return;
    _listening = true;

    // Lien qui a lancé l'app (app fermée, tapée depuis le navigateur).
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handle(uri);
    });

    // Lien reçu pendant que l'app tourne déjà (arrière-plan ou premier plan).
    _appLinks.uriLinkStream.listen(_handle);
  }

  static Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'akorahub' || uri.host != 'produit') return;
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (id == null || id.isEmpty || !SupabaseConfig.isConfigured) return;

    try {
      final product = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (product == null) return;

      final navigator = GlobalAuthListener.navigatorKey.currentState;
      if (navigator == null) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ProductDetailClient(product: product),
        ),
      );
    } catch (_) {
      // Produit introuvable/hors ligne, ou utilisateur pas encore connecté
      // (RLS bloque la lecture) — silencieux, l'app reste utilisable
      // normalement plutôt que d'afficher une erreur sur un lien externe.
    }
  }
}
