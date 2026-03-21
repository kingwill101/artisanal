import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // StatusItem
  // ---------------------------------------------------------------------------
  group('StatusItem', () {
    test('text item renders string', () {
      final item = StatusItem.text('[INSERT]');
      expect(item.renderToString(), equals('[INSERT]'));
      expect(item.displayWidth, equals(8));
      expect(item.isSpacer, isFalse);
    });

    test('keyHint item renders key + action', () {
      final item = StatusItem.keyHint('^C', 'Quit');
      expect(item.renderToString(), equals('^C Quit'));
      expect(item.displayWidth, equals(7));
    });

    test('progress item renders percentage', () {
      expect(StatusItem.progress(50, 100).renderToString(), equals('50%'));
      expect(StatusItem.progress(100, 100).renderToString(), equals('100%'));
      expect(StatusItem.progress(0, 100).renderToString(), equals('0%'));
      expect(StatusItem.progress(50, 0).renderToString(), equals('0%'));
    });

    test('spinner item renders braille character', () {
      final item = StatusItem.spinner(0);
      expect(item.renderToString(), equals('⠋'));
      expect(item.displayWidth, equals(1));
    });

    test('spinner cycles through 10 frames', () {
      expect(
        StatusItem.spinner(0).renderToString(),
        isNot(equals(StatusItem.spinner(1).renderToString())),
      );
      expect(
        StatusItem.spinner(0).renderToString(),
        equals(StatusItem.spinner(10).renderToString()),
      );
    });

    test('spacer item is empty', () {
      final item = StatusItem.spacer();
      expect(item.renderToString(), equals(''));
      expect(item.displayWidth, equals(0));
      expect(item.isSpacer, isTrue);
    });

    test('text item is not spacer', () {
      expect(StatusItem.text('x').isSpacer, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // StatusLine
  // ---------------------------------------------------------------------------
  group('StatusLine', () {
    test('renders left items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(StatusLine(left: [StatusItem.text('[INSERT]')]));

      expect(tester.view, isNotEmpty);
      expect(tester.locateText('[INSERT]'), isNotNull);
    });

    test('renders right items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(StatusLine(right: [StatusItem.text('Ln 42')]));

      expect(tester.view, isNotEmpty);
      expect(tester.locateText('Ln 42'), isNotNull);
    });

    test('renders center items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(StatusLine(center: [StatusItem.text('file.rs')]));

      expect(tester.view, isNotEmpty);
      expect(tester.locateText('file.rs'), isNotNull);
    });

    test('renders all three regions', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StatusLine(
          left: [StatusItem.text('L')],
          center: [StatusItem.text('C')],
          right: [StatusItem.text('R')],
        ),
      );

      expect(tester.locateText('L'), isNotNull);
      expect(tester.locateText('C'), isNotNull);
      expect(tester.locateText('R'), isNotNull);
    });

    test('renders keyHint items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StatusLine(left: [StatusItem.keyHint('^C', 'Quit')]),
      );

      expect(tester.locateText('^C Quit'), isNotNull);
    });

    test('renders progress items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(StatusLine(left: [StatusItem.progress(50, 100)]));

      expect(tester.locateText('50%'), isNotNull);
    });

    test('multiple items separated by gap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StatusLine(left: [StatusItem.text('A'), StatusItem.text('B')], gap: 1),
      );

      expect(tester.locateText('A'), isNotNull);
      expect(tester.locateText('B'), isNotNull);
    });

    test('custom separator between items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StatusLine(
          left: [StatusItem.text('A'), StatusItem.text('B')],
          separator: ' | ',
        ),
      );

      expect(tester.locateText('A | B'), isNotNull);
    });

    test('spacer expands in region', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StatusLine(
          left: [
            StatusItem.text('L'),
            StatusItem.spacer(),
            StatusItem.text('R'),
          ],
        ),
      );

      expect(tester.locateText('L'), isNotNull);
      expect(tester.locateText('R'), isNotNull);
    });

    test('isEmpty returns true for empty regions', () {
      expect(StatusLine().isEmpty, isTrue);
      expect(StatusLine(left: [StatusItem.text('x')]).isEmpty, isFalse);
    });

    test('with custom background color', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StatusLine(background: Colors.red, left: [StatusItem.text('X')]),
      );

      expect(tester.locateText('X'), isNotNull);
    });
  });
}
