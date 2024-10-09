import 'value.dart';

enum OpCode {
  opConstant,
  opNil,
  opTrue,
  opFalse,
  opPop,
  opGetGlobal,
  opDefineGlobal,
  opSetGlobal,
  opEqual,
  opGreater,
  opLess,
  opAdd,
  opSubtract,
  opMultiply,
  opDivide,
  opNot,
  opNegate,
  opPrint,
  opReturn,
}

class Chunk {
  final code = <int>[];
  final lines = <int>[];
  final constants = <Value>[];

  int get count => code.length;

  void write(int byte, int line) {
    code.add(byte);
    lines.add(line);
  }

  int addConstant(Value value) {
    var index = constants.indexOf(value);
    if (index == -1) {
      index = constants.length;
      constants.add(value);
    }
    return index;
  }
}
