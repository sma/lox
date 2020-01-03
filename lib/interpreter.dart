import 'ast.dart';
import 'environment.dart';
import 'lox_callable.dart';
import 'lox_class.dart';
import 'lox_function.dart';
import 'lox_instance.dart';
import 'lox_return.dart';
import 'runtime_error.dart';
import 'token.dart';
import 'token_type.dart';

class Interpreter implements ExprVisitor<Object>, StmtVisitor<void> {
  final globals = Environment();
  final locals = <Expr, int>{};
  Environment environment;

  Interpreter() {
    globals.define(
      "clock",
      LoxCallable(0, (interpreter, arguments) {
        return DateTime.now().millisecondsSinceEpoch / 1000;
      }),
    );
    environment = globals;
  }

  @override
  Object visitLiteralExpr(Literal expr) {
    return expr.value;
  }

  @override
  Object visitLogicalExpr(Logical expr) {
    var left = evaluate(expr.left);

    if (expr.operator.type == TokenType.OR) {
      if (isTruthy(left)) return left;
    } else {
      if (!isTruthy(left)) return left;
    }

    return evaluate(expr.right);
  }

  @override
  Object visitSetExpr(Set expr) {
    var object = evaluate(expr.object);

    if (object is LoxInstance) {
      var value = evaluate(expr.value);
      object.set(expr.name, value);
      return value;
    }
    throw RuntimeError(expr.name, "Only instances have fields.");
  }

  @override
  Object visitThisExpr(This expr) {
    return lookUpVariable(expr.keyword, expr);
  }

  @override
  Object visitGroupingExpr(Grouping expr) {
    return evaluate(expr.expression);
  }

  @override
  Object visitUnaryExpr(Unary expr) {
    var right = evaluate(expr.right);

    switch (expr.operator.type) {
      case BANG:
        return !isTruthy(right);
      case MINUS:
        return -checkNumberOperand(expr.operator, right);
      default:
        return null;
    }
  }

  @override
  Object visitVariableExpr(Variable expr) {
    return lookUpVariable(expr.name, expr);
  }

  Object lookUpVariable(Token name, Expr expr) {
    var distance = locals[expr];
    if (distance != null) {
      return environment.getAt(distance, name.lexeme);
    } else {
      return globals.get(name);
    }
  }

  double checkNumberOperand(Token operator, Object operand) {
    if (operand is double) return operand;
    throw RuntimeError(operator, "Operand must be a number.");
  }

  void checkNumberOperands(Token operator, Object left, Object right) {
    if (left is double && right is double) return;

    throw RuntimeError(operator, "Operands must be numbers.");
  }

  bool isTruthy(Object object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  Object evaluate(Expr expr) {
    return expr.accept(this);
  }

  void execute(Stmt stmt) {
    stmt.accept(this);
  }

  void resolve(Expr expr, int depth) {
    locals[expr] = depth;
  }

  @override
  void visitBlockStmt(Block stmt) {
    executeBlock(stmt.statements, Environment(environment));
  }

  @override
  void visitClassStmt(Class stmt) {
    environment.define(stmt.name.lexeme, null);

    var methods = <String, LoxFunction>{};
    for (var method in stmt.methods) {
      var function = LoxFunction(method, environment);
      methods[method.name.lexeme] = function;
    }

    var klass = LoxClass(stmt.name.lexeme, methods);
    environment.assign(stmt.name, klass);
  }

  void executeBlock(List<Stmt> statements, Environment environment) {
    var previous = this.environment;
    try {
      this.environment = environment;

      for (var statement in statements) {
        execute(statement);
      }
    } finally {
      this.environment = previous;
    }
  }

  @override
  void visitIfStmt(If stmt) {
    if (isTruthy(evaluate(stmt.condition))) {
      execute(stmt.thenBranch);
    } else if (stmt.elseBranch != null) {
      execute(stmt.elseBranch);
    }
    return null;
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    evaluate(stmt.expression);
  }

  @override
  void visitFunctionStmt(Function stmt) {
    var function = LoxFunction(stmt, environment);
    environment.define(stmt.name.lexeme, function);
  }

  @override
  void visitPrintStmt(Print stmt) {
    var value = evaluate(stmt.expression);
    print(stringify(value));
  }

  @override
  void visitReturnStmt(Return stmt) {
    var value = stmt.value != null ? evaluate(stmt.value) : null;
    throw LoxReturn(value);
  }

  @override
  void visitVarStmt(Var stmt) {
    Object value;
    if (stmt.initializer != null) {
      value = evaluate(stmt.initializer);
    }

    environment.define(stmt.name.lexeme, value);
  }

  @override
  void visitWhileStmt(While stmt) {
    while (isTruthy(evaluate(stmt.condition))) {
      execute(stmt.body);
    }
    return null;
  }

  @override
  Object visitAssignExpr(Assign expr) {
    var value = evaluate(expr.value);

    var distance = locals[expr];
    if (distance != null) {
      environment.assignAt(distance, expr.name, value);
    } else {
      globals.assign(expr.name, value);
    }
    return value;
  }

  @override
  Object visitBinaryExpr(Binary expr) {
    var left = evaluate(expr.left);
    var right = evaluate(expr.right);
    switch (expr.operator.type) {
      case GREATER:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) > (right as double);
      case GREATER_EQUAL:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) >= (right as double);
      case LESS:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) < (right as double);
      case LESS_EQUAL:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) <= (right as double);
      case MINUS:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) - (right as double);
      case PLUS:
        if (left is double && right is double) {
          return left + right;
        }
        if (left is String && right is String) {
          return left + right;
        }
        throw RuntimeError(expr.operator, "Operands must be two numbers or two strings.");
      case SLASH:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) / (right as double);
      case STAR:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) * (right as double);
      case BANG_EQUAL:
        return !isEqual(left, right);
      case EQUAL_EQUAL:
        return isEqual(left, right);
      default:
        return null;
    }
  }

  @override
  Object visitCallExpr(Call expr) {
    var callee = evaluate(expr.callee);
    if (callee is LoxCallable) {
      var arguments = <Object>[];
      for (var argument in expr.arguments) {
        arguments.add(evaluate(argument));
      }
      if (arguments.length != callee.arity) {
        throw RuntimeError(
            expr.paren,
            'Expected ${callee.arity} arguments '
            'but got ${arguments.length}.');
      }
      return callee.call(this, arguments);
    }
    throw RuntimeError(expr.paren, 'Can only call functions and classes.');
  }

  @override
  Object visitGetExpr(Get expr) {
    var object = evaluate(expr.object);
    if (object is LoxInstance) {
      return object.get(expr.name);
    }

    throw RuntimeError(expr.name, "Only instances have properties.");
  }

  bool isEqual(Object a, Object b) => a == b;

  String stringify(Object object) {
    if (object == null) return "nil";

    // Hack. Work around Dart adding ".0" to integer-valued doubles.
    if (object is double) {
      var text = object.toString();
      if (text.endsWith(".0")) {
        text = text.substring(0, text.length - 2);
      }
      return text;
    }

    return object.toString();
  }

  void interpret(List<Stmt> statements) {
    for (var statement in statements) {
      execute(statement);
    }
  }
}
