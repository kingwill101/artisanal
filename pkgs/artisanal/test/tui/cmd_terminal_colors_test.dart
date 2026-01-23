import 'package:artisanal/src/terminal/ansi.dart' as term_ansi;
import 'package:artisanal/src/tui/cmd.dart';
import 'package:test/test.dart';

void main() {
  group('Cmd terminal color reports', () {
    test(
      'requestTerminalColors emits WriteRawMsg with OSC 10/11/12 + DA1',
      () async {
        final msg = await Cmd.requestTerminalColors().execute();
        expect(msg, isA<WriteRawMsg>());
        final m = msg as WriteRawMsg;
        expect(
          m.data,
          term_ansi.Ansi.requestForegroundColor +
              term_ansi.Ansi.requestBackgroundColor +
              term_ansi.Ansi.requestCursorColor +
              term_ansi.Ansi.requestPrimaryDeviceAttributes,
        );
      },
    );

    test(
      'requestBackgroundColorReport emits WriteRawMsg with OSC 11 + DA1',
      () async {
        final msg = await Cmd.requestBackgroundColorReport().execute();
        expect(msg, isA<WriteRawMsg>());
        final m = msg as WriteRawMsg;
        expect(
          m.data,
          term_ansi.Ansi.requestBackgroundColor +
              term_ansi.Ansi.requestPrimaryDeviceAttributes,
        );
      },
    );
  });
}
