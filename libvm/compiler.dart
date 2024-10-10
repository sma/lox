import 'chunk.dart';
import 'debug.dart';
import 'printf.dart';
import 'scanner.dart';
import 'value.dart';

const debugPrintCode = false;

class Parser {
  Parser(this.scanner, this.chunk);

  final Scanner scanner;
  final Chunk chunk;

  Token current = Token.none;
  Token previous = Token.none;
  bool hadError = false;
  bool panicMode = false;
  int scopeDepth = 0;
  final locals = <Local>[];

  bool compile() {
    advance();

    while (!match(TokenType.eof)) {
      declaration();
    }

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

  bool match(TokenType type) {
    if (!check(type)) return false;
    advance();
    return true;
  }

  bool check(TokenType type) => current.type == type;

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

  int makeConstant(Value value) {
    var constant = chunk.addConstant(value);
    if (constant > 255) {
      error('Too many constants in one chunk.');
      return 0;
    }
    return constant;
  }

  void emitConstant(Value value) {
    emitOp(OpCode.opConstant);
    emitByte(makeConstant(value));
  }

  void endCompiler() {
    emitReturn();
    if (!hadError && debugPrintCode) {
      disassembleChunk(chunk, 'code');
    }
  }

  void beginScope() {
    scopeDepth++;
  }

  void endScope() {
    scopeDepth--;

    while (locals.isNotEmpty && locals.last.depth > scopeDepth) {
      emitOp(OpCode.opPop);
      locals.removeLast();
    }
  }

  // Parsing rules.

  void declaration() {
    if (match(TokenType.kVar)) {
      varDeclaration();
    } else {
      statement();
    }

    if (panicMode) synchronize();
  }

  void varDeclaration() {
    var global = parseVariable('Expect variable name.');

    if (match(TokenType.equal)) {
      expression();
    } else {
      emitOp(OpCode.opNil);
    }
    consume(TokenType.semicolon, "Expect ';' after variable declaration.");

    defineVariable(global);
  }

  void statement() {
    if (match(TokenType.kPrint)) {
      printStatement();
    } else if (match(TokenType.leftBrace)) {
      beginScope();
      block();
      endScope();
    } else {
      expressionStatement();
    }
  }

  void printStatement() {
    expression();
    consume(TokenType.semicolon, "Expect ';' after value.");
    emitOp(OpCode.opPrint);
  }

  void expressionStatement() {
    expression();
    consume(TokenType.semicolon, "Expect ';' after expression.");
    emitOp(OpCode.opPop);
  }

  void block() {
    while (!check(TokenType.rightBrace) && !check(TokenType.eof)) {
      declaration();
    }

    consume(TokenType.rightBrace, "Expect '}' after block.");
  }

  void synchronize() {
    panicMode = false;

    while (current.type != TokenType.eof) {
      if (previous.type == TokenType.semicolon) return;

      switch (current.type) {
        case TokenType.kClass:
        case TokenType.kFun:
        case TokenType.kVar:
        case TokenType.kFor:
        case TokenType.kIf:
        case TokenType.kWhile:
        case TokenType.kPrint:
        case TokenType.kReturn:
          return;
        default:
          // Do nothing.
          break;
      }

      advance();
    }
  }

  void expression() {
    parsePrecedence(Precedence.assignment);
  }

  void grouping(bool canAssign) {
    expression();
    consume(TokenType.rightParen, "Expect ')' after expression.");
  }

  void number(bool canAssign) {
    emitConstant(Number(double.parse(previous.start)));
  }

  void string(bool canAssign) {
    var chars = previous.start.substring(1, previous.start.length - 1);
    emitConstant(Obj(chars));
  }

  void variable(bool canAssign) {
    namedVariable(previous, canAssign);
  }

  void namedVariable(Token name, bool canAssign) {
    OpCode getOp, setOp;
    var arg = resolveLocal(name);
    if (arg != -1) {
      getOp = OpCode.opGetLocal;
      setOp = OpCode.opSetLocal;
    } else {
      arg = identifierConstant(name);
      getOp = OpCode.opGetGlobal;
      setOp = OpCode.opSetGlobal;
    }

    if (canAssign && match(TokenType.equal)) {
      expression();
      emitOp(setOp);
    } else {
      emitOp(getOp);
    }
    emitByte(arg);
  }

  int resolveLocal(Token name) {
    for (var i = locals.length - 1; i >= 0; i--) {
      var local = locals[i];
      if (name.start == local.name.start) {
        if (local.depth == -1) {
          error('Cannot read local variable in its own initializer.');
        }
        return i;
      }
    }
    return -1;
  }

  void unary(bool canAssign) {
    var operatorType = previous.type;

    // Compile the operand.
    parsePrecedence(Precedence.unary);

    // Emit the operator instruction.
    switch (operatorType) {
      case TokenType.minus:
        emitOp(OpCode.opNegate);
      case TokenType.bang:
        emitOp(OpCode.opNot);
      default:
        return; // Unreachable.
    }
  }

  void binary(bool canAssign) {
    var operatorType = previous.type;
    var rule = getRule(operatorType);
    parsePrecedence(rule.precedence.next);
    switch (operatorType) {
      case TokenType.bangEqual:
        emitOp(OpCode.opEqual);
        emitOp(OpCode.opNot);
      case TokenType.equalEqual:
        emitOp(OpCode.opEqual);
      case TokenType.greater:
        emitOp(OpCode.opGreater);
      case TokenType.greaterEqual:
        emitOp(OpCode.opLess);
        emitOp(OpCode.opNot);
      case TokenType.less:
        emitOp(OpCode.opLess);
      case TokenType.lessEqual:
        emitOp(OpCode.opGreater);
        emitOp(OpCode.opNot);
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

  void literal(bool canAssign) {
    switch (previous.type) {
      case TokenType.kFalse:
        emitOp(OpCode.opFalse);
      case TokenType.kTrue:
        emitOp(OpCode.opTrue);
      case TokenType.kNil:
        emitOp(OpCode.opNil);
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

    var canAssign = precedence <= Precedence.assignment;
    prefixRule(canAssign);

    while (precedence <= getRule(current.type).precedence) {
      advance();
      getRule(previous.type).infix!(canAssign);
    }

    if (canAssign && match(TokenType.equal)) {
      error('Invalid assignment target.');
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
    TokenType.bang: ParseRule(unary, null, Precedence.none),
    TokenType.bangEqual: ParseRule(null, binary, Precedence.equality),
    TokenType.equal: ParseRule(null, null, Precedence.none),
    TokenType.equalEqual: ParseRule(null, binary, Precedence.equality),
    TokenType.greater: ParseRule(null, binary, Precedence.comparison),
    TokenType.greaterEqual: ParseRule(null, binary, Precedence.comparison),
    TokenType.less: ParseRule(null, binary, Precedence.comparison),
    TokenType.lessEqual: ParseRule(null, binary, Precedence.comparison),
    TokenType.identifier: ParseRule(variable, null, Precedence.none),
    TokenType.string: ParseRule(string, null, Precedence.none),
    TokenType.number: ParseRule(number, null, Precedence.none),
    TokenType.kAnd: ParseRule(null, null, Precedence.none),
    TokenType.kClass: ParseRule(null, null, Precedence.none),
    TokenType.kElse: ParseRule(null, null, Precedence.none),
    TokenType.kFalse: ParseRule(literal, null, Precedence.none),
    TokenType.kFor: ParseRule(null, null, Precedence.none),
    TokenType.kFun: ParseRule(null, null, Precedence.none),
    TokenType.kIf: ParseRule(null, null, Precedence.none),
    TokenType.kNil: ParseRule(literal, null, Precedence.none),
    TokenType.kOr: ParseRule(null, null, Precedence.none),
    TokenType.kPrint: ParseRule(null, null, Precedence.none),
    TokenType.kReturn: ParseRule(null, null, Precedence.none),
    TokenType.kSuper: ParseRule(null, null, Precedence.none),
    TokenType.kThis: ParseRule(null, null, Precedence.none),
    TokenType.kTrue: ParseRule(literal, null, Precedence.none),
    TokenType.kVar: ParseRule(null, null, Precedence.none),
    TokenType.kWhile: ParseRule(null, null, Precedence.none),
    TokenType.error: ParseRule(null, null, Precedence.none),
    TokenType.eof: ParseRule(null, null, Precedence.none),
  };

  int identifierConstant(Token name) {
    return makeConstant(Obj(name.start));
  }

  void addLocal(Token name) {
    if (locals.length == 255) {
      error('Too many local variables in function.');
      return;
    }
    locals.add(Local(name, -1));
  }

  void declareVariable() {
    if (scopeDepth == 0) return;
    for (var i = locals.length - 1; i >= 0; i--) {
      var local = locals[i];
      if (local.depth != -1 && local.depth < scopeDepth) break;
      if (local.name.start == previous.start) {
        error('Already a variable with this name in this scope.');
      }
    }
    addLocal(previous);
  }

  int parseVariable(String message) {
    consume(TokenType.identifier, message);

    declareVariable();
    if (scopeDepth > 0) return 0;

    return identifierConstant(previous);
  }

  void markInitialized() {
    locals.last = Local(locals.last.name, scopeDepth);
  }

  void defineVariable(int global) {
    if (scopeDepth > 0) {
      markInitialized();
      return;
    }

    emitOp(OpCode.opDefineGlobal);
    emitByte(global);
  }
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

typedef ParseFn = void Function(bool canAssign);

class ParseRule {
  const ParseRule(this.prefix, this.infix, this.precedence);

  final ParseFn? prefix;
  final ParseFn? infix;
  final Precedence precedence;
}

class Local {
  Local(this.name, this.depth);

  final Token name;
  final int depth;
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
