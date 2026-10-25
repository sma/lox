import 'token_type.dart';
export 'token_type.dart';

class const Token(
  final TokenType type,
  final String lexeme,
  final Object? literal,
  final int line,
) {
  @override
  String toString() => '$type $lexeme $literal';
}
