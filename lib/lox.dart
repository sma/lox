import 'interpreter.dart';
import 'parser.dart';
import 'resolver.dart';
import 'runtime_error.dart';
import 'scanner.dart';

class Lox {
  final interpreter = Interpreter();

  void run(String source) {
    try {
      var scanner = Scanner(source);
      var tokens = scanner.scanTokens();
      var parser = Parser(tokens);
      var statements = parser.parse();
      Resolver(interpreter).resolve(statements);
      interpreter.interpret(statements);
    } on RuntimeError catch (error) {
      print(error);
    }
  }
}
