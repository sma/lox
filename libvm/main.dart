import 'dart:io';

import 'printf.dart';
import 'vm.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    repl();
  } else if (arguments.length == 1) {
    runFile(arguments.single);
  } else {
    printf('Usage: clox [script]\n');
    exit(64);
  }
}

void repl() {
  for (;;) {
    printf('> ');
    final line = stdin.readLineSync();
    if (line == null) break;
    vm.interpret(line);
  }
}

void runFile(String path) {
  if (!File(path).existsSync()) {
    printf("Could not open file '$path'.\n");
    exit(74);
  }
  final source = File(path).readAsStringSync();
  final result = vm.interpret(source);
  if (result == InterpreterResult.compileError) exit(65);
  if (result == InterpreterResult.runtimeError) exit(70);
}
