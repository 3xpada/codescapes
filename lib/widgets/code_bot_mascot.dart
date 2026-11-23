import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CodeBotMascot extends StatelessWidget {
  const CodeBotMascot({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final darkFace = palette.brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.02,
            child: Container(
              width: size * 0.08,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: palette.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: size * 0.08,
            child: Container(
              width: size * 0.76,
              height: size * 0.72,
              decoration: BoxDecoration(
                color: darkFace
                    ? const Color(0xFFC7CECB)
                    : const Color(0xFFD8D5CC),
                borderRadius: BorderRadius.circular(size * 0.24),
                border: Border.all(
                  color: palette.muted.withValues(alpha: 0.65),
                  width: size * 0.035,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: size * 0.12,
                    offset: Offset(0, size * 0.05),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.56,
                  height: size * 0.34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF202A30),
                    borderRadius: BorderRadius.circular(size * 0.12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _eye(palette.accent, size),
                      SizedBox(width: size * 0.1),
                      _eye(palette.accent, size),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.08,
            child: Container(
              width: size * 0.2,
              height: size * 0.045,
              decoration: BoxDecoration(
                color: const Color(0xFF55616A),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eye(Color color, double size) => Container(
    width: size * 0.09,
    height: size * 0.09,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
