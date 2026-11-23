import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../theme/app_colors.dart';

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final bool primary;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final foregroundColor = primary ? palette.onAccent : palette.text;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: primary
            ? Colors.transparent
            : palette.border.withValues(alpha: 0.7),
      ),
    );
    return Material(
      color: Colors.transparent,
      shape: shape,
      child: InkWell(
        onTap: () {
          unawaited(gameAudio.playEffect(GameSoundEffect.tap));
          onPressed();
        },
        customBorder: shape,
        child: Ink(
          height: primary ? 88 : 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: primary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.accent,
                      Color.lerp(palette.accent, palette.secondary, 0.42)!,
                    ],
                  )
                : null,
            color: primary ? null : palette.card.withValues(alpha: 0.72),
            border: primary
                ? null
                : Border.all(color: palette.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: (primary ? palette.accent : Colors.black).withValues(
                  alpha: primary ? 0.19 : 0.06,
                ),
                blurRadius: primary ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (primary ? foregroundColor : palette.accent)
                        .withValues(alpha: primary ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: primary ? foregroundColor : palette.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primary
                              ? foregroundColor.withValues(alpha: 0.76)
                              : palette.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  primary
                      ? Icons.arrow_forward_rounded
                      : Icons.chevron_right_rounded,
                  size: primary ? 22 : 24,
                  color: primary ? foregroundColor : palette.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
