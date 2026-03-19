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

    test('receives clipboard responses', () async {
      await terminal.start(handleSignals: false);
      final clipboardFuture = terminal.events
          .where((e) => e is ClipboardEvent)
          .cast<ClipboardEvent>()
          .firstWhere((e) => e.selection == 0x63 && e.content == 'Hello');

      inputController.add('\x1b]52;c;SGVsbG8=\x07'.codeUnits);

      final event = await clipboardFuture;
      expect(event.selection, 0x63);
      expect(event.content, 'Hello');

      await terminal.stop();
    });

    test('receives mouse click and release events', () async {
      await terminal.start(handleSignals: false);
      final clickFuture = terminal.events
          .where((e) => e is MouseClickEvent)
          .first;
      final releaseFuture = terminal.events
          .where((e) => e is MouseReleaseEvent)
          .first;

      inputController.add('\x1b[<0;5;3M'.codeUnits);
      inputController.add('\x1b[<0;5;3m'.codeUnits);

      final click = await clickFuture as MouseClickEvent;
      final release = await releaseFuture as MouseReleaseEvent;

      expect(
        click.mouse(),
        const Mouse(x: 4, y: 2, button: MouseButton.left, mod: 0),
      );
      expect(
        release.mouse(),
        const Mouse(x: 4, y: 2, button: MouseButton.left, mod: 0),
      );

      await terminal.stop();
    });

    test('receives mouse wheel events', () async {
      await terminal.start(handleSignals: false);
      final wheelFuture = terminal.events
          .where((e) => e is MouseWheelEvent)
          .first;

      inputController.add('\x1b[<64;7;4M'.codeUnits);

      final wheel = await wheelFuture as MouseWheelEvent;
      expect(
        wheel.mouse(),
        const Mouse(
          x: 6,
          y: 3,
          button: MouseButton.wheelUp,
          mod: 0,
        ),
      );

      await terminal.stop();
    });

    test('receives mouse motion events', () async {
      await terminal.start(handleSignals: false);
      final motionFuture = terminal.events
          .where((e) => e is MouseMotionEvent)
          .first;

      inputController.add('\x1b[<32;9;6M'.codeUnits);

      final motion = await motionFuture as MouseMotionEvent;
      expect(
        motion.mouse(),
        const Mouse(x: 8, y: 5, button: MouseButton.left, mod: 0),
      );

      await terminal.stop();
    });

    test('receives window size reports and updates terminal size', () async {
      await terminal.start(handleSignals: false);
      final resizeFuture = terminal.events
          .where((e) => e is WindowSizeEvent)
          .cast<WindowSizeEvent>()
          .firstWhere((e) => e.width == 120 && e.height == 33);

      inputController.add('\x1b[8;33;120t'.codeUnits);

      final resize = await resizeFuture;
      expect(resize.width, 120);
      expect(resize.height, 33);
      expect(terminal.bounds().width, 120);
      expect(terminal.bounds().height, 33);

      await terminal.stop();
    });

    test('receives cursor position reports', () async {
      await terminal.start(handleSignals: false);
      final cursorFuture = terminal.events
          .where((e) => e is CursorPositionEvent)
          .cast<CursorPositionEvent>()
          .firstWhere((e) => e.x == 33 && e.y == 11);

      inputController.add('\x1b[12;34R'.codeUnits);

      final pos = await cursorFuture;
      expect(pos.x, 33);
      expect(pos.y, 11);

      await terminal.stop();
    });

    test('receives in-band terminal size reports and updates terminal size', () async {
      await terminal.start(handleSignals: false);
      final resizeFuture = terminal.events
          .where((e) => e is WindowSizeEvent)
          .cast<WindowSizeEvent>()
          .firstWhere((e) => e.width == 120 && e.height == 33);
      final pixelFuture = terminal.events
          .where((e) => e is WindowPixelSizeEvent)
          .cast<WindowPixelSizeEvent>()
          .firstWhere((e) => e.width == 2400 && e.height == 660);

      inputController.add('\x1b[48;33;120;660;2400t'.codeUnits);

      final resize = await resizeFuture;
      final pixels = await pixelFuture;
      expect(resize.width, 120);
      expect(resize.height, 33);
      expect(pixels.width, 2400);
      expect(pixels.height, 660);
      expect(terminal.bounds().width, 120);
      expect(terminal.bounds().height, 33);

      await terminal.stop();
    });

    test('receives ModifyOtherKeys reports', () async {
      await terminal.start(handleSignals: false);
      final reportFuture = terminal.events
          .where((e) => e is ModifyOtherKeysEvent)
          .cast<ModifyOtherKeysEvent>()
          .firstWhere((e) => e.mode == 1);

      inputController.add('\x1b[>4;1m'.codeUnits);

      final report = await reportFuture;
      expect(report.mode, 1);
      expect(terminal.capabilities.modifyOtherKeysMode, 1);

      await terminal.stop();
    });

    test('receives color scheme reports and updates capabilities', () async {
      await terminal.start(handleSignals: false);
      final darkFuture = terminal.events.where((e) => e is DarkColorSchemeEvent).first;
      final lightFuture = terminal.events.where((e) => e is LightColorSchemeEvent).first;

      inputController.add('\x1b[?997;1n'.codeUnits);
      await darkFuture;
      expect(terminal.capabilities.darkColorScheme, isTrue);

      inputController.add('\x1b[?997;2n'.codeUnits);
      await lightFuture;
      expect(terminal.capabilities.darkColorScheme, isFalse);

      await terminal.stop();
    });

    test('receives device attribute reports and updates capabilities', () async {
      await terminal.start(handleSignals: false);
      final primaryFuture = terminal.events
          .where((e) => e is PrimaryDeviceAttributesEvent)
          .cast<PrimaryDeviceAttributesEvent>()
          .firstWhere((e) => e.attrs.length == 3 && e.attrs[1] == 4);
      final secondaryFuture = terminal.events
          .where((e) => e is SecondaryDeviceAttributesEvent)
          .cast<SecondaryDeviceAttributesEvent>()
          .firstWhere((e) => e.attrs.length == 3 && e.attrs[2] == 3);
      final tertiaryFuture = terminal.events
          .where((e) => e is TertiaryDeviceAttributesEvent)
          .cast<TertiaryDeviceAttributesEvent>()
          .firstWhere((e) => e.value == 'Chrm');

      inputController.add('\x1b[?1;4;18c'.codeUnits);
      inputController.add('\x1b[>1;2;3c'.codeUnits);
      inputController.add('\x1bP!|4368726d\x1b\\'.codeUnits);

      final primary = await primaryFuture;
      final secondary = await secondaryFuture;
      final tertiary = await tertiaryFuture;

      expect(primary.attrs, [1, 4, 18]);
      expect(secondary.attrs, [1, 2, 3]);
      expect(tertiary.value, 'Chrm');
      expect(terminal.capabilities.primaryAttributes, [1, 4, 18]);
      expect(terminal.capabilities.secondaryAttributes, [1, 2, 3]);
      expect(terminal.capabilities.tertiaryAttributes, 'Chrm');
      expect(terminal.capabilities.hasSixel, isTrue);

      await terminal.stop();
    });

    test('receives terminal version and XTGETTCAP responses', () async {
      await terminal.start(handleSignals: false);
      final versionFuture = terminal.events
          .where((e) => e is TerminalVersionEvent)
          .cast<TerminalVersionEvent>()
          .firstWhere((e) => e.name == 'Ultraviolet');
      final capabilityFuture = terminal.events
          .where((e) => e is CapabilityEvent)
          .cast<CapabilityEvent>()
          .firstWhere((e) => e.content == 'RGB;TN=xterm-256color');

      inputController.add('\x1bP>|Ultraviolet\x1b\\'.codeUnits);
      inputController.add(
        '\x1bP1+r524742;544e=787465726d2d323536636f6c6f72\x1b\\'.codeUnits,
      );

      final version = await versionFuture;
      final capability = await capabilityFuture;

      expect(version.name, 'Ultraviolet');
      expect(capability.content, 'RGB;TN=xterm-256color');
      expect(terminal.capabilities.terminalVersion, 'Ultraviolet');

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
      expect(output, contains('\x1b[>c'));
      expect(output, contains('\x1b[=c'));
      expect(output, contains('\x1b[>0q'));
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

    test('background and palette reports update capability state', () async {
      await terminal.start(handleSignals: false);

      final backgroundFuture = terminal.events
          .where((e) => e is BackgroundColorEvent)
          .cast<BackgroundColorEvent>()
          .firstWhere((e) => e.color == const UvRgb(0x11, 0x22, 0x33));
      final paletteFuture = terminal.events
          .where((e) => e is ColorPaletteEvent)
          .cast<ColorPaletteEvent>()
          .firstWhere((e) => e.index == 42 && e.color == const UvRgb(0x0f, 0x1a, 0x2b));

      inputController.add('\x1b]11;rgb:1111/2222/3333\x1b\\'.codeUnits);
      inputController.add('\x1b]4;42;rgb:0f0f/1a1a/2b2b\x1b\\'.codeUnits);

      await Future.wait([backgroundFuture, paletteFuture]);

      expect(terminal.capabilities.backgroundColor, const UvRgb(0x11, 0x22, 0x33));
      expect(terminal.capabilities.hasBackgroundColor, isTrue);
      expect(terminal.capabilities.palette[42], const UvRgb(0x0f, 0x1a, 0x2b));
      expect(terminal.capabilities.hasColorPalette, isTrue);

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
