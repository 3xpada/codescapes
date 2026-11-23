import 'package:flutter/material.dart';

import '../app_state.dart';
import '../engine/achievement.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      appBar: AppBar(title: const Text('ACHIEVEMENTS')),
      body: AppBackground(
        child: ListenableBuilder(
          listenable: gameProgress,
          builder: (context, _) {
            final achievements = gameProgress.achievements;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: palette.accent,
                            size: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR COLLECTION',
                                  style: TextStyle(
                                    color: palette.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${gameProgress.unlockedAchievementCount} of ${gameProgress.achievementCount} unlocked',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final achievement in achievements)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AchievementCard(
                          achievement: achievement,
                          palette: palette,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.palette});

  final AchievementProgress achievement;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final definition = achievement.definition;
    final color = achievement.isUnlocked ? palette.accent : palette.muted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked ? palette.accent : palette.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(definition.icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        definition.title,
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      achievement.isUnlocked
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                      color: color,
                      size: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  definition.description,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.fraction,
                    minHeight: 6,
                    backgroundColor: palette.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  achievement.isUnlocked
                      ? 'UNLOCKED'
                      : '${achievement.progress} / ${definition.target}',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
