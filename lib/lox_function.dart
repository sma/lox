import 'ast.dart';
import 'environment.dart';
import 'interpreter.dart';
import 'lox_callable.dart';
import 'lox_instance.dart';
import 'lox_return.dart';

class LoxFunction implements LoxCallable {
  final Function _declaration;
  final Environment _closure;
  final bool _isInitializer;

  LoxFunction(this._declaration, this._closure, this._isInitializer);

  LoxFunction bind(LoxInstance instance) {
    var environment = Environment(_closure);
    environment.define('this', instance);
    return LoxFunction(_declaration, environment, _isInitializer);
  }

  @override
  int get arity => _declaration.params.length;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    var environment = Environment(_closure);
    for (var i = 0; i < _declaration.params.length; i++) {
      environment.define(_declaration.params[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(_declaration.body, environment);
    } on LoxReturn catch (returnValue) {
      if (_isInitializer) return _closure.getAt(0, 'this');
      return returnValue.value;
    }

    if (_isInitializer) return _closure.getAt(0, 'this');
    return null;
  }

  @override
  String toString() => '<fn ${_declaration.name.lexeme}>';
}
