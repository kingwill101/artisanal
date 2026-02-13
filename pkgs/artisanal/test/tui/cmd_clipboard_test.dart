import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/tui/msg.dart' show BatchMsg;
import 'package:test/test.dart';

void main() {
  group('Cmd clipboard/window reports', () {
    test('Cmd.setClipboard creates WriteRawMsg with OSC 52 payload', () async {
      final msg = await Cmd.setClipboard('Hello', selection: 'c').execute();
      expect(msg, isA<WriteRawMsg>());
      final raw = (msg as WriteRawMsg).data;
      expect(raw, startsWith('\x1b]52;c;'));
      expect(raw, endsWith('\x07'));
      // base64("Hello") = SGVsbG8=
      expect(raw, contains('SGVsbG8='));
    });

    test(
      'Cmd.setClipboardBestEffort uses external or OSC 52 fallback',
      () async {
        final msg = await Cmd.setClipboardBestEffort('Hello').execute();
        expect(msg, isNotNull);
        expect(msg is ClipboardSetMsg || msg is BatchMsg, isTrue);
      },
    );

    test(
      'Cmd.requestClipboard creates WriteRawMsg with OSC 52 query',
      () async {
        final msg = await Cmd.requestClipboard(selection: 'c').execute();
        expect(msg, isA<WriteRawMsg>());
        expect((msg as WriteRawMsg).data, equals('\x1b]52;c;?\x07'));
      },
    );

    test('Cmd.requestWindowSizeReport creates WriteRawMsg', () async {
      final msg = await Cmd.requestWindowSizeReport().execute();
      expect(msg, isA<WriteRawMsg>());
      expect((msg as WriteRawMsg).data, equals('\x1b[18t'));
    });
  });
}
