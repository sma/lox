import 'dart:io' show stderr;

import 'chunk.dart';
import 'debug.dart';
import 'printf.dart';
import 'scanner.dart';
import 'value.dart';

const debugPrintCode = true;

class Compiler(final Scanner scanner) {
  final chunk = Chunk();

  Token current = Token.none;
  Token previous = Token.none;
  bool hadError = false;
  bool panicMode = false;
  int scopeDepth = 0;
  final locals = <Local>[];

  ObjFunction? compile() {
    advance();

    while (!match(.eof)) {
      declaration();
    }

    consume(.eof, 'Expect end of expression.');
    endCompiler();
    return !hadError ? ObjFunction(chunk) : null;
  }

  void advance() {
    previous = current;
    for (;;) {
      current = scanner.scanToken();
      if (current.type != .error) break;
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
    stderr.printf('[line %d] Error', [token.line]);
    if (token.type == .eof) {
      stderr.printf(' at end');
    } else if (token.type == .error) {
      // Nothing.
    } else {
      stderr.printf(" at '%s'", [token.start]);
    }
    stderr.printf(': %s\n', [message]);
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
    emitOp(.opReturn);
  }

  int emitJump(OpCode op) {
    emitOp(op);
    emitByte(0xff);
    emitByte(0xff);
    return chunk.count - 2;
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
    emitOp(.opConstant);
    emitByte(makeConstant(value));
  }

  void emitLoop(int offset) {
    emitOp(.opLoop);
    var jump = chunk.count - offset + 2;
    if (jump > 65535) {
      error('Loop body too large.');
    }
    emitByte((jump >> 8) & 0xff);
    emitByte(jump & 0xff);
  }

  void patchJump(int offset) {
    var jump = chunk.count - offset - 2;
    if (jump > 65535) {
      error('Too much code to jump over.');
    }
    chunk.code[offset] = (jump >> 8) & 0xff;
    chunk.code[offset + 1] = jump & 0xff;
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
      emitOp(.opPop);
      locals.removeLast();
    }
  }

  // Parsing rules.

  void declaration() {
    if (match(.kVar)) {
      varDeclaration();
    } else {
      statement();
    }

    if (panicMode) synchronize();
  }

  void varDeclaration() {
    var global = parseVariable('Expect variable name.');

    if (match(.equal)) {
      expression();
    } else {
      emitOp(.opNil);
    }
    consume(.semicolon, "Expect ';' after variable declaration.");

    defineVariable(global);
  }

  void statement() {
    if (match(.kPrint)) {
      printStatement();
    } else if (match(.kFor)) {
      forStatement();
    } else if (match(.kIf)) {
      ifStatement();
    } else if (match(.kWhile)) {
      whileStatement();
    } else if (match(.leftBrace)) {
      beginScope();
      block();
      endScope();
    } else {
      expressionStatement();
    }
  }

  void printStatement() {
    expression();
    consume(.semicolon, "Expect ';' after value.");
    emitOp(.opPrint);
  }

  void forStatement() {
    beginScope();
    consume(.leftParen, "Expect '(' after 'for'.");

    if (match(.semicolon)) {
      // No initializer.
    } else if (match(.kVar)) {
      varDeclaration();
    } else {
      expressionStatement();
    }

    var loopStart = chunk.count;
    var exitJump = -1;
    if (!match(.semicolon)) {
      expression();
      consume(.semicolon, "Expect ';' after loop condition.");

      // Jump out of the loop if the condition is false.
      exitJump = emitJump(.opJumpIfFalse);
      emitOp(.opPop); // Condition.
    }

    if (!match(.rightParen)) {
      var bodyJump = emitJump(.opJump);
      var incrementStart = chunk.count;
      expression();
      emitOp(.opPop);
      consume(.rightParen, "Expect ')' after for clauses.");

      emitLoop(loopStart);
      loopStart = incrementStart;
      patchJump(bodyJump);
    }

    statement();
    emitLoop(loopStart);

    if (exitJump != -1) {
      patchJump(exitJump);
      emitOp(.opPop); // Condition.
    }

    endScope();
  }

  void ifStatement() {
    consume(.leftParen, "Expect '(' after 'if'.");
    expression();
    consume(.rightParen, "Expect ')' after condition.");
    var thenJump = emitJump(.opJumpIfFalse);
    emitOp(.opPop);
    statement();
    var elseJump = emitJump(.opJump);
    patchJump(thenJump);
    emitOp(.opPop);
    if (match(.kElse)) statement();
    patchJump(elseJump);
  }

  void whileStatement() {
    var loopStart = chunk.count;
    consume(.leftParen, "Expect '(' after 'while'.");
    expression();
    consume(.rightParen, "Expect ')' after condition.");
    var exitJump = emitJump(.opJumpIfFalse);
    emitOp(.opPop);
    statement();
    emitLoop(loopStart);
    patchJump(exitJump);
    emitOp(.opPop);
  }

  void expressionStatement() {
    expression();
    consume(.semicolon, "Expect ';' after expression.");
    emitOp(.opPop);
  }

  void block() {
    while (!check(.rightBrace) && !check(.eof)) {
      declaration();
    }

    consume(.rightBrace, "Expect '}' after block.");
  }

  void synchronize() {
    panicMode = false;

    while (current.type != .eof) {
      if (previous.type == .semicolon) return;

      switch (current.type) {
        case .kClass:
        case .kFun:
        case .kVar:
        case .kFor:
        case .kIf:
        case .kWhile:
        case .kPrint:
        case .kReturn:
          return;
        default:
          // Do nothing.
          break;
      }

      advance();
    }
  }

