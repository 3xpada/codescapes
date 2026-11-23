import 'interpreter.dart';
import 'java_interpreter.dart';
import 'c_family_interpreter.dart';
import 'programming_language.dart';

/// A fill-in-the-blank level. Blanks in [template] are written as ___ .
class Puzzle {
  static const blankMarker = '___';

  final int id;
  final String title;
  final String story;
  final String task;
  final String template;
  final List<String> hints;
  final String expectedOutput;
  final List<String>? requiredAnswers;
  final String? solutionFeedback;
  final ProgrammingLanguage language;

  const Puzzle({
    required this.id,
    required this.title,
    required this.story,
    required this.task,
    required this.template,
    required this.hints,
    required this.expectedOutput,
    this.requiredAnswers,
    this.solutionFeedback,
    this.language = ProgrammingLanguage.python,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) => Puzzle(
    id: j['id'] as int,
    title: j['title'] as String,
    story: j['story'] as String,
    task: j['task'] as String,
    template: j['template'] as String,
    hints: List<String>.from(j['hints'] as List),
    expectedOutput: j['expectedOutput'] as String,
    requiredAnswers: j['requiredAnswers'] == null
        ? null
        : List<String>.from(j['requiredAnswers'] as List),
    solutionFeedback: j['solutionFeedback'] as String?,
    language: ProgrammingLanguage.values.byName(
      j['language'] as String? ?? ProgrammingLanguage.python.name,
    ),
  );

  int get blankCount => blankMarker.allMatches(template).length;

  /// Puts the player's answers into the blanks, in order.
  String fill(List<String> answers) {
    var i = 0;
    return template.replaceAllMapped(blankMarker, (m) {
      final a = i < answers.length ? answers[i] : '';
      i++;
      return a.replaceAll('\n', ' ').trim();
    });
  }
}

enum Verdict { incomplete, error, wrongOutput, correct }

class Attempt {
  final Verdict verdict;
  final String message;
  final String output;
  final String expected;
  const Attempt(this.verdict, this.message, this.output, this.expected);
}

String _normalize(String s) => s
    .replaceAll('\r', '')
    .split('\n')
    .map((l) => l.trimRight())
    .join('\n')
    .trim();

/// Fills the blanks, runs the code, and compares the output to the goal.
Attempt checkPuzzle(Puzzle p, List<String> answers) {
  final expected = _normalize(p.expectedOutput);

  if (answers.length != p.blankCount || answers.any((a) => a.trim().isEmpty)) {
    return Attempt(
      Verdict.incomplete,
      'Fill in every blank before running.',
      '',
      expected,
    );
  }

  final code = p.fill(answers);
  final result = switch (p.language) {
    ProgrammingLanguage.python => runProgram(code),
    ProgrammingLanguage.java => runJavaProgram(code),
    ProgrammingLanguage.csharp => runCSharpProgram(code),
    ProgrammingLanguage.c => runCProgram(code),
  };

  if (result.error != null) {
    return Attempt(Verdict.error, result.error.toString(), '', expected);
  }

  final actual = _normalize(result.output);
  if (actual == expected) {
    final requiredAnswers = p.requiredAnswers;
    final requiredAnswersMatch =
        requiredAnswers == null ||
        (requiredAnswers.length == answers.length &&
            List.generate(answers.length, (index) => index).every(
              (index) => requiredAnswers[index] == answers[index].trim(),
            ));
    if (!requiredAnswersMatch) {
      return Attempt(
        Verdict.wrongOutput,
        p.solutionFeedback ??
            'The output matches, but the code does not follow the task.',
        actual,
        expected,
      );
    }
    return Attempt(
      Verdict.correct,
      'Your code printed exactly what the level wants.',
      actual,
      expected,
    );
  }
  return Attempt(
    Verdict.wrongOutput,
    'Your code ran without errors, but the output is not what the level wants.',
    actual,
    expected,
  );
}
