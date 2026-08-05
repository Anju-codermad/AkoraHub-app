import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/chat/chat_bubble_settings_repo.dart';
import '../../core/chat/unread_support_messages.dart';
import 'chat_screen.dart';

/// Bulle de chat flottante, façon "chat head" Messenger — demande
/// explicite de l'utilisateur (capture d'une bulle similaire dans une
/// autre app). Enveloppe tout l'espace client (`ClientHome`) dans un
/// `Stack` : visible sur les 5 onglets (Accueil, Commandes, Académie,
/// Services, Profil), toujours au même endroit d'un onglet à l'autre
/// puisqu'elle vit au-dessus du `Scaffold` plutôt que dans chaque page.
/// Disparaît naturellement dès qu'un écran est poussé par-dessus
/// (fiche détail, chat lui-même...) car ceux-ci remplacent tout l'écran
/// via `Navigator.push` — aucune logique de masquage à gérer.
///
/// Redondant à dessein avec l'icône messagerie déjà présente dans
/// l'en-tête de l'Accueil (`catalog_tab.dart`) : celle-ci reste, la
/// bulle est un raccourci supplémentaire visible même hors de l'Accueil.
class FloatingChatBubble extends StatefulWidget {
  final Widget child;

  const FloatingChatBubble({super.key, required this.child});

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble> {
  static const _bubbleSize = 56.0;
  static const _dismissSize = 64.0;
  // Distance (centre à centre) en dessous de laquelle la bulle est
  // considérée "au-dessus" de la zone de suppression — assez large pour
  // ne pas obliger un geste pixel-perfect.
  static const _dismissHitRadius = 50.0;

  Offset? _position;
  int _unreadCount = 0;
  Timer? _pollTimer;
  bool _visible = true;
  // Glisser-déposer la bulle sur un ❌ en bas de l'écran pour la masquer
  // — demande explicite de l'utilisateur, capture d'une bulle similaire
  // (Messenger) à l'appui. Réutilise le masquage personnel déjà existant
  // (ChatBubbleSettingsRepo.setHiddenByClient), réactivable depuis
  // Paramètres, plutôt que d'inventer un 3e état.
  bool _dragging = false;
  bool _hoveringDismiss = false;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    _loadVisibility();
    // Simple polling (comme le badge de l'accueil, pas de flux temps réel
    // dédié) : suffisant pour une pastille qui n'a pas besoin d'être
    // instantanée à la seconde près.
    _pollTimer = Timer.periodic(
        const Duration(seconds: 25), (_) => _refreshUnreadCount());
  }

  /// La bulle ne s'affiche que si l'admin l'autorise globalement ET que
  /// le client ne l'a pas masquée pour lui-même (voir
  /// supabase/phase68_patch_chat_bubble_toggle.sql).
  Future<void> _loadVisibility() async {
    final results = await Future.wait([
      ChatBubbleSettingsRepo.isEnabledGlobally(),
      ChatBubbleSettingsRepo.isHiddenByClient(),
    ]);
    if (!mounted) return;
    setState(() => _visible = results[0] && !results[1]);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnreadCount() async {
    final count = await fetchUnreadSupportMessagesCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  Future<void> _openChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
    _refreshUnreadCount();
  }

  Offset _dismissCenter(Size screenSize) => Offset(
        screenSize.width / 2,
        screenSize.height - 24 - _dismissSize / 2,
      );

  void _onPanUpdate(DragUpdateDetails details, Size screenSize) {
    final next = _position! + details.delta;
    final clamped = Offset(
      next.dx.clamp(0, screenSize.width - _bubbleSize),
      next.dy.clamp(0, screenSize.height - _bubbleSize),
    );
    final bubbleCenter =
        clamped + const Offset(_bubbleSize / 2, _bubbleSize / 2);
    final hovering = (bubbleCenter - _dismissCenter(screenSize)).distance <
        _dismissHitRadius;
    setState(() {
      _position = clamped;
      _hoveringDismiss = hovering;
    });
  }

  Future<void> _onPanEnd() async {
    if (!_hoveringDismiss) {
      setState(() => _dragging = false);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _dragging = false;
      _hoveringDismiss = false;
      _visible = false;
    });
    await ChatBubbleSettingsRepo.setHiddenByClient(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Bulle de chat masquée — réactivable dans Paramètres.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;

    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    _position ??= Offset(
      screenSize.width - _bubbleSize - 16,
      screenSize.height - _bubbleSize - 140,
    );

    return Stack(
      children: [
        widget.child,
        if (_dragging)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _hoveringDismiss ? _dismissSize + 14 : _dismissSize,
                height: _hoveringDismiss ? _dismissSize + 14 : _dismissSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hoveringDismiss
                      ? theme.colorScheme.error
                      : Colors.black54,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 28),
              ),
            ),
          ),
        Positioned(
          left: _position!.dx,
          top: _position!.dy,
          child: GestureDetector(
            onPanStart: (_) => setState(() => _dragging = true),
            onPanUpdate: (details) => _onPanUpdate(details, screenSize),
            onPanEnd: (_) => _onPanEnd(),
            onTap: _openChat,
            child: AnimatedScale(
              scale: _hoveringDismiss ? 0.8 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: theme.colorScheme.primary,
                child: SizedBox(
                  width: _bubbleSize,
                  height: _bubbleSize,
                  child: Center(
                    child: Badge(
                      label: Text('$_unreadCount'),
                      isLabelVisible: _unreadCount > 0,
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
