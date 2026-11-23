import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/codescape_logo.dart';
import '../widgets/menu_button.dart';
import 'achievements_page.dart';
import 'mode_select_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

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
                          child: _IdleLogo(
                            child: CodeScapeLogo(
                              darkColor: palette.accent,
                              lightColor: palette.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EXPLORE WORLDS. LEARN TO CODE.',
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
                          subtitle: 'Choose a world and start coding',
                          primary: true,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ModeSelectPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MenuButton(
                          icon: Icons.emoji_events_rounded,
                          label: 'ACHIEVEMENTS',
                          subtitle: 'Milestones earned across your worlds',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AchievementsPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MenuButton(
                          icon: Icons.person_rounded,
                          label: 'PLAYER PROFILE',
                          subtitle: 'Your progress, coins, and player name',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfilePage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        MenuButton(
                          icon: Icons.tune_rounded,
                          label: 'SETTINGS',
                          subtitle: 'Tune your theme and sound',
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

class _IdleLogo extends StatefulWidget {
  const _IdleLogo({required this.child});

  final Widget child;

  @override
  State<_IdleLogo> createState() => _IdleLogoState();
}

class _IdleLogoState extends State<_IdleLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _offset = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        key: const ValueKey('idle-home-logo'),
        offset: Offset(0, _offset.value),
        child: child,
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
        color: palette.card.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.border.withValues(alpha: 0.58)),
      ),
      child: ListenableBuilder(
        listenable: gameProgress,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on_rounded,
              color: palette.accent,
              size: 19,
            ),
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
