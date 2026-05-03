import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  group('terminal graphics helpers', () {
    const image1 = '\x1b_Ga=T,f=100,i=1,c=3,r=2,C=1,q=2,m=0;AAAA\x1b\\';
    const image2 = '\x1b_Ga=T,f=100,i=2,c=4,r=1,C=1,q=2,m=0;BBBB\x1b\\';

    test('scans retained image ids from a frame', () {
      final frame = TerminalGraphicsFrame.scan('$image1\n$image2');

      expect(frame.hasRetainedGraphics, isTrue);
      expect(frame.retainedImageIds, equals(<int>{1, 2}));
    });

    test('deletes only stale retained image ids when ids are trackable', () {
      final previous = TerminalGraphicsFrame.scan('$image1\n$image2');
      final current = TerminalGraphicsFrame.scan(image2);

      expect(
        current.deletionSequencesSince(previous).toList(),
        equals(<String>['\x1b_Ga=d,d=I,i=1,q=2\x1b\\']),
      );
    });

    test('suppresses graphics that would overflow a text viewport', () {
      const tallImage = '\x1b_Ga=T,f=100,i=9,c=3,r=4,C=1,q=2,m=0;CCCC\x1b\\';

      final clipped = suppressOverflowingTerminalGraphics(
        'header\n${tallImage}tail',
        3,
      );

      expect(clipped, isNot(contains('\x1b_Ga=T')));
      expect(clipped, contains('   tail'));
    });

    test('keeps graphics that fit in a text viewport', () {
      final clipped = suppressOverflowingTerminalGraphics(
        'header\n$image1 tail',
        3,
      );

      expect(clipped, contains(image1));
    });

    test('prefilters terminal graphics payloads', () {
      const sixel = '\x1bPq#0;2;0;0;0!1~\x1b\\';
      const c1Kitty = '\x9fGa=T,c=2;AAAA\x9c';
      const c1Sixel = '\x90q#0;2;0;0;0!1~\x9c';

      expect(mayContainTerminalGraphics('plain text'), isFalse);
      expect(mayContainTerminalGraphics('\x1b[31mred\x1b[0m'), isFalse);
      expect(mayContainTerminalGraphics(image1), isTrue);
      expect(mayContainTerminalGraphics(sixel), isTrue);
      expect(mayContainTerminalGraphics(c1Kitty), isTrue);
      expect(mayContainTerminalGraphics(c1Sixel), isTrue);
    });
  });
}
