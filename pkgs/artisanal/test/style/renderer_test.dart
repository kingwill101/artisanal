import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('StringRenderer', () {
    test('captures written text', () {
      final renderer = StringRenderer();

      renderer.write('Hello');
      renderer.write(' World');

      expect(renderer.stringOutput, equals('Hello World'));
    });

    test('writeln adds newline', () {
      final renderer = StringRenderer();

      renderer.writeln('Line 1');
      renderer.writeln('Line 2');

      expect(renderer.stringOutput, equals('Line 1\nLine 2\n'));
    });

    test('writeln without argument adds empty line', () {
      final renderer = StringRenderer();

      renderer.writeln();

      expect(renderer.stringOutput, equals('\n'));
    });

    test('flush returns and clears output', () {
      final renderer = StringRenderer();

      renderer.write('Test');
      final result = renderer.flush();

      expect(result, equals('Test'));
      expect(renderer.stringOutput, isEmpty);
    });

    test('clear removes all output', () {
      final renderer = StringRenderer();

      renderer.write('Test');
      renderer.clear();

      expect(renderer.stringOutput, isEmpty);
    });

    test('isEmpty returns correct value', () {
      final renderer = StringRenderer();

      expect(renderer.isEmpty, isTrue);
      expect(renderer.isNotEmpty, isFalse);

      renderer.write('X');

      expect(renderer.isEmpty, isFalse);
      expect(renderer.isNotEmpty, isTrue);
    });

    test('length returns buffer length', () {
      final renderer = StringRenderer();

      renderer.write('12345');

      expect(renderer.length, equals(5));
    });

    test('default colorProfile is trueColor', () {
      final renderer = StringRenderer();

      expect(renderer.colorProfile, equals(ColorProfile.trueColor));
    });

    test('default hasDarkBackground is true', () {
      final renderer = StringRenderer();

      expect(renderer.hasDarkBackground, isTrue);
    });

    test('colorProfile can be configured', () {
      final renderer = StringRenderer(colorProfile: ColorProfile.ansi256);

      expect(renderer.colorProfile, equals(ColorProfile.ansi256));
    });

    test('colorProfile can be changed via setter', () {
      final renderer = StringRenderer();

      expect(renderer.colorProfile, equals(ColorProfile.trueColor));
      renderer.colorProfile = ColorProfile.ansi;
      expect(renderer.colorProfile, equals(ColorProfile.ansi));
    });

    test('hasDarkBackground can be configured', () {
      final renderer = StringRenderer(hasDarkBackground: false);

      expect(renderer.hasDarkBackground, isFalse);
    });

    test('hasDarkBackground can be changed via setter', () {
      final renderer = StringRenderer();

      expect(renderer.hasDarkBackground, isTrue);
      renderer.hasDarkBackground = false;
      expect(renderer.hasDarkBackground, isFalse);
    });

    test('output getter returns null for StringRenderer', () {
      final renderer = StringRenderer();
      expect(renderer.output, isNull);
    });

    test('toString includes useful info', () {
      final renderer = StringRenderer();
      renderer.write('Hello');

      final str = renderer.toString();

      expect(str, contains('StringRenderer'));
      expect(str, contains('length'));
    });
  });

  group('NullRenderer', () {
    test('write does nothing', () {
      final renderer = NullRenderer();

      // Should not throw
      renderer.write('Test');
      renderer.writeln('Test');
    });

    test('default colorProfile is ascii', () {
      final renderer = NullRenderer();

      expect(renderer.colorProfile, equals(ColorProfile.ascii));
    });

    test('can be configured', () {
      final renderer = NullRenderer(
        colorProfile: ColorProfile.trueColor,
        hasDarkBackground: false,
      );

      expect(renderer.colorProfile, equals(ColorProfile.trueColor));
      expect(renderer.hasDarkBackground, isFalse);
    });

    test('colorProfile can be changed via setter', () {
      final renderer = NullRenderer();

      expect(renderer.colorProfile, equals(ColorProfile.ascii));
      renderer.colorProfile = ColorProfile.trueColor;
      expect(renderer.colorProfile, equals(ColorProfile.trueColor));
    });

    test('hasDarkBackground can be changed via setter', () {
      final renderer = NullRenderer();

      expect(renderer.hasDarkBackground, isTrue);
      renderer.hasDarkBackground = false;
      expect(renderer.hasDarkBackground, isFalse);
    });

    test('output getter returns null', () {
      final renderer = NullRenderer();
      expect(renderer.output, isNull);
    });

    test('toString returns NullRenderer', () {
      expect(NullRenderer().toString(), equals('NullRenderer()'));
    });
  });

  group('TerminalRenderer', () {
    // Note: These tests use mocked/forced values since we can't
    // reliably test actual terminal detection in unit tests

    test('forceProfile overrides detection', () {
      final renderer = TerminalRenderer(forceProfile: ColorProfile.ansi);

      expect(renderer.colorProfile, equals(ColorProfile.ansi));
    });

    test('forceDarkBackground overrides detection', () {
      final renderer = TerminalRenderer(forceDarkBackground: false);

      expect(renderer.hasDarkBackground, isFalse);
    });

    test('colorProfile can be changed via setter', () {
      final renderer = TerminalRenderer(forceProfile: ColorProfile.ansi);

      expect(renderer.colorProfile, equals(ColorProfile.ansi));
      renderer.colorProfile = ColorProfile.trueColor;
      expect(renderer.colorProfile, equals(ColorProfile.trueColor));
    });

    test('hasDarkBackground can be changed via setter', () {
      final renderer = TerminalRenderer(forceDarkBackground: true);

      expect(renderer.hasDarkBackground, isTrue);
      renderer.hasDarkBackground = false;
      expect(renderer.hasDarkBackground, isFalse);
    });

    test('output getter returns IOSink', () {
      final renderer = TerminalRenderer();
      expect(renderer.output, isNotNull);
    });

    test('toString includes useful info', () {
      final renderer = TerminalRenderer(forceProfile: ColorProfile.trueColor);

      final str = renderer.toString();

      expect(str, contains('TerminalRenderer'));
      expect(str, contains('colorProfile'));
    });
  });

  group('defaultRenderer', () {
    tearDown(() {
      // Reset after each test
      resetDefaultRenderer();
    });

    test('returns a renderer', () {
      expect(defaultRenderer, isA<Renderer>());
    });

    test('can be set to custom renderer', () {
      final custom = StringRenderer();
      defaultRenderer = custom;

      expect(defaultRenderer, same(custom));
    });

    test('resetDefaultRenderer resets to terminal renderer', () {
      final custom = StringRenderer();
      defaultRenderer = custom;
      resetDefaultRenderer();

      // After reset, should be a TerminalRenderer
      expect(defaultRenderer, isA<TerminalRenderer>());
    });
  });

  group('ColorProfile', () {
    test('enum values exist', () {
      expect(ColorProfile.values, contains(ColorProfile.ascii));
      expect(ColorProfile.values, contains(ColorProfile.noColor));
      expect(ColorProfile.values, contains(ColorProfile.ansi));
      expect(ColorProfile.values, contains(ColorProfile.ansi256));
      expect(ColorProfile.values, contains(ColorProfile.trueColor));
    });

    test('enum has 5 values', () {
      expect(ColorProfile.values.length, equals(5));
    });
  });

  group('Renderer integration with Style', () {
    test('Style respects renderer colorProfile', () {
      final style = Style().bold().foreground(Colors.red);

      // ASCII profile - no ANSI output
      style.colorProfile = ColorProfile.ascii;
      final asciiResult = style.render('Hello');
      expect(asciiResult, isNot(contains('\x1B[')));

      // noColor profile - no colors but decoration is allowed
      style.colorProfile = ColorProfile.noColor;
      final noColorResult = style.render('Hello');
      expect(noColorResult, contains('\x1B['));

      // TrueColor profile - has colors
      style.colorProfile = ColorProfile.trueColor;
      final colorResult = style.render('Hello');
      expect(colorResult, contains('\x1B['));
    });

    test('Style respects hasDarkBackground for AdaptiveColor', () {
      final lightColor = BasicColor('#000000');
      final darkColor = BasicColor('#ffffff');
      final adaptive = AdaptiveColor(light: lightColor, dark: darkColor);

      final style = Style().foreground(adaptive);
      style.colorProfile = ColorProfile.trueColor;

      // Dark background uses dark variant
      style.hasDarkBackground = true;
      final darkResult = style.render('X');

      // Light background uses light variant
      style.hasDarkBackground = false;
      final lightResult = style.render('X');

      // Both should have ANSI codes but different ones
      expect(darkResult, contains('\x1B['));
      expect(lightResult, contains('\x1B['));
      // They should be different (different color values)
      expect(darkResult, isNot(equals(lightResult)));
    });
  });
}
