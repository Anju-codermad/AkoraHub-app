import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Social login options widget
class SocialLoginWidget extends StatelessWidget {
  final Function(String) onSocialLogin;
  final Map<String, String> translations;

  const SocialLoginWidget({
    super.key,
    required this.onSocialLogin,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                (translations['or_continue_with'] ?? 'Or continue with')
                    .toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.5.h),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                onTap: () => onSocialLogin('google'),
                label: 'Google',
                icon: const _GoogleGlyph(),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _SocialButton(
                onTap: () => onSocialLogin('facebook'),
                label: 'Facebook',
                icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final Widget icon;

  const _SocialButton({
    required this.onTap,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.7.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(width: 2.w),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "G" multicolore de Google, dessiné sans dépendance externe (pas de
/// package d'icônes de marque disponible dans ce projet).
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final stroke = size.width * 0.22;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startDeg * 3.14159265 / 180,
        sweepDeg * 3.14159265 / 180,
        false,
        paint,
      );
    }

    arc(-50, 95, const Color(0xFF4285F4)); // bleu (droite/bas)
    arc(45, 85, const Color(0xFF34A853)); // vert (bas/gauche)
    arc(130, 65, const Color(0xFFFBBC05)); // jaune (gauche)
    arc(195, 105, const Color(0xFFEA4335)); // rouge (haut)

    // Barre horizontale du "G"
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - stroke / 2,
        rect.width / 2 - stroke * 0.15,
        stroke,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
