import 'chunk.dart';
import 'printf.dart';
import 'value.dart';

void disassembleChunk(Chunk chunk, String name) {
  printf('== %s ==\n', [name]);
  for (var offset = 0; offset < chunk.count;) {
    offset = disassembleInstruction(chunk, offset);
  }
}

int disassembleInstruction(Chunk chunk, int offset) {
  printf('%04d ', [offset]);
  if (offset > 0 && chunk.lines[offset] == chunk.lines[offset - 1]) {
    printf('   | ');
  } else {
    printf('%4d ', [chunk.lines[offset]]);
  }
  final instruction = OpCode.values[chunk.code[offset]];
  switch (instruction) {
    case OpCode.opConstant:
      return _constantInstruction('OP_CONSTANT', chunk, offset);
    case OpCode.opNil:
      return _simpleInstruction('OP_ NIL', offset);
    case OpCode.opTrue:
      return _simpleInstruction('OP_ TRUE', offset);
    case OpCode.opFalse:
      return _simpleInstruction('OP_ FALSE', offset);
    case OpCode.opPop:
      return _simpleInstruction('OP_POP', offset);
    case OpCode.opGetLocal:
      return _byteInstruction('OP_GET_LOCAL', chunk, offset);
    case OpCode.opSetLocal:
      return _byteInstruction('OP_SET_LOCAL', chunk, offset);
    case OpCode.opGetGlobal:
      return _constantInstruction('OP_GET_GLOBAL', chunk, offset);
    case OpCode.opDefineGlobal:
      return _constantInstruction('OP_DEFINE_GLOBAL', chunk, offset);
    case OpCode.opSetGlobal:
      return _constantInstruction('OP_SET_GLOBAL', chunk, offset);
    case OpCode.opEqual:
      return _simpleInstruction('OP_EQUAL', offset);
    case OpCode.opGreater:
      return _simpleInstruction('OP_GREATER', offset);
    case OpCode.opLess:
      return _simpleInstruction('OP_LESS', offset);
    case OpCode.opAdd:
      return _simpleInstruction('OP_ADD', offset);
    case OpCode.opSubtract:
      return _simpleInstruction('OP_SUBTRACT', offset);
    case OpCode.opMultiply:
      return _simpleInstruction('OP_MULTIPLY', offset);
    case OpCode.opDivide:
      return _simpleInstruction('OP_DIVIDE', offset);
    case OpCode.opNot:
      return _simpleInstruction('OP_NOT', offset);
    case OpCode.opNegate:
      return _simpleInstruction('OP_NEGATE', offset);
    case OpCode.opPrint:
      return _simpleInstruction('OP_PRINT', offset);
    case OpCode.opReturn:
      return _simpleInstruction('OP_RETURN', offset);
  }
}

int _constantInstruction(String name, Chunk chunk, int offset) {
  final constant = chunk.code[offset + 1];
  printf("%-16s %4d '", [name, constant]);
  printValue(chunk.constants[constant]);
  printf("'\n");
  return offset + 2;
}

int _simpleInstruction(String name, int offset) {
  printf('%s\n', [name]);
  return offset + 1;
}

int _byteInstruction(String name, Chunk chunk, int offset) {
  final slot = chunk.code[offset + 1];
  printf('%-16s %4d\n', [name, slot]);
  return offset + 2;
}
