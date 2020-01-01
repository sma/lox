import 'scanner.dart';

class Lox {
  void run(String source) {
    var scanner = Scanner(source);
    var tokens = scanner.scanTokens();

    for (var token in tokens) {
      print(token);
    }
  }
}
