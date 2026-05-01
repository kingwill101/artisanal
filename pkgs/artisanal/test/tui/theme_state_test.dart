import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/theme.dart';
import 'package:artisanal/src/tui/terminal_palette.dart';
import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

void main() {
  test('TerminalThemeState updates from BackgroundColorMsg', () {
    var s = const TerminalThemeState();
    s = s.update(const BackgroundColorMsg(hex: '#ffffff'));
    expect(s.backgroundHex, '#ffffff');
    expect(s.hasDarkBackground, false);

    s = s.update(const BackgroundColorMsg(hex: '#000000'));
    expect(s.backgroundHex, '#000000');
    expect(s.hasDarkBackground, true);
  });

  test('TerminalThemeState keeps dark flag on unparseable hex', () {
    var s = const TerminalThemeState(
      backgroundHex: '#000000',
      hasDarkBackground: true,
    );
    s = s.update(const BackgroundColorMsg(hex: 'rgb:aa/bb/cc'));
    expect(s.backgroundHex, 'rgb:aa/bb/cc');
    expect(s.hasDarkBackground, true);
  });

  test('TerminalThemeState updates from UV color scheme events', () {
    var s = const TerminalThemeState(
      backgroundHex: '#101010',
      hasDarkBackground: null,
    );
    s = s.update(UvEventMsg(const LightColorSchemeEvent()));
    expect(s.backgroundHex, '#101010');
    expect(s.hasDarkBackground, false);

    s = s.update(UvEventMsg(const DarkColorSchemeEvent()));
    expect(s.hasDarkBackground, true);
  });

  test('TerminalThemeState updates from ColorSchemeMsg', () {
    var s = const TerminalThemeState(
      backgroundHex: '#101010',
      hasDarkBackground: null,
    );

    s = s.update(const ColorSchemeMsg(dark: false));
    expect(s.backgroundHex, '#101010');
    expect(s.hasDarkBackground, false);

    s = s.update(const ColorSchemeMsg(dark: true));
    expect(s.hasDarkBackground, true);
  });

  test('TerminalThemeState tracks foreground and cursor colors', () {
    var s = const TerminalThemeState();
    s = s.update(const ForegroundColorMsg(hex: '#eeeeee'));
    s = s.update(const CursorColorMsg(hex: '#ff00ff'));

    expect(s.foregroundHex, '#eeeeee');
    expect(s.cursorHex, '#ff00ff');
  });

  test('TerminalThemeState merges palette snapshots', () {
    final s =
        const TerminalThemeState(
          backgroundHex: '#ffffff',
          hasDarkBackground: false,
        ).mergePalette(
          TerminalPaletteSnapshot(
            foregroundHex: '#eeeeee',
            backgroundHex: '#101010',
            cursorHex: '#00ff00',
            palette: const <int, String>{4: '#336699'},
          ),
        );

    expect(s.foregroundHex, '#eeeeee');
    expect(s.backgroundHex, '#101010');
    expect(s.cursorHex, '#00ff00');
    expect(s.hasDarkBackground, true);
  });

  test('TerminalThemeHost updates theme from palette messages', () {
    final host = _TestTerminalThemeHost();

    host.updateTerminalTheme(const ForegroundColorMsg(hex: '#eeeeee'));
    host.updateTerminalTheme(const BackgroundColorMsg(hex: '#111111'));
    host.updateTerminalTheme(const CursorColorMsg(hex: '#ff00ff'));

    expect(host.terminalTheme.foregroundHex, '#eeeeee');
    expect(host.terminalTheme.backgroundHex, '#111111');
    expect(host.terminalTheme.cursorHex, '#ff00ff');
    expect(host.terminalTheme.hasDarkBackground, isTrue);
    expect(host.terminalPalette.snapshot.backgroundHex, '#111111');
  });

  test('TerminalThemeHost can issue core-color probes', () async {
    final host = _TestTerminalThemeHost();
    final msg = await host.probeTerminalTheme().execute();

    expect(msg, isA<BatchMsg>());
    expect((msg as BatchMsg).messages, hasLength(3));
  });

  test(
    'TerminalThemeHost can issue startup probes with palette entries',
    () async {
      final host = _TestTerminalThemeHost();
      final msg = await host.initTerminalTheme(paletteCount: 4).execute();

      expect(msg, isA<BatchMsg>());
      final outer = msg as BatchMsg;
      expect(outer.messages, hasLength(2));
      expect(outer.messages.first, isA<BatchMsg>());
      expect(outer.messages.last, isA<BatchMsg>());
      expect((outer.messages.first as BatchMsg).messages, hasLength(3));
      expect((outer.messages.last as BatchMsg).messages, hasLength(4));
    },
  );
}

final class _TestTerminalThemeHost with TerminalThemeHost {}
