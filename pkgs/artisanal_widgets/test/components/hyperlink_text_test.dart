import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('HyperlinkText', () {
    test('renders label text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HyperlinkText(url: 'https://example.com', label: 'Example'),
      );

      expect(tester.find.text('Example'), isTrue);
    });

    test('renders URL as label when label is null', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(HyperlinkText(url: 'https://dart.dev'));

      expect(tester.find.text('https://dart.dev'), isTrue);
    });

    test('includes OSC 8 escape sequence in raw view', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HyperlinkText(url: 'https://example.com', label: 'Link'),
      );

      // The raw view should contain OSC 8 start and end sequences.
      expect(tester.view, contains('\x1b]8;;https://example.com\x1b\\'));
      expect(tester.view, contains('\x1b]8;;\x1b\\'));
    });

    test('showUrl false does not show URL in parens', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HyperlinkText(
          url: 'https://example.com',
          label: 'Click here',
          showUrl: false,
        ),
      );

      expect(tester.find.text('Click here'), isTrue);
      expect(tester.find.text('(https://example.com)'), isFalse);
    });

    test('showUrl true shows URL in parentheses after label', () async {
      final tester = WidgetTester(screenWidth: 80);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HyperlinkText(
          url: 'https://example.com',
          label: 'Example Site',
          showUrl: true,
        ),
      );

      expect(tester.find.text('Example Site'), isTrue);
      expect(tester.find.text('https://example.com'), isTrue);
    });

    test('showUrl true with label same as URL does not duplicate', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HyperlinkText(
          url: 'https://example.com',
          label: 'https://example.com',
          showUrl: true,
        ),
      );

      // When label equals URL, parens should not appear.
      expect(tester.find.text('(https://example.com)'), isFalse);
    });

    test('showUrl true with null label does not show parens', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        HyperlinkText(url: 'https://example.com', showUrl: true),
      );

      // When label is null, URL is displayed directly — no parens.
      expect(tester.find.text('https://example.com'), isTrue);
      expect(tester.find.text('(https://example.com)'), isFalse);
    });

    test('showUrl defaults to false', () {
      final h = HyperlinkText(url: 'https://example.com');
      expect(h.showUrl, isFalse);
    });

    test('has unique id', () {
      final h1 = HyperlinkText(url: 'https://a.com');
      final h2 = HyperlinkText(url: 'https://b.com');
      expect(h1.id, isNot(equals(h2.id)));
    });

    test('respects key', () {
      final h = HyperlinkText(
        key: ValueKey('link-key'),
        url: 'https://example.com',
      );
      expect(h.id, equals('link-key'));
    });
  });
}
