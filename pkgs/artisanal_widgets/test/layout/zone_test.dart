/// Tests for the Zone widget compatibility surface.
///
/// Zone now behaves as a transparent wrapper in artisanal_widgets. Legacy
/// zone-manager integration was removed in favor of hit-testing.
library;

import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('constructor', () {
    test('creates with required child', () {
      final zone = w.Zone(child: w.Text('content'));
      expect(zone.child, isA<w.Text>());
      expect(zone.zoneId, isNull);
    });

    test('accepts explicit zoneId', () {
      final zone = w.Zone(child: w.Text('content'), zoneId: 'my-zone');
      expect(zone.zoneId, equals('my-zone'));
    });

    test('accepts key', () {
      final zone = w.Zone(
        child: w.Text('content'),
        key: const w.ValueKey('zone-key'),
      );
      expect(zone.key, isA<w.ValueKey>());
    });
  });

  group('rendering', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Zone(child: w.Text('zone-content'), zoneId: 'z1'),
      );

      expect(tester.find.text('zone-content'), isTrue);
    });

    test('renders complex child tree', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Zone(
          zoneId: 'z2',
          child: w.Column(
            children: [w.Text('zone-line-a'), w.Text('zone-line-b')],
          ),
        ),
      );

      expect(tester.find.text('zone-line-a'), isTrue);
      expect(tester.find.text('zone-line-b'), isTrue);
    });
  });

  group('legacy API compatibility', () {
    test('finder hasZone is always false', () async {
      final tester = WidgetTester(enableZones: true);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Zone(child: w.Text('tracked'), zoneId: 'tracked-zone'),
        scanZones: true,
      );

      // ignore: deprecated_member_use_from_same_package
      expect(tester.find.hasZone('tracked-zone'), isFalse);
    });

    test('legacy zone tap target throws unsupported error', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Zone(child: w.Text('tracked'), zoneId: 'tracked-zone'),
      );

      expect(
        // ignore: deprecated_member_use_from_same_package
        () => tester.tap(tester.find.zone('tracked-zone')),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('zone ID data', () {
    test('zoneId takes precedence over key', () {
      final zone = w.Zone(
        child: w.Text('test'),
        zoneId: 'explicit-id',
        key: const w.ValueKey('key-id'),
      );
      expect(zone.zoneId, equals('explicit-id'));
    });
  });

  group('layout integration', () {
    test('Zone inside Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Container(
          width: 30,
          height: 3,
          child: w.Zone(zoneId: 'in-container', child: w.Text('wrapped')),
        ),
      );

      expect(tester.find.text('wrapped'), isTrue);
    });

    test('Zone inside Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Row(
          children: [
            w.Zone(child: w.Text('left'), zoneId: 'left-z'),
            w.Zone(child: w.Text('right'), zoneId: 'right-z'),
          ],
        ),
      );

      expect(tester.find.text('left'), isTrue);
      expect(tester.find.text('right'), isTrue);
    });
  });
}
