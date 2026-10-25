import 'dart:io' show stderr;

import 'chunk.dart';
import 'printf.dart';
import 'value.dart';

void disassembleChunk(Chunk chunk, String name) {
  stderr.printf('== %s ==\n', [name]);
  for (var offset = 0; offset < chunk.count;) {
    offset = disassembleInstruction(chunk, offset);
  }
}

int disassembleInstruction(Chunk chunk, int offset) {
  stderr.printf('%04d ', [offset]);
  if (offset > 0 && chunk.lines[offset] == chunk.lines[offset - 1]) {
    stderr.printf('   | ');
  } else {
    stderr.printf('%4d ', [chunk.lines[offset]]);
  }
  final instruction = OpCode.values[chunk.code[offset]];
  switch (instruction) {
    case .opConstant:
      return _constantInstruction('OP_CONSTANT', chunk, offset);
    case .opNil:
      return _simpleInstruction('OP_NIL', offset);
    case .opTrue:
      return _simpleInstruction('OP_TRUE', offset);
    case .opFalse:
      return _simpleInstruction('OP_FALSE', offset);
    case .opPop:
      return _simpleInstruction('OP_POP', offset);
    case .opGetLocal:
      return _byteInstruction('OP_GET_LOCAL', chunk, offset);
    case .opSetLocal:
      return _byteInstruction('OP_SET_LOCAL', chunk, offset);
    case .opGetGlobal:
      return _constantInstruction('OP_GET_GLOBAL', chunk, offset);
    case .opDefineGlobal:
      return _constantInstruction('OP_DEFINE_GLOBAL', chunk, offset);
    case .opSetGlobal:
      return _constantInstruction('OP_SET_GLOBAL', chunk, offset);
    case .opEqual:
      return _simpleInstruction('OP_EQUAL', offset);
    case .opGreater:
      return _simpleInstruction('OP_GREATER', offset);
    case .opLess:
      return _simpleInstruction('OP_LESS', offset);
    case .opAdd:
      return _simpleInstruction('OP_ADD', offset);
    case .opSubtract:
      return _simpleInstruction('OP_SUBTRACT', offset);
    case .opMultiply:
      return _simpleInstruction('OP_MULTIPLY', offset);
    case .opDivide:
      return _simpleInstruction('OP_DIVIDE', offset);
    case .opNot:
      return _simpleInstruction('OP_NOT', offset);
    case .opNegate:
      return _simpleInstruction('OP_NEGATE', offset);
    case .opPrint:
      return _simpleInstruction('OP_PRINT', offset);
    case .opJump:
      return _jumpInstruction('OP_JUMP', 1, chunk, offset);
    case .opJumpIfFalse:
      return _jumpInstruction('OP_JUMP_IF_FALSE', 1, chunk, offset);
    case .opLoop:
      return _jumpInstruction('OP_LOOP', -1, chunk, offset);
    case .opReturn:
      return _simpleInstruction('OP_RETURN', offset);
  }
}

int _constantInstruction(String name, Chunk chunk, int offset) {
  final constant = chunk.code[offset + 1];
  stderr.printf("%-16s %4d '", [name, constant]);
  stderr.printValue(chunk.constants[constant]);
  stderr.printf("'\n");
  return offset + 2;
}

int _simpleInstruction(String name, int offset) {
  stderr.printf('%s\n', [name]);
  return offset + 1;
}

int _byteInstruction(String name, Chunk chunk, int offset) {
  final slot = chunk.code[offset + 1];
  stderr.printf('%-16s %4d\n', [name, slot]);
  return offset + 2;
}

int _jumpInstruction(String name, int sign, Chunk chunk, int offset) {
  final jump = (chunk.code[offset + 1] << 8) | chunk.code[offset + 2];
  stderr.printf('%-16s %4d -> %d\n', [name, offset, offset + 3 + sign * jump]);
  return offset + 3;
}
