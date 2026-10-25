/// A tiny Python-like interpreter for Codescapes puzzles.
///
/// Supports: print(), variables, + - * / // %, comparisons (== != < > <= >=),
/// and / or / not, if / elif / else, while, for ... in range(...),
/// and the helpers len(), str(), int().

class RunException implements Exception {
  final String message;
  final int? line;
  RunException(this.message, [this.line]);

  @override
  String toString() => line == null ? message : 'Line $line: $message';
}

class ExecResult {
  final String output;
  final RunException? error;
  const ExecResult(this.output, this.error);
}

/// Runs source code. Never throws: problems come back in [ExecResult.error].
ExecResult runProgram(String source) {
  final interp = _Interpreter();
  try {
    final program = parseProgram(source);
    interp.execBlock(program);
    return ExecResult(interp.out.toString(), null);
  } on RunException catch (e) {
    return ExecResult(interp.out.toString(), e);
  }
}

// ---------------------------------------------------------------- tokens

enum TokType { number, string, name, op }

class Tok {
  final TokType type;
  final String text;
  const Tok(this.type, this.text);
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

bool _isAlpha(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 65 && u <= 90) || (u >= 97 && u <= 122) || u == 95;
}

const _keywords = {'if', 'elif', 'else', 'while', 'for', 'in', 'and', 'or', 'not'};

List<Tok> tokenizeLine(String s, int line) {
  final toks = <Tok>[];
  const twoChar = {'==', '!=', '<=', '>=', '//', '+=', '-=', '*='};
  const oneChar = '+-*/%<>=(),:';
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == ' ' || c == '\t') {
      i++;
      continue;
    }
    if (c == '#') break;

    if (_isDigit(c)) {
      var j = i;
      while (j < s.length && _isDigit(s[j])) {
        j++;
      }
      if (j + 1 < s.length && s[j] == '.' && _isDigit(s[j + 1])) {
        j++;
        while (j < s.length && _isDigit(s[j])) {
          j++;
        }
      }
      toks.add(Tok(TokType.number, s.substring(i, j)));
      i = j;
      continue;
    }

    if (_isAlpha(c)) {
      var j = i;
      while (j < s.length && (_isAlpha(s[j]) || _isDigit(s[j]))) {
        j++;
      }
      toks.add(Tok(TokType.name, s.substring(i, j)));
      i = j;
      continue;
    }

    if (c == '"' || c == "'") {
      final buf = StringBuffer();
      var j = i + 1;
      var closed = false;
      while (j < s.length) {
        final d = s[j];
        if (d == '\\' && j + 1 < s.length) {
          final e = s[j + 1];
          buf.write(e == 'n' ? '\n' : (e == 't' ? '\t' : e));
          j += 2;
          continue;
        }
        if (d == c) {
          closed = true;
          j++;
          break;
        }
        buf.write(d);
        j++;
      }
      if (!closed) throw RunException('Missing a closing quote', line);
      toks.add(Tok(TokType.string, buf.toString()));
      i = j;
      continue;
    }

    if (i + 1 < s.length && twoChar.contains(s.substring(i, i + 2))) {
      toks.add(Tok(TokType.op, s.substring(i, i + 2)));
      i += 2;
      continue;
    }
    if (oneChar.contains(c)) {
      toks.add(Tok(TokType.op, c));
      i++;
      continue;
    }
    throw RunException('Unexpected character "$c"', line);
  }
  return toks;
}

// ------------------------------------------------------------------- AST

sealed class Expr {}

class NumLit extends Expr {
  final num value;
  NumLit(this.value);
}

class StrLit extends Expr {
  final String value;
  StrLit(this.value);
}

class BoolLit extends Expr {
  final bool value;
  BoolLit(this.value);
}

class VarRef extends Expr {
  final String name;
  VarRef(this.name);
}

class BinOp extends Expr {
  final String op;
  final Expr left, right;
  BinOp(this.op, this.left, this.right);
}

class UnaryOp extends Expr {
  final String op;
  final Expr operand;
  UnaryOp(this.op, this.operand);
}

