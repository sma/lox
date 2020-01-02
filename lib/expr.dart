part of ast;

abstract class Expr {
  R accept<R>(ExprVisitor<R> visitor);
}

abstract class ExprVisitor<R> {
  R visitAssignExpr(Assign expr);
  R visitBinaryExpr(Binary expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitLogicalExpr(Logical expr);
  R visitUnaryExpr(Unary expr);
  R visitVariableExpr(Variable expr);
}

class Assign extends Expr {
  Assign(
    this.name,
    this.value,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitAssignExpr(this);
  }

  final Token name;
  final Expr value;
}

class Binary extends Expr {
  Binary(
    this.left,
    this.operator,
    this.right,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
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
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGroupingExpr(this);
  }

  final Expr expression;
}

class Literal extends Expr {
  Literal(
    this.value,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLiteralExpr(this);
  }

  final Object value;
}

class Logical extends Expr {
  Logical(
    this.left,
    this.operator,
    this.right,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLogicalExpr(this);
  }

  final Expr left;
  final Token operator;
  final Expr right;
}

class Unary extends Expr {
  Unary(
    this.operator,
    this.right,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitUnaryExpr(this);
  }

  final Token operator;
  final Expr right;
}

class Variable extends Expr {
  Variable(
    this.name,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitVariableExpr(this);
  }

  final Token name;
}
