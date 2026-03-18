import 'package:ultraviolet/src/uv/uv.dart';
import 'package:test/test.dart';

void main() {
  group('TerminalCapabilities', () {
    test('detects iTerm2 via environment', () {
      final caps = TerminalCapabilities(
        env: const ['TERM_PROGRAM=iTerm.app', 'LC_TERMINAL=iTerm2'],
      );
      expect(caps.hasITerm2, isTrue);
      // iTerm2 does not imply kitty graphics.
      expect(caps.hasKittyGraphics, isFalse);
    });

    test('does not mark WezTerm as iTerm2, but can hint kitty graphics', () {
      final caps = TerminalCapabilities(env: const ['TERM_PROGRAM=WezTerm']);
      expect(caps.hasITerm2, isFalse);
      expect(caps.hasKittyGraphics, isTrue);
    });

    test('sets hasSixel from primary device attributes (DA1 attr 4)', () {
      final caps = TerminalCapabilities(env: const []);
      expect(caps.hasSixel, isFalse);
      caps.updateFromEvent(const PrimaryDeviceAttributesEvent([1, 4, 18]));
      expect(caps.hasSixel, isTrue);
    });

    test('stores background color and palette reports', () {
      final caps = TerminalCapabilities(env: const []);

      final backgroundChanged = caps.updateFromEvent(
        const BackgroundColorEvent(UvRgb(0x11, 0x22, 0x33)),
      );
      final paletteChanged = caps.updateFromEvent(
        const ColorPaletteEvent(4, UvRgb(0xaa, 0xbb, 0xcc)),
      );

      expect(backgroundChanged, isTrue);
      expect(paletteChanged, isTrue);
      expect(caps.backgroundColor, const UvRgb(0x11, 0x22, 0x33));
      expect(caps.hasBackgroundColor, isTrue);
      expect(caps.palette[4], const UvRgb(0xaa, 0xbb, 0xcc));
      expect(caps.hasColorPalette, isTrue);
    });

    test('ignores palette query responses without a color payload', () {
      final caps = TerminalCapabilities(env: const []);

      final changed = caps.updateFromEvent(const ColorPaletteEvent(7, null));

      expect(changed, isFalse);
      expect(caps.palette, isEmpty);
      expect(caps.hasColorPalette, isFalse);
    });
  });
}
