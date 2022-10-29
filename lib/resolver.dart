// ignore_for_file: constant_identifier_names

import 'ast.dart';
import 'interpreter.dart';
import 'runtime_error.dart';
import 'token.dart';

class Resolver implements ExprVisitor<void>, StmtVisitor<void> {
  final Interpreter interpreter;
  final List<Map<String, bool>> scopes = [];
  var currentClass = ClassType.NONE;
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

  void resolveFunction(Func function, FunctionType type) {
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
  void visitClassStmt(Class stmt) {
    var enclosingClass = currentClass;
    currentClass = ClassType.CLASS;

    declare(stmt.name);
    define(stmt.name);
    var superclass = stmt.superclass;
    if (superclass is Variable) {
      if (stmt.name.lexeme == superclass.name.lexeme) {
        throw RuntimeError(superclass.name, 'A class cannot inherit from itself.');
      }
      currentClass = ClassType.SUBCLASS;
      resolveE(superclass);

      beginScope();
      scopes.last['super'] = true;
    }

    beginScope();
    scopes.last['this'] = true;

    for (var method in stmt.methods) {
      var declaration = method.name.lexeme == 'init' ? FunctionType.INITIALIZER : FunctionType.METHOD;
      resolveFunction(method, declaration);
    }

    endScope();

    if (stmt.superclass != null) endScope();

    currentClass = enclosingClass;
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    resolveE(stmt.expression);
  }

  @override
  void visitFuncStmt(Func stmt) {
    declare(stmt.name);
    define(stmt.name);

    resolveFunction(stmt, FunctionType.FUNCTION);
  }

  @override
  void visitIfStmt(If stmt) {
    resolveE(stmt.condition);
    resolveS(stmt.thenBranch);
    if (stmt.elseBranch != null) resolveS(stmt.elseBranch!);
  }

  @override
  void visitPrintStmt(Print stmt) {
    resolveE(stmt.expression);
  }

  @override
  void visitReturnStmt(Return stmt) {
    if (currentFunction == FunctionType.NONE) {
      throw RuntimeError(stmt.keyword, 'Cannot return from top-level code.');
    }
    if (stmt.value != null) {
      if (currentFunction == FunctionType.INITIALIZER) {
        throw RuntimeError(stmt.keyword, 'Cannot return a value from an initializer.');
      }
      resolveE(stmt.value!);
    }
  }

  @override
  void visitVarStmt(Var stmt) {
    declare(stmt.name);
    if (stmt.initializer != null) {
      resolveE(stmt.initializer!);
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
  void visitGetExpr(Get expr) {
    resolveE(expr.object);
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
  void visitSetExpr(Set expr) {
    resolveE(expr.value);
    resolveE(expr.object);
  }

  @override
  void visitSuperExpr(Super expr) {
    if (currentClass == ClassType.NONE) {
      throw RuntimeError(expr.keyword, "Cannot use 'super' outside of a class.");
    } else if (currentClass != ClassType.SUBCLASS) {
      throw RuntimeError(expr.keyword, "Cannot use 'super' in a class with no superclass.");
    }
    resolveLocal(expr, expr.keyword);
  }

  @override
  void visitThisExpr(This expr) {
    if (currentClass == ClassType.NONE) {
      throw RuntimeError(expr.keyword, "Cannot use 'this' outside of a class.");
    }

    resolveLocal(expr, expr.keyword);
  }

  @override
  void visitUnaryExpr(Unary expr) {
    resolveE(expr.right);
  }

  @override
  void visitVariableExpr(Variable expr) {
    if (scopes.isNotEmpty && scopes.last[expr.name.lexeme] == false) {
      throw RuntimeError(expr.name, 'Cannot read local variable in its own initializer.');
    }

    resolveLocal(expr, expr.name);
  }
}

enum ClassType { NONE, CLASS, SUBCLASS }

enum FunctionType { NONE, FUNCTION, INITIALIZER, METHOD }