class CallExpr extends Expr {
  final String name;
  final List<Expr> args;
  CallExpr(this.name, this.args);
}

sealed class Stmt {
  final int line;
  Stmt(this.line);
}

class AssignStmt extends Stmt {
  final String name, op;
  final Expr value;
  AssignStmt(super.line, this.name, this.op, this.value);
}

class ExprStmt extends Stmt {
  final Expr expr;
  ExprStmt(super.line, this.expr);
}

class IfStmt extends Stmt {
  final List<(Expr, List<Stmt>)> branches;
  final List<Stmt>? orelse;
  IfStmt(super.line, this.branches, this.orelse);
}

class WhileStmt extends Stmt {
  final Expr cond;
  final List<Stmt> body;
  WhileStmt(super.line, this.cond, this.body);
}

class ForStmt extends Stmt {
  final String variable;
  final Expr iterable;
  final List<Stmt> body;
  ForStmt(super.line, this.variable, this.iterable, this.body);
}

// ------------------------------------------------------ expression parser

class ExprParser {
  final List<Tok> toks;
  final int line;
  int pos = 0;
  ExprParser(this.toks, this.line);

  bool get atEnd => pos >= toks.length;
  Tok? get peek => atEnd ? null : toks[pos];

  bool isOp(String t) => !atEnd && toks[pos].type == TokType.op && toks[pos].text == t;
  bool _isKw(String t) => !atEnd && toks[pos].type == TokType.name && toks[pos].text == t;

  void expectOp(String t) {
    if (atEnd) throw RunException('Something is missing: "$t"', line);
    if (!isOp(t)) throw RunException('Expected "$t" but found "${toks[pos].text}"', line);
    pos++;
  }

  Expr parseExpression() => _or();

  Expr _or() {
    var left = _and();
    while (_isKw('or')) {
      pos++;
      left = BinOp('or', left, _and());
    }
    return left;
  }

  Expr _and() {
    var left = _not();
    while (_isKw('and')) {
      pos++;
      left = BinOp('and', left, _not());
    }
    return left;
  }

  Expr _not() {
    if (_isKw('not')) {
      pos++;
      return UnaryOp('not', _not());
    }
    return _compare();
  }

  Expr _compare() {
    var left = _add();
    while (!atEnd &&
        toks[pos].type == TokType.op &&
        const {'==', '!=', '<', '>', '<=', '>='}.contains(toks[pos].text)) {
      final op = toks[pos++].text;
      left = BinOp(op, left, _add());
    }
    return left;
  }

  Expr _add() {
    var left = _mul();
    while (isOp('+') || isOp('-')) {
      final op = toks[pos++].text;
      left = BinOp(op, left, _mul());
    }
    return left;
  }

  Expr _mul() {
    var left = _unary();
    while (isOp('*') || isOp('/') || isOp('//') || isOp('%')) {
      final op = toks[pos++].text;
      left = BinOp(op, left, _unary());
    }
    return left;
  }

  Expr _unary() {
    if (isOp('-')) {
      pos++;
      return UnaryOp('-', _unary());
    }
    return _atom();
  }

  Expr _atom() {
    if (atEnd) throw RunException('The line ends too early, something is missing', line);
    final t = toks[pos++];
    if (t.type == TokType.number) {
      return NumLit(t.text.contains('.') ? double.parse(t.text) : int.parse(t.text));
    }
    if (t.type == TokType.string) return StrLit(t.text);
    if (t.type == TokType.name) {
      if (t.text == 'True') return BoolLit(true);
      if (t.text == 'False') return BoolLit(false);
      if (_keywords.contains(t.text)) throw RunException('Unexpected "${t.text}"', line);
      if (isOp('(')) {
        pos++;
        final args = <Expr>[];
        if (!isOp(')')) {
          args.add(parseExpression());
          while (isOp(',')) {
            pos++;
            args.add(parseExpression());
          }
        }
        expectOp(')');
        return CallExpr(t.text, args);
      }
      return VarRef(t.text);
    }
    if (t.text == '(') {
      final e = parseExpression();
      expectOp(')');
      return e;
    }
    throw RunException('Unexpected "${t.text}"', line);
  }
}

