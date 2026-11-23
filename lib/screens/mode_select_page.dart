import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../engine/programming_language.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import 'puzzle_screen.dart';

class ModeSelectPage extends StatelessWidget {
  const ModeSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      appBar: AppBar(title: const Text('CHOOSE WORLD')),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Choose your next world',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Start with small wins, then build through variables, loops, and multi-step challenges.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      for (final language in ProgrammingLanguage.values) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _WorldCard(
                            language: language,
                            palette: palette,
                            onTap: () {
                              unawaited(
                                gameAudio.playEffect(GameSoundEffect.tap),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      PuzzleScreen(language: language),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.language,
    required this.palette,
    required this.onTap,
  });

  final ProgrammingLanguage language;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (language) {
      ProgrammingLanguage.python => palette.accent,
      ProgrammingLanguage.java => palette.secondary,
      ProgrammingLanguage.csharp => palette.success,
      ProgrammingLanguage.c => palette.warning,
    };
    final icon = switch (language) {
      ProgrammingLanguage.python => Icons.code_rounded,
      ProgrammingLanguage.java => Icons.coffee_rounded,
      ProgrammingLanguage.csharp => Icons.memory_rounded,
      ProgrammingLanguage.c => Icons.terminal_rounded,
    };

    return Material(
      color: palette.card.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.worldName,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      language.description,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${language.puzzleCount} PUZZLES  ·  ${language.label.toUpperCase()}',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}
