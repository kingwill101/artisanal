import 'package:artisanal/src/tui/cmd.dart';
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

  test('BackgroundColorMsg uses WCAG luminance for dark detection', () {
    expect(const BackgroundColorMsg(hex: '#282c34').isDark, isTrue);
    expect(const BackgroundColorMsg(hex: '#f5f5f5').isDark, isFalse);
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

  test('TerminalThemeState ignores color scheme preference messages', () {
    var s = const TerminalThemeState(
      backgroundHex: '#101010',
      hasDarkBackground: null,
    );
    s = s.update(UvEventMsg(const LightColorSchemeEvent()));
    expect(s.backgroundHex, '#101010');
    expect(s.hasDarkBackground, null);

    s = s.update(UvEventMsg(const DarkColorSchemeEvent()));
    expect(s.backgroundHex, '#101010');
    expect(s.hasDarkBackground, null);
  });

  test('TerminalColorSchemeState updates from color scheme messages', () {
    var s = const TerminalColorSchemeState();

    s = s.update(const ColorSchemeMsg(dark: false));
    expect(s.hasDarkColorScheme, false);

    s = s.update(const ColorSchemeMsg(dark: true));
    expect(s.hasDarkColorScheme, true);

    s = s.update(UvEventMsg(const LightColorSchemeEvent()));
    expect(s.hasDarkColorScheme, false);
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
    host.updateTerminalTheme(const ColorSchemeMsg(dark: false));
    host.updateTerminalTheme(const CursorColorMsg(hex: '#ff00ff'));

    expect(host.terminalTheme.foregroundHex, '#eeeeee');
    expect(host.terminalTheme.backgroundHex, '#111111');
    expect(host.terminalTheme.cursorHex, '#ff00ff');
    expect(host.terminalTheme.hasDarkBackground, isTrue);
    expect(host.terminalColorScheme.hasDarkColorScheme, isFalse);
    expect(host.terminalPalette.snapshot.backgroundHex, '#111111');
  });

  test('TerminalThemeHost can issue core-color probes', () async {
    final host = _TestTerminalThemeHost();
    final cmd = host.probeTerminalTheme();

    expect(cmd, isA<ParallelCmd>());
    final batch = cmd as ParallelCmd;
    expect(batch.commands, hasLength(3));
    expect(await batch.commands[0].execute(), isA<WriteRawMsg>());
    expect(await batch.commands[1].execute(), isA<WriteRawMsg>());
    expect(await batch.commands[2].execute(), isA<WriteRawMsg>());
  });

  test('TerminalThemeHost can issue startup probes with palette entries', () {
    final host = _TestTerminalThemeHost();
    final cmd = host.initTerminalTheme(paletteCount: 4);

    expect(cmd, isA<ParallelCmd>());
    final outer = cmd as ParallelCmd;
    expect(outer.commands, hasLength(2));
    expect(outer.commands.first, isA<ParallelCmd>());
    expect(outer.commands.last, isA<ParallelCmd>());

    final core = outer.commands.first as ParallelCmd;
    final palette = outer.commands.last as ParallelCmd;
    expect(core.commands, hasLength(3));
    expect(palette.commands, hasLength(4));
  });
}

final class _TestTerminalThemeHost with TerminalThemeHost {}
