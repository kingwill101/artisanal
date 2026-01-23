import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/theme.dart';
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
}
