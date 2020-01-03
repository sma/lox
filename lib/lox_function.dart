import 'ast.dart';
import 'environment.dart';
import 'interpreter.dart';
import 'lox_callable.dart';
import 'lox_instance.dart';
import 'lox_return.dart';

class LoxFunction implements LoxCallable {
  final Function declaration;
  final Environment closure;
  final bool isInitializer;

  LoxFunction(this.declaration, this.closure, this.isInitializer);

  LoxFunction bind(LoxInstance instance) {
    var environment = Environment(closure);
    environment.define("this", instance);
    return LoxFunction(declaration, environment, isInitializer);
  }

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
      if (isInitializer) return closure.getAt(0, 'this');
      return returnValue.value;
    }

    if (isInitializer) return closure.getAt(0, 'this');
    return null;
  }

  @override
  String toString() => '<fn ${declaration.name.lexeme}>';
}
