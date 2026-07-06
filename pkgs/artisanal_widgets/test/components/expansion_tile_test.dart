import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('ExpansionTile', () {
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
