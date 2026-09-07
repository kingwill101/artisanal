// Regression tests: the ANSI cell slicer must treat device-control
// strings (Kitty APC, Sixel DCS) as atomic payloads, never splitting
// base64/sixel data at cut boundaries. Widths mirror Ansi.visibleLength
// (Kitty transmit/put occupies c= columns, Sixel occupies one).

import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  group('cutAnsiByCells: device-control passthrough', () {
    test('Kitty payload survives cuts intact', () {
      const apc = '\x1b_Ga=T,q=2,f=32,c=10,r=4;QUJDRA==\x1b\\';
      // Fully containing cut keeps the whole escape.
      final kept = cutAnsiByCells('ab${apc}cd', 0, 12);
      expect(kept, contains('QUJDRA=='));
      expect(kept, contains('\x1b_G'));
      expect(kept, contains('ab'));
      // Cuts ending mid-image exclude it whole: no corrupt fragments.
      expect(cutAnsiByCells('ab${apc}cd', 0, 5), 'ab');
      // Cut past the image drops it whole (no fragments leak as text).
      final tail = cutAnsiByCells('ab${apc}cd', 12, 20);
      expect(tail, isNot(contains('QUJD')));
      expect(tail, contains('cd'));
    });

    test('multi-chunk Kitty payload survives a width cut intact', () {
      const first =
          '\x1b_Ga=T,q=2,f=100,c=10,r=4,m=1;QUJDRA==\x1b\\';
      const continuation = '\x1b_Gm=0;RUZHSA==\x1b\\';

      final kept = cutAnsiByCells('$first$continuation', 0, 10);

      expect(kept, first + continuation);
    });

    test('Kitty control-only actions are zero-width but intact', () {
      const del = '\x1b_Ga=d,d=I,i=42,q=2\x1b\\';
      expect(cutAnsiByCells('ab${del}cd', 0, 4), contains('ab'));
      expect(cutAnsiByCells('ab${del}cd', 0, 4), contains('d=I'));
    });

    test('Sixel payload survives cuts intact', () {
      const sixel = '\x1bPq"1;1;100;100#0;2;0;0;0#1;2;100;100;0_\x1b\\';
      expect(cutAnsiByCells('ab${sixel}cd', 0, 4), contains('#0;2'));
    });

    test('BEL-terminated APC is one atomic token', () {
      const apc = '\x1b_Ga=T,c=4;QUJD\x07after';
      // Cut ending inside the width-4 image excludes it whole.
      expect(cutAnsiByCells(apc, 0, 2), isEmpty);
      // Fully containing cut keeps it whole.
      expect(cutAnsiByCells(apc, 0, 4), contains('QUJD'));
      // Past the image: payload gone whole, text remains.
      final tail = cutAnsiByCells(apc, 4, 20);
      expect(tail, isNot(contains('QUJD')));
      expect(tail, contains('after'));
    });

    test('truncateLeft preserves trailing payloads', () {
      const apc = '\x1b_Ga=T,q=2,c=3;QUJD\x1b\\';
      expect(truncateLeftAnsiByCells('ab$apc', 0), contains('QUJD'));
    });
  });
}
