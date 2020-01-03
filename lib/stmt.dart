part of ast;

abstract class Stmt {
  R accept<R>(StmtVisitor<R> visitor);
}

abstract class StmtVisitor<R> {
  R visitBlockStmt(Block stmt);
  R visitClassStmt(Class stmt);
  R visitExpressionStmt(Expression stmt);
  R visitFunctionStmt(Function stmt);
  R visitIfStmt(If stmt);
  R visitPrintStmt(Print stmt);
  R visitReturnStmt(Return stmt);
  R visitVarStmt(Var stmt);
  R visitWhileStmt(While stmt);
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

class Class extends Stmt {
  Class(
    this.name,
    this.superclass,
    this.methods,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitClassStmt(this);
  }

  final Token name;
  final Variable superclass;
  final List<Function> methods;
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

class Function extends Stmt {
  Function(
    this.name,
    this.params,
    this.body,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitFunctionStmt(this);
  }

  final Token name;
  final List<Token> params;
  final List<Stmt> body;
}

class If extends Stmt {
  If(
    this.condition,
    this.thenBranch,
    this.elseBranch,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitIfStmt(this);
  }

  final Expr condition;
  final Stmt thenBranch;
  final Stmt elseBranch;
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

class Return extends Stmt {
  Return(
    this.keyword,
    this.value,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitReturnStmt(this);
  }

  final Token keyword;
  final Expr value;
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

class While extends Stmt {
  While(
    this.condition,
    this.body,
  );

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitWhileStmt(this);
  }

  final Expr condition;
  final Stmt body;
}
