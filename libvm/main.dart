import 'chunk.dart';
import 'debug.dart';

void main(List<String> arguments) {
  final chunk = Chunk();
  chunk.writeOp(OpCode.opConstant, 123);
  chunk.write(chunk.addConstant(1.2), 123);
  chunk.writeOp(OpCode.opReturn, 123);
  disassembleChunk(chunk, 'test chunk');
}
