import 'chunk.dart';
import 'printf.dart';

sealed class Value {
  const Value();

  factory Value.as(Object? value) => switch (value) {
        null => Nil(),
        bool value => Bool(value),
        double value => Number(value),
        _ => throw ArgumentError(),
      };

  bool get isFalsey => false;

  static const nil = Nil();
}

class Nil extends Value {
  const Nil();

  @override
  bool get isFalsey => true;

  @override
  String toString() => 'nil';
}

class Bool extends Value {
  const Bool(this.value);

  final bool value;

  @override
  bool get isFalsey => !value;

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) => other is Bool && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class Number extends Value {
  const Number(this.value);

  final double value;

  @override
  String toString() => '$value';

  @override
  bool operator ==(Object other) => other is Number && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

sealed class Obj extends Value {
  const Obj();
}

class ObjString extends Obj {
  const ObjString(this.value);

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is ObjString && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class ObjFunction extends Obj {
  ObjFunction(this.chunk, [this.arity = 0, this.name]);

  final Chunk chunk;
  int arity;
  String? name;

  @override
  String toString() => '<fn ${name ?? '<script>'}>';
}

void printValue(Value value) {
  switch (value) {
    case Nil():
      printf('nil');
    case Bool(:var value):
      printf(value ? 'true' : 'false');
    case Number(:var value):
      printf('%g', [value]);
    case Obj():
      printObject(value);
  }
}

void printObject(Obj object) {
  switch (object) {
    case ObjString():
      printf('%s', [object.value]);
    case ObjFunction():
      printf('<fn %s>', [object.name ?? '<script>']);
  }
}
