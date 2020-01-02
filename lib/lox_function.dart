import 'ast.dart';
import 'environment.dart';
import 'interpreter.dart';
import 'lox_callable.dart';

class LoxFunction implements LoxCallable {
  final Function declaration;
  LoxFunction(this.declaration);

  @override
  int get arity => declaration.params.length;

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    var environment = Environment(interpreter.globals);
    for (var i = 0; i < declaration.params.length; i++) {
      environment.define(declaration.params[i].lexeme, arguments[i]);
    }

    interpreter.executeBlock(declaration.body, environment);
    return null;
  }

  @override
  String toString() => '<fn ${declaration.name.lexeme}>';
}
