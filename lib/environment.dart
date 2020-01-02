import 'runtime_error.dart';
import 'token.dart';

class Environment {
  final _values = <String, Object>{};

  Object get(Token name) {
    if (_values.containsKey(name.lexeme)) {
      return _values[name.lexeme];
    }

    throw RuntimeError(name, "Undefined variable '${name.lexeme}'.");
  }

  void assign(Token name, Object value) {
    if (_values.containsKey(name.lexeme)) {
      _values[name.lexeme] = value;
      return;
    }

    throw RuntimeError(name, "Undefined variable '${name.lexeme}'.");
  }

  void define(String name, Object value) {
    _values[name] = value;
  }
}
