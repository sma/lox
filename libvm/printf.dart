import 'dart:io';

void printf(String fmt, [List<Object?> arguments = const []]) {
  var i = 0;
  stdout.write(fmt.replaceAllMapped(RegExp(r'%%|%(-)?(0)?(\d+)?[sdfg]'), (match) {
    if (match[0] == '%%') return '%';
    var s = '${arguments[i++]}';
    if (match[3] case final w?) {
      final pad = match[1] != null ? s.padRight : s.padLeft;
      s = pad(int.parse(w), match[2] == '0' ? '0' : ' ');
    }
    return s;
  }));
}
