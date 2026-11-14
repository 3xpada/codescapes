import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/codescape_logo.dart';
import '../widgets/menu_button.dart';
import 'mode_select_page.dart';
import 'settings_page.dart';
import 'simple_page.dart';

class CodeScapeHome extends StatelessWidget {
  const CodeScapeHome({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = (constraints.maxWidth - 48)
                  .clamp(0.0, 340.0)
                  .toDouble();
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 440,
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: contentWidth,
                          height: contentWidth * 0.82,
                          child: CodeScapeLogo(
                            darkColor: palette.accent,
                            lightColor: palette.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'THINK. CODE. SOLVE.',
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.8,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _WalletBadge(palette: palette),
                        const SizedBox(height: 28),
                        MenuButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'PLAY',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ModeSelectPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MenuButton(
                          icon: Icons.calendar_month_rounded,
                          label: 'DAILY PUZZLE',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const SimplePage(
                                title: 'DAILY PUZZLE',
                                message: 'Your daily puzzle is coming soon!',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MenuButton(
                          icon: Icons.tune_rounded,
                          label: 'SETTINGS',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WalletBadge extends StatelessWidget {
  const _WalletBadge({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.border),
      ),
      child: ListenableBuilder(
        listenable: gameProgress,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, color: palette.accent, size: 19),
            const SizedBox(width: 8),
            Text(
              '${gameProgress.coins} coins',
              style: TextStyle(
                color: palette.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
