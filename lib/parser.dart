import 'ast.dart';
import 'runtime_error.dart';
import 'token.dart';

class Parser {
  final List<Token> _tokens;
  int _current = 0;

  Parser(this._tokens);

  List<Stmt> parse() {
    var statements = <Stmt>[];
    while (!isAtEnd()) {
      statements.add(declaration());
    }

    return statements;
  }

  Expr expression() {
    return equality();
  }

  Stmt declaration() {
    if (match(VAR)) return varDeclaration();

    return statement();
  }

  Stmt statement() {
    if (match(PRINT)) return printStatement();

    return expressionStatement();
  }

  Stmt printStatement() {
    var value = expression();
    consume(SEMICOLON, "Expect ';' after value.");
    return Print(value);
  }

  Stmt varDeclaration() {
    var name = consume(IDENTIFIER, "Expect variable name.");

    Expr initializer;
    if (match(EQUAL)) {
      initializer = expression();
    }

    consume(SEMICOLON, "Expect ';' after variable declaration.");
    return Var(name, initializer);
  }

  Stmt expressionStatement() {
    var expr = expression();
    consume(SEMICOLON, "Expect ';' after expression.");
    return Expression(expr);
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

    if (match(IDENTIFIER)) {
      return Variable(previous());
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
    return RuntimeError(token, message);
  }

  void synchronize() {
    advance();

    while (!isAtEnd()) {
      if (previous().type == SEMICOLON) return;

      switch (peek().type) {
        case CLASS:
        case FUN:
        case VAR:
        case FOR:
        case IF:
        case WHILE:
        case PRINT:
        case RETURN:
          return;
        default:
          advance();
      }
    }
  }
}
