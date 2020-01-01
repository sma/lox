import 'package:lox/token.dart';

abstract class Expr {
  R accept<R>(Visitor<R> visitor);
}

abstract class Visitor<R> {
  R visitBinaryExpr(Binary expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitUnaryExpr(Unary expr);
}

class Binary extends Expr {
  Binary(
    this.left,
    this.operator,
    this.right,
  );

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitBinaryExpr(this);
  }

  final Expr left;
  final Token operator;
  final Expr right;
}

class Grouping extends Expr {
  Grouping(
    this.expression,
  );

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitGroupingExpr(this);
  }

  final Expr expression;
}

class Literal extends Expr {
  Literal(
    this.value,
  );

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitLiteralExpr(this);
  }

  final Object value;
}

class Unary extends Expr {
  Unary(
    this.operator,
    this.right,
  );

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitUnaryExpr(this);
  }

  final Token operator;
  final Expr right;
}
