import 'package:flutter/material.dart';

/// Bulle "en train d'écrire..." (3 points qui pulsent) — 05/08, partagée
/// entre `chat_screen.dart` et `friend_chat_screen.dart` (voir
/// `typing_presence.dart` pour la détection côté réseau).
class TypingDots extends StatefulWidget {
  final Color color;

  const TypingDots({super.key, required this.color});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Décale la pulsation de chaque point d'un tiers de cycle.
            final t = (_controller.value + i / 3) % 1.0;
            final scale = 0.5 + 0.5 * (1 - (2 * t - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: 0.4 + 0.6 * scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
