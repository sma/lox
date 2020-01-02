import 'ast.dart';
import 'environment.dart';
import 'interpreter.dart';
import 'lox_callable.dart';
import 'lox_return.dart';

class LoxFunction implements LoxCallable {
  final Function declaration;
  final Environment closure;

  LoxFunction(this.declaration, this.closure);

  @override
  int get arity => declaration.params.length;

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    var environment = Environment(closure);
    for (var i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(declaration.body, environment);
    } on LoxReturn catch (returnValue) {
      return returnValue.value;
    }
    return null;
  }

  @override
  String toString() => '<fn ${declaration.name.lexeme}>';
}
