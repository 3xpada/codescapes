import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class WorldBackground extends StatelessWidget {
  const WorldBackground({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _WorldBackgroundPainter(context.appPalette),
    child: const SizedBox.expand(),
  );
}

class _WorldBackgroundPainter extends CustomPainter {
  const _WorldBackgroundPainter(this.palette);

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final isDark = palette.brightness == Brightness.dark;
    final stone = isDark ? const Color(0xFF26313D) : const Color(0xFFBBC5CE);
    final hillside = isDark ? const Color(0xFF172321) : const Color(0xFFB8C4B9);
    final grass = isDark ? const Color(0xFF526458) : const Color(0xFF839180);

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgTop, palette.bgBottom],
        ).createShader(bounds),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.77, size.height * 0.32),
        width: size.width * 0.74,
        height: size.height * 0.36,
      ),
      Paint()..color = stone.withValues(alpha: isDark ? 0.07 : 0.22),
    );

    _drawCastle(canvas, size, stone, isDark);
    _drawHills(canvas, size, hillside, grass, isDark);
    _drawFloatingIsle(canvas, size, stone, grass, isDark);
  }

  void _drawCastle(Canvas canvas, Size size, Color stone, bool isDark) {
    final x = size.width * 0.69;
    final y = size.height * 0.25;
    final width = size.width * 0.26;
    final height = size.height * 0.19;
    final paint = Paint()
      ..color = stone.withValues(alpha: isDark ? 0.55 : 0.52);
    final outline = Path()
      ..moveTo(x, y + height)
      ..lineTo(x, y + height * 0.38)
      ..lineTo(x + width * 0.15, y + height * 0.38)
      ..lineTo(x + width * 0.15, y + height * 0.12)
      ..lineTo(x + width * 0.29, y + height * 0.12)
      ..lineTo(x + width * 0.29, y + height * 0.38)
      ..lineTo(x + width * 0.43, y + height * 0.38)
      ..lineTo(x + width * 0.43, y + height * 0.2)
      ..lineTo(x + width * 0.61, y + height * 0.2)
      ..lineTo(x + width * 0.61, y + height * 0.38)
      ..lineTo(x + width * 0.78, y + height * 0.38)
      ..lineTo(x + width * 0.78, y + height * 0.05)
      ..lineTo(x + width * 0.94, y + height * 0.05)
      ..lineTo(x + width * 0.94, y + height * 0.38)
      ..lineTo(x + width, y + height * 0.38)
      ..lineTo(x + width, y + height)
      ..close();
    canvas.drawPath(outline, paint);

    final windowPaint = Paint()
      ..color = (isDark ? const Color(0xFFB9A98D) : const Color(0xFF8A7659))
          .withValues(alpha: 0.28);
    for (final offset in [
      Offset(0.23, 0.56),
      Offset(0.54, 0.56),
      Offset(0.84, 0.24),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + width * offset.dx,
            y + height * offset.dy,
            width * 0.045,
            height * 0.15,
          ),
          const Radius.circular(2),
        ),
        windowPaint,
      );
    }
  }

  void _drawHills(
    Canvas canvas,
    Size size,
    Color hillside,
    Color grass,
    bool isDark,
  ) {
    final distant = Path()
      ..moveTo(0, size.height * 0.83)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.75,
        size.width * 0.37,
        size.height * 0.88,
        size.width * 0.58,
        size.height * 0.81,
      )
      ..cubicTo(
        size.width * 0.77,
        size.height * 0.75,
        size.width * 0.88,
        size.height * 0.81,
        size.width,
        size.height * 0.76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      distant,
      Paint()..color = hillside.withValues(alpha: isDark ? 0.52 : 0.42),
    );

    final foreground = Path()
      ..moveTo(0, size.height * 0.91)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.84,
        size.width * 0.35,
        size.height * 0.96,
        size.width * 0.59,
        size.height * 0.89,
      )
      ..cubicTo(
        size.width * 0.79,
        size.height * 0.83,
        size.width * 0.88,
        size.height * 0.93,
        size.width,
        size.height * 0.87,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      foreground,
      Paint()..color = hillside.withValues(alpha: isDark ? 0.82 : 0.72),
    );

    final grassPaint = Paint()
      ..color = grass.withValues(alpha: isDark ? 0.38 : 0.48)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final x in [size.width * 0.09, size.width * 0.18, size.width * 0.88]) {
      final base = Offset(x, size.height * 0.94);
      canvas.drawLine(base, base.translate(-5, -12), grassPaint);
      canvas.drawLine(base, base.translate(4, -16), grassPaint);
    }
  }

  void _drawFloatingIsle(
    Canvas canvas,
    Size size,
    Color stone,
    Color grass,
    bool isDark,
  ) {
    final centerX = size.width * 0.53;
    final top = size.height * 0.94;
    final island = Path()
      ..moveTo(centerX - size.width * 0.2, top)
      ..quadraticBezierTo(
        centerX,
        top - size.height * 0.045,
        centerX + size.width * 0.2,
        top,
      )
      ..lineTo(centerX + size.width * 0.12, top + size.height * 0.035)
      ..lineTo(centerX + size.width * 0.07, top + size.height * 0.048)
      ..lineTo(centerX - size.width * 0.1, top + size.height * 0.04)
      ..close();
    canvas.drawPath(
      island,
      Paint()..color = stone.withValues(alpha: isDark ? 0.82 : 0.75),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, top),
        width: size.width * 0.4,
        height: size.height * 0.035,
      ),
      Paint()..color = grass.withValues(alpha: isDark ? 0.5 : 0.58),
    );
  }

  @override
  bool shouldRepaint(_WorldBackgroundPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
