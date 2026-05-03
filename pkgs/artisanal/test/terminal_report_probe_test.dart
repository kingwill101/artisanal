import 'dart:convert';

import 'package:artisanal/terminal.dart';
import 'package:test/test.dart';

void main() {
  test('TerminalReportProbe decodes foot report bundle', () {
    const raw =
        '\x1b[4;1024;954t'
        '\x1b[6;16;6t'
        '\x1b[?62;4;22;28;52c'
        '\x1bP>|foot(1.26.1)\x1b\\';

    final snapshot = TerminalReportProbe.decodeBytes(utf8.encode(raw));

    expect(snapshot.windowPixelWidth, 954);
    expect(snapshot.windowPixelHeight, 1024);
    expect(snapshot.cellPixelWidth, 6);
    expect(snapshot.cellPixelHeight, 16);
    expect(snapshot.primaryAttributes, [62, 4, 22, 28, 52]);
    expect(snapshot.hasSixel, isTrue);
    expect(snapshot.terminalVersion, 'foot(1.26.1)');
  });
}
