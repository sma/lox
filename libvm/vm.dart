import 'compiler.dart';
import 'chunk.dart';
import 'debug.dart';
import 'printf.dart';
import 'scanner.dart';
import 'value.dart';

const traceInstructions = false;

enum InterpreterResult { ok, compileError, runtimeError }

class CallFrame {
  CallFrame(this.function, this.slots);
  final ObjFunction function;
  final List<Value> slots;
  int ip = 0;
}

class VM {
  VM({required this.sink});

  final StringSink sink;
  final frames = <CallFrame>[];
  final stack = <Value>[];
  final globals = <String, Value>{};

  void push(Value value) => stack.add(value);

  Value pop() => stack.removeLast();

  InterpreterResult interpret(String source) {
    final compiler = Compiler(Scanner(source));
    final function = compiler.compile();
    if (function == null) {
      return .compileError;
    }
    frames.add(CallFrame(function, [function]));
    return run();
  }

  InterpreterResult run() {
    var frame = frames.last;
    var chunk = frame.function.chunk;
    for (;;) {
      if (traceInstructions) {
        sink.printf('          ');
        for (var i = 0; i < stack.length; i++) {
          sink.printf('[ ');
          sink.printValue(stack[i]);
          sink.printf(' ]');
        }
        sink.printf('\n');
        disassembleInstruction(chunk, frame.ip);
      }
      final instruction = OpCode.values[_readByte()];
      switch (instruction) {
        case .opConstant:
          push(_readConstant());
        case .opNil:
          push(const Nil());
        case .opTrue:
          push(const Bool(true));
        case .opFalse:
          push(const Bool(false));
        case .opPop:
          pop();
        case .opGetLocal:
          var slot = _readByte();
          push(stack[slot]);
        case .opSetLocal:
          var slot = _readByte();
          stack[slot] = _peek(-1);
        case .opGetGlobal:
          var name = _readString();
          if (!globals.containsKey(name)) {
            _runtimeError("Undefined variable '%s'.", [name]);
            return .runtimeError;
          }
          push(globals[name]!);
        case .opDefineGlobal:
          var name = _readString();
          globals[name] = pop();
        case .opSetGlobal:
          var name = _readString();
          if (!globals.containsKey(name)) {
            _runtimeError("Undefined variable '%s'.", [name]);
            return .runtimeError;
          }
          globals[name] = _peek(-1);
        case .opEqual:
          push(Bool(pop() == pop()));
        case .opGreater:
          if (_binary((a, b) => Bool(a > b))) return .runtimeError;
        case .opLess:
          if (_binary((a, b) => Bool(a < b))) return .runtimeError;
        case .opAdd:
          if ((_peek(-1), _peek(-2)) case (ObjString(), ObjString())) {
            var b = (pop() as ObjString).value;
            var a = (pop() as ObjString).value;
            push(ObjString('$a$b'));
          } else {
            if (_binary((a, b) => Number(a + b))) return .runtimeError;
          }
        case .opSubtract:
          if (_binary((a, b) => Number(a - b))) return .runtimeError;
        case .opMultiply:
          if (_binary((a, b) => Number(a * b))) return .runtimeError;
        case .opDivide:
          if (_binary((a, b) => Number(a / b))) return .runtimeError;
        case .opNot:
          push(Bool(pop().isFalsey));
        case .opNegate:
          if (pop() case Number n) {
            push(Number(-n.value));
          } else {
            _runtimeError('Operand must be a number.');
            return .runtimeError;
          }
        case .opPrint:
          sink.writeln(pop());
        case .opJump:
          var offset = _readShort(); // must be 2 lines
          frame.ip += offset;
        case .opJumpIfFalse:
          var offset = _readShort();
          if (_peek(-1).isFalsey) frame.ip += offset;
        case .opLoop:
          var offset = _readShort(); // must be 2 lines
          frame.ip -= offset;
        case .opReturn:
          return .ok;
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

  Chunk get _chunk => frames.last.function.chunk;

  int _readByte() => _chunk.code[frames.last.ip++];

  int _readShort() => (_readByte() << 8) | _readByte();

  Value _readConstant() => _chunk.constants[_readByte()];

  String _readString() => (_readConstant() as ObjString).value;

  void _runtimeError(String format, [List<Object?> args = const []]) {
    var frame = frames.last;
    var name = frame.function.name ?? '<script>';
    sink.printf(format, args);
    sink.printf('\n');
    sink.printf('[line %d] in %s\n', [frame.function.chunk.lines[frame.ip - 1], name]);
    stack.clear();
  }
}
