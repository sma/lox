import 'package:lox/ast_printer.dart';
import 'package:lox/ast.dart';
import 'package:lox/token.dart';

void main() {
  Expr expression = Binary(
    Unary(
      Token(TokenType.MINUS, "-", null, 1),
      Literal(123),
    ),
    Token(TokenType.STAR, "*", null, 1),
    Grouping(
      Literal(45.67),
    ),
  );

  print(AstPrinter().print(expression));
}
