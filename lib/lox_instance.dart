import 'lox_class.dart';

class LoxInstance {
  final LoxClass klass;

  LoxInstance(this.klass);

  @override
  String toString() {
    return klass.name + " instance";
  }
}
