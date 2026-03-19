import 'package:artisanal/src/uv/uv.dart';
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

    test('tracks primary device attribute changes even without sixel changes', () {
      final caps = TerminalCapabilities(env: const []);

      expect(
        caps.updateFromEvent(const PrimaryDeviceAttributesEvent([1, 2])),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const PrimaryDeviceAttributesEvent([1, 2])),
        isFalse,
      );
      expect(
        caps.updateFromEvent(const PrimaryDeviceAttributesEvent([1, 18])),
        isTrue,
      );
      expect(caps.primaryAttributes, [1, 18]);
      expect(caps.hasSixel, isFalse);
    });

    test('stores foreground, background, cursor, and palette reports', () {
      final caps = TerminalCapabilities(env: const []);

      expect(
        caps.updateFromEvent(const ForegroundColorEvent(UvRgb(0x44, 0x55, 0x66))),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const BackgroundColorEvent(UvRgb(0x11, 0x22, 0x33))),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const CursorColorEvent(UvRgb(0x77, 0x88, 0x99))),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const ColorPaletteEvent(4, UvRgb(0xaa, 0xbb, 0xcc))),
        isTrue,
      );

      expect(caps.foregroundColor, const UvRgb(0x44, 0x55, 0x66));
      expect(caps.backgroundColor, const UvRgb(0x11, 0x22, 0x33));
      expect(caps.cursorColor, const UvRgb(0x77, 0x88, 0x99));
      expect(caps.palette[4], const UvRgb(0xaa, 0xbb, 0xcc));
    });

    test('tracks keyboard enhancement flags and ignores repeated reports', () {
      final caps = TerminalCapabilities(env: const []);

      expect(
        caps.updateFromEvent(
          const KeyboardEnhancementsEvent(
            KeyboardEnhancementsEvent.disambiguateEscapeCodes |
                KeyboardEnhancementsEvent.reportEventTypes,
          ),
        ),
        isTrue,
      );
      expect(
        caps.keyboardEnhancementFlags,
        KeyboardEnhancementsEvent.disambiguateEscapeCodes |
            KeyboardEnhancementsEvent.reportEventTypes,
      );
      expect(
        caps.updateFromEvent(
          const KeyboardEnhancementsEvent(
            KeyboardEnhancementsEvent.disambiguateEscapeCodes |
                KeyboardEnhancementsEvent.reportEventTypes,
          ),
        ),
        isFalse,
      );
    });

    test('keyboard enhancement flags can clear back to zero', () {
      final caps = TerminalCapabilities(env: const []);

      expect(
        caps.updateFromEvent(
          const KeyboardEnhancementsEvent(
            KeyboardEnhancementsEvent.disambiguateEscapeCodes,
          ),
        ),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const KeyboardEnhancementsEvent(0)),
        isTrue,
      );
      expect(caps.hasKeyboardEnhancements, isFalse);
      expect(caps.keyboardEnhancementFlags, 0);
    });
  });
}
