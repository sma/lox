import 'compiler.dart';
import 'debug.dart';
import 'chunk.dart';
import 'printf.dart';

const traceInstructions = true;

enum InterpreterResult { ok, compileError, runtimeError }

class VM {
  late Chunk chunk;
  late int ip;
  final stack = <double>[];

  void push(double value) => stack.add(value);

  double pop() => stack.removeLast();

  InterpreterResult interpret(String source) {
    compile(source);
    return InterpreterResult.ok;
  }

  InterpreterResult run() {
    for (;;) {
      if (traceInstructions) {
        printf("          ");
        for (var i = 0; i < stack.length; i++) {
          printf("[ ");
          printValue(stack[i]);
          printf(" ]");
        }
        printf("\n");
        disassembleInstruction(chunk, ip);
      }
      final instruction = OpCode.values[_readByte()];
      switch (instruction) {
        case OpCode.opConstant:
          push(_readConstant());
        case OpCode.opAdd:
          push(pop() + pop());
        case OpCode.opSubtract:
          push(-pop() + pop());
        case OpCode.opMultiply:
          push(pop() * pop());
        case OpCode.opDivide:
          push(1 / pop() * pop());
        case OpCode.opNegate:
          push(-pop());
        case OpCode.opReturn:
          printValue(pop());
          printf('\n');
          return InterpreterResult.ok;
      }
    }
  }

  int _readByte() => chunk.code[ip++];

  double _readConstant() => chunk.constants[_readByte()];
}

final vm = VM();
