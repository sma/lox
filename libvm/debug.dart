import 'chunk.dart';
import 'printf.dart';

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
    case OpCode.opAdd:
      return _simpleInstruction('OP_ADD', offset);
    case OpCode.opSubtract:
      return _simpleInstruction('OP_SUBTRACT', offset);
    case OpCode.opMultiply:
      return _simpleInstruction('OP_MULTIPLY', offset);
    case OpCode.opDivide:
      return _simpleInstruction('OP_DIVIDE', offset);
    case OpCode.opNegate:
      return _simpleInstruction('OP_NEGATE', offset);
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

void printValue(double value) {
  printf('%g', [value]);
}
