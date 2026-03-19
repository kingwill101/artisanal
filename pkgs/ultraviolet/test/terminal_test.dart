import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

void main() {
  group('Terminal', () {
    late StreamController<List<int>> inputController;
    late StringBuffer outputBuffer;
    late Terminal terminal;

    setUp(() {
      inputController = StreamController<List<int>>();
      outputBuffer = StringBuffer();
      terminal = Terminal(
        input: inputController.stream,
        output: _MockIOSink(outputBuffer),
      );
    });

    test('start and stop', () async {
      final eventFuture = terminal.events.firstWhere(
        (e) => e is WindowSizeEvent,
      );
      await terminal.start(handleSignals: false);
      await eventFuture;
      await terminal.stop();
    });

    test('receives key events', () async {
      await terminal.start(handleSignals: false);
      final eventFuture = terminal.events
          .where((e) => e is KeyPressEvent)
          .first;

      inputController.add('a'.codeUnits);

      final event = await eventFuture as KeyPressEvent;
      expect(event.key().code, 'a'.codeUnitAt(0));

      await terminal.stop();
    });

    test('receives focus and blur events', () async {
      await terminal.start(handleSignals: false);
      final focusFuture = terminal.events.where((e) => e is FocusEvent).first;
      final blurFuture = terminal.events.where((e) => e is BlurEvent).first;

      inputController.add('\x1b[I'.codeUnits);
      inputController.add('\x1b[O'.codeUnits);

      expect(await focusFuture, isA<FocusEvent>());
      expect(await blurFuture, isA<BlurEvent>());

      await terminal.stop();
    });

    test('receives bracketed paste events', () async {
      await terminal.start(handleSignals: false);
      final pasteFuture = terminal.events.where((e) => e is PasteEvent).first;

      inputController.add('\x1b[200~hello\nworld\x1b[201~'.codeUnits);

      final event = await pasteFuture as PasteEvent;
      expect(event.content, 'hello\nworld');

      await terminal.stop();
    });

    test('draw writes to output', () async {
      await terminal.start(handleSignals: false);
      terminal.resize(10, 10);
      terminal.setCell(0, 0, Cell(content: 'X'));
      terminal.draw();

      expect(outputBuffer.toString(), isNotEmpty);
      await terminal.stop();
    });

    test('start queries terminal capabilities', () async {
      await terminal.start(handleSignals: false);

      final output = outputBuffer.toString();
      expect(output, contains('\x1b[?c'));
      expect(output, contains('\x1b[?u'));
      expect(output, contains('\x1b]10;?\x1b\\'));
      expect(output, contains('\x1b]11;?\x1b\\'));
      expect(output, contains('\x1b]12;?\x1b\\'));
      expect(output, contains('\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\\'));

      await terminal.stop();
    });

    test('startup color probes update capability state', () async {
      await terminal.start(handleSignals: false);

      final foregroundFuture = terminal.events
          .where((e) => e is ForegroundColorEvent)
          .first;
      final cursorFuture = terminal.events.where((e) => e is CursorColorEvent).first;

      inputController.add('\x1b]10;rgb:1111/2222/3333\x1b\\'.codeUnits);
      inputController.add('\x1b]12;rgb:aaaa/bbbb/cccc\x1b\\'.codeUnits);

      await Future.wait([foregroundFuture, cursorFuture]);

      expect(terminal.capabilities.foregroundColor, const UvRgb(0x11, 0x22, 0x33));
      expect(terminal.capabilities.hasForegroundColor, isTrue);
      expect(terminal.capabilities.cursorColor, const UvRgb(0xaa, 0xbb, 0xcc));
      expect(terminal.capabilities.hasCursorColor, isTrue);

      await terminal.stop();
    });

    test('keyboard enhancements enable and disable with kitty protocol', () async {
      await terminal.start(handleSignals: false);

      outputBuffer.clear();
      terminal.enableKeyboardEnhancements(
        KeyboardEnhancementsEvent.disambiguateEscapeCodes |
            KeyboardEnhancementsEvent.reportEventTypes,
      );
      terminal.disableKeyboardEnhancements();

      final output = outputBuffer.toString();
      expect(output, contains('\x1b[>3u'));
      expect(output, contains('\x1b[<u'));

      await terminal.stop();
    });

    test('stop disables enabled modes and exits alt screen', () async {
      await terminal.start(handleSignals: false);
      terminal.enterAltScreen();
      terminal.hideCursor();
      terminal.enableMouse();
      terminal.enableBracketedPaste();
      terminal.enableFocusReporting();
      terminal.enableKeyboardEnhancements(
        KeyboardEnhancementsEvent.disambiguateEscapeCodes,
      );

      outputBuffer.clear();
      await terminal.stop();

      final output = outputBuffer.toString();
      expect(output, contains('\x1b[<u'));
      expect(output, contains(UvAnsi.disableMouseAllEvents));
      expect(output, contains(UvAnsi.disableMouseSgr));
      expect(output, contains(UvAnsi.disableBracketedPaste));
      expect(output, contains(UvAnsi.disableFocusReporting));
      expect(output, contains(UvAnsi.showCursor));
      expect(output, contains(UvAnsi.resetModeAltScreenSaveCursor));
    });
  });
}

class _MockIOSink implements IOSink {
  _MockIOSink(this.buffer);
  final StringBuffer buffer;

  @override
  void add(List<int> data) {
    buffer.write(String.fromCharCodes(data));
  }

  @override
  void write(Object? obj) {
    buffer.write(obj);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    buffer.writeCharCode(charCode);
  }

  @override
  void writeln([Object? obj = ""]) {
    buffer.writeln(obj);
  }

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future close() async {}

  @override
  Future get done => Future.value();

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  set encoding(Encoding encoding) {}
  @override
  Encoding get encoding => utf8;

  @override
  Future flush() async {}
}
