import 'ast.dart';
import 'token.dart';

class Parser {
  final List<Token> _tokens;
  int _current = 0;

  Parser(this._tokens);

  Expr parse() {
    try {
      return expression();
    } catch (error) {
      print(error);
      return null;
    }
  }

  Expr expression() {
    return equality();
  }

  Expr equality() {
    var expr = comparison();

    while (match(BANG_EQUAL, EQUAL_EQUAL)) {
      var operator = previous();
      var right = comparison();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr comparison() {
    var expr = addition();

    while (match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL)) {
      var operator = previous();
      var right = addition();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr addition() {
    var expr = multiplication();

    while (match(MINUS, PLUS)) {
      var operator = previous();
      var right = multiplication();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr multiplication() {
    var expr = unary();

    while (match(SLASH, STAR)) {
      var operator = previous();
      var right = unary();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr unary() {
    if (match(BANG, MINUS)) {
      var operator = previous();
      var right = unary();
      return Unary(operator, right);
    }

    return primary();
  }

  Expr primary() {
    if (match(FALSE)) return Literal(false);
    if (match(TRUE)) return Literal(true);
    if (match(NIL)) return Literal(null);

    if (match(NUMBER, STRING)) {
      return Literal(previous().literal);
    }

    if (match(LEFT_PAREN)) {
      var expr = expression();
      consume(RIGHT_PAREN, "Expect ')' after expression.");
      return Grouping(expr);
    }

    throw error(peek(), "Expect expression.");
  }

  bool match([TokenType t1, TokenType t2, TokenType t3, TokenType t4]) {
    for (var type in [t1, t2, t3, t4].whereType<TokenType>()) {
      if (check(type)) {
        advance();
        return true;
      }
    }

    return false;
  }

  Token consume(TokenType type, String message) {
    if (check(type)) return advance();

    throw error(peek(), message);
  }

  bool check(TokenType type) {
    if (isAtEnd()) return false;
    return peek().type == type;
  }

  Token advance() {
    if (!isAtEnd()) _current++;
    return previous();
  }

  bool isAtEnd() {
    return peek().type == EOF;
  }

  Token peek() {
    return _tokens[_current];
  }

  Token previous() {
    return _tokens[_current - 1];
  }

  Exception error(Token token, String message) {
    if (token.type == TokenType.EOF) {
      return Exception('[line ${token.line}] at end: $message');
    } else {
      return Exception('[line ${token.line}] at "${token.lexeme}": $message');
    }
  }
}
