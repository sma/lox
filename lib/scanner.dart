import 'runtime_error.dart';
import 'token.dart';

class Scanner {
  final String _source;
  final List<Token> _tokens = [];
  int _start = 0;
  int _current = 0;
  int _line = 1;

  Scanner(this._source);

  List<Token> scanTokens() {
    while (!_isAtEnd) {
      // We are at the beginning of the next lexeme.
      _start = _current;
      _scanToken();
    }

    _tokens.add(Token(TokenType.EOF, '', null, _line));
    return _tokens;
  }

  bool get _isAtEnd => _current >= _source.length;

  void _scanToken() {
    var c = _advance();
    switch (c) {
      case '(':
        _addToken(TokenType.LEFT_PAREN);
        break;
      case ')':
        _addToken(TokenType.RIGHT_PAREN);
        break;
      case '{':
        _addToken(TokenType.LEFT_BRACE);
        break;
      case '}':
        _addToken(TokenType.RIGHT_BRACE);
        break;
      case ',':
        _addToken(TokenType.COMMA);
        break;
      case '.':
        _addToken(TokenType.DOT);
        break;
      case '-':
        _addToken(TokenType.MINUS);
        break;
      case '+':
        _addToken(TokenType.PLUS);
        break;
      case ';':
        _addToken(TokenType.SEMICOLON);
        break;
      case '*':
        _addToken(TokenType.STAR);
        break;
      case '!':
        _addToken(_match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);
        break;
      case '=':
        _addToken(_match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
        break;
      case '<':
        _addToken(_match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);
        break;
      case '>':
        _addToken(_match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);
        break;
      case '/':
        if (_match('/')) {
          // A comment goes until the end of the line.
          while (_peek() != '\n' && !_isAtEnd) {
            _advance();
          }
        } else {
          _addToken(TokenType.SLASH);
        }
        break;

      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace.
        break;

      case '\n':
        _line++;
        break;

      case '"':
        _string();
        break;
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          throw RuntimeError(
            Token(TokenType.IDENTIFIER, c, null, _line),
            'Unexpected character.',
          );
        }
    }
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    // See if the identifier is a reserved word.
    var text = _source.substring(_start, _current);

    _addToken(keywords[text] ?? TokenType.IDENTIFIER);
  }

  void _number() {
    while (_isDigit(_peek())) {
      _advance();
    }

    // Look for a fractional part.
    if (_peek() == '.' && _isDigit(_peekNext())) {
      // Consume the "."
      _advance();

      while (_isDigit(_peek())) {
        _advance();
      }
    }

    _addToken(
        TokenType.NUMBER, double.parse(_source.substring(_start, _current)));
  }

  void _string() {
    while (_peek() != '"' && !_isAtEnd) {
      if (_peek() == '\n') _line++;
      _advance();
    }

    // Unterminated string.
    if (_isAtEnd) {
      throw RuntimeError(
        Token(TokenType.EOF, '', null, _line),
        'Unterminated string.',
      );
    }

    // The closing ".
    _advance();

    // Trim the surrounding quotes.
    var value = _source.substring(_start + 1, _current - 1);
    _addToken(TokenType.STRING, value);
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (_source[_current] != expected) return false;

    _current++;
    return true;
  }

  String _peek() {
    if (_isAtEnd) return '\x00';
    return _source[_current];
  }

  String _peekNext() {
    if (_current + 1 >= _source.length) return '\x00';
    return _source[_current + 1];
  }

  bool _isAlpha(String c) {
    var u = c.codeUnitAt(0);
    return (u >= 97 && u <= 122) || (u >= 65 && u <= 90) || c == '_';
  }

  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }

  bool _isDigit(String c) {
    var u = c.codeUnitAt(0);
    return u >= 48 && u <= 57;
  }

  String _advance() {
    return _source[_current++];
  }

  void _addToken(TokenType type, [Object? literal]) {
    var text = _source.substring(_start, _current);
    _tokens.add(Token(type, text, literal, _line));
  }

  static const keywords = <String, TokenType>{
    'and': TokenType.AND,
    'class': TokenType.CLASS,
    'else': TokenType.ELSE,
    'false': TokenType.FALSE,
    'for': TokenType.FOR,
    'fun': TokenType.FUN,
    'if': TokenType.IF,
    'nil': TokenType.NIL,
    'or': TokenType.OR,
    'print': TokenType.PRINT,
    'return': TokenType.RETURN,
    'super': TokenType.SUPER,
    'this': TokenType.THIS,
    'true': TokenType.TRUE,
    'var': TokenType.VAR,
    'while': TokenType.WHILE,
  };
}
