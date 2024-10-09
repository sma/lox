enum OpCode {
  opConstant,
  opAdd,
  opSubtract,
  opMultiply,
  opDivide,
  opNegate,
  opReturn,
}

class Chunk {
  final code = <int>[];
  final lines = <int>[];
  final constants = <double>[];

  int get count => code.length;

  void write(int byte, int line) {
    code.add(byte);
    lines.add(line);
  }

  int addConstant(double value) {
    var index = constants.indexOf(value);
    if (index == -1) {
      index = constants.length;
      constants.add(value);
    }
    return index;
  }
}
