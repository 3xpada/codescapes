import 'level.dart';
import 'parser.dart';

/// One animation step the UI can play back.
class Frame {
  final String command;
  final int x, y, dir; // dir: 0 up, 1 right, 2 down, 3 left
  final bool ok;
  const Frame(this.command, this.x, this.y, this.dir, this.ok);
}

class RunResult {
  final List<Frame> frames;
  final bool won;
  final String? error;
  final int stepsUsed;
  const RunResult(this.frames, this.won, this.error, this.stepsUsed);
}

class _Halt implements Exception {
  final String message;
  _Halt(this.message);
}

class GameEngine {
  static const _dirs = [(0, -1), (1, 0), (0, 1), (-1, 0)];

  /// Convenience: parse + run. Never throws; errors come back in RunResult.
  static RunResult runSource(Level level, String source) {
    try {
      return run(level, Parser.parse(source));
    } on ParseException catch (e) {
      return RunResult(const [], false, 'Syntax error: ${e.message}', 0);
    }
  }

  static RunResult run(Level level, List<Node> ast) {
    final grid = level.grid.map((r) => r.split('')).toList();
    var x = 0, y = 0, dir = 1;
    for (var r = 0; r < grid.length; r++) {
      for (var c = 0; c < grid[r].length; c++) {
        if (grid[r][c] == 'P') {
          x = c;
          y = r;
          grid[r][c] = '.';
        }
      }
    }

    final frames = <Frame>[];
    var steps = 0;

    void execCall(String name) {
      if (!level.allowedCommands.contains(name)) {
        throw _Halt('Unknown or locked command: $name');
      }
      if (++steps > level.maxSteps) {
        throw _Halt('Too many steps (infinite loop?)');
      }
      switch (name) {
        case 'move':
          final (dx, dy) = _dirs[dir];
          final nx = x + dx, ny = y + dy;
          final blocked = ny < 0 ||
              ny >= grid.length ||
              nx < 0 ||
              nx >= grid[ny].length ||
              grid[ny][nx] == '#';
          if (blocked) {
            frames.add(Frame(name, x, y, dir, false));
            throw _Halt('Blocked!');
          }
          x = nx;
          y = ny;
        case 'turnLeft':
          dir = (dir + 3) % 4;
        case 'turnRight':
          dir = (dir + 1) % 4;
        default:
          throw _Halt('Unknown command: $name');
      }
      frames.add(Frame(name, x, y, dir, true));
    }

    void exec(List<Node> nodes) {
      for (final n in nodes) {
        switch (n) {
          case CallNode():
            execCall(n.name);
          case RepeatNode():
            for (var k = 0; k < n.count; k++) {
              exec(n.body);
            }
        }
      }
    }

    try {
      exec(ast);
    } on _Halt catch (h) {
      return RunResult(frames, false, h.message, steps);
    }

    final won = grid[y][x] == 'G';
    return RunResult(frames, won, won ? null : "You didn't reach the goal.", steps);
  }
}
