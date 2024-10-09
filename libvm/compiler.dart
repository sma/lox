import 'chunk.dart';
import 'debug.dart';
import 'printf.dart';
import 'scanner.dart';

const debugPrintCode = false;

class Parser {
  Parser(this.scanner, this.chunk);

  final Scanner scanner;
  final Chunk chunk;

  Token current = Token.none;
  Token previous = Token.none;
  bool hadError = false;
  bool panicMode = false;

  bool compile() {
    advance();
    expression();
    consume(TokenType.eof, 'Expect end of expression.');
    endCompiler();
    return !hadError;
  }

  void advance() {
    previous = current;
    for (;;) {
      current = scanner.scanToken();
      if (current.type != TokenType.error) break;
      errorAtCurrent(current.start);
    }
  }

  void consume(TokenType type, String message) {
    if (current.type == type) {
      advance();
      return;
    }
    errorAtCurrent(message);
  }

  void errorAtCurrent(String message) => errorAt(current, message);

  void error(String message) => errorAt(previous, message);

  void errorAt(Token token, String message) {
    if (panicMode) return;
    panicMode = true;
    printf('[line %d] Error', [token.line]);
    if (token.type == TokenType.eof) {
      printf(' at end');
    } else if (token.type == TokenType.error) {
      // Nothing.
    } else {
      printf(" at '%s'", [token.start]);
    }
    printf(': %s\n', [message]);
    hadError = true;
  }

  // Emitting bytecode.

  void emitByte(int byte) {
    chunk.write(byte, previous.line);
  }

  void emitOp(OpCode op) {
    chunk.write(op.index, previous.line);
  }

  void emitReturn() {
    emitOp(OpCode.opReturn);
  }

  int makeConstant(double value) {
    var constant = chunk.addConstant(value);
    if (constant > 255) {
      error('Too many constants in one chunk.');
      return 0;
    }
    return constant;
  }

  void emitConstant(double value) {
    emitOp(OpCode.opConstant);
    emitByte(makeConstant(value));
  }

  void endCompiler() {
    emitReturn();
    if (!hadError && debugPrintCode) {
      disassembleChunk(chunk, 'code');
    }
  }

  // Parsing rules.

  void expression() {
    parsePrecedence(Precedence.assignment);
  }

  void grouping() {
    expression();
    consume(TokenType.rightParen, "Expect ')' after expression.");
  }

  void number() {
    emitConstant(double.parse(previous.start));
  }

  void unary() {
    var operatorType = previous.type;

    // Compile the operand.
    parsePrecedence(Precedence.unary);

    // Emit the operator instruction.
    switch (operatorType) {
      case TokenType.minus:
        emitByte(OpCode.opNegate.index);
      default:
        return; // Unreachable.
    }
  }

  void binary() {
    var operatorType = previous.type;
    var rule = getRule(operatorType);
    parsePrecedence(rule.precedence.next);
    switch (operatorType) {
      case TokenType.plus:
        emitOp(OpCode.opAdd);
      case TokenType.minus:
        emitOp(OpCode.opSubtract);
      case TokenType.star:
        emitOp(OpCode.opMultiply);
      case TokenType.slash:
        emitOp(OpCode.opDivide);
      default:
        return; // Unreachable.
    }
  }

  void parsePrecedence(Precedence precedence) {
    advance();
    var prefixRule = getRule(previous.type).prefix;
    if (prefixRule == null) {
      error('Expect expression.');
      return;
    }

    prefixRule();

    while (precedence <= getRule(current.type).precedence) {
      advance();
      getRule(previous.type).infix!();
    }
  }

  ParseRule getRule(TokenType type) => _rules[type]!;

  late final _rules = <TokenType, ParseRule>{
    TokenType.leftParen: ParseRule(grouping, null, Precedence.none),
    TokenType.rightParen: ParseRule(null, null, Precedence.none),
    TokenType.leftBrace: ParseRule(null, null, Precedence.none),
    TokenType.rightBrace: ParseRule(null, null, Precedence.none),
    TokenType.comma: ParseRule(null, null, Precedence.none),
    TokenType.dot: ParseRule(null, null, Precedence.none),
    TokenType.minus: ParseRule(unary, binary, Precedence.term),
    TokenType.plus: ParseRule(null, binary, Precedence.term),
    TokenType.semicolon: ParseRule(null, null, Precedence.none),
    TokenType.slash: ParseRule(null, binary, Precedence.factor),
    TokenType.star: ParseRule(null, binary, Precedence.factor),
    TokenType.bang: ParseRule(null, null, Precedence.none),
    TokenType.bangEqual: ParseRule(null, null, Precedence.none),
    TokenType.equal: ParseRule(null, null, Precedence.none),
    TokenType.equalEqual: ParseRule(null, null, Precedence.none),
    TokenType.greater: ParseRule(null, null, Precedence.none),
    TokenType.greaterEqual: ParseRule(null, null, Precedence.none),
    TokenType.less: ParseRule(null, null, Precedence.none),
    TokenType.lessEqual: ParseRule(null, null, Precedence.none),
    TokenType.identifier: ParseRule(null, null, Precedence.none),
    TokenType.string: ParseRule(null, null, Precedence.none),
    TokenType.number: ParseRule(number, null, Precedence.none),
    TokenType.kAnd: ParseRule(null, null, Precedence.none),
    TokenType.kClass: ParseRule(null, null, Precedence.none),
    TokenType.kElse: ParseRule(null, null, Precedence.none),
    TokenType.kFalse: ParseRule(null, null, Precedence.none),
    TokenType.kFor: ParseRule(null, null, Precedence.none),
    TokenType.kFun: ParseRule(null, null, Precedence.none),
    TokenType.kIf: ParseRule(null, null, Precedence.none),
    TokenType.kNil: ParseRule(null, null, Precedence.none),
    TokenType.kOr: ParseRule(null, null, Precedence.none),
    TokenType.kPrint: ParseRule(null, null, Precedence.none),
    TokenType.kReturn: ParseRule(null, null, Precedence.none),
    TokenType.kSuper: ParseRule(null, null, Precedence.none),
    TokenType.kThis: ParseRule(null, null, Precedence.none),
    TokenType.kTrue: ParseRule(null, null, Precedence.none),
    TokenType.kVar: ParseRule(null, null, Precedence.none),
    TokenType.kWhile: ParseRule(null, null, Precedence.none),
    TokenType.error: ParseRule(null, null, Precedence.none),
    TokenType.eof: ParseRule(null, null, Precedence.none),
  };
}

enum Precedence {
  none,
  assignment, // =
  or, // or
  and, // and
  equality, // == !=
  comparison, // < > <= >=
  term, // + -
  factor, // * /
  unary, // ! -
  call, // . ()
  primary;

  Precedence get next => Precedence.values[index + 1];

  bool operator <=(Precedence other) => index <= other.index;
}

typedef ParseFn = void Function();

class ParseRule {
  const ParseRule(this.prefix, this.infix, this.precedence);

  final ParseFn? prefix;
  final ParseFn? infix;
  final Precedence precedence;
}

void dump(String source) {
  var scanner = Scanner(source);
  var line = -1;
  for (;;) {
    var token = scanner.scanToken();
    if (token.line != line) {
      line = token.line;
      printf('%04d ', [line]);
    } else {
      printf('   | ');
    }
    printf("%10s '%s'\n", [token.type.name, token.start]);

    if (token.type == TokenType.eof) break;
  }
}