// --------------------------------------------------------- block parser

class _Line {
  final int indent;
  final int number;
  final List<Tok> toks;
  _Line(this.indent, this.number, this.toks);
}

List<Stmt> parseProgram(String source) {
  final lines = <_Line>[];
  final raw = source.split('\n');
  for (var i = 0; i < raw.length; i++) {
    final text = raw[i].replaceAll('\r', '');
    final toks = tokenizeLine(text, i + 1);
    if (toks.isEmpty) continue;
    var indent = 0;
    for (var k = 0; k < text.length; k++) {
      if (text[k] == ' ') {
        indent++;
      } else if (text[k] == '\t') {
        indent += 4;
      } else {
        break;
      }
    }
    lines.add(_Line(indent, i + 1, toks));
  }
  if (lines.isEmpty) return [];
  final parser = _BlockParser(lines);
  final stmts = parser.parseBlock(lines.first.indent);
  if (parser.pos < lines.length) {
    throw RunException('Unexpected indentation', lines[parser.pos].number);
  }
  return stmts;
}

class _BlockParser {
  final List<_Line> lines;
  int pos = 0;
  _BlockParser(this.lines);

  List<Stmt> parseBlock(int indent) {
    final out = <Stmt>[];
    while (pos < lines.length && lines[pos].indent == indent) {
      out.add(_statement(indent));
    }
    if (pos < lines.length && lines[pos].indent > indent) {
      throw RunException('Unexpected indentation', lines[pos].number);
    }
    return out;
  }

  List<Stmt> _body(int parentIndent, int headerLine) {
    if (pos >= lines.length || lines[pos].indent <= parentIndent) {
      throw RunException('Expected an indented block after the colon', headerLine);
    }
    return parseBlock(lines[pos].indent);
  }

  void _endHeader(ExprParser ep) {
    if (ep.isOp('=')) {
      throw RunException('Use == to compare values (a single = is for assigning)', ep.line);
    }
    ep.expectOp(':');
    if (!ep.atEnd) {
      throw RunException('Unexpected "${ep.peek!.text}" after the colon', ep.line);
    }
  }

  Stmt _statement(int indent) {
    final ln = lines[pos];
    final toks = ln.toks;
    final first = toks.first;
    final isName = first.type == TokType.name;

    if (isName && first.text == 'if') return _if(indent);

    if (isName && first.text == 'while') {
      pos++;
      final epWhile = ExprParser(toks, ln.number)..pos = 1;
      final cond = epWhile.parseExpression();
      _endHeader(epWhile);
      return WhileStmt(ln.number, cond, _body(indent, ln.number));
    }

    if (isName && first.text == 'for') {
      pos++;
      if (toks.length < 4 ||
          toks[1].type != TokType.name ||
          toks[2].type != TokType.name ||
          toks[2].text != 'in') {
        throw RunException('A for loop looks like: for i in range(3):', ln.number);
      }
      final epFor = ExprParser(toks, ln.number)..pos = 3;
      final iter = epFor.parseExpression();
      _endHeader(epFor);
      return ForStmt(ln.number, toks[1].text, iter, _body(indent, ln.number));
    }

    if (isName &&
        toks.length >= 2 &&
        toks[1].type == TokType.op &&
        const {'=', '+=', '-=', '*='}.contains(toks[1].text)) {
      if (_keywords.contains(first.text)) {
        throw RunException('"${first.text}" cannot be used as a name', ln.number);
      }
      pos++;
      final epAssign = ExprParser(toks, ln.number)..pos = 2;
      final value = epAssign.parseExpression();
      if (!epAssign.atEnd) {
        throw RunException('Unexpected "${epAssign.peek!.text}"', ln.number);
      }
      return AssignStmt(ln.number, first.text, toks[1].text, value);
    }

    pos++;
    final epExpr = ExprParser(toks, ln.number);
    final e = epExpr.parseExpression();
    if (!epExpr.atEnd) {
      throw RunException('Unexpected "${epExpr.peek!.text}"', ln.number);
    }
    return ExprStmt(ln.number, e);
  }

