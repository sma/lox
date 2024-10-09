enum TokenType {
  // Single-character tokens.
  leftParen,
  rightParen,
  leftBrace,
  rightBrace,
  comma,
  dot,
  minus,
  plus,
  semicolon,
  slash,
  star,
  // One or two character tokens.
  bang,
  bangEqual,
  equal,
  equalEqual,
  greater,
  greaterEqual,
  less,
  lessEqual,
  // Literals.
  identifier,
  string,
  number,
  // Keywords.
  kAnd,
  kClass,
  kElse,
  kFalse,
  kFor,
  kFun,
  kIf,
  kNil,
  kOr,
  kPrint,
  kReturn,
  kSuper,
  kThis,
  kTrue,
  kVar,
  kWhile,
  // Special.
  error,
  eof,
}

class Token {
  const Token(this.type, this.start, this.line);

  final TokenType type;
  final String start;
  final int line;

  @override
  String toString() => '${type.name}: "$start" at $line';

  static const none = Token(TokenType.error, '', 0);
}

class Scanner {
  Scanner(this.source)
      : start = 0,
        current = 0,
        line = 1;

  final String source;
  int start;
  int current;
  int line;

  Token scanToken() {
    _skipWhitespace();

    start = current;

    if (_isAtEnd) return _makeToken(TokenType.eof);

    var c = _advance();

    return switch (c) {
      '(' => _makeToken(TokenType.leftParen),
      ')' => _makeToken(TokenType.rightParen),
      '{' => _makeToken(TokenType.leftBrace),
      '}' => _makeToken(TokenType.rightBrace),
      ',' => _makeToken(TokenType.comma),
      '.' => _makeToken(TokenType.dot),
      '-' => _makeToken(TokenType.minus),
      '+' => _makeToken(TokenType.plus),
      ';' => _makeToken(TokenType.semicolon),
      '/' => _makeToken(TokenType.slash),
      '*' => _makeToken(TokenType.star),
      '!' => _makeToken(_match('=') ? TokenType.bangEqual : TokenType.bang),
      '=' => _makeToken(_match('=') ? TokenType.equalEqual : TokenType.equal),
      '>' => _makeToken(_match('=') ? TokenType.greaterEqual : TokenType.greater),
      '<' => _makeToken(_match('=') ? TokenType.lessEqual : TokenType.less),
      '"' => _string(),
      _ when _isAlpha(c) => _identifier(),
      _ when _isDigit(c) => _number(),
      _ => _errorToken('unexpected character.'),
    };
  }

  bool get _isAtEnd => current == source.length;

  String _peek() => _isAtEnd ? '' : source[current];

  bool _match(String expected) {
    if (_peek() != expected) return false;
    current++;
    return true;
  }

  String _advance() => source[current++];

  void _skipWhitespace() {
    for (;;) {
      if (_isAtEnd) return;

      switch (_advance()) {
        case ' ' || '\r' || '\t':
          continue;
        case '\n':
          line++;
          continue;
        case '/':
          if (!_match('/')) {
            current--;
            return;
          }
          while (!_isAtEnd && source[current] != '\n') {
            _advance();
          }
        default:
          current--;
          return;
      }
    }
  }

  Token _makeToken(TokenType type) => Token(type, source.substring(start, current), line);

  Token _errorToken(String message) => Token(TokenType.error, message, line);

  Token _string() {
    while (!_isAtEnd && _peek() != '"') {
      if (_peek() == '\n') line++;
      _advance();
    }

    if (_isAtEnd) return _errorToken('Unterminated string.');

    _advance();

    return _makeToken(TokenType.string);
  }

  Token _number() {
    while (_isDigit(_peek())) {
      _advance();
    }
    if (_match('.')) {
      if (_isDigit(_peek())) {
        while (_isDigit(_peek())) {
          _advance();
        }
      } else {
        current--;
      }
    }
    return _makeToken(TokenType.number);
  }

  Token _identifier() {
    while (_isAlpha(_peek()) || _isDigit(_peek())) {
      _advance();
    }
    final name = source.substring(start, current);
    final types = const {
      'and': TokenType.kAnd,
      'class': TokenType.kClass,
      'else': TokenType.kElse,
      'false': TokenType.kFalse,
      'for': TokenType.kFor,
      'fun': TokenType.kFun,
      'if': TokenType.kIf,
      'nil': TokenType.kNil,
      'or': TokenType.kOr,
      'print': TokenType.kPrint,
      'return': TokenType.kReturn,
      'super': TokenType.kSuper,
      'this': TokenType.kThis,
      'true': TokenType.kTrue,
      'var': TokenType.kVar,
      'while': TokenType.kWhile,
    };
    return Token(types[name] ?? TokenType.identifier, name, line);
  }
}

bool _isDigit(String c) {
  if (c.isEmpty) return false;
  final u = c.codeUnitAt(0);
  return u >= 48 && u < 58;
}

bool _isAlpha(String c) {
  if (c.isEmpty) return false;
  final u = c.codeUnitAt(0);
  return u >= 65 && u < 91 || u >= 97 && u < 123 || u == 95;
}
