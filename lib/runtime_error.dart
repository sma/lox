import 'package:lox/token.dart';

class RuntimeError implements Exception {
  final Token token;
  final String message;

  RuntimeError(this.token, this.message);

  @override
  String toString() {
    if (token.type == TokenType.EOF) {
      if (token.lexeme == '') {
        return '[line ${token.line}] Error: $message';
      }
      return '[line ${token.line}] Error at end: $message';
    }
    return "[line ${token.line}] Error at '${token.lexeme}': $message";
  }
}
