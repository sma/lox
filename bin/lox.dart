import 'dart:io';

import 'package:lox/lox.dart';

void main(List<String> args) {
  if (args.length > 1) {
    stderr.writeln('Usage: lox [script]');
    exit(64);
  } else if (args.length == 1) {
    _runFile(args[0]);
  } else {
    _runPrompt();
  }
}

void _runFile(String path) {
  Lox().run(File(path).readAsStringSync());
}

void _runPrompt() {
  var lox = Lox();
  while (true) {
    stdout.write('> ');
    var line = stdin.readLineSync();
    if (line == null) {
      stdout.writeln();
      break;
    }
    lox.run(line);
  }
}