  void expression() {
    parsePrecedence(.assignment);
  }

  void grouping(bool canAssign) {
    expression();
    consume(.rightParen, "Expect ')' after expression.");
  }

  void number(bool canAssign) {
    emitConstant(Number(double.parse(previous.start)));
  }

  void string(bool canAssign) {
    var chars = previous.start.substring(1, previous.start.length - 1);
    emitConstant(ObjString(chars));
  }

  void variable(bool canAssign) {
    namedVariable(previous, canAssign);
  }

  void namedVariable(Token name, bool canAssign) {
    OpCode getOp, setOp;
    var arg = resolveLocal(name);
    if (arg != -1) {
      getOp = .opGetLocal;
      setOp = .opSetLocal;
    } else {
      arg = identifierConstant(name);
      getOp = .opGetGlobal;
      setOp = .opSetGlobal;
    }

    if (canAssign && match(.equal)) {
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
    parsePrecedence(.unary);

    // Emit the operator instruction.
    switch (operatorType) {
      case .minus:
        emitOp(.opNegate);
      case .bang:
        emitOp(.opNot);
      default:
        return; // Unreachable.
    }
  }

  void binary(bool canAssign) {
    var operatorType = previous.type;
    var rule = getRule(operatorType);
    parsePrecedence(rule.precedence.next);
    switch (operatorType) {
      case .bangEqual:
        emitOp(.opEqual);
        emitOp(.opNot);
      case .equalEqual:
        emitOp(.opEqual);
      case .greater:
        emitOp(.opGreater);
      case .greaterEqual:
        emitOp(.opLess);
        emitOp(.opNot);
      case .less:
        emitOp(.opLess);
      case .lessEqual:
        emitOp(.opGreater);
        emitOp(.opNot);
      case .plus:
        emitOp(.opAdd);
      case .minus:
        emitOp(.opSubtract);
      case .star:
        emitOp(.opMultiply);
      case .slash:
        emitOp(.opDivide);
      default:
        return; // Unreachable.
    }
  }

  void literal(bool canAssign) {
    switch (previous.type) {
      case .kFalse:
        emitOp(.opFalse);
      case .kTrue:
        emitOp(.opTrue);
      case .kNil:
        emitOp(.opNil);
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

    var canAssign = precedence <= .assignment;
    prefixRule(canAssign);

    while (precedence <= getRule(current.type).precedence) {
      advance();
      getRule(previous.type).infix!(canAssign);
    }

    if (canAssign && match(.equal)) {
      error('Invalid assignment target.');
    }
  }

  ParseRule getRule(TokenType type) => _rules[type]!;

  late final _rules = <TokenType, ParseRule>{
    .leftParen: ParseRule(grouping, null, .none),
    .rightParen: ParseRule(null, null, .none),
    .leftBrace: ParseRule(null, null, .none),
    .rightBrace: ParseRule(null, null, .none),
    .comma: ParseRule(null, null, .none),
    .dot: ParseRule(null, null, .none),
    .minus: ParseRule(unary, binary, .term),
    .plus: ParseRule(null, binary, .term),
    .semicolon: ParseRule(null, null, .none),
    .slash: ParseRule(null, binary, .factor),
    .star: ParseRule(null, binary, .factor),
    .bang: ParseRule(unary, null, .none),
    .bangEqual: ParseRule(null, binary, .equality),
    .equal: ParseRule(null, null, .none),
    .equalEqual: ParseRule(null, binary, .equality),
    .greater: ParseRule(null, binary, .comparison),
    .greaterEqual: ParseRule(null, binary, .comparison),
    .less: ParseRule(null, binary, .comparison),
    .lessEqual: ParseRule(null, binary, .comparison),
    .identifier: ParseRule(variable, null, .none),
    .string: ParseRule(string, null, .none),
    .number: ParseRule(number, null, .none),
    .kAnd: ParseRule(null, and_, .and),
    .kClass: ParseRule(null, null, .none),
    .kElse: ParseRule(null, null, .none),
    .kFalse: ParseRule(literal, null, .none),
    .kFor: ParseRule(null, null, .none),
    .kFun: ParseRule(null, null, .none),
    .kIf: ParseRule(null, null, .none),
    .kNil: ParseRule(literal, null, .none),
    .kOr: ParseRule(null, or_, .or),
    .kPrint: ParseRule(null, null, .none),
    .kReturn: ParseRule(null, null, .none),
    .kSuper: ParseRule(null, null, .none),
    .kThis: ParseRule(null, null, .none),
    .kTrue: ParseRule(literal, null, .none),
    .kVar: ParseRule(null, null, .none),
    .kWhile: ParseRule(null, null, .none),
    .error: ParseRule(null, null, .none),
    .eof: ParseRule(null, null, .none),
  };

  int identifierConstant(Token name) {
    return makeConstant(ObjString(name.start));
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
    consume(.identifier, message);

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

    emitOp(.opDefineGlobal);
    emitByte(global);
  }

  void and_(bool canAssign) {
    var endJump = emitJump(.opJumpIfFalse);
    emitOp(.opPop);
    parsePrecedence(.and);
    patchJump(endJump);
  }

  void or_(bool canAssign) {
    var elseJump = emitJump(.opJumpIfFalse);
    var endJump = emitJump(.opJump);
    patchJump(elseJump);
    emitOp(.opPop);
    parsePrecedence(.or);
    patchJump(endJump);
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
      stderr.printf('%04d ', [line]);
    } else {
      stderr.printf('   | ');
    }
    stderr.printf("%10s '%s'\n", [token.type.name, token.start]);

    if (token.type == .eof) break;
  }
}
