import 'ast.dart';
import 'token.dart';
import 'token_type.dart';

class Interpreter implements ExprVisitor<Object>, StmtVisitor<void> {
  @override
  Object visitLiteralExpr(Literal expr) {
    return expr.value;
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
  void visitExpressionStmt(Expression stmt) {
    evaluate(stmt.expression);
  }

  @override
  void visitPrintStmt(Print stmt) {
    var value = evaluate(stmt.expression);
    print(stringify(value));
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
    try {
      for (var statement in statements) {
        execute(statement);
      }
    } catch (error) {
      print(error);
    }
  }
}

class RuntimeError implements Exception {
  final Token token;
  final String message;

  RuntimeError(this.token, this.message);
}
