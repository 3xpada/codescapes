import 'interpreter.dart';

/// Runs the safe C# subset used by the C# world.
ExecResult runCSharpProgram(String source) => _runCStyleProgram(source, 'C#');

/// Runs the safe C subset used by the C world.
ExecResult runCProgram(String source) => _runCStyleProgram(source, 'C');

ExecResult _runCStyleProgram(String source, String language) {
  try {
    return runProgram(_translateCStyle(source, language));
  } on RunException catch (error) {
    return ExecResult('', error);
  }
}

String _translateCStyle(String source, String language) {
  final output = <String>[];
  final classWrapper = RegExp(r'^(?:public\s+)?class\s+\w+\s*\{$');
  final mainWrapper = RegExp(
    r'^(?:(?:public|private|internal)\s+)?static\s+void\s+Main\s*\(\s*(?:(?:string|String)\s*\[\]\s+\w+)?\s*\)\s*\{$',
  );
  final cMainWrapper = RegExp(
    r'^(?:int|void)\s+main\s*\(\s*(?:void)?\s*\)\s*\{$',
  );
  final forLoop = RegExp(
    r'^for\s*\(\s*(?:(?:int|long|float|double)\s+)?([A-Za-z_]\w*)\s*=\s*(-?\d+)\s*;\s*\1\s*<\s*(.+?)\s*;\s*\1\+\+\s*\)\s*\{$',
  );
  final declaration = RegExp(
    r'^(?:int|long|float|double|char|bool|_Bool|string|String)\s+([A-Za-z_]\w*)\s*=\s*(.+);$',
  );
  final csharpPrint = RegExp(r'^Console\.WriteLine\((.*)\);$');
  final cPrint = RegExp(r'^printf\((.*)\);$');
  var indent = 0;

  final lines = source.split('\n');
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty || line.startsWith('//') || line.startsWith('#include ')) {
      output.add('');
      continue;
    }

    if (line == 'using System;') {
      output.add('');
      continue;
    }

    if (classWrapper.hasMatch(line) ||
        mainWrapper.hasMatch(line) ||
        cMainWrapper.hasMatch(line)) {
      output.add('');
      indent++;
      continue;
    }

    if (line == '}') {
      if (indent == 0) {
        throw RunException('Unexpected closing brace.', index + 1);
      }
      indent--;
      output.add('');
      continue;
    }

    if (line == 'return;' || line == 'return 0;') {
      output.add('');
      continue;
    }

    final loop = forLoop.firstMatch(line);
    if (loop != null) {
      output.add(
        '${_indentation(indent)}for ${loop.group(1)} in range(${loop.group(2)}, ${loop.group(3)}):',
      );
      indent++;
      continue;
    }

    final variable = declaration.firstMatch(line);
    final csharpPrintMatch = csharpPrint.firstMatch(line);
    final cPrintMatch = cPrint.firstMatch(line);
    final statement = variable != null
        ? '${variable.group(1)} = ${variable.group(2)}'
        : csharpPrintMatch != null
        ? 'print(${csharpPrintMatch.group(1)})'
        : cPrintMatch != null
        ? _translatePrintf(cPrintMatch.group(1)!, index + 1)
        : line.endsWith(';')
        ? line.substring(0, line.length - 1)
        : null;

    if (statement == null || line.contains('{') || line.contains('}')) {
      throw RunException(
        'Unsupported $language syntax in this puzzle.',
        index + 1,
      );
    }
    output.add('${_indentation(indent)}$statement');
  }

  if (indent != 0) {
    throw RunException('Missing a closing brace.', source.split('\n').length);
  }
  return output.join('\n');
}

String _translatePrintf(String arguments, int line) {
  final parts = _splitArguments(arguments);
  if (parts.isEmpty) throw RunException('printf needs a format string.', line);

  final formatToken = parts.first.trim();
  if (formatToken.length < 2 ||
      !const {'"', "'"}.contains(formatToken[0]) ||
      formatToken[formatToken.length - 1] != formatToken[0]) {
    throw RunException('printf needs a quoted format string.', line);
  }
  final format = _decodeCString(
    formatToken.substring(1, formatToken.length - 1),
  );
  final values = parts.skip(1).toList();
  final pieces = <String>[];
  final literal = StringBuffer();
  var valueIndex = 0;

  void flushLiteral() {
    if (literal.isEmpty) return;
    pieces.add(_quoteForInterpreter(literal.toString()));
    literal.clear();
  }

  for (var index = 0; index < format.length; index++) {
    final char = format[index];
    if (char != '%' || index + 1 >= format.length) {
      literal.write(char);
      continue;
    }

    final specifier = format[index + 1];
    if (specifier == '%') {
      literal.write('%');
      index++;
      continue;
    }
    if (!const {'d', 'i', 'u', 'f', 's', 'c'}.contains(specifier)) {
      throw RunException('Unsupported printf format specifier.', line);
    }
    if (valueIndex >= values.length) {
      throw RunException(
        'printf is missing a value for its format string.',
        line,
      );
    }
    flushLiteral();
    pieces.add('str(${values[valueIndex++]})');
    index++;
  }
  flushLiteral();

  if (valueIndex != values.length) {
    throw RunException('printf has more values than format specifiers.', line);
  }
  return 'print(${pieces.isEmpty ? '""' : pieces.join(' + ')})';
}

List<String> _splitArguments(String source) {
  final result = <String>[];
  var start = 0;
  var depth = 0;
  String? quote;
  var escaped = false;

  for (var index = 0; index < source.length; index++) {
    final char = source[index];
    if (quote != null) {
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == '"' || char == "'") {
      quote = char;
    } else if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
    } else if (char == ',' && depth == 0) {
      result.add(source.substring(start, index).trim());
      start = index + 1;
    }
  }
  result.add(source.substring(start).trim());
  return result;
}

String _decodeCString(String value) {
  final result = StringBuffer();
  for (var index = 0; index < value.length; index++) {
    final char = value[index];
    if (char == r'\' && index + 1 < value.length) {
      final next = value[++index];
      result.write(switch (next) {
        'n' => '\n',
        't' => '\t',
        _ => next,
      });
    } else {
      result.write(char);
    }
  }
  return result.toString();
}

String _quoteForInterpreter(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\t', r'\t');
  return '"$escaped"';
}

String _indentation(int depth) => List.filled(depth, '    ').join();
