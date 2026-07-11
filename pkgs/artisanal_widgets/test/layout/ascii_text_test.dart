import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('AsciiText', () {
    test('renders single character', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: 'A', font: AsciiFont.slim));
      // Slim 'A' is 5 chars wide, should appear in output
      expect(tester.view, contains('▄▀▄'));
    });

    test('renders a word', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: 'HI', font: AsciiFont.slim));
      // Both 'H' and 'I' glyphs should appear
      final view = tester.view;
      expect(view, contains('█▀▀█'));
      expect(view, contains('▀█▀'));
    });

    test('renders empty string', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: ''));
      expect(tester.view.trim(), isEmpty);
    });
  });

  group('StyledAsciiText', () {
    test('renders same content as AsciiText when style is null', () async {
      final tester1 = WidgetTester();
      final tester2 = WidgetTester();
      addTearDown(() => tester1.dispose());
      addTearDown(() => tester2.dispose());

      await tester1.pumpWidget(AsciiText(data: 'OK', font: AsciiFont.slim));
      await tester2.pumpWidget(
        StyledAsciiText(data: 'OK', font: AsciiFont.slim),
      );

      // Without style, StyledAsciiText delegates to AsciiText — same output
      expect(tester2.view, equals(tester1.view));
    });

    test('styled output preserves spacing (softWrap bug)', () async {
      // This is the regression test for the bug where StyledAsciiText
      // passed softWrap:true to Text, causing Layout.wrap() to collapse
      // consecutive spaces in the ASCII art glyphs.
      final testerPlain = WidgetTester();
      final testerStyled = WidgetTester();
      addTearDown(() => testerPlain.dispose());
      addTearDown(() => testerStyled.dispose());

      await testerPlain.pumpWidget(AsciiText(data: 'HI', font: AsciiFont.slim));
      await testerStyled.pumpWidget(
        StyledAsciiText(
          data: 'HI',
          font: AsciiFont.slim,
          style: Style()..foreground(Colors.cyan),
        ),
      );

      // Get visible (ANSI-stripped) lines for each
      final plainLines = testerPlain.viewLines.map(Layout.stripAnsi).toList();
      final styledLines = testerStyled.viewLines.map(Layout.stripAnsi).toList();

      // Both should produce the same number of lines
      expect(styledLines.length, equals(plainLines.length));

      // The visible content (stripping ANSI) should be identical
      // If softWrap was collapsing spaces, the styled lines would be narrower
      for (var i = 0; i < plainLines.length; i++) {
        expect(
          styledLines[i],
          equals(plainLines[i]),
          reason:
              'Line $i differs: styled="${styledLines[i]}" '
              'vs plain="${plainLines[i]}"',
        );
      }
    });

    test('styled output has same dimensions as plain', () async {
      final testerPlain = WidgetTester();
      final testerStyled = WidgetTester();
      addTearDown(() => testerPlain.dispose());
      addTearDown(() => testerStyled.dispose());

      await testerPlain.pumpWidget(
        AsciiText(data: 'OK', font: AsciiFont.standard),
      );
      await testerStyled.pumpWidget(
        StyledAsciiText(
          data: 'OK',
          font: AsciiFont.standard,
          style: Style()..foreground(Colors.green),
        ),
      );

      final plainLines = testerPlain.viewLines.map(Layout.stripAnsi).toList();
      final styledLines = testerStyled.viewLines.map(Layout.stripAnsi).toList();

      expect(styledLines.length, equals(plainLines.length));

      // Each line should have the same visible width
      for (var i = 0; i < plainLines.length; i++) {
        final plainWidth = Layout.visibleLength(plainLines[i]);
        final styledWidth = Layout.visibleLength(styledLines[i]);
        expect(
          styledWidth,
          equals(plainWidth),
          reason:
              'Line $i width differs: styled=$styledWidth '
              'vs plain=$plainWidth',
        );
      }
    });

    test('styled output preserves multi-space runs', () async {
      // ASCII art glyphs often contain runs of multiple spaces.
      // The softWrap bug would collapse "█   █" into "█ █".
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // Slim 'H' has line "█  █" (with internal spaces)
      await tester.pumpWidget(
        StyledAsciiText(
          data: 'H',
          font: AsciiFont.slim,
          style: Style()..foreground(Colors.red),
        ),
      );

      final strippedView = Layout.stripAnsi(tester.view);
      // Slim 'H' glyph lines: ['█  █', '█▀▀█', '█  █', '▀  ▀', '    ']
      // The double-space run between characters must be preserved
      expect(strippedView, contains('█  █'));
    });

    test('styled with bold preserves layout', () async {
      final testerPlain = WidgetTester();
      final testerStyled = WidgetTester();
      addTearDown(() => testerPlain.dispose());
      addTearDown(() => testerStyled.dispose());

      await testerPlain.pumpWidget(AsciiText(data: '42', font: AsciiFont.slim));
      await testerStyled.pumpWidget(
        StyledAsciiText(
          data: '42',
          font: AsciiFont.slim,
          style: Style()
            ..foreground(Colors.yellow)
            ..bold(true),
        ),
      );

      final plainLines = testerPlain.viewLines.map(Layout.stripAnsi).toList();
      final styledLines = testerStyled.viewLines.map(Layout.stripAnsi).toList();

      for (var i = 0; i < plainLines.length; i++) {
        expect(
          styledLines[i],
          equals(plainLines[i]),
          reason: 'Line $i differs with bold style',
        );
      }
    });
  });

  group('AsciiText with different fonts', () {
    test('standard font renders', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: 'A', font: AsciiFont.standard));
      expect(tester.view, contains('██'));
    });

    test('banner font renders', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: 'A', font: AsciiFont.banner));
      expect(tester.view.trim(), isNotEmpty);
    });

    test('block font renders', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: 'A', font: AsciiFont.block));
      expect(tester.view.trim(), isNotEmpty);
    });

    test('slim font renders', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: 'A', font: AsciiFont.slim));
      expect(tester.view, contains('▄▀▄'));
    });
  });

  group('StyledAsciiText across all fonts', () {
    for (final fontEntry in [
      ('standard', AsciiFont.standard),
      ('banner', AsciiFont.banner),
      ('block', AsciiFont.block),
      ('slim', AsciiFont.slim),
    ]) {
      test('${fontEntry.$1} font: styled matches plain layout', () async {
        final testerPlain = WidgetTester();
        final testerStyled = WidgetTester();
        addTearDown(() => testerPlain.dispose());
        addTearDown(() => testerStyled.dispose());

        await testerPlain.pumpWidget(AsciiText(data: 'HI', font: fontEntry.$2));
        await testerStyled.pumpWidget(
          StyledAsciiText(
            data: 'HI',
            font: fontEntry.$2,
            style: Style()..foreground(Colors.cyan),
          ),
        );

        final plainLines = testerPlain.viewLines.map(Layout.stripAnsi).toList();
        final styledLines = testerStyled.viewLines
            .map(Layout.stripAnsi)
            .toList();

        expect(
          styledLines.length,
          equals(plainLines.length),
          reason: '${fontEntry.$1}: line count mismatch',
        );

        for (var i = 0; i < plainLines.length; i++) {
          expect(
            styledLines[i],
            equals(plainLines[i]),
            reason:
                '${fontEntry.$1} line $i: '
                'styled="${styledLines[i]}" vs plain="${plainLines[i]}"',
          );
        }
      });
    }
  });
}