  Stmt _if(int indent) {
    final startLine = lines[pos].number;
    final branches = <(Expr, List<Stmt>)>[];
    List<Stmt>? orelse;

    var ln = lines[pos++];
    var ep = ExprParser(ln.toks, ln.number)..pos = 1;
    var cond = ep.parseExpression();
    _endHeader(ep);
    branches.add((cond, _body(indent, ln.number)));

    while (pos < lines.length &&
        lines[pos].indent == indent &&
        lines[pos].toks.first.type == TokType.name) {
      final kw = lines[pos].toks.first.text;
      if (kw == 'elif') {
        ln = lines[pos++];
        ep = ExprParser(ln.toks, ln.number)..pos = 1;
        cond = ep.parseExpression();
        _endHeader(ep);
        branches.add((cond, _body(indent, ln.number)));
      } else if (kw == 'else') {
        ln = lines[pos++];
        if (ln.toks.length != 2 || ln.toks[1].text != ':') {
          throw RunException('else should be written as:  else:', ln.number);
        }
        orelse = _body(indent, ln.number);
        break;
      } else {
        break;
      }
    }
    return IfStmt(startLine, branches, orelse);
  }
}

// ----------------------------------------------------------- interpreter

class _Interpreter {
  final vars = <String, dynamic>{};
  final out = StringBuffer();
  int steps = 0;
  int line = 0;
  static const maxSteps = 20000;

  RunException _err(String msg) => RunException(msg, line);

  void _tick() {
    if (++steps > maxSteps) {
      throw _err('Your code ran for too long. Is there an infinite loop?');
    }
    if (out.length > 5000) throw _err('Your code printed too much');
  }

  void execBlock(List<Stmt> block) {
    for (final s in block) {
      exec(s);
    }
  }

  void exec(Stmt s) {
    _tick();
    line = s.line;
    switch (s) {
      case AssignStmt():
        final v = eval(s.value);
        if (s.op == '=') {
          vars[s.name] = v;
        } else {
          if (!vars.containsKey(s.name)) throw _err("name '${s.name}' is not defined");
          vars[s.name] = _binary(s.op.substring(0, 1), vars[s.name], v);
        }
      case ExprStmt():
        eval(s.expr);
      case IfStmt():
        for (final (cond, body) in s.branches) {
          line = s.line;
          if (_truthy(eval(cond))) {
            execBlock(body);
            return;
          }
        }
        final otherwise = s.orelse;
        if (otherwise != null) execBlock(otherwise);
      case WhileStmt():
        while (true) {
          line = s.line;
          if (!_truthy(eval(s.cond))) break;
          _tick();
          execBlock(s.body);
        }
      case ForStmt():
        final items = _iterate(s.iterable);
        for (final item in items) {
          _tick();
          vars[s.variable] = item;
          execBlock(s.body);
        }
    }
  }

  List<dynamic> _iterate(Expr e) {
    if (e is CallExpr && e.name == 'range') {
      final a = e.args.map(eval).toList();
      for (final v in a) {
        if (v is! int) throw _err('range() needs whole numbers');
      }
      int start = 0;
      int stop;
      int step = 1;
      if (a.length == 1) {
        stop = a[0] as int;
      } else if (a.length == 2) {
        start = a[0] as int;
        stop = a[1] as int;
      } else if (a.length == 3) {
        start = a[0] as int;
        stop = a[1] as int;
        step = a[2] as int;
      } else {
        throw _err('range() takes 1 to 3 numbers');
      }
      if (step == 0) throw _err('range() step cannot be 0');
      final result = <int>[];
      for (var i = start; step > 0 ? i < stop : i > stop; i += step) {
        result.add(i);
        if (result.length > 10000) throw _err('That loop is too long');
      }
      return result;
    }
    final v = eval(e);
    if (v is String) return v.split('');
    throw _err('A for loop needs range(...) or text to loop over');
  }

