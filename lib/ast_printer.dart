import 'expr.dart' as Expr;

// Creates an unambiguous, if ugly, string representation of AST nodes.
class AstPrinter implements Expr.Visitor<String> {
  String print(Expr.Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitBinaryExpr(Expr.Binary expr) {
    return parenthesize(expr.operator.lexeme, expr.left, expr.right);
  }

  @override
  String visitGroupingExpr(Expr.Grouping expr) {
    return parenthesize("group", expr.expression);
  }

  @override
  String visitLiteralExpr(Expr.Literal expr) {
    if (expr.value == null) return "nil";
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Expr.Unary expr) {
    return parenthesize(expr.operator.lexeme, expr.right);
  }

  String parenthesize(String name, [Expr.Expr e1, Expr.Expr e2, Expr.Expr e3]) {
    var builder = StringBuffer();

    builder..write("(")..write(name);
    for (var expr in [e1, e2, e3].whereType<Expr.Expr>()) {
      builder..write(" ")..write(expr.accept(this));
    }
    builder.write(")");

    return builder.toString();
  }
}
