import 'package:lox/token.dart';

class RuntimeError(final Token token, final String message) implements Exception {
  @override
  String toString() {
    if (token.type == .EOF) {
      if (token.lexeme == '') {
        return '[line ${token.line}] Error: $message';
      }
      return '[line ${token.line}] Error at end: $message';
    }
    return "[line ${token.line}] Error at '${token.lexeme}': $message";
  }
}
