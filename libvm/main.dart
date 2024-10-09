import 'chunk.dart';
import 'debug.dart';
import 'vm.dart';

void main(List<String> arguments) {
  final chunk = Chunk();
  chunk.writeOp(OpCode.opConstant, 123);
  chunk.write(chunk.addConstant(1.2), 123);
  chunk.writeOp(OpCode.opConstant, 123);
  chunk.write(chunk.addConstant(3.4), 123);
  chunk.writeOp(OpCode.opAdd, 123);
  chunk.writeOp(OpCode.opConstant, 123);
  chunk.write(chunk.addConstant(5.6), 123);
  chunk.writeOp(OpCode.opDivide, 123);
  chunk.writeOp(OpCode.opNegate, 123);
  chunk.writeOp(OpCode.opReturn, 123);
  disassembleChunk(chunk, 'test chunk');
  vm.interpret(chunk);
}
