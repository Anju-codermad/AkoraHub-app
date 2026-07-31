import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/notifications/notification_sound_catalog_repo.dart';
import '../../core/notifications/notification_sounds.dart';
import '../../core/notifications/push_notification_service.dart';

/// Choix du son de notification par catégorie (Messagerie/Devis/
/// Commandes) — réservoir commun de sons, n'importe lequel peut être
/// choisi pour n'importe quelle catégorie (demande explicite de
/// l'utilisateur). Chaque choix est sauvegardé en base
/// (`profiles.notification_sound_<catégorie>`, phase24) pour que le
/// serveur envoie le bon son même app fermée, et crée immédiatement le
/// canal Android correspondant (voir PushNotificationService).
class NotificationSoundsScreen extends StatefulWidget {
  const NotificationSoundsScreen({super.key});

  @override
  State<NotificationSoundsScreen> createState() =>
      _NotificationSoundsScreenState();
}

class _NotificationSoundsScreenState extends State<NotificationSoundsScreen> {
  final _player = AudioPlayer();
  final Map<NotificationCategory, String> _selected = {};
  final Map<NotificationCategory, List<NotificationSoundOption>> _options = {};
  bool _isLoading = true;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    for (final category in NotificationCategory.values) {
      _selected[category] =
          await PushNotificationService.getSoundPreference(category);
      // Ne propose que les sons que l'Admin n'a pas masqués pour cette
      // catégorie (voir notification_sounds_catalog_admin_screen.dart) —
      // repli sur la liste complète si le catalogue n'est pas configuré.
      _options[category] =
          await NotificationSoundCatalogRepo.visibleSounds(category);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _preview(String soundId) async {
    try {
      setState(() => _playingId = soundId);
      await _player.stop();
      await _player.play(AssetSource('$soundId.wav'));
    } catch (_) {
      // Aperçu indisponible (ex: fichier manquant) — pas bloquant, le
      // choix reste possible même sans pouvoir prévisualiser.
    }
  }

  Future<void> _select(NotificationCategory category, String soundId) async {
    setState(() => _selected[category] = soundId);
    await PushNotificationService.setSoundPreference(category, soundId);
    await _preview(soundId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sons de notification')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                Text(
                  'Choisissez un son différent pour chaque type de '
                  'notification. Appuyez sur ▶ pour écouter avant de '
                  'choisir.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 2.h),
                for (final category in NotificationCategory.values) ...[
                  Text(category.label, style: theme.textTheme.titleMedium),
                  SizedBox(height: 1.h),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final sound in _options[category]!) ...[
                          RadioListTile<String>(
                            value: sound.id,
                            groupValue: _selected[category],
                            title: Text(sound.label),
                            onChanged: (value) {
                              if (value != null) _select(category, value);
                            },
                            secondary: IconButton(
                              icon: Icon(
                                _playingId == sound.id
                                    ? Icons.volume_up
                                    : Icons.play_arrow,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () => _preview(sound.id),
                            ),
                          ),
                          if (sound != _options[category]!.last)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                ],
              ],
            ),
    );
  }
}
