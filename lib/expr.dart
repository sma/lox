part of 'ast.dart';

sealed class const Expr() {
  R accept<R>(ExprVisitor<R> visitor);
}

abstract class ExprVisitor<R> {
  R visitAssignExpr(Assign expr);
  R visitBinaryExpr(Binary expr);
  R visitCallExpr(Call expr);
  R visitGetExpr(Get expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitLogicalExpr(Logical expr);
  R visitSetExpr(Set expr);
  R visitSuperExpr(Super expr);
  R visitThisExpr(This expr);
  R visitUnaryExpr(Unary expr);
  R visitVariableExpr(Variable expr);
}

class const Assign(
  final Token name,
  final Expr value,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitAssignExpr(this);
  }
}

class const Binary(
  final Expr left,
  final Token operator,
  final Expr right,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitBinaryExpr(this);
  }
}

class const Call(
  final Expr callee,
  final Token paren,
  final List<Expr> arguments,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitCallExpr(this);
  }
}

class const Get(
  final Expr object,
  final Token name,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGetExpr(this);
  }
}

class const Grouping(
  final Expr expression,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGroupingExpr(this);
  }
}

class const Literal(
  final Object? value,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLiteralExpr(this);
  }
}

class const Logical(
  final Expr left,
  final Token operator,
  final Expr right,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLogicalExpr(this);
  }
}

class const Set(
  final Expr object,
  final Token name,
  final Expr value,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitSetExpr(this);
  }
}

class const Super(
  final Token keyword,
  final Token method,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitSuperExpr(this);
  }
}

class const This(
  final Token keyword,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitThisExpr(this);
  }
}

class const Unary(
  final Token operator,
  final Expr right,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitUnaryExpr(this);
  }
}

class const Variable(
  final Token name,
) extends Expr {

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitVariableExpr(this);
  }
}
