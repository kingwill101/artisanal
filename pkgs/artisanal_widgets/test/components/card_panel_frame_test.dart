import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Frame
  // ---------------------------------------------------------------------------
  group('Frame', () {
    test('renders child text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Frame(child: Text('Hello Frame')));
      expect(tester.find.text('Hello Frame'), isTrue);
    });

    test('applies border — view contains border characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Frame(border: Border.rounded, child: Text('bordered')),
      );

      // Rounded border uses ╭, ╮, ╰, ╯, ─, │
      final view = tester.view;
      expect(view, contains('─'));
      expect(view, contains('│'));
    });

    test('applies normal border characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Frame(border: Border.normal, child: Text('normal')),
      );

      final view = tester.view;
      expect(view, contains('┌'));
      expect(view, contains('┐'));
      expect(view, contains('└'));
      expect(view, contains('┘'));
    });

    test('applies rounded border corner characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Frame(border: Border.rounded, child: Text('round')),
      );

      final view = tester.view;
      expect(view, contains('╭'));
      expect(view, contains('╮'));
      expect(view, contains('╰'));
      expect(view, contains('╯'));
    });

    test('keeps frame visuals inside Row render layout', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          gap: 1,
          children: [
            Text('before'),
            Frame(
              border: Border.normal,
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Text('framed'),
            ),
            Text('after'),
          ],
        ),
      );

      expect(tester.view, contains('┌'));
      expect(tester.view, contains('┐'));
      expect(tester.view, contains('└'));
      expect(tester.view, contains('┘'));
      expect(tester.locateText('framed'), isNotNull);
    });

    test('child is accessible via children getter', () {
      final child = Text('inner');
      final frame = Frame(child: child);
      expect(frame.children, hasLength(1));
      expect(frame.children.first, same(child));
    });

    test('has unique id', () {
      final f1 = Frame(child: Text('a'));
      final f2 = Frame(child: Text('b'));
      expect(f1.id, isNot(equals(f2.id)));
    });

    test('respects key', () {
      final frame = Frame(key: ValueKey('frame-key'), child: Text('keyed'));
      expect(frame.id, equals('frame-key'));
    });

    test('is not focusable', () {
      final frame = Frame(child: Text('test'));
      expect(frame.focusable, isFalse);
    });

    test('renders without border when none specified', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Frame(child: Text('no border')));
      expect(tester.find.text('no border'), isTrue);
      // No rounded border chars should appear
      expect(tester.view, isNot(contains('╭')));
      expect(tester.view, isNot(contains('┌')));
    });

    test('applies padding — content is not at origin', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Frame(padding: EdgeInsets.all(2), child: Text('padded')),
      );

      expect(tester.find.text('padded'), isTrue);
      final location = tester.locateText('padded');
      expect(location, isNotNull);
      // With padding of 2 on all sides, text should not start at x=0
      expect(location!.x, greaterThanOrEqualTo(2));
      expect(location.y, greaterThanOrEqualTo(2));
    });
  });

  // ---------------------------------------------------------------------------
  // Card
  // ---------------------------------------------------------------------------
  group('Card', () {
    test('renders child text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Card(child: Text('Card Content')));
      expect(tester.find.text('Card Content'), isTrue);
    });

    test('has rounded border by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Card(child: Text('default card')));

      // Card uses Border.rounded which has ╭ ╮ ╰ ╯ corners
      final view = tester.view;
      expect(view, contains('╭'));
      expect(view, contains('╮'));
      expect(view, contains('╰'));
      expect(view, contains('╯'));
    });

    test('content is padded — text not at origin', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Card(child: Text('padded card')));

      final location = tester.locateText('padded card');
      expect(location, isNotNull);
      // Card has default padding of EdgeInsets.all(1) plus a border,
      // so text should not be at (0,0).
      expect(location!.x, greaterThan(0));
      expect(location.y, greaterThan(0));
    });

    test('styled title line keeps card surface background', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final previousTheme = currentTheme;
      addTearDown(() => setTheme(previousTheme));
      setTheme(Theme.dark());

      await tester.pumpWidget(
        Card(
          padding: const EdgeInsets.all(1),
          child: Column(
            gap: 1,
            children: [
              Text('Card Title', style: currentTheme.titleSmall),
              Text(
                'A longer detail line that widens the card body.',
                style: currentTheme.bodySmall,
              ),
            ],
          ),
        ),
      );

      final line = tester.view
          .split('\n')
          .firstWhere((entry) => entry.contains('Card Title'));
      final hasSurfaceBackground =
          line.contains('48;5;236') || line.contains('48;2;48;48;48');
      final hasPageBackground =
          line.contains('48;5;233') || line.contains('48;2;18;18;18');
      expect(hasSurfaceBackground, isTrue, reason: line);
      expect(hasPageBackground, isFalse, reason: line);
    });

    test('has unique id', () {
      final c1 = Card(child: Text('a'));
      final c2 = Card(child: Text('b'));
      expect(c1.id, isNot(equals(c2.id)));
    });

    test('respects key', () {
      final card = Card(key: ValueKey('card-key'), child: Text('keyed'));
      expect(card.id, equals('card-key'));
    });

    test('is not focusable', () {
      final card = Card(child: Text('test'));
      expect(card.focusable, isFalse);
    });

    test('renders with custom padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text('custom pad'),
        ),
      );

      expect(tester.find.text('custom pad'), isTrue);
      final location = tester.locateText('custom pad');
      expect(location, isNotNull);
      // horizontal padding 4 + border 1 = at least 5 from left
      expect(location!.x, greaterThanOrEqualTo(5));
    });

    test('renders with custom border style', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(border: Border.double, child: Text('double border')),
      );

      expect(tester.find.text('double border'), isTrue);
      final view = tester.view;
      // Double border uses ╔ ╗ ╚ ╝
      expect(view, contains('╔'));
      expect(view, contains('╗'));
    });

    test('renders with thick border', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Card(border: Border.thick, child: Text('thick')));

      expect(tester.find.text('thick'), isTrue);
      final view = tester.view;
      // Thick border uses ┏ ┓
      expect(view, contains('┏'));
      expect(view, contains('┓'));
    });

    test('renders with normal border override', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(border: Border.normal, child: Text('normal')),
      );

      expect(tester.find.text('normal'), isTrue);
      final view = tester.view;
      expect(view, contains('┌'));
      expect(view, contains('┐'));
    });

    test('renders with custom border color', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(borderColor: Colors.red, child: Text('colored border')),
      );

      expect(tester.find.text('colored border'), isTrue);
      // The view should still contain border characters
      expect(tester.view, contains('╭'));
    });

    test('renders with no padding override', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(padding: EdgeInsets.zero, child: Text('no pad')),
      );

      expect(tester.find.text('no pad'), isTrue);
      final location = tester.locateText('no pad');
      expect(location, isNotNull);
      // Only border offset, no padding: x should be 1 (border column)
      expect(location!.x, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // PanelBox
  // ---------------------------------------------------------------------------
  group('PanelBox', () {
    test('renders child text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(PanelBox(child: Text('Panel Body')));
      expect(tester.find.text('Panel Body'), isTrue);
    });

    test('has border by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(PanelBox(child: Text('bordered panel')));

      final view = tester.view;
      // PanelBox uses Border.rounded by default
      expect(view, contains('╭'));
      expect(view, contains('╮'));
      expect(view, contains('╰'));
      expect(view, contains('╯'));
    });

    test('renders title in view', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(PanelBox(title: 'My Title', child: Text('body')));

      expect(tester.find.text('My Title'), isTrue);
      expect(tester.find.text('body'), isTrue);
    });

    test('title appears above body', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(title: 'Header', child: Text('Body Content')),
      );

      final titleLoc = tester.locateText('Header');
      final bodyLoc = tester.locateText('Body Content');
      expect(titleLoc, isNotNull);
      expect(bodyLoc, isNotNull);
      // Title row should be above body row
      expect(titleLoc!.y, lessThan(bodyLoc!.y));
    });

    test('renders divider between title and body', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(title: 'Section', child: Text('details')),
      );

      // The divider between header and body renders horizontal line chars
      // (uses ─ from the style)
      final view = tester.view;
      expect(view, contains('─'));
    });

    test('without title has no header', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(PanelBox(child: Text('body only')));

      expect(tester.find.text('body only'), isTrue);
      // The body should be closer to the top (inside border + padding)
      final loc = tester.locateText('body only');
      expect(loc, isNotNull);
      // With border(1) + padding(1) = y should be 2
      expect(loc!.y, lessThanOrEqualTo(2));
    });

    test('with actions renders action widgets', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(
          title: 'Actions Panel',
          actions: [Text('[Close]'), Text('[Help]')],
          child: Text('action body'),
        ),
      );

      expect(tester.find.text('Actions Panel'), isTrue);
      expect(tester.find.text('[Close]'), isTrue);
      expect(tester.find.text('[Help]'), isTrue);
      expect(tester.find.text('action body'), isTrue);
    });

    test('actions without title still show header', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(actions: [Text('[X]')], child: Text('actions only')),
      );

      expect(tester.find.text('[X]'), isTrue);
      expect(tester.find.text('actions only'), isTrue);
    });

    test('actions appear on same row as title', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(
          title: 'Title',
          actions: [Text('[Act]')],
          child: Text('content'),
        ),
      );

      final titleLoc = tester.locateText('Title');
      final actionLoc = tester.locateText('[Act]');
      expect(titleLoc, isNotNull);
      expect(actionLoc, isNotNull);
      // Title and actions should be on the same row
      expect(titleLoc!.y, equals(actionLoc!.y));
    });

    test('has unique id', () {
      final p1 = PanelBox(child: Text('a'));
      final p2 = PanelBox(child: Text('b'));
      expect(p1.id, isNot(equals(p2.id)));
    });

    test('respects key', () {
      final panel = PanelBox(key: ValueKey('panel-key'), child: Text('keyed'));
      expect(panel.id, equals('panel-key'));
    });

    test('is not focusable', () {
      final panel = PanelBox(child: Text('test'));
      expect(panel.focusable, isFalse);
    });

    test('renders with custom border', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(
          border: Border.double,
          title: 'Double',
          child: Text('double panel'),
        ),
      );

      expect(tester.find.text('Double'), isTrue);
      expect(tester.find.text('double panel'), isTrue);
      expect(tester.view, contains('╔'));
      expect(tester.view, contains('╗'));
    });

    test('renders with custom padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(padding: EdgeInsets.all(3), child: Text('big pad')),
      );

      expect(tester.find.text('big pad'), isTrue);
      final loc = tester.locateText('big pad');
      expect(loc, isNotNull);
      // padding(3) + border(1) = at least 4
      expect(loc!.x, greaterThanOrEqualTo(4));
    });
  });

  // ---------------------------------------------------------------------------
  // Integration
  // ---------------------------------------------------------------------------
  group('Integration', () {
    test('Card containing Column of texts', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Card(
          child: Column(
            children: [Text('Line 1'), Text('Line 2'), Text('Line 3')],
          ),
        ),
      );

      expect(tester.find.text('Line 1'), isTrue);
      expect(tester.find.text('Line 2'), isTrue);
      expect(tester.find.text('Line 3'), isTrue);
      // Should have rounded border
      expect(tester.view, contains('╭'));
    });

    test('PanelBox containing Column of widgets', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(
          title: 'Info',
          child: Column(children: [Text('Name: Widget'), Text('Version: 1.0')]),
        ),
      );

      expect(tester.find.text('Info'), isTrue);
      expect(tester.find.text('Name: Widget'), isTrue);
      expect(tester.find.text('Version: 1.0'), isTrue);
    });

    test('Card nested inside PanelBox', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(
          title: 'Outer',
          child: Card(child: Text('Inner Card')),
        ),
      );

      expect(tester.find.text('Outer'), isTrue);
      expect(tester.find.text('Inner Card'), isTrue);
    });

    test('PanelBox with title, actions, and complex body', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PanelBox(
          title: 'Dashboard',
          actions: [Text('[Refresh]')],
          child: Column(children: [Text('Status: OK'), Text('Uptime: 99.9%')]),
        ),
      );

      expect(tester.find.text('Dashboard'), isTrue);
      expect(tester.find.text('[Refresh]'), isTrue);
      expect(tester.find.text('Status: OK'), isTrue);
      expect(tester.find.text('Uptime: 99.9%'), isTrue);
    });

    test('Frame wrapping Card', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Frame(
          border: Border.thick,
          padding: EdgeInsets.all(1),
          child: Card(child: Text('framed card')),
        ),
      );

      expect(tester.find.text('framed card'), isTrue);
      // Outer frame should have thick border chars
      expect(tester.view, contains('┏'));
      // Inner card should have rounded border chars
      expect(tester.view, contains('╭'));
    });

    test('multiple Cards in a Column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Card(child: Text('Card A')),
            Card(child: Text('Card B')),
          ],
        ),
      );

      expect(tester.find.text('Card A'), isTrue);
      expect(tester.find.text('Card B'), isTrue);

      final locA = tester.locateText('Card A');
      final locB = tester.locateText('Card B');
      expect(locA, isNotNull);
      expect(locB, isNotNull);
      // Card B should be below Card A
      expect(locB!.y, greaterThan(locA!.y));
    });
  });
}
