import '../supabase/supabase_config.dart';

/// Récupère un token Agora RTC pour rejoindre un canal — le certificat
/// Agora ne doit jamais être présent côté client, seule l'Edge Function
/// `generate-agora-token` y a accès (voir ce fichier côté serveur).
class AgoraTokenRepo {
  AgoraTokenRepo._();

  static Future<({String appId, String token})> fetchToken(
      String channelName) async {
    final response = await SupabaseConfig.client.functions.invoke(
      'generate-agora-token',
      body: {'channelName': channelName},
    );
    final data = response.data as Map;
    if (data['token'] == null || data['appId'] == null) {
      throw Exception(data['error'] as String? ?? 'Token indisponible');
    }
    return (appId: data['appId'] as String, token: data['token'] as String);
  }
}
