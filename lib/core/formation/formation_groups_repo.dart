import 'dart:io';

import '../supabase/supabase_config.dart';

/// Groupes communautaires AkoraFormation par catégorie — voir
/// supabase/phase56_patch_formation_groups.sql. Version volontairement
/// simple (choisie explicitement, 02/08) : un fil de publications
/// texte/photo par catégorie, réservé aux clients ayant un achat de
/// cours VALIDÉ dans cette catégorie précise (`course_purchases`, Phase
/// 50) — pas de commentaires ni réactions pour cette première version.
/// La vraie protection ("seulement pour les participants") est la RLS,
/// pas un filtre côté app.
class FormationGroupsRepo {
  FormationGroupsRepo._();

  static String? get _myId => SupabaseConfig.client.auth.currentUser?.id;

  /// Catégories dont le client connecté est participant validé — pour
  /// l'écran "Mes groupes".
  static Future<List<String>> fetchMyGroupCategories() async {
    final uid = _myId;
    if (uid == null || !SupabaseConfig.isConfigured) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('course_purchases')
          .select('formation_courses(category)')
          .eq('customer_id', uid)
          .eq('status', 'validee');
      final categories = List<Map<String, dynamic>>.from(rows)
          .map((r) =>
              (r['formation_courses'] as Map?)?['category'] as String?)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      return categories;
    } catch (_) {
      return [];
    }
  }

  /// Toutes les catégories de cours existantes — pour l'écran Admin
  /// (le staff contourne la vérification "participant" via la RLS, mais
  /// a besoin de connaître la liste des catégories pour y accéder).
  static Future<List<String>> fetchAllCourseCategories() async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final rows =
          await SupabaseConfig.client.from('formation_courses').select('category');
      final categories = List<Map<String, dynamic>>.from(rows)
          .map((r) => r['category'] as String?)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      return categories;
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchGroupPosts(
      String category) async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('formation_group_posts')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  static Future<void> createGroupPost({
    required String category,
    required String content,
    File? image,
  }) async {
    final uid = _myId;
    if (uid == null) throw Exception('Non connecté.');
    String? imageUrl;
    if (image != null) {
      final fileName =
          '$uid/group_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseConfig.client.storage
          .from('wall-photos')
          .upload(fileName, image);
      imageUrl = SupabaseConfig.client.storage
          .from('wall-photos')
          .getPublicUrl(fileName);
    }
    await SupabaseConfig.client.from('formation_group_posts').insert({
      'category': category,
      'author_id': uid,
      'content': content,
      'image_url': imageUrl,
    });
  }

  static Future<void> updateGroupPost(String id, String content) async {
    await SupabaseConfig.client.from('formation_group_posts').update({
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> deleteGroupPost(String id) async {
    await SupabaseConfig.client
        .from('formation_group_posts')
        .delete()
        .eq('id', id);
  }
}
