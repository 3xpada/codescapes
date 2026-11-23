import 'interpreter.dart';

/// Runs the beginner Java subset used by the Java world.
///
/// Supports class/main wrappers, primitive declarations, println, and
/// incrementing for-loops; expressions are evaluated by the safe puzzle
/// interpreter rather than by a native compiler.
ExecResult runJavaProgram(String source) {
  try {
    return runProgram(_translateJavaSubset(source));
  } on RunException catch (error) {
    return ExecResult('', error);
  }
}

String _translateJavaSubset(String source) {
  final output = <String>[];
  final classWrapper = RegExp(r'^(?:public\s+)?class\s+\w+\s*\{$');
  final mainWrapper = RegExp(
    r'^(?:public\s+)?static\s+void\s+main\s*\(\s*String\[\]\s+\w+\s*\)\s*\{$',
  );
  final forLoop = RegExp(
    r'^for\s*\(\s*(?:int\s+)?([A-Za-z_]\w*)\s*=\s*(-?\d+)\s*;\s*\1\s*<\s*(.+?)\s*;\s*\1\+\+\s*\)\s*\{$',
  );
  final declaration = RegExp(
    r'^(?:int|long|double|String|boolean)\s+([A-Za-z_]\w*)\s*=\s*(.+);$',
  );
  final println = RegExp(r'^System\.out\.println\((.*)\);$');
  var indent = 0;
  final lines = source.split('\n');

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty || line.startsWith('//')) {
      output.add('');
      continue;
    }

    if (classWrapper.hasMatch(line) || mainWrapper.hasMatch(line)) {
      output.add('');
      continue;
    }

    if (line == '}') {
      if (indent > 0) indent--;
      output.add('');
      continue;
    }

    final loop = forLoop.firstMatch(line);
    if (loop != null) {
      final variable = loop.group(1)!;
      final start = loop.group(2)!;
      final end = loop.group(3)!;
      output.add(
        '${_indentation(indent)}for $variable in range($start, $end):',
      );
      indent++;
      continue;
    }

    final variable = declaration.firstMatch(line);
    final printCall = println.firstMatch(line);
    final statement = variable != null
        ? '${variable.group(1)} = ${variable.group(2)}'
        : printCall != null
        ? 'print(${printCall.group(1)})'
        : line.endsWith(';')
        ? line.substring(0, line.length - 1)
        : null;

    if (statement == null || line.contains('{') || line.contains('}')) {
      throw RunException('Unsupported Java syntax in this puzzle.', index + 1);
    }
    output.add('${_indentation(indent)}$statement');
  }

  if (indent != 0) {
    throw RunException(
      'Missing a closing brace for the for-loop.',
      lines.length,
    );
  }
  return output.join('\n');
}

String _indentation(int depth) => List.filled(depth, '    ').join();
