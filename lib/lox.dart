import 'interpreter.dart';
import 'parser.dart';
import 'scanner.dart';

class Lox {
  final interpreter = Interpreter();

  void run(String source) {
    var scanner = Scanner(source);
    var tokens = scanner.scanTokens();
    var parser = Parser(tokens);
    var statements = parser.parse();
    interpreter.interpret(statements);
  }
}
