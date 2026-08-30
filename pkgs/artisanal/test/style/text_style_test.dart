import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('TextStyle', () {
    test('has value equality', () {
      const first = TextStyle(
        color: Colors.purple,
        backgroundColor: Colors.black,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.normal,
        decoration: TextDecoration.underline,
        decorationColor: Colors.cyan,
        decorationStyle: TextDecorationStyle.wavy,
        reverse: false,
        blink: true,
      );
      const second = TextStyle(
        color: Colors.purple,
        backgroundColor: Colors.black,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.normal,
        decoration: TextDecoration.underline,
        decorationColor: Colors.cyan,
        decorationStyle: TextDecorationStyle.wavy,
        reverse: false,
        blink: true,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(const TextStyle(fontWeight: FontWeight.normal)));
    });

    test('copyWith replaces supplied properties', () {
      const base = TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      );

      final copied = base.copyWith(
        color: Colors.blue,
        fontWeight: FontWeight.normal,
      );

      expect(
        copied,
        const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.italic,
        ),
      );
      expect(
        base,
        const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      );
    });

    test('merge lets non-null child declarations win', () {
      const parent = TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        reverse: true,
      );
      const child = TextStyle(color: Colors.blue, fontWeight: FontWeight.dim);

      expect(
        parent.merge(child),
        const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.dim,
          fontStyle: FontStyle.italic,
          reverse: true,
        ),
      );
      expect(parent.merge(null), same(parent));
    });

    test('merge stops inheritance when requested by the child', () {
      const parent = TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
      const child = TextStyle(inherit: false, fontStyle: FontStyle.italic);

      expect(parent.merge(child), same(child));
    });

    test('applyTo overrides text declarations and preserves block styling', () {
      final target = Style()
        ..padding(1, 2)
        ..foreground(Colors.red)
        ..bold()
        ..italic();

      const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.normal,
      ).applyTo(target);

      expect(target.getForeground, Colors.blue);
      expect(target.isBold, isFalse);
      expect(target.isItalic, isTrue);
      expect(
        target.data.padding,
        const Padding.symmetric(vertical: 1, horizontal: 2),
      );
    });

    test('font weights select exactly one terminal intensity', () {
      final boldTarget = Style()..dim();
      const TextStyle(fontWeight: FontWeight.bold).applyTo(boldTarget);
      expect(boldTarget.isBold, isTrue);
      expect(boldTarget.isDim, isFalse);

      final dimTarget = Style()..bold();
      const TextStyle(fontWeight: FontWeight.dim).applyTo(dimTarget);
      expect(dimTarget.isBold, isFalse);
      expect(dimTarget.isDim, isTrue);

      const TextStyle(fontWeight: FontWeight.normal).applyTo(dimTarget);
      expect(dimTarget.isBold, isFalse);
      expect(dimTarget.isDim, isFalse);
    });

    test('inherit false resets inherited text but not block styling', () {
      final target = Style()
        ..padding(1)
        ..foreground(Colors.red)
        ..background(Colors.blue)
        ..underlineColor(Colors.cyan)
        ..bold()
        ..italic()
        ..underlineStyle(UnderlineStyle.curly)
        ..strikethrough()
        ..dim()
        ..inverse()
        ..blink();

      const TextStyle(
        inherit: false,
        fontWeight: FontWeight.bold,
      ).applyTo(target);

      expect(target.getForeground, const DefaultColor());
      expect(target.getBackground, const DefaultColor());
      expect(target.getUnderlineColor, const DefaultColor());
      expect(target.getUnderlineStyle, UnderlineStyle.single);
      expect(target.isBold, isTrue);
      expect(target.isItalic, isFalse);
      expect(target.isUnderline, isFalse);
      expect(target.isStrikethrough, isFalse);
      expect(target.isDim, isFalse);
      expect(target.isInverse, isFalse);
      expect(target.isBlink, isFalse);
      expect(target.data.padding, const Padding.all(1));
    });

    test('toStyle materializes terminal text attributes', () {
      final style = const TextStyle(
        color: Colors.green,
        fontStyle: FontStyle.italic,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.double,
        reverse: true,
      ).toStyle();

      expect(style.getForeground, Colors.green);
      expect(style.getUnderlineStyle, UnderlineStyle.double);
      expect(style.isUnderline, isTrue);
      expect(style.getUnderlineSpaces, isTrue);
      expect(style.isItalic, isTrue);
      expect(style.isInverse, isTrue);
    });

    test('decorations remain continuous across interior spaces', () {
      final underline = const TextStyle(
        decoration: TextDecoration.underline,
      ).toStyle();
      final lineThrough = const TextStyle(
        decoration: TextDecoration.lineThrough,
      ).toStyle();

      expect(underline.getUnderlineSpaces, isTrue);
      expect(lineThrough.getStrikethroughSpaces, isTrue);
      expect(underline.render('two words'), contains('\x1b[4m \x1b[24m'));
      expect(lineThrough.render('two words'), contains('\x1b[9m \x1b[m'));
    });

    test('combined decorations materialize as one declaration', () {
      final decoration = TextDecoration.combine(const [
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);

      expect(decoration.contains(TextDecoration.underline), isTrue);
      expect(decoration.contains(TextDecoration.lineThrough), isTrue);

      final style = TextStyle(decoration: decoration).toStyle();
      expect(style.isUnderline, isTrue);
      expect(style.isStrikethrough, isTrue);
      expect(style.getUnderlineSpaces, isTrue);
      expect(style.getStrikethroughSpaces, isTrue);
    });

    test('decoration none overrides an accompanying decoration style', () {
      final style = const TextStyle(
        decoration: TextDecoration.none,
        decorationStyle: TextDecorationStyle.wavy,
      ).toStyle();

      expect(style.isUnderline, isFalse);
      expect(style.isStrikethrough, isFalse);
      expect(style.getUnderlineSpaces, isFalse);
      expect(style.getStrikethroughSpaces, isFalse);
    });

    test('decoration style alone does not enable underline', () {
      final style = const TextStyle(
        decorationStyle: TextDecorationStyle.double,
      ).toStyle();

      expect(style.isUnderline, isFalse);
    });

    test('decoration style updates an inherited underline', () {
      final style = Style().underline();

      const TextStyle(
        decorationStyle: TextDecorationStyle.double,
      ).applyTo(style);

      expect(style.isUnderline, isTrue);
      expect(style.getUnderlineStyle, UnderlineStyle.double);
    });
  });
}
