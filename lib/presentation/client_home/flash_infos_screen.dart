import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Remplace `{nom}` dans un message flash info par le nom du client qui
/// regarde (voir catalog_tab.dart pour la même logique côté bannière
/// Accueil) — un message générique "à tout le monde" devient personnalisé.
String _personalize(String message, String? name) {
  final trimmed = name?.trim();
  return message.replaceAll(
      '{nom}', (trimmed != null && trimmed.isNotEmpty) ? trimmed : 'cher client');
}

/// Historique complet des Flash infos (annonces courtes de l'Admin),
/// accessible en tapant le bandeau affiché sur l'Accueil
/// (`catalog_tab.dart`). Lecture seule côté client — publication
/// réservée à l'Admin (`flash_infos_management.dart`).
class FlashInfosScreen extends StatefulWidget {
  const FlashInfosScreen({super.key});

  @override
  State<FlashInfosScreen> createState() => _FlashInfosScreenState();
}

class _FlashInfosScreenState extends State<FlashInfosScreen> {
  List<Map<String, dynamic>> _infos = [];
  bool _isLoading = true;
  String? _error;
  String? _clientName;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('flash_infos')
            .select()
            .eq('active', true)
            .or('expires_at.is.null,expires_at.gt.$nowIso')
            .order('created_at', ascending: false),
        if (userId != null)
          SupabaseConfig.client
              .from('profiles')
              .select('full_name')
              .eq('id', userId)
              .maybeSingle(),
      ]);
      final data = results[0];
      final profile =
          results.length > 1 ? results[1] as Map<String, dynamic>? : null;
      setState(() {
        _infos = List<Map<String, dynamic>>.from(data);
        _clientName = profile?['full_name'] as String?;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les flash infos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Flash infos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _infos.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            const Center(
                                child: Text('Aucune annonce pour le moment.')),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _infos.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, index) {
                            final info = _infos[index];
                            final createdAt =
                                DateTime.tryParse(info['created_at'] ?? '');
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.campaign_outlined,
                                    color: theme.colorScheme.primary),
                                title: Text(_personalize(
                                    info['message'] ?? '', _clientName)),
                                subtitle: createdAt != null
                                    ? Text(_dateFormat.format(
                                        createdAt.toLocal()))
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
