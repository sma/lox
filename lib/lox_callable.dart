import 'interpreter.dart';

abstract class LoxCallable {
  int get arity;

  Object? call(Interpreter interpreter, List<Object?> arguments);

  factory LoxCallable(int arity,
      Object? Function(Interpreter interpreter, List<Object?> arguments) fn) {
    return _Callable(arity, fn);
  }
}

class _Callable implements LoxCallable {
  @override
  final int arity;
  final Object? Function(Interpreter interpreter, List<Object?> arguments) fn;

  _Callable(this.arity, this.fn);

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    return fn(interpreter, arguments);
  }

  @override
  String toString() => '<native fn>';
}
