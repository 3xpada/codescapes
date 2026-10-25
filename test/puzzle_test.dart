import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:codescapes/engine/interpreter.dart';
import 'package:codescapes/engine/puzzle.dart';

void main() {
  final puzzles = (jsonDecode(File('assets/puzzles/puzzles.json').readAsStringSync())['puzzles'] as List)
      .map((j) => Puzzle.fromJson(j as Map<String, dynamic>))
      .toList();
  Puzzle byId(int id) => puzzles.firstWhere((p) => p.id == id);

  group('interpreter', () {
    test('print and math', () {
      expect(runProgram('print(1 + 2 * 3)').output, '7\n');
      expect(runProgram('print(7 / 2)').output, '3.5\n');
      expect(runProgram('print(7 // 2)').output, '3\n');
      expect(runProgram('print("a" + "b")').output, 'ab\n');
    });

    test('loops and ifs', () {
      expect(runProgram('t = 0\nfor i in range(1, 4):\n    t += i\nprint(t)').output, '6\n');
      expect(runProgram('x = 5\nif x > 3:\n    print("big")\nelse:\n    print("small")').output, 'big\n');
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
    };

    for (final entry in solutions.entries) {
      test('level ${entry.key} accepts the right answer', () {
        expect(checkPuzzle(byId(entry.key), entry.value).verdict, Verdict.correct);
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

    test('code with an error', () {
      expect(checkPuzzle(byId(2), ['oops']).verdict, Verdict.error);
    });
  });
}
