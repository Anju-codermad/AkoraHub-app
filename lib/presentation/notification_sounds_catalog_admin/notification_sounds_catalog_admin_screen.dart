import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/notifications/notification_sound_catalog_repo.dart';
import '../../core/notifications/notification_sounds.dart';

/// Gestion (Admin) du catalogue de sons proposés à TOUT LE MONDE (client
/// et staff) dans "Sons de notification" — réordonner et masquer les
/// sons par catégorie. On ne peut pas ajouter de nouveau fichier son
/// arbitraire (limite Android/iOS : le son d'un canal de notification
/// doit être une ressource intégrée à l'app à la compilation) — seulement
/// curer les 20 déjà intégrés. Écriture protégée côté serveur par
/// `current_role_is_admin()` (phase32) ; visible dans le menu staff
/// (`more_menu_screen.dart`) pour tous les rôles, comme "Modes de
/// paiement", la RLS étant la vraie barrière.
class NotificationSoundsCatalogAdminScreen extends StatefulWidget {
  const NotificationSoundsCatalogAdminScreen({super.key});

  @override
  State<NotificationSoundsCatalogAdminScreen> createState() =>
      _NotificationSoundsCatalogAdminScreenState();
}

class _NotificationSoundsCatalogAdminScreenState
    extends State<NotificationSoundsCatalogAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _player = AudioPlayer();
  final Map<NotificationCategory, List<SoundCatalogEntry>> _entries = {};
  bool _isLoading = true;
  String? _error;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: NotificationCategory.values.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      for (final category in NotificationCategory.values) {
        _entries[category] =
            await NotificationSoundCatalogRepo.fullCatalog(category);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Impossible de charger le catalogue de sons.';
        });
      }
    }
  }

  Future<void> _preview(String soundId) async {
    try {
      setState(() => _playingId = soundId);
      await _player.stop();
      await _player.play(AssetSource('$soundId.wav'));
    } catch (_) {
      // Aperçu indisponible — pas bloquant.
    }
  }

  Future<void> _toggle(
      NotificationCategory category, SoundCatalogEntry entry) async {
    final newEnabled = !entry.enabled;
    setState(() {
      _entries[category] = _entries[category]!
          .map((e) => e.soundId == entry.soundId
              ? SoundCatalogEntry(
                  soundId: e.soundId,
                  sortOrder: e.sortOrder,
                  enabled: newEnabled)
              : e)
          .toList();
    });
    try {
      await NotificationSoundCatalogRepo.setEnabled(
          category, entry.soundId, newEnabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la mise à jour.')),
      );
      _load();
    }
  }

  Future<void> _reorder(
      NotificationCategory category, int oldIndex, int newIndex) async {
    setState(() {
      final list = List<SoundCatalogEntry>.from(_entries[category]!);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      _entries[category] = list;
    });
    try {
      await NotificationSoundCatalogRepo.reorder(
        category,
        _entries[category]!.map((e) => e.soundId).toList(),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la réorganisation.')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byId = {for (final s in kNotificationSounds) s.id: s};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les sons de notification'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            for (final c in NotificationCategory.values) Tab(text: c.label),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    for (final category in NotificationCategory.values)
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Text(
                              'Glissez pour réordonner. Décochez un son pour '
                              'le retirer du choix proposé à tout le monde '
                              'dans cette catégorie.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ReorderableListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              itemCount: _entries[category]!.length,
                              onReorder: (oldIndex, newIndex) =>
                                  _reorder(category, oldIndex, newIndex),
                              itemBuilder: (context, index) {
                                final entry = _entries[category]![index];
                                final sound = byId[entry.soundId];
                                return Card(
                                  key:
                                      ValueKey('${category.id}-${entry.soundId}'),
                                  child: ListTile(
                                    leading: IconButton(
                                      icon: Icon(
                                        _playingId == entry.soundId
                                            ? Icons.volume_up
                                            : Icons.play_arrow,
                                        color: theme.colorScheme.primary,
                                      ),
                                      onPressed: () => _preview(entry.soundId),
                                    ),
                                    title: Text(
                                      sound?.label ?? entry.soundId,
                                      style: TextStyle(
                                        color: entry.enabled
                                            ? null
                                            : theme.colorScheme.outline,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: entry.enabled,
                                          onChanged: (_) =>
                                              _toggle(category, entry),
                                        ),
                                        const Icon(Icons.drag_handle),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
    );
  }
}
