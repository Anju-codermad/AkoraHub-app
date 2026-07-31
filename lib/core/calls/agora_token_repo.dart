import '../supabase/supabase_config.dart';

/// Récupère un token Agora RTC pour rejoindre un canal — le certificat
/// Agora ne doit jamais être présent côté client, seule l'Edge Function
/// `super-endpoint` y a accès (contenu = "generate-agora-token", nom
/// imposé par le Dashboard lors du déploiement, comme pour
/// hyper-endpoint/secure-login — voir supabase/functions/super-endpoint/index.ts).
class AgoraTokenRepo {
  AgoraTokenRepo._();

  static Future<({String appId, String token})> fetchToken(
      String channelName) async {
    final response = await SupabaseConfig.client.functions.invoke(
      'super-endpoint',
      body: {'channelName': channelName},
    );
    final data = response.data as Map;
    if (data['token'] == null || data['appId'] == null) {
      throw Exception(data['error'] as String? ?? 'Token indisponible');
    }
    return (appId: data['appId'] as String, token: data['token'] as String);
  }
}
