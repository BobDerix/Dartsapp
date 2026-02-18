import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Branded logo widget that recreates the Dart-Core Bonanza logo style.
/// If assets/images/logo.png exists, set [useImage] to true to show it instead.
class LogoWidget extends StatelessWidget {
  final double scale;
  final bool useImage;

  const LogoWidget({super.key, this.scale = 1.0, this.useImage = false});

  @override
  Widget build(BuildContext context) {
    if (useImage) {
      return Image.asset(
        'assets/images/logoo.png',
        width: 280 * scale,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildTextLogo(),
      );
    }
    return _buildTextLogo();
  }

  Widget _buildTextLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dartboard icon
        SizedBox(
          width: 80 * scale,
          height: 80 * scale,
          child: CustomPaint(painter: _DartboardPainter()),
        ),
        SizedBox(height: 12 * scale),

        // DART-CORE in metallic cyan gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.cyanLight,
              AppColors.cyan,
              AppColors.cyanDark,
              AppColors.cyan,
              AppColors.cyanLight,
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'DART-CORE',
            style: TextStyle(
              fontSize: 42 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 3 * scale,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
        SizedBox(height: 2 * scale),

        // BONANZA in warm gold gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.goldDark,
              AppColors.gold,
              AppColors.goldLight,
              AppColors.gold,
              AppColors.goldDark,
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'BONANZA',
            style: TextStyle(
              fontSize: 36 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 6 * scale,
              color: Colors.white,
              height: 1.1,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _DartboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring glow
    final glowPaint = Paint()
      ..color = AppColors.cyan.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, glowPaint);

    // Rings from outside in
    final rings = [
      (radius * 0.95, AppColors.cyanDark),
      (radius * 0.85, const Color(0xFF1A1A20)),
      (radius * 0.75, AppColors.cyan),
      (radius * 0.60, const Color(0xFF1A1A20)),
      (radius * 0.45, AppColors.gold),
      (radius * 0.30, const Color(0xFF1A1A20)),
      (radius * 0.15, const Color(0xFFFF1744)),
    ];

    for (final (r, color) in rings) {
      canvas.drawCircle(
        center,
        r,
        Paint()..color = color,
      );
    }

    // Bullseye center
    canvas.drawCircle(
      center,
      radius * 0.07,
      Paint()..color = AppColors.cyanLight,
    );

    // Cross-hairs
    final hairPaint = Paint()
      ..color = AppColors.textPrimary.withAlpha(60)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.85),
      Offset(center.dx, center.dy + radius * 0.85),
      hairPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.85, center.dy),
      Offset(center.dx + radius * 0.85, center.dy),
      hairPaint,
    );

    // Outer border
    canvas.drawCircle(
      center,
      radius * 0.95,
      Paint()
        ..color = AppColors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
