/// A level is pure data, loaded from assets/levels/*.json
class Level {
  final int id;
  final String title;
  final List<String> grid; // 'P' start, 'G' goal, '#' wall, '.' empty
  final List<String> allowedCommands;
  final int maxSteps;

  const Level({
    required this.id,
    required this.title,
    required this.grid,
    required this.allowedCommands,
    required this.maxSteps,
  });

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        id: json['id'] as int,
        title: json['title'] as String,
        grid: List<String>.from(json['grid'] as List),
        allowedCommands: List<String>.from(json['allowedCommands'] as List),
        maxSteps: json['maxSteps'] as int,
      );
}
