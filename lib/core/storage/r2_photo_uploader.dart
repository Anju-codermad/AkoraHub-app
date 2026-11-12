import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../supabase/supabase_config.dart';

/// Upload/suppression des photos produit sur Cloudflare R2 au lieu de
/// Supabase Storage — demande explicite de la propriétaire (12/10), pour
/// faire baisser le "Cached Egress" Supabase (quota gratuit dépassé).
///
/// Remplace les appels directs à
/// `SupabaseConfig.client.storage.from('products')` dans
/// `product_management_real.dart` et `product_variants_screen.dart`.
/// Passe par l'Edge Function `r2-product-photo` (voir
/// supabase/functions/r2-product-photo/index.ts) : le client n'a jamais
/// les identifiants R2 en clair, seulement une URL d'upload signée et
/// temporaire.
///
/// ⚠️ Nom de fonction : le Dashboard Supabase a déjà renommé
/// aléatoirement des fonctions lors du déploiement par le passé
/// (super-endpoint/hyper-endpoint, voir ces fichiers) — si ça arrive à
/// nouveau ici, mettre à jour `_functionName` ci-dessous avec le nom
/// réellement déployé.
class R2PhotoUploader {
  R2PhotoUploader._();

  static const _functionName = 'r2-product-photo';

  /// Edge Function qui incruste le filigrane Groupe Akora (12/11, voir
  /// supabase/functions/watermark-product-photos). Même remarque que
  /// `_functionName` si le Dashboard la déploie sous un autre nom.
  static const watermarkFunctionName = 'watermark-product-photos';

  /// Upload un fichier local vers R2 et renvoie son URL publique.
  /// [fileName] = chemin relatif dans le bucket (ex.
  /// `$productId/${DateTime.now().millisecondsSinceEpoch}_0.jpg`).
  ///
  /// [watermark] = true pour les photos PRODUIT (demande explicite du
  /// 12/11) : la photo envoyée est ensuite recopiée avec le filigrane
  /// Groupe Akora incrusté, et c'est l'URL de cette copie qui est
  /// renvoyée (la photo d'origine reste sur R2, jamais supprimée). Si le
  /// filigrane échoue (fonction pas encore déployée, format illisible...),
  /// l'URL d'origine est renvoyée pour ne jamais bloquer l'enregistrement
  /// du produit — le bouton "Ajouter le filigrane" de l'écran Produits la
  /// rattrapera ensuite.
  static Future<String> upload({
    required File file,
    required String fileName,
    String contentType = 'image/jpeg',
    bool watermark = false,
  }) async {
    final presign = await SupabaseConfig.client.functions.invoke(
      _functionName,
      body: {
        'action': 'presign-upload',
        'fileName': fileName,
        'contentType': contentType,
      },
    );
    final data = presign.data as Map;
    final uploadUrl = data['uploadUrl'] as String?;
    final publicUrl = data['publicUrl'] as String?;
    if (uploadUrl == null || publicUrl == null) {
      throw Exception(
          data['error'] as String? ?? 'URL d\'upload R2 indisponible');
    }

    final Uint8List bytes = await file.readAsBytes();
    final putResponse = await http.put(
      Uri.parse(uploadUrl),
      body: bytes,
      headers: {'Content-Type': contentType},
    );
    if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
      throw Exception('Échec de l\'envoi vers R2 (${putResponse.statusCode})');
    }
    if (!watermark) return publicUrl;
    try {
      final wm = await SupabaseConfig.client.functions.invoke(
        watermarkFunctionName,
        body: {'action': 'watermark-one', 'imageUrl': publicUrl},
      );
      final wmUrl = (wm.data as Map?)?['publicUrl'] as String?;
      return (wmUrl != null && wmUrl.isNotEmpty) ? wmUrl : publicUrl;
    } catch (_) {
      return publicUrl;
    }
  }

  /// Supprime un fichier sur R2 à partir de son URL publique (best-effort
  /// — à appeler dans un try/catch, une suppression échouée ne doit
  /// jamais bloquer le reste de l'opération).
  static Future<void> delete(String imageUrl) async {
    await SupabaseConfig.client.functions.invoke(
      _functionName,
      body: {'action': 'delete', 'imageUrl': imageUrl},
    );
  }
}
