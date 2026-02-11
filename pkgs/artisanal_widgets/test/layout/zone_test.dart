/// Tests for the Zone widget (legacy zone-based dispatch).
///
/// Zone wraps a child with a zone ID used by the legacy zone manager for
/// mouse dispatch. These tests verify zone registration, rendering, and
/// basic zone-based interaction.
library;

import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Rendering (without zone manager)
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Zone registration (with zone manager enabled)
  // ---------------------------------------------------------------------------

  group('zone registration', () {
    test('explicit zoneId is registered in zone manager', () async {
      final tester = WidgetTester(enableZones: true);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Zone(child: w.Text('tracked'), zoneId: 'tracked-zone'),
        scanZones: true,
      );

      // ignore: deprecated_member_use_from_same_package
      final info = tester.find.hasZone('tracked-zone');
      expect(info, isTrue, reason: 'Zone "tracked-zone" should be registered');
    });

    test('zone renders child normally when registered', () async {
      final tester = WidgetTester(enableZones: true);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Zone(child: w.Text('visible-zone'), zoneId: 'vis-zone'),
        scanZones: true,
      );

      expect(tester.find.text('visible-zone'), isTrue);
    });

    test('multiple zones can coexist', () async {
      final tester = WidgetTester(enableZones: true);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Column(
          children: [
            w.Zone(child: w.Text('first'), zoneId: 'zone-a'),
            w.Zone(child: w.Text('second'), zoneId: 'zone-b'),
          ],
        ),
        scanZones: true,
      );

      expect(tester.find.text('first'), isTrue);
      expect(tester.find.text('second'), isTrue);
      // ignore: deprecated_member_use_from_same_package
      expect(tester.find.hasZone('zone-a'), isTrue);
      // ignore: deprecated_member_use_from_same_package
      expect(tester.find.hasZone('zone-b'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Zone ID resolution
  // ---------------------------------------------------------------------------

  group('zone ID resolution', () {
    test('zoneId takes precedence over key', () {
      final zone = w.Zone(
        child: w.Text('test'),
        zoneId: 'explicit-id',
        key: const w.ValueKey('key-id'),
      );
      expect(zone.zoneId, equals('explicit-id'));
    });

    test('null zoneId falls back to key-based resolution', () async {
      final tester = WidgetTester(enableZones: true);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Zone(child: w.Text('keyed'), key: const w.ValueKey('auto-zone')),
        scanZones: true,
      );

      // When zoneId is null, Zone resolves from key → child.key → child.id.
      // With ValueKey('auto-zone'), the resolved zone ID should be 'auto-zone'.
      // ignore: deprecated_member_use_from_same_package
      expect(tester.find.hasZone('auto-zone'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Inside layout containers
  // ---------------------------------------------------------------------------

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
