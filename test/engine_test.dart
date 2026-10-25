import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:codescapes/engine/engine.dart';
import 'package:codescapes/engine/level.dart';

void main() {
  final level = Level.fromJson(
      jsonDecode(File('assets/levels/level_01.json').readAsStringSync()));

  test('correct solution wins', () {
    final r = GameEngine.runSource(
        level, 'repeat(2) { move(); } turnRight(); repeat(2) { move(); }');
    expect(r.won, true);
    expect(r.stepsUsed, 5);
  });

  test('walking into a wall fails', () {
    final r = GameEngine.runSource(level, 'repeat(3) { move(); }');
    expect(r.won, false);
    expect(r.error, 'Blocked!');
  });

  test('infinite-ish loops are capped', () {
    final r = GameEngine.runSource(level, 'repeat(999) { turnLeft(); }');
    expect(r.error, contains('Too many steps'));
  });

  test('syntax errors are reported, not thrown', () {
    final r = GameEngine.runSource(level, 'move()');
    expect(r.won, false);
    expect(r.error, startsWith('Syntax error'));
  });
}
