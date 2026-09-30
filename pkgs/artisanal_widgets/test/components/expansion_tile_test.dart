import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('ExpansionTile', () {
    test(
      'controlled requests wait for acceptance and follow live updates',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        final requests = <bool>[];
        late void Function(bool?) update;
        await tester.pumpWidget(
          _ControlledHost(
            ready: (callback) => update = callback,
            requests: requests,
          ),
        );
        final title = tester.locateText('Controlled')!;
        tester.tapAt(title.x, title.y);
        expect(requests, [true]);
        expect(tester.locateText('Controlled body'), isNull);
        update(true);
        tester.pump();
        expect(tester.locateText('Controlled body'), isNotNull);
        expect(requests, [true]);
        tester.tapAt(title.x, title.y);
        expect(requests, [true, false]);
        expect(tester.locateText('Controlled body'), isNotNull);
        update(null);
        tester.pump();
        expect(tester.locateText('Controlled body'), isNotNull);
        tester.tapAt(title.x, title.y);
        expect(tester.locateText('Controlled body'), isNull);
        expect(requests, [true, false, false]);
        update(true);
        tester.pump();
        expect(tester.locateText('Controlled body'), isNotNull);
      },
    );

    test('disabled controlled tile renders state without requests', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final requests = <bool>[];
      await tester.pumpWidget(
        ExpansionTile(
          title: 'Controlled',
          expanded: true,
          enabled: false,
          onExpansionChanged: (value) {
            requests.add(value);
            return null;
          },
          children: [Text('Controlled body')],
        ),
      );
      final title = tester.locateText('Controlled')!;
      tester.tapAt(title.x, title.y);
      expect(requests, isEmpty);
      expect(tester.locateText('Controlled body'), isNotNull);
    });

    test('starts collapsed by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ExpansionTile(title: 'Section', children: [Text('Hidden child')]),
      );

      expect(tester.locateText('Section'), isNotNull);
      expect(tester.locateText('Hidden child'), isNull);
    });

    test('uses initiallyExpanded to show children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ExpansionTile(
          title: 'Section',
          initiallyExpanded: true,
          children: [Text('Visible child')],
        ),
      );

      expect(tester.locateText('Visible child'), isNotNull);
    });

    test('toggles expansion when tapped', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ExpansionTile(title: 'Tap me', children: [Text('Toggle child')]),
      );

      expect(tester.locateText('Toggle child'), isNull);
      final titleLoc = tester.locateText('Tap me');
      expect(titleLoc, isNotNull);
      tester.tapAt(titleLoc!.x, titleLoc.y);

      expect(tester.locateText('Toggle child'), isNotNull);
    });

    test('reports expansion changes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final changes = <bool>[];
      await tester.pumpWidget(
        ExpansionTile(
          title: 'Events',
          onExpansionChanged: (expanded) {
            changes.add(expanded);
            return null;
          },
          children: [Text('Body')],
        ),
      );

      final titleLoc = tester.locateText('Events');
      expect(titleLoc, isNotNull);
      tester.tapAt(titleLoc!.x, titleLoc.y);
      tester.tapAt(titleLoc.x, titleLoc.y);

      expect(changes, [true, false]);
    });

    test('disabled tile does not toggle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ExpansionTile(
          title: 'Disabled',
          enabled: false,
          children: [Text('No show')],
        ),
      );

      final titleLoc = tester.locateText('Disabled');
      expect(titleLoc, isNotNull);
      tester.tapAt(titleLoc!.x, titleLoc.y);

      expect(tester.locateText('No show'), isNull);
    });
  });
}

class _ControlledHost extends StatefulWidget {
  _ControlledHost({required this.ready, required this.requests});
  final void Function(void Function(bool?)) ready;
  final List<bool> requests;

  @override
  State<_ControlledHost> createState() => _ControlledHostState();
}

class _ControlledHostState extends State<_ControlledHost> {
  bool? expanded = false;

  @override
  void initState() {
    super.initState();
    widget.ready((value) => setState(() => expanded = value));
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: const ValueKey('controlled'),
    title: 'Controlled',
    initiallyExpanded: true,
    expanded: expanded,
    onExpansionChanged: (value) {
      widget.requests.add(value);
      return null;
    },
    children: [Text('Controlled body')],
  );
}
