part of 'ast.dart';

sealed class const Stmt() {
  R accept<R>(StmtVisitor<R> visitor);
}

abstract class StmtVisitor<R> {
  R visitBlockStmt(Block stmt);
  R visitClassStmt(Class stmt);
  R visitExpressionStmt(Expression stmt);
  R visitFuncStmt(Func stmt);
  R visitIfStmt(If stmt);
  R visitPrintStmt(Print stmt);
  R visitReturnStmt(Return stmt);
  R visitVarStmt(Var stmt);
  R visitWhileStmt(While stmt);
}

class const Block(
  final List<Stmt> statements,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitBlockStmt(this);
  }
}

class const Class(
  final Token name,
  final Variable? superclass,
  final List<Func> methods,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitClassStmt(this);
  }
}

class const Expression(
  final Expr expression,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitExpressionStmt(this);
  }
}

class const Func(
  final Token name,
  final List<Token> params,
  final List<Stmt> body,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitFuncStmt(this);
  }
}

class const If(
  final Expr condition,
  final Stmt thenBranch,
  final Stmt? elseBranch,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitIfStmt(this);
  }
}

class const Print(
  final Expr expression,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitPrintStmt(this);
  }
}

class const Return(
  final Token keyword,
  final Expr? value,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitReturnStmt(this);
  }
}

class const Var(
  final Token name,
  final Expr? initializer,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitVarStmt(this);
  }
}

class const While(
  final Expr condition,
  final Stmt body,
) extends Stmt {

  @override
  R accept<R>(StmtVisitor<R> visitor) {
    return visitor.visitWhileStmt(this);
  }
}
