import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('AccentPanel', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: AccentPanel(child: Text('Hello panel')),
        ),
      );
      expect(tester.find.text('Hello panel'), isTrue);
    });

    test('renders accent stripe character', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: AccentPanel(child: Text('content')),
        ),
      );
      // Default accent char is │
      expect(tester.find.text('│'), isTrue);
    });

    test('renders custom accent character', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: AccentPanel(accentChar: '▎', child: Text('content')),
        ),
      );
      expect(tester.find.text('▎'), isTrue);
    });

    test('renders title when provided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: AccentPanel(title: 'Section Title', child: Text('body text')),
        ),
      );
      expect(tester.find.text('Section Title'), isTrue);
      expect(tester.find.text('body text'), isTrue);
    });

    test('shows child when expanded is true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: AccentPanel(
            title: 'Collapsible',
            expanded: true,
            child: Text('visible content'),
          ),
        ),
      );
      expect(tester.find.text('Collapsible'), isTrue);
      expect(tester.find.text('visible content'), isTrue);
      // Expanded chevron is 'v'
      expect(tester.find.text('v'), isTrue);
    });

    test('hides child when expanded is false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: AccentPanel(
            title: 'Collapsed',
            expanded: false,
            child: Text('hidden content'),
          ),
        ),
      );
      expect(tester.find.text('Collapsed'), isTrue);
      expect(tester.find.text('hidden content'), isFalse);
      // Collapsed chevron is '>'
      expect(tester.find.text('>'), isTrue);
    });

    test('calls onExpandChanged when chevron is tapped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      bool? expandValue;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: AccentPanel(
            title: 'Toggle',
            expanded: true,
            onExpandChanged: (value) {
              expandValue = value;
              return null;
            },
            child: Text('body'),
          ),
        ),
      );

      // Locate the title (chevron is on the same row)
      final location = tester.locateText('Toggle');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);
      expect(expandValue, isFalse);
    });

    test('stores accent side property', () {
      final panel = AccentPanel(side: AccentSide.right, child: Text('x'));
      expect(panel.side, equals(AccentSide.right));
    });

    test('defaults side to left', () {
      final panel = AccentPanel(child: Text('x'));
      expect(panel.side, equals(AccentSide.left));
    });

    test('stores accent width property', () {
      final panel = AccentPanel(accentWidth: 3, child: Text('x'));
      expect(panel.accentWidth, equals(3));
    });

    test('stores color overrides', () {
      final panel = AccentPanel(
        accentColor: const BasicColor('#ff0000'),
        background: const BasicColor('#111111'),
        foreground: const BasicColor('#eeeeee'),
        child: Text('x'),
      );
      expect(panel.accentColor, isNotNull);
      expect(panel.background, isNotNull);
      expect(panel.foreground, isNotNull);
    });

    test('stores padding override', () {
      final panel = AccentPanel(
        padding: const EdgeInsets.all(2),
        child: Text('x'),
      );
      expect(panel.padding, isNotNull);
    });
  });
}
