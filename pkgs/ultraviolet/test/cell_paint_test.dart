import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  test('resolves basic16 bright and indexed256 colors', () {
    final policy = UvPaintPolicy();
    expect(
      policy.resolveColor(const UvBasic16(1), const UvRgb(1, 1, 1)),
      const UvRgb(128, 0, 0),
    );
    expect(
      policy.resolveColor(
        const UvBasic16(1, bright: true),
        const UvRgb(1, 1, 1),
      ),
      const UvRgb(255, 0, 0),
    );
    expect(
      policy.resolveColor(const UvIndexed256(196), const UvRgb(1, 1, 1)),
      const UvRgb(255, 0, 0),
    );
  });

  test('reverse, faint, conceal, alpha and underline use one resolution', () {
    final policy = UvPaintPolicy(
      foreground: const UvRgb(200, 100, 0, a: 120),
      background: const UvRgb(20, 40, 60),
      faintMix: 0.5,
    );
    final paint = policy.resolve(
      const UvStyle(
        fg: UvRgb(100, 0, 0),
        bg: UvRgb(0, 100, 0),
        underlineColor: UvBasic16(4),
        attrs: Attr.reverse | Attr.faint | Attr.conceal,
      ),
    );
    expect(paint.background, const UvRgb(100, 0, 0));
    expect(paint.foreground, paint.background);
    expect(paint.underlineColor, const UvRgb(0, 0, 128));
  });

  test('does not retain caller palette mutations', () {
    final palette = List<UvRgb>.filled(16, const UvRgb(1, 2, 3));
    final policy = UvPaintPolicy(palette: palette);
    palette[1] = const UvRgb(9, 9, 9);
    expect(
      policy.resolveColor(const UvBasic16(1), const UvRgb(0, 0, 0)),
      const UvRgb(1, 2, 3),
    );
  });
}
