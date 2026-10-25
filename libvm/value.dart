import 'chunk.dart';
import 'printf.dart';

sealed class const Value() {
  factory Value.as(Object? value) => switch (value) {
    null => Nil(),
    bool value => Bool(value),
    double value => Number(value),
    _ => throw ArgumentError(),
  };

  bool get isFalsey => false;

  static const nil = Nil();
}

class const Nil() extends Value {
  @override
  bool get isFalsey => true;

  @override
  String toString() => 'nil';
}

class const Bool(final bool value) extends Value {
  @override
  bool get isFalsey => !value;

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) => other is Bool && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class const Number(final double value) extends Value {
  @override
  String toString() => '$value';

  @override
  bool operator ==(Object other) => other is Number && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

sealed class const Obj() extends Value;

class const ObjString(final String value) extends Obj {
  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is ObjString && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class ObjFunction(final Chunk chunk, [var int arity = 0, var String? name]) extends Obj {
  @override
  String toString() => '<fn ${name ?? '<script>'}>';
}

extension ValueExt on StringSink {
  void printValue(Value value) {
    switch (value) {
      case Nil():
        write('nil');
      case Bool(:var value):
        write(value ? 'true' : 'false');
      case Number(:var value):
        write(sprintf('%g', [value]));
      case Obj():
        printObject(value);
    }
  }

  void printObject(Obj object) {
    switch (object) {
      case ObjString():
        write(sprintf('%s', [object.value]));
      case ObjFunction():
        write(sprintf('<fn %s>', [object.name ?? '<script>']));
    }
  }
}
