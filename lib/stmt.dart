part of ast;

abstract class Stmt {
  R accept<R>(StmtVisitor<R> visitor);
}

abstract class StmtVisitor<R> {
  R visitBlockStmt(Block stmt);
  R visitExpressionStmt(Expression stmt);
  R visitPrintStmt(Print stmt);
  R visitVarStmt(Var stmt);
}

class Block extends Stmt {
  Block(
    this.statements,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitBlockStmt(this);
  }

  final List<Stmt> statements;
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

class Var extends Stmt {
  Var(
    this.name,
    this.initializer,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitVarStmt(this);
  }

  final Token name;
  final Expr initializer;
}
