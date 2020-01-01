enum TokenType {                                   
  // Single-character tokens.                      
  LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
  COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR, 

  // One or two character tokens.                  
  BANG, BANG_EQUAL,                                
  EQUAL, EQUAL_EQUAL,                              
  GREATER, GREATER_EQUAL,                          
  LESS, LESS_EQUAL,                                

  // Literals.                                     
  IDENTIFIER, STRING, NUMBER,                      

  // Keywords.                                     
  AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR,
  PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE,

  EOF                                              
}

// for compatibility with Java
const LEFT_PAREN = TokenType.LEFT_PAREN;
const RIGHT_PAREN = TokenType.RIGHT_PAREN;
const LEFT_BRACE = TokenType.LEFT_BRACE;
const RIGHT_BRACE = TokenType.RIGHT_BRACE;
const COMMA = TokenType.COMMA;
const DOT = TokenType.DOT;
const MINUS = TokenType.MINUS;
const PLUS = TokenType.PLUS;
const SEMICOLON = TokenType.SEMICOLON;
const SLASH = TokenType.SLASH;
const STAR = TokenType.STAR;

const BANG = TokenType.BANG;
const BANG_EQUAL = TokenType.BANG_EQUAL;
const EQUAL = TokenType.EQUAL;
const EQUAL_EQUAL = TokenType.EQUAL_EQUAL;
const GREATER = TokenType.GREATER;
const GREATER_EQUAL = TokenType.GREATER_EQUAL;
const LESS = TokenType.LESS;
const LESS_EQUAL = TokenType.LESS_EQUAL;

const IDENTIFIER = TokenType.IDENTIFIER;
const STRING = TokenType.STRING;
const NUMBER = TokenType.NUMBER;

const AND = TokenType.AND;
const CLASS = TokenType.CLASS;
const ELSE = TokenType.ELSE;
const FALSE = TokenType.FALSE;
const FUN = TokenType.FUN;
const FOR = TokenType.FOR;
const IF = TokenType.IF;
const NIL = TokenType.NIL;
const OR = TokenType.OR;
const PRINT = TokenType.PRINT;
const RETURN = TokenType.RETURN;
const SUPER = TokenType.SUPER;
const THIS = TokenType.THIS;
const TRUE = TokenType.TRUE;
const VAR = TokenType.VAR;
const WHILE = TokenType.WHILE;

const EOF = TokenType.EOF;
