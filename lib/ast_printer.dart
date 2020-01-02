import 'ast.dart';

// Creates an unambiguous, if ugly, string representation of AST nodes.
class AstPrinter implements ExprVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitBinaryExpr(Binary expr) {
    return parenthesize(expr.operator.lexeme, expr.left, expr.right);
  }

  @override
  String visitGroupingExpr(Grouping expr) {
    return parenthesize("group", expr.expression);
  }

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return "nil";
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) {
    return parenthesize(expr.operator.lexeme, expr.right);
  }

  @override
  String visitVariableExpr(Variable expr) {
    return expr.name.lexeme;
  }

  @override
  String visitAssignExpr(Assign expr) {
    return parenthesize('assign', Variable(expr.name), expr.value);
  }

  String parenthesize(String name, [Expr e1, Expr e2, Expr e3]) {
    var builder = StringBuffer();

    builder..write("(")..write(name);
    for (var expr in [e1, e2, e3].whereType<Expr>()) {
      builder..write(" ")..write(expr.accept(this));
    }
    builder.write(")");

    return builder.toString();
  }
}
