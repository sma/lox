import 'compiler.dart';
import 'debug.dart';
import 'chunk.dart';
import 'printf.dart';
import 'scanner.dart';
import 'value.dart';

const traceInstructions = true;

enum InterpreterResult { ok, compileError, runtimeError }

class VM {
  late Chunk chunk;
  late int ip;
  final stack = <Value>[];

  void push(Value value) => stack.add(value);

  Value pop() => stack.removeLast();

  InterpreterResult interpret(String source) {
    chunk = Chunk();
    final parser = Parser(Scanner(source), chunk);
    if (!parser.compile()) {
      return InterpreterResult.compileError;
    }
    ip = 0;
    return run();
  }

  InterpreterResult run() {
    for (;;) {
      if (traceInstructions) {
        printf('          ');
        for (var i = 0; i < stack.length; i++) {
          printf('[ ');
          printValue(stack[i]);
          printf(' ]');
        }
        printf('\n');
        disassembleInstruction(chunk, ip);
      }
      final instruction = OpCode.values[_readByte()];
      switch (instruction) {
        case OpCode.opConstant:
          push(_readConstant());
        case OpCode.opNil:
          push(const Nil());
        case OpCode.opTrue:
          push(const Bool(true));
        case OpCode.opFalse:
          push(const Bool(false));
        case OpCode.opEqual:
          push(Bool(pop() == pop()));
        case OpCode.opGreater:
          if (_binary((a, b) => Bool(a > b))) return InterpreterResult.runtimeError;
        case OpCode.opLess:
          if (_binary((a, b) => Bool(a < b))) return InterpreterResult.runtimeError;
        case OpCode.opAdd:
          if ((_peek(-1), _peek(-2)) case (Obj(), Obj())) {
            var b = (pop() as Obj).value as String;
            var a = (pop() as Obj).value as String;
            push(Obj('$a$b'));
          } else {
            if (_binary((a, b) => Number(a + b))) return InterpreterResult.runtimeError;
          }
        case OpCode.opSubtract:
          if (_binary((a, b) => Number(a - b))) return InterpreterResult.runtimeError;
        case OpCode.opMultiply:
          if (_binary((a, b) => Number(a * b))) return InterpreterResult.runtimeError;
        case OpCode.opDivide:
          if (_binary((a, b) => Number(a / b))) return InterpreterResult.runtimeError;
        case OpCode.opNot:
          push(Bool(pop().isFalsey));
        case OpCode.opNegate:
          if (pop() case Number n) {
            push(Number(-n.value));
          } else {
            _runtimeError('Operand must be a number.');
            return InterpreterResult.runtimeError;
          }
        case OpCode.opReturn:
          printValue(pop());
          printf('\n');
          return InterpreterResult.ok;
      }
    }
  }

  Value _peek(int index) => stack[stack.length + index];

  bool _binary(Value Function(double, double) op) {
    if ((pop(), pop()) case (Number b, Number a)) {
      push(op(a.value, b.value));
      return false;
    } else {
      _runtimeError('Operands must be numbers.');
      return true;
    }
  }

  int _readByte() => chunk.code[ip++];

  Value _readConstant() => chunk.constants[_readByte()];

  void _runtimeError(String format, [List<Object?> args = const []]) {
    printf(format, args);
    printf('\n');
    printf('[line %d] in script\n', [chunk.lines[ip - 1]]);
    stack.clear();
  }
}

final vm = VM();
