import 'dart:async';

import 'package:flutter/material.dart';

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
  Offset? _position;
  int _unreadCount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    // Simple polling (comme le badge de l'accueil, pas de flux temps réel
    // dédié) : suffisant pour une pastille qui n'a pas besoin d'être
    // instantanée à la seconde près.
    _pollTimer = Timer.periodic(
        const Duration(seconds: 25), (_) => _refreshUnreadCount());
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    const bubbleSize = 56.0;
    _position ??= Offset(
      screenSize.width - bubbleSize - 16,
      screenSize.height - bubbleSize - 140,
    );

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _position!.dx,
          top: _position!.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final next = _position! + details.delta;
                _position = Offset(
                  next.dx.clamp(0, screenSize.width - bubbleSize),
                  next.dy.clamp(0, screenSize.height - bubbleSize),
                );
              });
            },
            onTap: _openChat,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: theme.colorScheme.primary,
              child: SizedBox(
                width: bubbleSize,
                height: bubbleSize,
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
      ],
    );
  }
}
