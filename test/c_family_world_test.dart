import 'dart:convert';
import 'dart:io';

import 'package:codescapes/engine/programming_language.dart';
import 'package:codescapes/engine/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

List<Puzzle> loadPuzzles(ProgrammingLanguage language) =>
    ((jsonDecode(File(language.assetPath).readAsStringSync())
                as Map<String, dynamic>)['puzzles']
            as List)
        .map((item) => Puzzle.fromJson(item as Map<String, dynamic>))
        .toList();

void main() {
  for (final language in [ProgrammingLanguage.csharp, ProgrammingLanguage.c]) {
    final puzzles = loadPuzzles(language);
    final solutions = language == ProgrammingLanguage.csharp
        ? const {
            201: ['Hello from C#!'],
            202: ['5'],
            203: ['6', 'n'],
            204: ['turns'],
            205: ['name'],
            206: ['4'],
            207: ['5', 'n'],
            208: ['4', 'n * n'],
            209: ['step'],
            210: ['2', '3'],
          }
        : const {
            301: ['World'],
            302: ['5'],
            303: ['6', 'n'],
            304: ['turns'],
            305: ['42'],
            306: ['4'],
            307: ['5', 'n'],
            308: ['4', 'n * n'],
            309: ['step'],
            310: ['2', '3'],
          };

    group('${language.label} world', () {
      test('loads and solves every level in the new world', () {
        expect(puzzles, hasLength(language.puzzleCount));
        for (final puzzle in puzzles) {
          expect(
            checkPuzzle(puzzle, solutions[puzzle.id]!).verdict,
            Verdict.correct,
            reason: puzzle.title,
          );
        }
      });

      test('levels are ordered from introductory work to nested loops', () {
        expect(puzzles.first.title, 'First Output');
        expect(puzzles.last.title, 'Grid Signals');
      });

      test(
        'rejects a loop answer that only happens to print the right total',
        () {
          final loopPuzzle = puzzles[2];
          final attempt = checkPuzzle(loopPuzzle, ['4', '5']);

          expect(attempt.verdict, Verdict.wrongOutput);
          expect(attempt.output, '15');
          expect(attempt.message, contains('loop variable'));
        },
      );
    });
  }
}
