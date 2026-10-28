import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Identifiant d'appareil stable, généré une seule fois et conservé en
/// local (survit aux redémarrages de l'app, mais pas à une réinstallation
/// — c'est voulu : une réinstallation légitime doit pouvoir "reprendre la
/// main" sur les formations comme un nouvel appareil, voir
/// course_content_screen.dart et supabase/phase279_patch_formation_single_device.sql).
class DeviceId {
  DeviceId._();

  static const _prefsKey = 'akorahub_device_id';
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_prefsKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_prefsKey, id);
    }
    _cached = id;
    return id;
  }
}
