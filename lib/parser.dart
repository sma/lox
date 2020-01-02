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
    return assignment();
  }

  Stmt declaration() {
    if (match(VAR)) return varDeclaration();

    return statement();
  }

  Stmt statement() {
    if (match(FOR)) return forStatement();
    if (match(IF)) return ifStatement();
    if (match(PRINT)) return printStatement();
    if (match(WHILE)) return whileStatement();
    if (match(LEFT_BRACE)) return Block(block());

    return expressionStatement();
  }

  Stmt forStatement() {
    consume(LEFT_PAREN, "Expect '(' after 'for'.");

    Stmt initializer;
    if (match(SEMICOLON)) {
      initializer = null;
    } else if (match(VAR)) {
      initializer = varDeclaration();
    } else {
      initializer = expressionStatement();
    }

    Expr condition;
    if (!check(SEMICOLON)) {
      condition = expression();
    }
    consume(SEMICOLON, "Expect ';' after loop condition.");

    Expr increment;
    if (!check(RIGHT_PAREN)) {
      increment = expression();
    }
    consume(RIGHT_PAREN, "Expect ')' after for clauses.");
    var body = statement();

    if (increment != null) {
      body = Block([
        body,
        Expression(increment),
      ]);
    }

    body = While(condition ?? Literal(true), body);

    if (initializer != null) {
      body = Block([initializer, body]);
    }

    return body;
  }

  Stmt ifStatement() {
    consume(LEFT_PAREN, "Expect '(' after 'if'.");
    var condition = expression();
    consume(RIGHT_PAREN, "Expect ')' after if condition.");

    var thenBranch = statement();
    var elseBranch = match(ELSE) ? statement() : null;

    return If(condition, thenBranch, elseBranch);
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

  Stmt whileStatement() {
    consume(LEFT_PAREN, "Expect '(' after 'while'.");
    var condition = expression();
    consume(RIGHT_PAREN, "Expect ')' after condition.");
    var body = statement();

    return While(condition, body);
  }

  Stmt expressionStatement() {
    var expr = expression();
    consume(SEMICOLON, "Expect ';' after expression.");
    return Expression(expr);
  }

  List<Stmt> block() {
    var statements = <Stmt>[];

    while (!check(RIGHT_BRACE) && !isAtEnd()) {
      statements.add(declaration());
    }

    consume(RIGHT_BRACE, "Expect '}' after block.");
    return statements;
  }

  Expr assignment() {
    var expr = or();

    if (match(EQUAL)) {
      var equals = previous();
      var value = assignment();

      if (expr is Variable) {
        var name = expr.name;
        return Assign(name, value);
      }

      error(equals, "Invalid assignment target.");
    }

    return expr;
  }

  Expr or() {
    var expr = and();

    while (match(OR)) {
      var operator = previous();
      var right = and();
      expr = Logical(expr, operator, right);
    }

    return expr;
  }

  Expr and() {
    var expr = equality();

    while (match(AND)) {
      var operator = previous();
      var right = equality();
      expr = Logical(expr, operator, right);
    }

    return expr;
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

    return call();
  }

  Expr call() {
    var expr = primary();

    while (true) {
      if (match(LEFT_PAREN)) {
        expr = finishCall(expr);
      } else {
        break;
      }
    }

    return expr;
  }

  Expr finishCall(Expr callee) {
    var arguments = <Expr>[];
    if (!check(RIGHT_PAREN)) {
      do {
        if (arguments.length >= 255) {
          error(peek(), "Cannot have more than 255 arguments.");
        }
        arguments.add(expression());
      } while (match(COMMA));
    }

    var paren = consume(RIGHT_PAREN, "Expect ')' after arguments.");

    return Call(callee, paren, arguments);
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
