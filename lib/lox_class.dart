import 'interpreter.dart';
import 'lox_callable.dart';
import 'lox_function.dart';
import 'lox_instance.dart';

class LoxClass implements LoxCallable {
  final String name;
  final Map<String, LoxFunction> _methods;

  LoxClass(this.name, this._methods);

  LoxFunction findMethod(String name) {
    if (_methods.containsKey(name)) {
      return _methods[name];
    }

    return null;
  }

  @override
  int get arity => 0;

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    return LoxInstance(this);
  }

  @override
  String toString() => name;
}
