import 'printf.dart';
import 'scanner.dart';

void compile(String source) {
  final scanner = Scanner(source);
  var line = -1;
  for (;;) {
    var token = scanner.scanToken();
    if (token.line != line) {
      line = token.line;
      printf('%04d ', [line]);
    } else {
      printf("   | ");
    }
    printf("%10s '%s'\n", [token.type.name, token.start]);

    if (token.type == TokenType.eof) break;
  }
}
