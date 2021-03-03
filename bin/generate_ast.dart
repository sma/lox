import 'dart:io';

var files = <String>[];

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: generate_ast <output directory>');
    exit(1);
  }
  var outputDir = args[0];
  defineAst(outputDir, 'Expr', [
    'Assign   : Token name, Expr value',
    'Binary   : Expr left, Token operator, Expr right',
    'Call     : Expr callee, Token paren, List<Expr> arguments',
    'Get      : Expr object, Token name',
    'Grouping : Expr expression',
    'Literal  : Object value',
    'Logical  : Expr left, Token operator, Expr right',
    'Set      : Expr object, Token name, Expr value',
    'Super    : Token keyword, Token method',
    'This     : Token keyword',
    'Unary    : Token operator, Expr right',
    'Variable : Token name',
  ]);

  defineAst(outputDir, 'Stmt', [
    'Block      : List<Stmt> statements',
    'Class      : Token name, Variable superclass, List<Function> methods',
    'Expression : Expr expression',
    'Function   : Token name, List<Token> params, List<Stmt> body',
    'If         : Expr condition, Stmt thenBranch, Stmt elseBranch',
    'Print      : Expr expression',
    'Return     : Token keyword, Expr value',
    'Var        : Token name, Expr initializer',
    'While      : Expr condition, Stmt body',
  ]);

  var writer = File('$outputDir/ast.dart').openWrite();
  writer.writeln('library ast;');
  writer.writeln();
  writer.writeln("import 'token.dart';");
  writer.writeln();
  for (var file in files) {
    writer.writeln("part '$file';");
  }
  writer.close();
}

void defineAst(String outputDir, String baseName, List<String> types) {
  var file = snakeCase(baseName) + '.dart';
  files.add(file);
  var writer = File('$outputDir/$file').openWrite();

  writer.writeln('part of ast;');
  writer.writeln();
  writer.writeln('abstract class $baseName {');
  // The base accept() method.
  writer.writeln('  R accept<R>(${baseName}Visitor<R> visitor);');
  writer.writeln('}');
  writer.writeln();

  defineVisitor(writer, baseName, types);

  // The AST classes.
  for (var type in types) {
    var className = type.split(':')[0].trim();
    var fields = type.split(':')[1].trim();
    defineType(writer, baseName, className, fields);
  }

  writer.close();
}

void defineVisitor(IOSink writer, String baseName, List<String> types) {
  writer.writeln('abstract class ${baseName}Visitor<R> {');

  for (var type in types) {
    var typeName = type.split(':')[0].trim();
    writer.writeln('  R visit$typeName$baseName($typeName ${baseName.toLowerCase()});');
  }

  writer.writeln('}');
}

void defineType(IOSink writer, String baseName, String className, String fieldList) {
  writer.writeln();
  writer.writeln('class $className extends $baseName {');

  // Constructor.
  writer.writeln('  $className(');

  // Store parameters in fields.
  var fields = fieldList.split(', ');
  for (var field in fields) {
    var name = field.split(' ')[1];
    writer.writeln('    this.$name,');
  }

  writer.writeln('  );');

  // Visitor pattern.
  writer.writeln();
  writer.writeln('  @override');
  writer.writeln('  R accept<R>(${baseName}Visitor<R> visitor) {');
  writer.writeln('    return visitor.visit$className$baseName(this);');
  writer.writeln('  }');

  // Fields.
  writer.writeln();
  for (var field in fields) {
    writer.writeln('  final $field;');
  }

  writer.writeln('}');
}

String snakeCase(String s) {
  return s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}').toLowerCase();
}
