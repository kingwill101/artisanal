import 'package:artisanal/tui.dart';
import 'package:artisanal/src/tui/cmd.dart' show WriteRawMsg;
import 'package:test/test.dart';

void main() {
  group('TerminalPaletteService', () {
    test('handle caches core and indexed palette reports', () {
      final service = TerminalPaletteService();

      expect(service.handle(const ForegroundColorMsg(hex: '#eeeeee')), isTrue);
      expect(service.handle(const BackgroundColorMsg(hex: '#111111')), isTrue);
      expect(service.handle(const CursorColorMsg(hex: '#ff00ff')), isTrue);
      expect(
        service.handle(const ColorPaletteMsg(index: 4, hex: '#336699')),
        isTrue,
      );
      expect(service.handle(const RepaintMsg()), isFalse);

      final snapshot = service.snapshot;
      expect(snapshot.foregroundHex, equals('#eeeeee'));
      expect(snapshot.backgroundHex, equals('#111111'));
      expect(snapshot.cursorHex, equals('#ff00ff'));
      expect(snapshot.paletteHex(4), equals('#336699'));
      expect(snapshot.isBackgroundDark, isTrue);
    });

    test('clear resets cached values', () {
      final service = TerminalPaletteService()
        ..handle(const ForegroundColorMsg(hex: '#ffffff'))
        ..handle(const ColorPaletteMsg(index: 1, hex: '#ff0000'));

      service.clear();

      final snapshot = service.snapshot;
      expect(snapshot.foregroundHex, isNull);
      expect(snapshot.backgroundHex, isNull);
      expect(snapshot.cursorHex, isNull);
      expect(snapshot.palette, isEmpty);
    });

    test(
      'requestCoreColors batches foreground background and cursor probes',
      () async {
        final msg = await TerminalPaletteService()
            .requestCoreColors()
            .execute();

        expect(msg, isA<BatchMsg>());
        final batch = msg as BatchMsg;
        expect(batch.messages, hasLength(3));
        expect(
          batch.messages.whereType<WriteRawMsg>().map((m) => m.data).toList(),
          equals(<String>['\x1b]10;?\x07', '\x1b]11;?\x07', '\x1b]12;?\x07']),
        );
      },
    );

    test('requestPalette deduplicates and sorts indices', () async {
      final msg = await TerminalPaletteService().requestPalette(<int>[
        7,
        2,
        7,
        0,
      ]).execute();

      expect(msg, isA<BatchMsg>());
      final batch = msg as BatchMsg;
      expect(
        batch.messages.whereType<WriteRawMsg>().map((m) => m.data).toList(),
        equals(<String>['\x1b]4;0;?\x07', '\x1b]4;2;?\x07', '\x1b]4;7;?\x07']),
      );
    });

    test('requestAnsiPalette clamps count and supports zero', () async {
      final zero = await TerminalPaletteService()
          .requestAnsiPalette(count: 0)
          .execute();
      expect(zero, isNull);

      final three = await TerminalPaletteService()
          .requestAnsiPalette(count: 3)
          .execute();
      expect(three, isA<BatchMsg>());
      expect((three as BatchMsg).messages, hasLength(3));
    });
  });
}
