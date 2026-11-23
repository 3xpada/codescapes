import 'package:flutter/material.dart';

import 'programming_language.dart';

enum AchievementMetric {
  totalPuzzlesSolved,
  puzzlesSolvedInLanguage,
  languagesVisited,
  hintsUnlocked,
  coinsEarned,
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.metric,
    required this.target,
    this.language,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementMetric metric;
  final int target;
  final ProgrammingLanguage? language;
}

class AchievementProgress {
  const AchievementProgress({
    required this.definition,
    required this.progress,
    required this.isUnlocked,
  });

  final AchievementDefinition definition;
  final int progress;
  final bool isUnlocked;

  double get fraction =>
      (progress / definition.target).clamp(0.0, 1.0).toDouble();
}

abstract final class AchievementCatalog {
  static final List<AchievementDefinition> definitions = List.unmodifiable([
    const AchievementDefinition(
      id: 'first_solve',
      title: 'First Steps',
      description: 'Solve your first puzzle.',
      icon: Icons.flag_rounded,
      metric: AchievementMetric.totalPuzzlesSolved,
      target: 1,
    ),
    const AchievementDefinition(
      id: 'five_solves',
      title: 'Puzzle Apprentice',
      description: 'Solve 5 different puzzles.',
      icon: Icons.extension_rounded,
      metric: AchievementMetric.totalPuzzlesSolved,
      target: 5,
    ),
    AchievementDefinition(
      id: 'all_puzzles',
      title: 'Completionist',
      description: 'Complete every level across all language worlds.',
      icon: Icons.emoji_events_rounded,
      metric: AchievementMetric.totalPuzzlesSolved,
      target: ProgrammingLanguage.values.fold(
        0,
        (total, language) => total + language.puzzleCount,
      ),
    ),
    AchievementDefinition(
      id: 'all_languages',
      title: 'World Traveler',
      description: 'Solve a puzzle in every language world.',
      icon: Icons.public_rounded,
      metric: AchievementMetric.languagesVisited,
      target: ProgrammingLanguage.values.length,
    ),
    const AchievementDefinition(
      id: 'python_pioneer',
      title: 'Python Pioneer',
      description: 'Solve a puzzle in Python Valley.',
      icon: Icons.code_rounded,
      metric: AchievementMetric.puzzlesSolvedInLanguage,
      target: 1,
      language: ProgrammingLanguage.python,
    ),
    const AchievementDefinition(
      id: 'java_starter',
      title: 'Java Starter',
      description: 'Solve a puzzle in Java Foundry.',
      icon: Icons.coffee_rounded,
      metric: AchievementMetric.puzzlesSolvedInLanguage,
      target: 1,
      language: ProgrammingLanguage.java,
    ),
    const AchievementDefinition(
      id: 'csharp_starter',
      title: 'C# Starter',
      description: 'Solve a puzzle in C# Circuit.',
      icon: Icons.memory_rounded,
      metric: AchievementMetric.puzzlesSolvedInLanguage,
      target: 1,
      language: ProgrammingLanguage.csharp,
    ),
    const AchievementDefinition(
      id: 'c_starter',
      title: 'C Starter',
      description: 'Solve a puzzle in C Workshop.',
      icon: Icons.terminal_rounded,
      metric: AchievementMetric.puzzlesSolvedInLanguage,
      target: 1,
      language: ProgrammingLanguage.c,
    ),
    const AchievementDefinition(
      id: 'python_master',
      title: 'Python Pathfinder',
      description: 'Complete all 10 levels in Python Valley.',
      icon: Icons.terrain_rounded,
      metric: AchievementMetric.puzzlesSolvedInLanguage,
      target: 10,
      language: ProgrammingLanguage.python,
    ),
    const AchievementDefinition(
      id: 'java_master',
      title: 'Foundry Engineer',
      description: 'Complete all 10 levels in Java Foundry.',
      icon: Icons.factory_rounded,
      metric: AchievementMetric.puzzlesSolvedInLanguage,
      target: 10,
      language: ProgrammingLanguage.java,
    ),
    const AchievementDefinition(
      id: 'csharp_master',
      title: 'Circuit Architect',
      description: 'Complete all 10 levels in C# Circuit.',
      icon: Icons.memory_rounded,
      metric: AchievementMetric.puzzlesSolvedInLanguage,
      target: 10,
      language: ProgrammingLanguage.csharp,
    ),
    const AchievementDefinition(
      id: 'c_master',
      title: 'Workshop Master',
      description: 'Complete all 10 levels in C Workshop.',
      icon: Icons.build_rounded,
      metric: AchievementMetric.puzzlesSolvedInLanguage,
      target: 10,
      language: ProgrammingLanguage.c,
    ),
    const AchievementDefinition(
      id: 'first_hint',
      title: 'Curious Mind',
      description: 'Unlock your first hint.',
      icon: Icons.lightbulb_rounded,
      metric: AchievementMetric.hintsUnlocked,
      target: 1,
    ),
    const AchievementDefinition(
      id: 'ten_hints',
      title: 'Hint Explorer',
      description: 'Unlock 10 hints.',
      icon: Icons.tips_and_updates_rounded,
      metric: AchievementMetric.hintsUnlocked,
      target: 10,
    ),
    const AchievementDefinition(
      id: 'earn_hundred_coins',
      title: 'Coin Collector',
      description: 'Earn 100 coins over your coding journey.',
      icon: Icons.monetization_on_rounded,
      metric: AchievementMetric.coinsEarned,
      target: 100,
    ),
  ]);
}
