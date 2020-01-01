void error(int line, String message) {
  throw Exception('[line $line] Error: $message');
}
