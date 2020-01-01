part of ast;

abstract class Stmt {
  R accept<R>(StmtVisitor<R> visitor);
}

abstract class StmtVisitor<R> {
  R visitExpressionStmt(Expression stmt);
  R visitPrintStmt(Print stmt);
}

class Expression extends Stmt {
  Expression(
    this.expression,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitExpressionStmt(this);
  }

  final Expr expression;
}

class Print extends Stmt {
  Print(
    this.expression,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitPrintStmt(this);
  }

  final Expr expression;
}
