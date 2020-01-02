import 'ast.dart';
import 'environment.dart';
import 'lox_callable.dart';
import 'lox_function.dart';
import 'runtime_error.dart';
import 'token.dart';
import 'token_type.dart';

class Interpreter implements ExprVisitor<Object>, StmtVisitor<void> {
  final globals = Environment();
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
    return environment.get(expr.name);
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

  @override
  void visitBlockStmt(Block stmt) {
    executeBlock(stmt.statements, Environment(environment));
    return null;
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
    var function = LoxFunction(stmt);
    environment.define(stmt.name.lexeme, function);
  }

  @override
  void visitPrintStmt(Print stmt) {
    var value = evaluate(stmt.expression);
    print(stringify(value));
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

    environment.assign(expr.name, value);
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
