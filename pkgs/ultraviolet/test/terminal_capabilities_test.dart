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

    test('tracks primary device attribute changes even without sixel changes', () {
      final caps = TerminalCapabilities(env: const []);

      expect(
        caps.updateFromEvent(const PrimaryDeviceAttributesEvent([1, 2])),
        isTrue,
      );
      expect(caps.primaryAttributes, [1, 2]);
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

    test('tracks secondary device attribute changes', () {
      final caps = TerminalCapabilities(env: const []);

      expect(
        caps.updateFromEvent(const SecondaryDeviceAttributesEvent([1, 2, 3])),
        isTrue,
      );
      expect(caps.secondaryAttributes, [1, 2, 3]);
      expect(
        caps.updateFromEvent(const SecondaryDeviceAttributesEvent([1, 2, 3])),
        isFalse,
      );
      expect(
        caps.updateFromEvent(const SecondaryDeviceAttributesEvent([1, 4, 5])),
        isTrue,
      );
      expect(caps.secondaryAttributes, [1, 4, 5]);
    });

    test('tracks tertiary device attributes and terminal version', () {
      final caps = TerminalCapabilities(env: const []);

      expect(
        caps.updateFromEvent(const TertiaryDeviceAttributesEvent('Chrm')),
        isTrue,
      );
      expect(caps.tertiaryAttributes, 'Chrm');
      expect(
        caps.updateFromEvent(const TertiaryDeviceAttributesEvent('Chrm')),
        isFalse,
      );
      expect(
        caps.updateFromEvent(const TerminalVersionEvent('Ghostty 1.2.3')),
        isTrue,
      );
      expect(caps.terminalVersion, 'Ghostty 1.2.3');
      expect(
        caps.updateFromEvent(const TerminalVersionEvent('Ghostty 1.2.3')),
        isFalse,
      );
    });

    test('stores foreground, background, cursor, and palette reports', () {
      final caps = TerminalCapabilities(env: const []);

      final foregroundChanged = caps.updateFromEvent(
        const ForegroundColorEvent(UvRgb(0x44, 0x55, 0x66)),
      );
      final backgroundChanged = caps.updateFromEvent(
        const BackgroundColorEvent(UvRgb(0x11, 0x22, 0x33)),
      );
      final cursorChanged = caps.updateFromEvent(
        const CursorColorEvent(UvRgb(0x77, 0x88, 0x99)),
      );
      final paletteChanged = caps.updateFromEvent(
        const ColorPaletteEvent(4, UvRgb(0xaa, 0xbb, 0xcc)),
      );

      expect(foregroundChanged, isTrue);
      expect(backgroundChanged, isTrue);
      expect(cursorChanged, isTrue);
      expect(paletteChanged, isTrue);
      expect(caps.foregroundColor, const UvRgb(0x44, 0x55, 0x66));
      expect(caps.hasForegroundColor, isTrue);
      expect(caps.backgroundColor, const UvRgb(0x11, 0x22, 0x33));
      expect(caps.hasBackgroundColor, isTrue);
      expect(caps.cursorColor, const UvRgb(0x77, 0x88, 0x99));
      expect(caps.hasCursorColor, isTrue);
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

    test('tracks keyboard enhancement flags', () {
      final caps = TerminalCapabilities(env: const []);

      final changed = caps.updateFromEvent(
        const KeyboardEnhancementsEvent(
          KeyboardEnhancementsEvent.disambiguateEscapeCodes |
              KeyboardEnhancementsEvent.reportEventTypes,
        ),
      );

      expect(changed, isTrue);
      expect(caps.hasKeyboardEnhancements, isTrue);
      expect(
        caps.keyboardEnhancementFlags,
        KeyboardEnhancementsEvent.disambiguateEscapeCodes |
            KeyboardEnhancementsEvent.reportEventTypes,
      );
    });

    test('tracks modifyOtherKeys mode and color scheme reports', () {
      final caps = TerminalCapabilities(env: const []);

      expect(caps.updateFromEvent(const ModifyOtherKeysEvent(2)), isTrue);
      expect(caps.modifyOtherKeysMode, 2);
      expect(caps.updateFromEvent(const ModifyOtherKeysEvent(2)), isFalse);

      expect(caps.updateFromEvent(const DarkColorSchemeEvent()), isTrue);
      expect(caps.darkColorScheme, isTrue);
      expect(caps.updateFromEvent(const DarkColorSchemeEvent()), isFalse);

      expect(caps.updateFromEvent(const LightColorSchemeEvent()), isTrue);
      expect(caps.darkColorScheme, isFalse);
      expect(caps.updateFromEvent(const LightColorSchemeEvent()), isFalse);
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

    test('repeated identical reports are idempotent', () {
      final caps = TerminalCapabilities(env: const []);

      expect(
        caps.updateFromEvent(const BackgroundColorEvent(UvRgb(0x11, 0x22, 0x33))),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const BackgroundColorEvent(UvRgb(0x11, 0x22, 0x33))),
        isFalse,
      );

      expect(
        caps.updateFromEvent(const ColorPaletteEvent(4, UvRgb(0xaa, 0xbb, 0xcc))),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const ColorPaletteEvent(4, UvRgb(0xaa, 0xbb, 0xcc))),
        isFalse,
      );

      expect(
        caps.updateFromEvent(
          const KeyboardEnhancementsEvent(
            KeyboardEnhancementsEvent.disambiguateEscapeCodes,
          ),
        ),
        isTrue,
      );
      expect(
        caps.updateFromEvent(
          const KeyboardEnhancementsEvent(
            KeyboardEnhancementsEvent.disambiguateEscapeCodes,
          ),
        ),
        isFalse,
      );

      expect(
        caps.updateFromEvent(const ModifyOtherKeysEvent(2)),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const ModifyOtherKeysEvent(2)),
        isFalse,
      );

      expect(caps.updateFromEvent(const DarkColorSchemeEvent()), isTrue);
      expect(caps.updateFromEvent(const DarkColorSchemeEvent()), isFalse);

      expect(
        caps.updateFromEvent(const SecondaryDeviceAttributesEvent([1, 2, 3])),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const SecondaryDeviceAttributesEvent([1, 2, 3])),
        isFalse,
      );

      expect(
        caps.updateFromEvent(const TertiaryDeviceAttributesEvent('Chrm')),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const TertiaryDeviceAttributesEvent('Chrm')),
        isFalse,
      );

      expect(
        caps.updateFromEvent(const TerminalVersionEvent('Ultraviolet')),
        isTrue,
      );
      expect(
        caps.updateFromEvent(const TerminalVersionEvent('Ultraviolet')),
        isFalse,
      );

      expect(caps.updateFromEvent(const LightColorSchemeEvent()), isTrue);
      expect(caps.updateFromEvent(const LightColorSchemeEvent()), isFalse);
    });
  });
}
