// Regression tests for Kitty APC width accounting in visible-length helpers.
//
// The Kitty Graphics Protocol encodes images as APC sequences:
//   ESC _ G <params> ; <data> ESC \
//
// The `c=N` parameter specifies how many terminal columns the image occupies.
// `Ansi.stripAnsi` should still remove control sequences entirely, but
// `Ansi.visibleLength` must account for Kitty display width so higher-level
// layout code measures image blocks correctly.

import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  group('Ansi.visibleLength: Kitty APC width', () {
    test('stripAnsi removes Kitty APC payloads completely', () {
      const apc = '\x1b_Ga=T,q=2,f=32,c=10,r=4;AAAA\x1b\\';
      expect(Ansi.stripAnsi(apc), isEmpty);
    });

    test('Ansi.visibleLength of Kitty APC equals c= param', () {
      const apc = '\x1b_Ga=T,q=2,f=32,c=10,r=4;AAAA\x1b\\';
      expect(Ansi.visibleLength(apc), equals(10));
    });

    test('Kitty APC with c=1 reports width 1', () {
      const apc = '\x1b_Ga=T,q=2,c=1,r=1;DATA\x1b\\';
      expect(Ansi.visibleLength(apc), equals(1));
    });

    test('Kitty APC without c= param reports width 0', () {
      const apc = '\x1b_Ga=d,d=I,i=42,q=2\x1b\\'; // delete sequence
      expect(Ansi.visibleLength(apc), equals(0));
    });

    test('multi-chunk Kitty APC total width equals c= from first chunk', () {
      // Multi-chunk: first chunk carries c=10, subsequent chunks don't
      const chunk1 = '\x1b_Ga=T,q=2,f=32,c=10,r=4,m=1;DATA1\x1b\\';
      const chunk2 = '\x1b_Gm=0;DATA2\x1b\\';
      final apc = chunk1 + chunk2;
      expect(
        Ansi.visibleLength(apc),
        equals(10),
        reason: 'Multi-chunk Kitty APC width comes from first chunk c= param',
      );
    });

    test('text adjacent to Kitty APC has correct visibleLength', () {
      const apc = '\x1b_Ga=T,q=2,c=10,r=1;DATA\x1b\\';
      const line = '${apc}HELLO';
      // APC occupies 10 cells, "HELLO" occupies 5, total = 15
      expect(Ansi.visibleLength(line), equals(15));
    });

    test('non-Kitty APC is still stripped to empty', () {
      // An APC that doesn't start with 'G' is not Kitty graphics
      const apc = '\x1b_Xsome other protocol\x1b\\';
      expect(Ansi.visibleLength(apc), equals(0));
    });

    test('regular ANSI CSI still stripped normally', () {
      const csi = '\x1b[31mHELLO\x1b[0m';
      expect(Ansi.visibleLength(csi), equals(5));
    });
  });
}
