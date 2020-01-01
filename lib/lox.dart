import 'ast_printer.dart';
import 'parser.dart';
import 'scanner.dart';

class Lox {
  void run(String source) {
    var scanner = Scanner(source);
    var tokens = scanner.scanTokens();
    var parser = Parser(tokens);
    var expression = parser.parse();
    if (expression != null) {
      print(AstPrinter().print(expression));
    }
  }
}
