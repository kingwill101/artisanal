import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Style', () {
    group('fluent chaining', () {
      test('basic chaining works', () {
        final style = Style().bold().italic().underline();

        expect(style.isBold, isTrue);
        expect(style.isItalic, isTrue);
        expect(style.isUnderline, isTrue);
      });

      test('color chaining works', () {
        final style = Style().foreground(Colors.green).background(Colors.black);

        expect(style.getForeground, equals(Colors.green));
        expect(style.getBackground, equals(Colors.black));
      });

      test('dimension chaining works', () {
        final style = Style().width(40).height(10);

        expect(style.getWidth, equals(40));
        expect(style.getHeight, equals(10));
      });

      test('padding chaining works', () {
        final style = Style().padding(1, 2);

        expect(style.getPadding.top, equals(1));
        expect(style.getPadding.bottom, equals(1));
        expect(style.getPadding.left, equals(2));
        expect(style.getPadding.right, equals(2));
      });

      test('margin chaining works', () {
        final style = Style().margin(2);

        expect(style.getMargin.top, equals(2));
        expect(style.getMargin.bottom, equals(2));
        expect(style.getMargin.left, equals(2));
        expect(style.getMargin.right, equals(2));
      });

      test('border chaining works', () {
        final style = Style().border(Border.rounded);

        expect(style.getBorder, equals(Border.rounded));
      });

      test('all methods return Style for chaining', () {
        // This test ensures the fluent API works as expected
        final style = Style()
            .bold()
            .italic()
            .underline()
            .strikethrough()
            .dim()
            .inverse()
            .foreground(Colors.red)
            .background(Colors.white)
            .width(80)
            .height(24)
            .padding(1)
            .margin(2)
            .border(Border.normal)
            .align(HorizontalAlign.center);

        expect(style, isA<Style>());
      });
    });

    group('property tracking', () {
      test('unset properties are not tracked', () {
        final style = Style();

        expect(style.isBold, isFalse);
        expect(style.getForeground, isNull);
        expect(style.getWidth, equals(0));
      });

      test('set properties are tracked', () {
        final style = Style().bold();

        expect(style.isBold, isTrue);
        expect(style.hasTextAttributes, isTrue);
      });

      test('hasTextAttributes returns true when any text attribute is set', () {
        expect(Style().bold().hasTextAttributes, isTrue);
        expect(Style().italic().hasTextAttributes, isTrue);
        expect(Style().underline().hasTextAttributes, isTrue);
        expect(Style().strikethrough().hasTextAttributes, isTrue);
        expect(Style().dim().hasTextAttributes, isTrue);
        expect(Style().inverse().hasTextAttributes, isTrue);
      });

      test('hasColors returns true when colors are set', () {
        expect(Style().foreground(Colors.red).hasColors, isTrue);
        expect(Style().background(Colors.blue).hasColors, isTrue);
        expect(Style().underlineColor(Colors.green).hasColors, isTrue);
        expect(Style().hasColors, isFalse);
      });

      test('Lipgloss v2 parity features', () {
        final style = Style()
            .underlineColor(Colors.red)
            .paddingChar('.')
            .marginChar('#')
            .marginBackground(Colors.blue)
            .underlineSpaces(true)
            .strikethroughSpaces(true);

        expect(style.getUnderlineColor, equals(Colors.red));
        expect(style.getPaddingChar, equals('.'));
        expect(style.getMarginChar, equals('#'));
        expect(style.getMarginBackground, equals(Colors.blue));
        expect(style.getUnderlineSpaces, isTrue);
        expect(style.getStrikethroughSpaces, isTrue);
        expect(style.hasColors, isTrue);

        style
            .unsetUnderlineColor()
            .unsetPaddingChar()
            .unsetMarginChar()
            .unsetMarginBackground()
            .unsetUnderlineSpaces()
            .unsetStrikethroughSpaces();

        expect(style.getUnderlineColor, isNull);
        expect(style.getPaddingChar, equals(' '));
        expect(style.getMarginChar, equals(' '));
        expect(style.getMarginBackground, isNull);
        expect(style.getUnderlineSpaces, isFalse);
        expect(style.getStrikethroughSpaces, isFalse);
      });

      test('render with list of strings', () {
        final style = Style().bold();
        final result = style.render(['a', 'b', 'c']);
        expect(result, contains('a b c'));
        expect(result, contains('\x1b[1m'));
      });

      test('hasSpacing returns true when padding or margin is set', () {
        expect(Style().padding(1).hasSpacing, isTrue);
        expect(Style().margin(1).hasSpacing, isTrue);
        expect(Style().paddingTop(1).hasSpacing, isTrue);
        expect(Style().marginLeft(2).hasSpacing, isTrue);
        expect(Style().hasSpacing, isFalse);
      });
    });

    group('unset methods', () {
      test('unsetBold clears bold', () {
        final style = Style().bold().unsetBold();

        expect(style.isBold, isFalse);
      });

      test('unsetForeground clears foreground', () {
        final style = Style().foreground(Colors.red).unsetForeground();

        expect(style.getForeground, isNull);
      });

      test('unsetWidth clears width', () {
        final style = Style().width(40).unsetWidth();

        expect(style.getWidth, equals(0));
      });

      test('unsetPadding clears all padding', () {
        final style = Style().padding(2).unsetPadding();

        expect(style.getPadding.isZero, isTrue);
      });

      test('unsetMargin clears all margin', () {
        final style = Style().margin(2).unsetMargin();

        expect(style.getMargin.isZero, isTrue);
      });

      test('unsetBorder clears border', () {
        final style = Style().border(Border.rounded).unsetBorder();

        expect(style.getBorder, isNull);
      });
    });

    group('extended Style properties', () {
      test('tabWidth sets and retrieves tab width', () {
        final style = Style().tabWidth(4);
        expect(style.getTabWidth, equals(4));
      });

      test('tabWidth defaults to 4 when not set', () {
        final style = Style();
        expect(style.getTabWidth, equals(4));
      });

      test('underlineSpaces sets and retrieves underline spaces', () {
        final style = Style().underlineSpaces();
        expect(style.isUnderlineSpaces, isTrue);
      });

      test('underlineSpaces with false parameter', () {
        final style = Style().underlineSpaces(false);
        expect(style.isUnderlineSpaces, isFalse);
      });

      test('strikethroughSpaces sets and retrieves strikethrough spaces', () {
        final style = Style().strikethroughSpaces();
        expect(style.isStrikethroughSpaces, isTrue);
      });

      test('strikethroughSpaces with false parameter', () {
        final style = Style().strikethroughSpaces(false);
        expect(style.isStrikethroughSpaces, isFalse);
      });

      test('marginBackground sets and retrieves margin background', () {
        final color = Colors.red;
        final style = Style().marginBackground(color);
        expect(style.getMarginBackground, equals(color));
      });

      test('marginBackground is null when not set', () {
        final style = Style();
        expect(style.getMarginBackground, isNull);
      });

      test('getValue returns set string value', () {
        final style = Style().setString('test');
        expect(style.getValue, equals('test'));
      });

      test('getValue returns null when not set', () {
        final style = Style();
        expect(style.getValue, isNull);
      });

      test('unsetTabWidth clears tab width to default', () {
        final style = Style().tabWidth(8).unsetTabWidth();
        expect(style.getTabWidth, equals(4)); // back to default
      });

      test('unsetUnderlineSpaces clears underline spaces', () {
        final style = Style().underlineSpaces().unsetUnderlineSpaces();
        expect(style.isUnderlineSpaces, isFalse);
      });

      test('unsetStrikethroughSpaces clears strikethrough spaces', () {
        final style = Style().strikethroughSpaces().unsetStrikethroughSpaces();
        expect(style.isStrikethroughSpaces, isFalse);
      });

      test('unsetMarginBackground clears margin background', () {
        final style = Style()
            .marginBackground(Colors.red)
            .unsetMarginBackground();
        expect(style.getMarginBackground, isNull);
      });

      test('extended properties are copied', () {
        final original = Style()
            .tabWidth(8)
            .underlineSpaces()
            .strikethroughSpaces()
            .marginBackground(Colors.blue)
            .setString('hello');

        final copied = original.copy();

        expect(copied.getTabWidth, equals(8));
        expect(copied.isUnderlineSpaces, isTrue);
        expect(copied.isStrikethroughSpaces, isTrue);
        expect(copied.getMarginBackground, equals(Colors.blue));
        expect(copied.getValue, equals('hello'));
      });

      test('extended properties are inherited', () {
        final base = Style();
        final other = Style()
            .tabWidth(4)
            .underlineSpaces()
            .marginBackground(Colors.green);

        base.inherit(other);

        expect(base.getTabWidth, equals(4));
        expect(base.isUnderlineSpaces, isTrue);
        expect(base.getMarginBackground, equals(Colors.green));
      });
    });

    group('copy', () {
      test('copy creates independent instance', () {
        final original = Style().bold().foreground(Colors.green);
        final copied = original.copy();

        // Copied has same values
        expect(copied.isBold, isTrue);
        expect(copied.getForeground, equals(Colors.green));

        // Modifying copied doesn't affect original
        copied.italic().foreground(Colors.red);
        expect(original.isItalic, isFalse);
        expect(original.getForeground, equals(Colors.green));
      });

      test('copy preserves all properties', () {
        final original = Style()
            .bold()
            .italic()
            .foreground(Colors.cyan)
            .background(Colors.black)
            .width(60)
            .padding(2)
            .margin(1)
            .border(Border.thick)
            .align(HorizontalAlign.right);

        final copied = original.copy();

        expect(copied.isBold, equals(original.isBold));
        expect(copied.isItalic, equals(original.isItalic));
        expect(copied.getForeground, equals(original.getForeground));
        expect(copied.getBackground, equals(original.getBackground));
        expect(copied.getWidth, equals(original.getWidth));
        expect(copied.getPadding, equals(original.getPadding));
        expect(copied.getMargin, equals(original.getMargin));
        expect(copied.getBorder, equals(original.getBorder));
        expect(copied.getAlign, equals(original.getAlign));
      });
    });

    group('inherit', () {
      test('inherit copies explicitly set properties', () {
        final base = Style().foreground(Colors.white).padding(1);
        final override = Style().bold().foreground(Colors.cyan);

        base.inherit(override);

        // Bold was set in override, so it's inherited
        expect(base.isBold, isTrue);
        // Foreground was set in override, so it's overwritten
        expect(base.getForeground, equals(Colors.cyan));
        // Padding was not in override, so it stays
        expect(base.getPadding.top, equals(1));
      });

      test('inherit only copies set properties', () {
        final base = Style().bold().foreground(Colors.red);
        final override = Style().italic(); // Only italic is set

        base.inherit(override);

        // Bold stays from base
        expect(base.isBold, isTrue);
        // Italic is inherited
        expect(base.isItalic, isTrue);
        // Foreground stays from base
        expect(base.getForeground, equals(Colors.red));
      });

      test('inherit does not copy unset properties', () {
        final base = Style().foreground(Colors.green);
        final override = Style(); // Nothing set

        base.inherit(override);

        // Foreground stays
        expect(base.getForeground, equals(Colors.green));
      });

      test('inherit returns this for chaining', () {
        final style = Style().inherit(Style().bold());

        expect(style, isA<Style>());
        expect(style.isBold, isTrue);
      });
    });

    group('render', () {
      test('render returns text when no styling', () {
        final style = Style();
        style.colorProfile = ColorProfile.ascii;

        expect(style.render('Hello'), equals('Hello'));
      });

      test('render applies ANSI codes for colors', () {
        final style = Style().foreground(Colors.red);
        style.colorProfile = ColorProfile.trueColor;

        final result = style.render('Hello');

        // Should contain ANSI escape sequences
        expect(result, contains('\x1B['));
        expect(result, contains('Hello'));
      });

      test('render applies text attributes', () {
        final style = Style().bold();
        style.colorProfile = ColorProfile.trueColor;

        final result = style.render('Hello');

        // Should contain ANSI bold sequence
        expect(result, contains('\x1B['));
        expect(result, contains('Hello'));
      });

      test('render applies padding', () {
        final style = Style().padding(1);
        style.colorProfile = ColorProfile.ascii;

        final result = style.render('Hi');

        // Should have empty lines for vertical padding
        expect(result.split('\n').length, greaterThan(1));
      });

      test('render applies width with alignment', () {
        final style = Style().width(10).align(HorizontalAlign.center);
        style.colorProfile = ColorProfile.ascii;

        final result = style.render('Hi');

        // "Hi" centered in 10 chars = "    Hi    "
        expect(Style.visibleLength(result), equals(10));
      });

      test('render applies border', () {
        final style = Style().border(Border.ascii);
        style.colorProfile = ColorProfile.ascii;

        final result = style.render('X');

        expect(result, contains('+'));
        expect(result, contains('-'));
        expect(result, contains('|'));
      });

      test('render applies transform', () {
        final style = Style().transform((s) => s.toUpperCase());
        style.colorProfile = ColorProfile.ascii;

        final result = style.render('hello');

        expect(result, contains('HELLO'));
      });

      test('inline mode skips layout processing', () {
        final style = Style().inline().bold().padding(5).margin(5);
        style.colorProfile = ColorProfile.trueColor;

        final result = style.render('Test');

        // Inline mode should not add padding/margin lines
        expect(result.split('\n').length, equals(1));
      });
    });

    group('visibleLength', () {
      test('returns correct length for plain text', () {
        expect(Style.visibleLength('Hello'), equals(5));
      });

      test('ignores ANSI codes', () {
        const ansiText = '\x1B[1;32mHello\x1B[0m';
        expect(Style.visibleLength(ansiText), equals(5));
      });

      test('handles empty string', () {
        expect(Style.visibleLength(''), equals(0));
      });
    });
  });

  group('Padding', () {
    test('all creates uniform padding', () {
      final p = Padding.all(2);

      expect(p.top, equals(2));
      expect(p.right, equals(2));
      expect(p.bottom, equals(2));
      expect(p.left, equals(2));
    });

    test('symmetric creates vertical/horizontal padding', () {
      final p = Padding.symmetric(vertical: 1, horizontal: 3);

      expect(p.top, equals(1));
      expect(p.bottom, equals(1));
      expect(p.left, equals(3));
      expect(p.right, equals(3));
    });

    test('only creates per-side padding', () {
      final p = Padding.only(top: 1, left: 2);

      expect(p.top, equals(1));
      expect(p.left, equals(2));
      expect(p.bottom, equals(0));
      expect(p.right, equals(0));
    });

    test('isZero returns true for zero padding', () {
      expect(Padding.zero.isZero, isTrue);
      expect(Padding.all(1).isZero, isFalse);
    });

    test('horizontal returns sum of left and right', () {
      expect(Padding(left: 2, right: 3).horizontal, equals(5));
    });

    test('vertical returns sum of top and bottom', () {
      expect(Padding(top: 1, bottom: 4).vertical, equals(5));
    });

    test('equality works', () {
      expect(Padding.all(2), equals(Padding.all(2)));
      expect(Padding.all(1), isNot(equals(Padding.all(2))));
    });
  });

  group('Margin', () {
    test('all creates uniform margin', () {
      final m = Margin.all(3);

      expect(m.top, equals(3));
      expect(m.right, equals(3));
      expect(m.bottom, equals(3));
      expect(m.left, equals(3));
    });

    test('symmetric creates vertical/horizontal margin', () {
      final m = Margin.symmetric(vertical: 2, horizontal: 4);

      expect(m.top, equals(2));
      expect(m.bottom, equals(2));
      expect(m.left, equals(4));
      expect(m.right, equals(4));
    });

    test('isZero returns true for zero margin', () {
      expect(Margin.zero.isZero, isTrue);
      expect(Margin.all(1).isZero, isFalse);
    });
  });

  group('Align', () {
    test('preset alignments exist', () {
      expect(Align.topLeft.horizontal, equals(HorizontalAlign.left));
      expect(Align.topLeft.vertical, equals(VerticalAlign.top));

      expect(Align.center.horizontal, equals(HorizontalAlign.center));
      expect(Align.center.vertical, equals(VerticalAlign.center));

      expect(Align.bottomRight.horizontal, equals(HorizontalAlign.right));
      expect(Align.bottomRight.vertical, equals(VerticalAlign.bottom));
    });

    test('position extension returns correct values', () {
      expect(HorizontalAlign.left.position, equals(0.0));
      expect(HorizontalAlign.center.position, equals(0.5));
      expect(HorizontalAlign.right.position, equals(1.0));

      expect(VerticalAlign.top.position, equals(0.0));
      expect(VerticalAlign.center.position, equals(0.5));
      expect(VerticalAlign.bottom.position, equals(1.0));
    });
  });

  group('Colors', () {
    test('semantic colors exist', () {
      expect(Colors.success, isA<Color>());
      expect(Colors.error, isA<Color>());
      expect(Colors.warning, isA<Color>());
      expect(Colors.info, isA<Color>());
      expect(Colors.muted, isA<Color>());
    });

    test('named colors exist', () {
      expect(Colors.red, isA<Color>());
      expect(Colors.green, isA<Color>());
      expect(Colors.blue, isA<Color>());
      expect(Colors.yellow, isA<Color>());
      expect(Colors.cyan, isA<Color>());
      expect(Colors.magenta, isA<Color>());
      expect(Colors.white, isA<Color>());
      expect(Colors.black, isA<Color>());
    });

    test('factory methods work', () {
      expect(Colors.hex('#ff0000'), isA<BasicColor>());
      expect(Colors.ansi(196), isA<AnsiColor>());
      expect(Colors.rgb(255, 128, 0), isA<BasicColor>());
      expect(
        Colors.adaptive(light: Colors.black, dark: Colors.white),
        isA<AdaptiveColor>(),
      );
    });

    test('none is NoColor', () {
      expect(Colors.none, isA<NoColor>());
    });
  });

  group('Border', () {
    test('preset borders exist', () {
      expect(Border.normal.topLeft, equals('┌'));
      expect(Border.rounded.topLeft, equals('╭'));
      expect(Border.thick.topLeft, equals('┏'));
      expect(Border.double.topLeft, equals('╔'));
      expect(Border.ascii.topLeft, equals('+'));
      expect(Border.hidden.topLeft, equals(' '));
    });

    test('isVisible returns correct value', () {
      expect(Border.normal.isVisible, isTrue);
      expect(Border.none.isVisible, isFalse);
    });

    test('buildTop creates correct string', () {
      expect(Border.ascii.buildTop(5), equals('+-----+'));
    });

    test('buildBottom creates correct string', () {
      expect(Border.ascii.buildBottom(5), equals('+-----+'));
    });

    test('wrapLine wraps content with borders', () {
      expect(Border.ascii.wrapLine('test'), equals('|test|'));
    });

    test('equality works', () {
      expect(Border.rounded, equals(Border.rounded));
      expect(Border.rounded, isNot(equals(Border.normal)));
    });

    test('getTopSize returns width of top border elements', () {
      expect(Border.normal.getTopSize(), equals(1));
      expect(Border.none.getTopSize(), equals(0));
      expect(Border.ascii.getTopSize(), equals(1));
    });

    test('getBottomSize returns width of bottom border elements', () {
      expect(Border.normal.getBottomSize(), equals(1));
      expect(Border.none.getBottomSize(), equals(0));
    });

    test('getLeftSize returns width of left border elements', () {
      expect(Border.normal.getLeftSize(), equals(1));
      expect(Border.none.getLeftSize(), equals(0));
    });

    test('getRightSize returns width of right border elements', () {
      expect(Border.normal.getRightSize(), equals(1));
      expect(Border.none.getRightSize(), equals(0));
    });

    test('size helpers work with block border', () {
      // Block characters are typically single-width
      expect(Border.block.getTopSize(), equals(1));
      expect(Border.block.getLeftSize(), equals(1));
    });
  });

  group('BorderSides', () {
    test('all shows all sides', () {
      expect(BorderSides.all.top, isTrue);
      expect(BorderSides.all.bottom, isTrue);
      expect(BorderSides.all.left, isTrue);
      expect(BorderSides.all.right, isTrue);
    });

    test('none shows no sides', () {
      expect(BorderSides.none.top, isFalse);
      expect(BorderSides.none.bottom, isFalse);
      expect(BorderSides.none.left, isFalse);
      expect(BorderSides.none.right, isFalse);
    });

    test('horizontal shows only top and bottom', () {
      expect(BorderSides.horizontal.top, isTrue);
      expect(BorderSides.horizontal.bottom, isTrue);
      expect(BorderSides.horizontal.left, isFalse);
      expect(BorderSides.horizontal.right, isFalse);
    });

    test('hasAny returns correct value', () {
      expect(BorderSides.all.hasAny, isTrue);
      expect(BorderSides.none.hasAny, isFalse);
      expect(BorderSides.topOnly.hasAny, isTrue);
    });
  });

  group('BasicColor', () {
    test('identifies hex colors', () {
      expect(BasicColor('#ff0000').isHex, isTrue);
      expect(BasicColor('ff0000').isHex, isTrue);
      expect(BasicColor('f00').isHex, isTrue);
      expect(BasicColor('196').isHex, isFalse);
    });

    test('toAnsi returns empty for ascii profile', () {
      final color = BasicColor('#ff0000');
      expect(color.toAnsi(ColorProfile.ascii), isEmpty);
    });

    test('toAnsi returns escape sequence for trueColor', () {
      final color = BasicColor('#ff0000');
      final ansi = color.toAnsi(ColorProfile.trueColor);
      expect(ansi, startsWith('\x1B['));
    });

    test('equality works', () {
      expect(BasicColor('#ff0000'), equals(BasicColor('#ff0000')));
      expect(BasicColor('#ff0000'), isNot(equals(BasicColor('#00ff00'))));
    });
  });

  group('AnsiColor', () {
    test('produces foreground ANSI sequence', () {
      final color = AnsiColor(196);
      final ansi = color.toAnsi(ColorProfile.ansi256);
      expect(ansi, equals('\x1B[38;5;196m'));
    });

    test('produces background ANSI sequence', () {
      final color = AnsiColor(196);
      final ansi = color.toAnsi(ColorProfile.ansi256, background: true);
      expect(ansi, equals('\x1B[48;5;196m'));
    });

    test('returns empty for ascii profile', () {
      final color = AnsiColor(196);
      expect(color.toAnsi(ColorProfile.ascii), isEmpty);
    });
  });

  group('AdaptiveColor', () {
    test('uses dark variant on dark background', () {
      final color = AdaptiveColor(
        light: BasicColor('#000000'),
        dark: BasicColor('#ffffff'),
      );

      final ansi = color.toAnsi(
        ColorProfile.trueColor,
        hasDarkBackground: true,
      );
      // Should use white (dark variant)
      expect(ansi, isNotEmpty);
    });

    test('uses light variant on light background', () {
      final color = AdaptiveColor(
        light: BasicColor('#000000'),
        dark: BasicColor('#ffffff'),
      );

      final ansi = color.toAnsi(
        ColorProfile.trueColor,
        hasDarkBackground: false,
      );
      // Should use black (light variant)
      expect(ansi, isNotEmpty);
    });
  });

  group('CompleteColor', () {
    test('uses trueColor for trueColor profile', () {
      final color = CompleteColor(
        trueColor: '#ff0000',
        ansi256: '196',
        ansi: '1',
      );

      final ansi = color.toAnsi(ColorProfile.trueColor);
      expect(ansi, isNotEmpty);
    });

    test('uses ansi256 for ansi256 profile', () {
      final color = CompleteColor(
        trueColor: '#ff0000',
        ansi256: '196',
        ansi: '1',
      );

      final ansi = color.toAnsi(ColorProfile.ansi256);
      expect(ansi, contains('196'));
    });

    test('uses ansi for ansi profile', () {
      final color = CompleteColor(
        trueColor: '#ff0000',
        ansi256: '196',
        ansi: '1',
      );

      final ansi = color.toAnsi(ColorProfile.ansi);
      expect(ansi, contains('31')); // 30 + 1 = 31 (red)
    });
  });

  group('CompleteAdaptiveColor', () {
    test('uses dark variant on dark backgrounds', () {
      final color = CompleteAdaptiveColor(
        light: CompleteColor(trueColor: '#000000', ansi256: '0', ansi: '0'),
        dark: CompleteColor(trueColor: '#ffffff', ansi256: '255', ansi: '7'),
      );

      final ansi = color.toAnsi(ColorProfile.ansi256, hasDarkBackground: true);
      expect(ansi, contains('255')); // Dark variant
    });

    test('uses light variant on light backgrounds', () {
      final color = CompleteAdaptiveColor(
        light: CompleteColor(trueColor: '#000000', ansi256: '0', ansi: '0'),
        dark: CompleteColor(trueColor: '#ffffff', ansi256: '255', ansi: '7'),
      );

      final ansi = color.toAnsi(ColorProfile.ansi256, hasDarkBackground: false);
      expect(ansi, contains(';5;0')); // Light variant
    });

    test('respects color profile', () {
      final color = CompleteAdaptiveColor(
        light: CompleteColor(trueColor: '#ff0000', ansi256: '196', ansi: '1'),
        dark: CompleteColor(trueColor: '#00ff00', ansi256: '46', ansi: '2'),
      );

      // ANSI profile on dark bg
      final ansi = color.toAnsi(ColorProfile.ansi, hasDarkBackground: true);
      expect(ansi, contains('32')); // 30 + 2 = green in ANSI
    });

    test('equality works', () {
      final c1 = CompleteAdaptiveColor(
        light: CompleteColor(trueColor: '#000'),
        dark: CompleteColor(trueColor: '#fff'),
      );
      final c2 = CompleteAdaptiveColor(
        light: CompleteColor(trueColor: '#000'),
        dark: CompleteColor(trueColor: '#fff'),
      );
      expect(c1, equals(c2));
    });

    test('toString works', () {
      final color = CompleteAdaptiveColor(
        light: CompleteColor(trueColor: '#000'),
        dark: CompleteColor(trueColor: '#fff'),
      );
      expect(color.toString(), contains('CompleteAdaptiveColor'));
    });
  });

  group('NoColor', () {
    test('toAnsi returns empty string', () {
      expect(NoColor().toAnsi(ColorProfile.trueColor), isEmpty);
    });

    test('equality works', () {
      expect(NoColor(), equals(NoColor()));
    });
  });

  group('align with optional vertical', () {
    test('align with horizontal only', () {
      final style = Style().align(HorizontalAlign.center);
      expect(style.getAlign, equals(HorizontalAlign.center));
    });

    test('align with horizontal and vertical', () {
      final style = Style().align(HorizontalAlign.center, VerticalAlign.center);
      expect(style.getAlign, equals(HorizontalAlign.center));
      expect(style.getAlignVertical, equals(VerticalAlign.center));
    });

    test('align sets both flags when vertical provided', () {
      final style = Style().align(HorizontalAlign.right, VerticalAlign.bottom);
      // Both should be tracked as set
      expect(style.getAlign, equals(HorizontalAlign.right));
      expect(style.getAlignVertical, equals(VerticalAlign.bottom));
    });

    test('align only sets horizontal flag when vertical not provided', () {
      final base = Style().alignVertical(VerticalAlign.top);
      final style = base.align(HorizontalAlign.center);
      // Horizontal should change, vertical should remain
      expect(style.getAlign, equals(HorizontalAlign.center));
      expect(style.getAlignVertical, equals(VerticalAlign.top));
    });
  });

  group('border with optional sides', () {
    test('border with style only', () {
      final style = Style().border(Border.rounded);
      expect(style.getBorder, equals(Border.rounded));
    });

    test('border with specific sides', () {
      final style = Style().border(Border.rounded, top: true, bottom: true);
      expect(style.getBorder, equals(Border.rounded));
      expect(style.getBorderSides.top, isTrue);
      expect(style.getBorderSides.right, isFalse);
      expect(style.getBorderSides.bottom, isTrue);
      expect(style.getBorderSides.left, isFalse);
    });

    test('border with all sides specified', () {
      final style = Style().border(
        Border.double,
        top: true,
        right: true,
        bottom: false,
        left: false,
      );
      expect(style.getBorder, equals(Border.double));
      expect(style.getBorderSides.top, isTrue);
      expect(style.getBorderSides.right, isTrue);
      expect(style.getBorderSides.bottom, isFalse);
      expect(style.getBorderSides.left, isFalse);
    });

    test('borderStyle only sets border without affecting sides', () {
      final style = Style()
          .borderSides(BorderSides(top: true, bottom: true))
          .borderStyle(Border.thick);
      expect(style.getBorder, equals(Border.thick));
      expect(style.getBorderSides.top, isTrue);
      expect(style.getBorderSides.bottom, isTrue);
    });

    test('border without sides does not reset existing sides', () {
      final style = Style()
          .borderSides(
            BorderSides(top: true, right: true, bottom: true, left: true),
          )
          .border(Border.rounded);
      // Should keep the existing sides
      expect(style.getBorderSides.top, isTrue);
      expect(style.getBorderSides.right, isTrue);
    });
  });
}
