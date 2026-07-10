import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Accordion
  // ---------------------------------------------------------------------------
  group('Accordion', () {
    group('basic rendering', () {
      test('renders title when collapsed', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Accordion(title: 'Section', child: Text('Body')),
        );

        expect(tester.view, isNotEmpty);
        expect(tester.locateText('Section'), isNotNull);
      });

      test('collapsed shows > chevron', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Accordion(title: 'Section', child: Text('Body')),
        );

        expect(tester.locateText('>'), isNotNull);
      });

      test('collapsed does NOT show child content', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Accordion(title: 'Section', child: Text('Hidden Body')),
        );

        expect(tester.locateText('Hidden Body'), isNull);
      });

      test('expanded shows v chevron', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Accordion(title: 'Section', expanded: true, child: Text('Body')),
        );

        expect(tester.locateText('v'), isNotNull);
      });

      test('expanded shows child content', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Accordion(
            title: 'Section',
            expanded: true,
            child: Text('Visible Body'),
          ),
        );

        expect(tester.locateText('Visible Body'), isNotNull);
      });
    });

    group('properties', () {
      test('default expanded is false', () {
        final a = Accordion(title: 'T', child: Text('C'));
        expect(a.expanded, isFalse);
      });

      test('default enabled is true', () {
        final a = Accordion(title: 'T', child: Text('C'));
        expect(a.enabled, isTrue);
      });

      test('leading defaults to null', () {
        final a = Accordion(title: 'T', child: Text('C'));
        expect(a.leading, isNull);
      });

      test('padding defaults to null', () {
        final a = Accordion(title: 'T', child: Text('C'));
        expect(a.padding, isNull);
      });

      test('custom properties are stored', () {
        final lead = Text('*');
        final pad = const EdgeInsets.all(4);
        final a = Accordion(
          title: 'MyTitle',
          child: Text('C'),
          expanded: true,
          enabled: false,
          leading: lead,
          padding: pad,
        );
        expect(a.title, 'MyTitle');
        expect(a.expanded, isTrue);
        expect(a.enabled, isFalse);
        expect(a.leading, same(lead));
        expect(a.padding, same(pad));
      });

      test('respects key', () {
        final k = ValueKey('acc');
        final a = Accordion(title: 'T', child: Text('C'), key: k);
        expect(a.key, same(k));
      });

      test('has unique id without key', () {
        final a = Accordion(title: 'T', child: Text('C'));
        expect(a.id, isNotNull);
        expect(a.id, isNotEmpty);
      });
    });

    group('leading widget', () {
      test('leading renders beside title', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Accordion(title: 'Info', leading: Text('*'), child: Text('Details')),
        );

        expect(tester.locateText('*'), isNotNull);
        expect(tester.locateText('Info'), isNotNull);
      });
    });

    group('onChanged callback', () {
      test('onChanged receives !expanded when tapped', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        bool? receivedValue;
        await tester.pumpWidget(
          Accordion(
            title: 'Toggle',
            expanded: false,
            onChanged: (val) {
              receivedValue = val;
              return null;
            },
            child: Text('Content'),
          ),
        );

        // Locate the title and tap on it
        final loc = tester.locateText('Toggle');
        expect(loc, isNotNull);
        tester.tapAt(loc!.x, loc.y);

        expect(receivedValue, isTrue, reason: '!false == true');
      });

      test('onChanged receives false when expanded accordion tapped', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        bool? receivedValue;
        await tester.pumpWidget(
          Accordion(
            title: 'Toggle',
            expanded: true,
            onChanged: (val) {
              receivedValue = val;
              return null;
            },
            child: Text('Content'),
          ),
        );

        final loc = tester.locateText('Toggle');
        expect(loc, isNotNull);
        tester.tapAt(loc!.x, loc.y);

        expect(receivedValue, isFalse, reason: '!true == false');
      });
    });

    group('disabled accordion', () {
      test('disabled does NOT fire onChanged on tap', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        bool called = false;
        await tester.pumpWidget(
          Accordion(
            title: 'NoClick',
            enabled: false,
            onChanged: (val) {
              called = true;
              return null;
            },
            child: Text('Content'),
          ),
        );

        final loc = tester.locateText('NoClick');
        expect(loc, isNotNull);
        tester.tapAt(loc!.x, loc.y);

        expect(called, isFalse);
      });
    });

    group('expanded with padding', () {
      test('child is rendered with default left padding', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Accordion(title: 'Sec', expanded: true, child: Text('Indented')),
        );

        // Child content should appear
        expect(tester.locateText('Indented'), isNotNull);

        // The child should be indented relative to the title (default left: 2)
        final titleLoc = tester.locateText('Sec');
        final childLoc = tester.locateText('Indented');
        expect(titleLoc, isNotNull);
        expect(childLoc, isNotNull);
        // Child should be on a lower row than the title
        expect(childLoc!.y, greaterThan(titleLoc!.y));
      });
    });

    group('integration', () {
      test('multiple accordions in Column', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Column(
            children: [
              Accordion(title: 'First', child: Text('Content1')),
              Accordion(
                title: 'Second',
                expanded: true,
                child: Text('Content2'),
              ),
            ],
          ),
        );

        expect(tester.locateText('First'), isNotNull);
        expect(tester.locateText('Second'), isNotNull);
        // Only second accordion's content visible
        expect(tester.locateText('Content1'), isNull);
        expect(tester.locateText('Content2'), isNotNull);
      });

      test('accordion inside Container', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            width: 40,
            child: Accordion(
              title: 'Boxed',
              expanded: true,
              child: Text('Inside'),
            ),
          ),
        );

        expect(tester.locateText('Boxed'), isNotNull);
        expect(tester.locateText('Inside'), isNotNull);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Toast
  // ---------------------------------------------------------------------------
  group('Toast', () {
    group('basic rendering', () {
      test('renders as AlertBox with rounded border', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(Toast(message: 'Hello Toast'));

        expect(tester.view, isNotEmpty);
        expect(tester.locateText('Hello Toast'), isNotNull);
      });

      test('renders title when provided', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Toast(title: 'Alert!', message: 'Something happened'),
        );

        expect(tester.locateText('Alert!'), isNotNull);
        expect(tester.locateText('Something happened'), isNotNull);
      });

      test('renders with info variant marker by default', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(Toast(message: 'Info msg'));

        // AlertVariant.info produces marker 'i'
        expect(tester.locateText('i'), isNotNull);
      });
    });

    group('variant markers', () {
      test('success variant shows + marker', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Toast(message: 'OK', variant: AlertVariant.success),
        );

        expect(tester.locateText('+'), isNotNull);
      });

      test('warning variant shows ! marker', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Toast(message: 'Warn', variant: AlertVariant.warning),
        );

        expect(tester.locateText('!'), isNotNull);
      });

      test('error variant shows x marker', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Toast(message: 'Err', variant: AlertVariant.error),
        );

        expect(tester.locateText('x'), isNotNull);
      });

      test('neutral variant shows * marker', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Toast(message: 'Neutral', variant: AlertVariant.neutral),
        );

        expect(tester.locateText('*'), isNotNull);
      });
    });

    group('with child widget', () {
      test('child takes precedence over message', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Toast(message: 'Fallback', child: Text('Custom Child')),
        );

        // AlertBox uses child ?? Text(message ?? ''), so child wins
        expect(tester.locateText('Custom Child'), isNotNull);
      });
    });

    group('with actions', () {
      test('actions render alongside content', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Toast(
            message: 'Undoable',
            actions: [Button(label: 'Undo', onPressed: () => null)],
          ),
        );

        expect(tester.locateText('Undoable'), isNotNull);
        expect(tester.locateText('Undo'), isNotNull);
      });
    });

    group('properties', () {
      test('default variant is info', () {
        final t = Toast(message: 'msg');
        expect(t.variant, AlertVariant.info);
      });

      test('default actions is empty', () {
        final t = Toast(message: 'msg');
        expect(t.actions, isEmpty);
      });

      test('default padding is null (Toast uses h:2 v:1 internally)', () {
        final t = Toast(message: 'msg');
        expect(t.padding, isNull);
      });

      test('default margin is null', () {
        final t = Toast(message: 'msg');
        expect(t.margin, isNull);
      });

      test('custom properties are stored', () {
        final pad = const EdgeInsets.all(3);
        final mar = const EdgeInsets.only(top: 1);
        final t = Toast(
          title: 'T',
          message: 'M',
          variant: AlertVariant.error,
          padding: pad,
          margin: mar,
        );
        expect(t.title, 'T');
        expect(t.message, 'M');
        expect(t.variant, AlertVariant.error);
        expect(t.padding, same(pad));
        expect(t.margin, same(mar));
      });

      test('respects key', () {
        final k = ValueKey('toast');
        final t = Toast(message: 'msg', key: k);
        expect(t.key, same(k));
      });

      test('has unique id without key', () {
        final t = Toast(message: 'msg');
        expect(t.id, isNotNull);
        expect(t.id, isNotEmpty);
      });
    });

    group('integration', () {
      test('Toast in Column with other widgets', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Column(
            children: [
              Text('Header'),
              Toast(message: 'Notification'),
              Text('Footer'),
            ],
          ),
        );

        expect(tester.locateText('Header'), isNotNull);
        expect(tester.locateText('Notification'), isNotNull);
        expect(tester.locateText('Footer'), isNotNull);
      });

      test('Toast inside Container', () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Container(
            width: 50,
            child: Toast(title: 'Hey', message: 'Contained'),
          ),
        );

        expect(tester.locateText('Hey'), isNotNull);
        expect(tester.locateText('Contained'), isNotNull);
      });
    });
  });
}
