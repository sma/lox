part of ast;

abstract class Expr {
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

class Call extends Expr {
  Call(
    this.callee,
    this.paren,
    this.arguments,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitCallExpr(this);
  }

  final Expr callee;
  final Token paren;
  final List<Expr> arguments;
}

class Get extends Expr {
  Get(
    this.object,
    this.name,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGetExpr(this);
  }

  final Expr object;
  final Token name;
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

  final Object? value;
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

class Set extends Expr {
  Set(
    this.object,
    this.name,
    this.value,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitSetExpr(this);
  }

  final Expr object;
  final Token name;
  final Expr value;
}

class Super extends Expr {
  Super(
    this.keyword,
    this.method,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitSuperExpr(this);
  }

  final Token keyword;
  final Token method;
}

class This extends Expr {
  This(
    this.keyword,
  );

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitThisExpr(this);
  }

  final Token keyword;
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
