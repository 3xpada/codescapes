import 'dart:convert';

import 'package:codescapes/engine/game_progress_manager.dart';
import 'package:codescapes/engine/programming_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'achievements unlock from progress and persist across sessions',
    () async {
      SharedPreferences.setMockInitialValues({});
      final progress = GameProgress();
      addTearDown(progress.dispose);

      await progress.load();
      await progress.completePuzzle(1, language: ProgrammingLanguage.python);
      expect(await progress.completePuzzle(1), isFalse);
      expect(progress.coins, 55);
      expect(
        progress.achievements
            .singleWhere((item) => item.definition.id == 'first_solve')
            .isUnlocked,
        isTrue,
      );
      expect(
        progress.achievements
            .singleWhere((item) => item.definition.id == 'python_pioneer')
            .isUnlocked,
        isTrue,
      );

      await progress.completePuzzle(101, language: ProgrammingLanguage.java);
      await progress.completePuzzle(201, language: ProgrammingLanguage.csharp);
      await progress.completePuzzle(301, language: ProgrammingLanguage.c);
      expect(
        progress.achievements
            .singleWhere((item) => item.definition.id == 'all_languages')
            .isUnlocked,
        isTrue,
      );
      expect(
        progress.takeNewlyUnlockedAchievements().any(
          (item) => item.definition.id == 'all_languages',
        ),
        isTrue,
      );
      expect(progress.takeNewlyUnlockedAchievements(), isEmpty);

      final restored = GameProgress();
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.solvedPuzzleCount, 4);
      expect(restored.unlockedAchievementCount, greaterThanOrEqualTo(5));
      expect(
        restored.achievements
            .singleWhere((item) => item.definition.id == 'all_languages')
            .isUnlocked,
        isTrue,
      );
    },
  );

  test(
    'hint achievements count distinct hints and unlock at their targets',
    () async {
      SharedPreferences.setMockInitialValues({});
      final progress = GameProgress();
      addTearDown(progress.dispose);
      await progress.load();

      for (var index = 0; index < 10; index++) {
        expect(await progress.unlockHint(index, 0, 1), isTrue);
      }

      expect(progress.totalHintsUnlocked, 10);
      expect(
        progress.achievements
            .singleWhere((item) => item.definition.id == 'first_hint')
            .isUnlocked,
        isTrue,
      );
      expect(
        progress.achievements
            .singleWhere((item) => item.definition.id == 'ten_hints')
            .isUnlocked,
        isTrue,
      );
      await progress.addCoins(100);
      expect(
        progress.achievements
            .singleWhere((item) => item.definition.id == 'earn_hundred_coins')
            .isUnlocked,
        isTrue,
      );
    },
  );

  test('language mastery unlocks after ten distinct levels', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = GameProgress();
    addTearDown(progress.dispose);
    await progress.load();

    for (var puzzleId = 1; puzzleId <= 9; puzzleId++) {
      await progress.completePuzzle(
        puzzleId,
        language: ProgrammingLanguage.python,
      );
    }
    expect(
      progress.achievements
          .singleWhere((item) => item.definition.id == 'python_master')
          .isUnlocked,
      isFalse,
    );

    await progress.completePuzzle(10, language: ProgrammingLanguage.python);
    expect(
      progress.achievements
          .singleWhere((item) => item.definition.id == 'python_master')
          .isUnlocked,
      isTrue,
    );
  });

  test(
    'older saved progress migrates language attribution and achievements',
    () async {
      SharedPreferences.setMockInitialValues({
        'codescapes.game_progress.v1': jsonEncode({
          'coins': 60,
          'currentPuzzleIndices': {'python': 1},
          'solvedPuzzles': [1, 101],
          'unlockedHints': <String, int>{},
        }),
      });
      final progress = GameProgress();
      addTearDown(progress.dispose);
      await progress.load();

      expect(
        progress.achievements
            .singleWhere((item) => item.definition.id == 'python_pioneer')
            .isUnlocked,
        isTrue,
      );
      expect(
        progress.achievements
            .singleWhere((item) => item.definition.id == 'java_starter')
            .isUnlocked,
        isTrue,
      );
    },
  );
}
