import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

void main() {
  group('UV style_ops underline color SGR', () {
    test(
      'styleToSgr emits xterm colon params for underline color (truecolor)',
      () {
        final style = UvStyle(
          underline: UnderlineStyle.curly,
          underlineColor: const UvRgb(205, 0, 0),
        );
        final sgr = styleToSgr(style);
        expect(sgr, contains('\x1b['));
        expect(sgr, contains('4:3'));
        expect(sgr, contains('58:2::205:0:0'));
        expect(sgr, endsWith('m'));
      },
    );

    test('styleDiff emits 59 when underline color is cleared', () {
      final from = UvStyle(
        underline: UnderlineStyle.single,
        underlineColor: const UvIndexed256(196),
      );
      final to = const UvStyle(underline: UnderlineStyle.single);
      final diff = styleDiff(from, to);
      expect(diff, contains('\x1b['));
      expect(diff, contains('59'));
      expect(diff, endsWith('m'));
    });
  });
}
