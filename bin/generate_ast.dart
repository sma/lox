import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln("Usage: generate_ast <output directory>");
    exit(1);
  }
  var outputDir = args[0];
  defineAst(outputDir, "Expr", [
    "Binary   : Expr left, Token operator, Expr right",
    "Grouping : Expr expression",
    "Literal  : Object value",
    "Unary    : Token operator, Expr right",
  ]);
}

void defineAst(String outputDir, String baseName, List<String> types) {
  var path = outputDir + "/" + snakeCase(baseName) + ".dart";
  var writer = File(path).openWrite();

  writer.writeln("import 'package:lox/token.dart';");
  writer.writeln();
  writer.writeln("abstract class " + baseName + " {");
  // The base accept() method.
  writer.writeln("  R accept<R>(Visitor<R> visitor);");
  writer.writeln("}");
  writer.writeln();

  defineVisitor(writer, baseName, types);

  // The AST classes.
  for (var type in types) {
    var className = type.split(":")[0].trim();
    var fields = type.split(":")[1].trim();
    defineType(writer, baseName, className, fields);
  }

  writer.close();
}

void defineVisitor(IOSink writer, String baseName, List<String> types) {
  writer.writeln("abstract class Visitor<R> {");

  for (var type in types) {
    var typeName = type.split(":")[0].trim();
    writer.writeln("  R visit" + typeName + baseName + "(" + typeName + " " + baseName.toLowerCase() + ");");
  }

  writer.writeln("}");
}

void defineType(IOSink writer, String baseName, String className, String fieldList) {
  writer.writeln();
  writer.writeln("class $className extends $baseName {");

  // Constructor.
  writer.writeln("  $className(");

  // Store parameters in fields.
  var fields = fieldList.split(", ");
  for (var field in fields) {
    var name = field.split(" ")[1];
    writer.writeln("    this.$name,");
  }

  writer.writeln("  );");

  // Visitor pattern.
  writer.writeln();
  writer.writeln("  @override");
  writer.writeln("  R accept<R>(Visitor<R> visitor) {");
  writer.writeln("    return visitor.visit$className$baseName(this);");
  writer.writeln("  }");

  // Fields.
  writer.writeln();
  for (var field in fields) {
    writer.writeln("  final " + field + ";");
  }

  writer.writeln("}");
}

String snakeCase(String s) {
  return s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}').toLowerCase();
}
