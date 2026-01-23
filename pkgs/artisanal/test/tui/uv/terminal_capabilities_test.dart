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
  });
}
