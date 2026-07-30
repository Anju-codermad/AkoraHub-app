import 'dart:io';

import '../supabase/supabase_config.dart';

/// Résultat d'un upload de pièce jointe, prêt à insérer dans `messages`
/// (voir `supabase/phase30_patch_message_attachments.sql`).
class ChatAttachmentUpload {
  final String path;
  final String type;
  final String? name;
  final int? durationMs;

  const ChatAttachmentUpload({
    required this.path,
    required this.type,
    this.name,
    this.durationMs,
  });
}

/// Upload d'une pièce jointe de messagerie vers le bucket privé
/// `chat-attachments` (participants de la conversation uniquement) et
/// génération d'URL signées temporaires pour l'affichage.
class ChatAttachmentService {
  ChatAttachmentService._();

  static Future<ChatAttachmentUpload> upload({
    required String conversationId,
    required File file,
    required String type,
    String? name,
    int? durationMs,
  }) async {
    final ext = file.path.contains('.') ? file.path.split('.').last : 'bin';
    final path =
        '$conversationId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await SupabaseConfig.client.storage
        .from('chat-attachments')
        .upload(path, file);
    return ChatAttachmentUpload(
      path: path,
      type: type,
      name: name,
      durationMs: durationMs,
    );
  }

  /// URL signée temporaire (1h) pour afficher/lire une pièce jointe déjà
  /// uploadée — le bucket étant privé, une URL publique ne fonctionnerait
  /// pas.
  static Future<String> signedUrl(String path) {
    return SupabaseConfig.client.storage
        .from('chat-attachments')
        .createSignedUrl(path, 3600);
  }
}
