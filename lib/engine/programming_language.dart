enum ProgrammingLanguage { python, java, csharp, c }

extension ProgrammingLanguageInfo on ProgrammingLanguage {
  String get label => switch (this) {
    ProgrammingLanguage.python => 'Python',
    ProgrammingLanguage.java => 'Java',
    ProgrammingLanguage.csharp => 'C#',
    ProgrammingLanguage.c => 'C',
  };

  String get worldName => switch (this) {
    ProgrammingLanguage.python => 'Python Valley',
    ProgrammingLanguage.java => 'Java Foundry',
    ProgrammingLanguage.csharp => 'C# Circuit',
    ProgrammingLanguage.c => 'C Workshop',
  };

  String get description => switch (this) {
    ProgrammingLanguage.python =>
      'Build your coding basics with friendly, short puzzles.',
    ProgrammingLanguage.java =>
      'Practice Java output, variables, and loops in the foundry.',
    ProgrammingLanguage.csharp =>
      'Practice C# output, variables, and loops in the circuit.',
    ProgrammingLanguage.c =>
      'Practice C output, variables, and loops in the workshop.',
  };

  String get assetPath => switch (this) {
    ProgrammingLanguage.python => 'assets/puzzles/puzzles.json',
    ProgrammingLanguage.java => 'assets/puzzles/java_puzzles.json',
    ProgrammingLanguage.csharp => 'assets/puzzles/csharp_puzzles.json',
    ProgrammingLanguage.c => 'assets/puzzles/c_puzzles.json',
  };

  int get puzzleCount => switch (this) {
    ProgrammingLanguage.python => 10,
    ProgrammingLanguage.java => 10,
    ProgrammingLanguage.csharp => 10,
    ProgrammingLanguage.c => 10,
  };

  int get firstPuzzleId => switch (this) {
    ProgrammingLanguage.python => 1,
    ProgrammingLanguage.java => 101,
    ProgrammingLanguage.csharp => 201,
    ProgrammingLanguage.c => 301,
  };

  bool ownsPuzzleId(int id) =>
      id >= firstPuzzleId && id < firstPuzzleId + puzzleCount;
}
