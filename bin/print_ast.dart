import 'package:lox/ast_printer.dart';
import 'package:lox/expr.dart' as Expr;
import 'package:lox/token.dart';

void main() {
  Expr.Expr expression = Expr.Binary(
    Expr.Unary(
      Token(TokenType.MINUS, "-", null, 1),
      Expr.Literal(123),
    ),
    Token(TokenType.STAR, "*", null, 1),
    Expr.Grouping(
      Expr.Literal(45.67),
    ),
  );

  print(AstPrinter().print(expression));
}
