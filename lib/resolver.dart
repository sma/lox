import 'ast.dart';
import 'interpreter.dart';
import 'runtime_error.dart';
import 'token.dart';

class Resolver implements ExprVisitor<void>, StmtVisitor<void> {
  final Interpreter interpreter;
  final List<Map<String, bool>> scopes = [];
  var currentFunction = FunctionType.NONE;

  Resolver(this.interpreter);

  void resolve(List<Stmt> statements) {
    for (var statement in statements) {
      resolveS(statement);
    }
  }

  void resolveS(Stmt stmt) {
    stmt.accept(this);
  }

  void resolveE(Expr expr) {
    expr.accept(this);
  }

  void resolveFunction(Function function, FunctionType type) {
    var enclosingFunction = currentFunction;
    currentFunction = type;

    beginScope();
    for (var param in function.params) {
      declare(param);
      define(param);
    }
    resolve(function.body);
    endScope();

    currentFunction = enclosingFunction;
  }

  void beginScope() {
    scopes.add({});
  }

  void endScope() {
    scopes.removeLast();
  }

  void declare(Token name) {
    if (scopes.isEmpty) return;
    if (scopes.last.containsKey(name.lexeme)) {
      throw RuntimeError(name, 'Variable with this name already declared in this scope.');
    }

    scopes.last[name.lexeme] = false;
  }

  void define(Token name) {
    if (scopes.isEmpty) return;
    scopes.last[name.lexeme] = true;
  }

  void resolveLocal(Expr expr, Token name) {
    for (var i = scopes.length - 1; i >= 0; i--) {
      if (scopes[i].containsKey(name.lexeme)) {
        interpreter.resolve(expr, scopes.length - 1 - i);
        return;
      }
    }

    // Not found. Assume it is global.
  }

  @override
  void visitBlockStmt(Block stmt) {
    beginScope();
    resolve(stmt.statements);
    endScope();
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    resolveE(stmt.expression);
  }

  @override
  void visitFunctionStmt(Function stmt) {
    declare(stmt.name);
    define(stmt.name);

    resolveFunction(stmt, FunctionType.FUNCTION);
  }

  @override
  void visitIfStmt(If stmt) {
    resolveE(stmt.condition);
    resolveS(stmt.thenBranch);
    if (stmt.elseBranch != null) resolveS(stmt.elseBranch);
  }

  @override
  void visitReturnStmt(Return stmt) {
    if (currentFunction == FunctionType.NONE) {
      throw RuntimeError(stmt.keyword, 'Cannot return from top-level code.');
    }
    if (stmt.value != null) {
      resolveE(stmt.value);
    }
  }

  @override
  void visitVarStmt(Var stmt) {
    declare(stmt.name);
    if (stmt.initializer != null) {
      resolveE(stmt.initializer);
    }
    define(stmt.name);
  }

  @override
  void visitWhileStmt(While stmt) {
    resolveE(stmt.condition);
    resolveS(stmt.body);
  }

  @override
  void visitAssignExpr(Assign expr) {
    resolveE(expr.value);
    resolveLocal(expr, expr.name);
  }

  @override
  void visitBinaryExpr(Binary expr) {
    resolveE(expr.left);
    resolveE(expr.right);
  }

  @override
  void visitCallExpr(Call expr) {
    resolveE(expr.callee);

    for (var argument in expr.arguments) {
      resolveE(argument);
    }
  }

  @override
  void visitGroupingExpr(Grouping expr) {
    resolveE(expr.expression);
  }

  @override
  void visitLiteralExpr(Literal expr) {}

  @override
  void visitLogicalExpr(Logical expr) {
    resolveE(expr.left);
    resolveE(expr.right);
  }

  @override
  void visitUnaryExpr(Unary expr) {
    resolveE(expr.right);
  }

  @override
  void visitVariableExpr(Variable expr) {
    if (scopes.isNotEmpty && !scopes.last[expr.name.lexeme]) {
      throw RuntimeError(expr.name, 'Cannot read local variable in its own initializer.');
    }

    resolveLocal(expr, expr.name);
  }

  @override
  void visitPrintStmt(Print stmt) {
    resolveE(stmt.expression);
  }
}

enum FunctionType { NONE, FUNCTION }