  dynamic eval(Expr e) {
    switch (e) {
      case NumLit():
        return e.value;
      case StrLit():
        return e.value;
      case BoolLit():
        return e.value;
      case VarRef():
        if (!vars.containsKey(e.name)) throw _err("name '${e.name}' is not defined");
        return vars[e.name];
      case UnaryOp():
        final v = eval(e.operand);
        if (e.op == 'not') return !_truthy(v);
        if (v is num) return -v;
        throw _err("Can't put a minus sign in front of ${_typeName(v)}");
      case BinOp():
        if (e.op == 'and') {
          final l = eval(e.left);
          return _truthy(l) ? eval(e.right) : l;
        }
        if (e.op == 'or') {
          final l = eval(e.left);
          return _truthy(l) ? l : eval(e.right);
        }
        return _binary(e.op, eval(e.left), eval(e.right));
      case CallExpr():
        return _call(e);
    }
  }

  dynamic _binary(String op, dynamic a, dynamic b) {
    switch (op) {
      case '+':
        if (a is num && b is num) return a + b;
        if (a is String && b is String) return a + b;
        throw _err("Can't add ${_typeName(a)} and ${_typeName(b)}. Try str() to turn a number into text");
      case '-':
      case '*':
      case '/':
      case '//':
      case '%':
        if (op == '*' && a is String && b is int) return b > 0 ? a * b : '';
        if (a is! num || b is! num) {
          throw _err("Can't use '$op' with ${_typeName(a)} and ${_typeName(b)}");
        }
        if ((op == '/' || op == '//' || op == '%') && b == 0) {
          throw _err("You can't divide by zero");
        }
        if (op == '-') return a - b;
        if (op == '*') return a * b;
        if (op == '/') return a / b;
        if (op == '//') {
          final q = (a / b).floor();
          return (a is int && b is int) ? q : q.toDouble();
        }
        return a % b;
      case '==':
        return a == b;
      case '!=':
        return a != b;
      case '<':
      case '>':
      case '<=':
      case '>=':
        int c;
        if (a is num && b is num) {
          c = a.compareTo(b);
        } else if (a is String && b is String) {
          c = a.compareTo(b);
        } else {
          throw _err("Can't compare ${_typeName(a)} with ${_typeName(b)}");
        }
        if (op == '<') return c < 0;
        if (op == '>') return c > 0;
        if (op == '<=') return c <= 0;
        return c >= 0;
    }
    throw _err('Unknown operator $op');
  }

  dynamic _call(CallExpr e) {
    final args = e.args.map(eval).toList();
    switch (e.name) {
      case 'print':
        out.writeln(args.map(_fmt).join(' '));
        return null;
      case 'len':
        if (args.length != 1 || args[0] is! String) {
          throw _err('len() needs one piece of text');
        }
        return (args[0] as String).length;
      case 'str':
        if (args.length != 1) throw _err('str() needs exactly one value');
        return _fmt(args[0]);
      case 'int':
        if (args.length != 1) throw _err('int() needs exactly one value');
        final v = args[0];
        if (v is num) return v.truncate();
        if (v is String) {
          final n = int.tryParse(v.trim());
          if (n == null) throw _err('int() cannot turn "$v" into a number');
          return n;
        }
        throw _err("int() can't convert ${_typeName(v)}");
      case 'range':
        throw _err('range() can only be used inside a for loop');
    }
    throw _err("name '${e.name}' is not defined");
  }
}

bool _truthy(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.isNotEmpty;
  return true;
}

String _typeName(dynamic v) {
  if (v is String) return 'text';
  if (v is num) return 'a number';
  if (v is bool) return 'True/False';
  return 'nothing';
}

/// Formats a value the way Python's print() would.
String _fmt(dynamic v) {
  if (v == null) return 'None';
  if (v is bool) return v ? 'True' : 'False';
  if (v is double && v == v.truncateToDouble() && v.abs() < 1e15) {
    return '${v.toInt()}.0';
  }
  return '$v';
}
