import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Compte mémorisé localement sur l'appareil pour un accès rapide à la
/// connexion — inspiré du sélecteur de comptes de Facebook/Meta, mais
/// SANS mot de passe stocké : taper sur un compte pré-remplit juste
/// l'email, le mot de passe reste toujours nécessaire. Un vrai "1 tap,
/// sans mot de passe" comme Facebook nécessiterait de garder plusieurs
/// sessions Supabase actives en parallèle sur l'appareil (jetons stockés
/// localement) — plus complexe et plus sensible côté sécurité, volontairement
/// pas fait ici sans décision explicite.
class RecentAccount {
  final String email;
  final String? fullName;
  final String? avatarUrl;

  const RecentAccount({required this.email, this.fullName, this.avatarUrl});

  Map<String, dynamic> toJson() => {
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
      };

  factory RecentAccount.fromJson(Map<String, dynamic> json) => RecentAccount(
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class RecentAccountsStore {
  static const _prefsKey = 'akorahub_recent_accounts';
  static const _maxAccounts = 4;

  static Future<List<RecentAccount>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? [];
      return raw
          .map((s) => RecentAccount.fromJson(
              jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ajoute/déplace ce compte en tête de liste (le plus récent en premier),
  /// dédupliqué par email, plafonné à [_maxAccounts].
  static Future<void> remember(RecentAccount account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await load();
      current.removeWhere(
          (a) => a.email.toLowerCase() == account.email.toLowerCase());
      current.insert(0, account);
      final capped = current.take(_maxAccounts).toList();
      await prefs.setStringList(
        _prefsKey,
        capped.map((a) => jsonEncode(a.toJson())).toList(),
      );
    } catch (_) {
      // Non bloquant : la connexion réussit même si la mémorisation échoue.
    }
  }

  static Future<void> forget(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await load();
      current.removeWhere((a) => a.email.toLowerCase() == email.toLowerCase());
      await prefs.setStringList(
        _prefsKey,
        current.map((a) => jsonEncode(a.toJson())).toList(),
      );
    } catch (_) {
      // Non bloquant.
    }
  }
}
