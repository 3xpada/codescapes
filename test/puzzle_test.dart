import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codescapes/engine/interpreter.dart';
import 'package:codescapes/engine/puzzle.dart';
import 'package:codescapes/engine/game_progress_manager.dart';
import 'package:codescapes/engine/programming_language.dart';

void main() {
  test('each level grants five coins only on its first clear', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = GameProgress();
    addTearDown(progress.dispose);

    await progress.load();
    expect(await progress.completePuzzle(1), isTrue);
    expect(progress.coins, 55);
    expect(await progress.completePuzzle(1), isFalse);
    expect(progress.coins, 55);
    expect(await progress.completePuzzle(2), isTrue);
    expect(progress.coins, 60);
  });

  test('coins, solved levels, hints, and current level persist', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = GameProgress();
    addTearDown(progress.dispose);

    await progress.load();
    await progress.completePuzzle(4);
    await progress.unlockHint(5, 10, 2);
    await progress.setCurrentPuzzleIndex(3);
    await progress.setCurrentPuzzleIndex(1, language: ProgrammingLanguage.java);

    final restored = GameProgress();
    addTearDown(restored.dispose);
    await restored.load();

    expect(restored.coins, 45);
    expect(restored.isSolved(4), isTrue);
    expect(restored.getUnlockedHints(5), 1);
    expect(restored.currentPuzzleIndex, 3);
    expect(restored.getCurrentPuzzleIndex(ProgrammingLanguage.java), 1);
  });

  final puzzles =
      (jsonDecode(
                File('assets/puzzles/puzzles.json').readAsStringSync(),
              )['puzzles']
              as List)
          .map((j) => Puzzle.fromJson(j as Map<String, dynamic>))
          .toList();
  Puzzle byId(int id) => puzzles.firstWhere((p) => p.id == id);
  final javaPuzzles =
      (jsonDecode(
                File('assets/puzzles/java_puzzles.json').readAsStringSync(),
              )['puzzles']
              as List)
          .map((j) => Puzzle.fromJson(j as Map<String, dynamic>))
          .toList();
  Puzzle javaById(int id) => javaPuzzles.firstWhere((p) => p.id == id);

  group('interpreter', () {
    test('print and math', () {
      expect(runProgram('print(1 + 2 * 3)').output, '7\n');
      expect(runProgram('print(7 / 2)').output, '3.5\n');
      expect(runProgram('print(7 // 2)').output, '3\n');
      expect(runProgram('print("a" + "b")').output, 'ab\n');
    });

    test('loops and ifs', () {
      expect(
        runProgram('t = 0\nfor i in range(1, 4):\n    t += i\nprint(t)').output,
        '6\n',
      );
      expect(
        runProgram(
          'x = 5\nif x > 3:\n    print("big")\nelse:\n    print("small")',
        ).output,
        'big\n',
      );
    });

    test('undefined name reports line', () {
      final r = runProgram('x = 1\nprint(y)');
      expect(r.error, isNotNull);
      expect(r.error!.line, 2);
      expect(r.error!.message, contains('not defined'));
    });

    test('infinite loop is stopped', () {
      final r = runProgram('while True:\n    x = 1');
      expect(r.error!.message, contains('too long'));
    });
  });

  group('puzzles', () {
    const solutions = {
      1: ['World'],
      2: ['5'],
      3: ['3'],
      4: ['%'],
      5: ['>'],
      6: ['6', 'n'],
      7: ['quantity'],
      8: ['>='],
      9: ['11'],
      10: ['2'],
    };

    for (final entry in solutions.entries) {
      test('level ${entry.key} accepts the right answer', () {
        expect(
          checkPuzzle(byId(entry.key), entry.value).verdict,
          Verdict.correct,
        );
      });
    }

    test('empty blank is incomplete', () {
      expect(checkPuzzle(byId(1), ['']).verdict, Verdict.incomplete);
    });

    test('ran but wrong output', () {
      final a = checkPuzzle(byId(5), ['>=']);
      expect(a.verdict, Verdict.wrongOutput);
      expect(a.output, contains('0'));
    });

    test('rejects matching output when the requested loop logic is wrong', () {
      final attempt = checkPuzzle(byId(6), ['4', '5']);

      expect(attempt.verdict, Verdict.wrongOutput);
      expect(attempt.output, '15');
      expect(attempt.message, contains('adds 5 three times'));
    });

    test('code with an error', () {
      expect(checkPuzzle(byId(2), ['oops']).verdict, Verdict.error);
    });
  });

  group('Java world', () {
    const solutions = {
      101: ['Hello from Java!'],
      102: ['5'],
      103: ['6', 'n'],
      104: ['turns'],
      105: ['name'],
      106: ['4'],
      107: ['5', 'n'],
      108: ['4', 'n * n'],
      109: ['step'],
      110: ['2', '3'],
    };

    for (final entry in solutions.entries) {
      test('level ${entry.key} runs Java syntax', () {
        expect(
          checkPuzzle(javaById(entry.key), entry.value).verdict,
          Verdict.correct,
        );
      });
    }

    test('rejects matching output when the loop logic is wrong', () {
      final attempt = checkPuzzle(javaById(103), ['4', '5']);

      expect(attempt.verdict, Verdict.wrongOutput);
      expect(attempt.output, '15');
      expect(attempt.message, contains('loop variable'));
    });

    test('world has ten levels arranged from basics to nested loops', () {
      expect(javaPuzzles, hasLength(ProgrammingLanguage.java.puzzleCount));
      expect(javaPuzzles.first.title, 'First Output');
      expect(javaPuzzles.last.title, 'Grid Signals');
    });
  });
}
