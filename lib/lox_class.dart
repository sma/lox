import 'interpreter.dart';
import 'lox_callable.dart';
import 'lox_function.dart';
import 'lox_instance.dart';

class LoxClass(
  final String name,
  final LoxClass? superclass,
  final Map<String, LoxFunction> _methods,
) implements LoxCallable {
  LoxFunction? findMethod(String name) {
    if (_methods.containsKey(name)) {
      return _methods[name];
    }

    if (superclass != null) {
      return superclass!.findMethod(name);
    }

    return null;
  }

  @override
  int get arity => findMethod('init')?.arity ?? 0;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    var instance = LoxInstance(this);
    var initializer = findMethod('init');
    initializer?.bind(instance).call(interpreter, arguments);
    return instance;
  }

  @override
  String toString() => name;
}
