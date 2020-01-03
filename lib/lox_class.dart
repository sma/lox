import 'package:lox/interpreter.dart';
import 'package:lox/lox_callable.dart';

import 'lox_instance.dart';

class LoxClass implements LoxCallable {
  final String name;

  LoxClass(this.name);

  @override
  int get arity => 0;

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    return LoxInstance(this);
  }

  @override
  String toString() {
    return name;
  }
}
