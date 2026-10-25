/// Parses the player's script into an AST.
/// Supported syntax:  move();  turnLeft();  turnRight();  repeat(3) { move(); }
sealed class Node {}

class CallNode extends Node {
  final String name;
  CallNode(this.name);
}

class RepeatNode extends Node {
  final int count;
  final List<Node> body;
  RepeatNode(this.count, this.body);
}

class ParseException implements Exception {
  final String message;
  ParseException(this.message);
  @override
  String toString() => message;
}

class Parser {
  static final _tokenRegex = RegExp(r'[A-Za-z_]\w*|\d+|[(){};]');

  final List<String> _tokens;
  int _i = 0;

  Parser(String source)
      : _tokens = _tokenRegex.allMatches(source).map((m) => m.group(0)!).toList();

  static List<Node> parse(String source) => Parser(source)._parseProgram();

  String get _current => _i < _tokens.length ? _tokens[_i] : 'end of code';

  List<Node> _parseProgram() {
    final nodes = _parseBlock();
    if (_i < _tokens.length) {
      throw ParseException('Unexpected "$_current"');
    }
    return nodes;
  }

  List<Node> _parseBlock() {
    final out = <Node>[];
    while (_i < _tokens.length && _tokens[_i] != '}') {
      out.add(_parseStatement());
    }
    return out;
  }

  Node _parseStatement() {
    final name = _tokens[_i++];
    if (name == 'repeat') {
      _expect('(');
      final count = int.tryParse(_current);
      if (count == null) throw ParseException('repeat() needs a number');
      _i++;
      _expect(')');
      _expect('{');
      final body = _parseBlock();
      _expect('}');
      return RepeatNode(count, body);
    }
    _expect('(');
    _expect(')');
    _expect(';');
    return CallNode(name);
  }

  void _expect(String token) {
    if (_i >= _tokens.length || _tokens[_i] != token) {
      throw ParseException('Expected "$token" but got "$_current"');
    }
    _i++;
  }
}
