// Copyright (c) 2024. All rights reserved.
// Use of this source code is governed by the MIT license that can be found in
// the LICENSE file.

import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/zone/zone_info.dart';
import 'package:artisanal/src/tui/zone/zone_manager.dart';
import 'package:test/test.dart';

void main() {
  group('ZoneInfo', () {
    test('isZero returns true for empty ID', () {
      final zone = ZoneInfo(id: '', startX: 0, startY: 0, endX: 10, endY: 5);
      expect(zone.isZero, isTrue);
    });

    test('isZero returns false for non-empty ID', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 0,
        startY: 0,
        endX: 10,
        endY: 5,
      );
      expect(zone.isZero, isFalse);
    });

    test('inBounds returns false for zero zone', () {
      final zone = ZoneInfo(id: '', startX: 0, startY: 0, endX: 10, endY: 5);
      final msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 5,
        y: 2,
      );
      expect(zone.inBounds(msg), isFalse);
    });

    test('inBounds returns true for mouse inside zone', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );
      final msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 10,
        y: 5,
      );
      expect(zone.inBounds(msg), isTrue);
    });

    test('inBounds returns true for mouse at zone corners', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );

      // Top-left corner
      expect(
        zone.inBounds(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 5,
            y: 2,
          ),
        ),
        isTrue,
      );

      // Top-right corner
      expect(
        zone.inBounds(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 15,
            y: 2,
          ),
        ),
        isTrue,
      );

      // Bottom-left corner
      expect(
        zone.inBounds(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 5,
            y: 8,
          ),
        ),
        isTrue,
      );

      // Bottom-right corner
      expect(
        zone.inBounds(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 15,
            y: 8,
          ),
        ),
        isTrue,
      );
    });

    test('inBounds returns false for mouse outside zone', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );

      // Left of zone
      expect(
        zone.inBounds(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 5,
          ),
        ),
        isFalse,
      );

      // Right of zone
      expect(
        zone.inBounds(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 16,
            y: 5,
          ),
        ),
        isFalse,
      );

      // Above zone
      expect(
        zone.inBounds(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 10,
            y: 1,
          ),
        ),
        isFalse,
      );

      // Below zone
      expect(
        zone.inBounds(
          MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 10,
            y: 9,
          ),
        ),
        isFalse,
      );
    });

    test('inBounds returns false for invalid zone (start > end)', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 15,
        startY: 8,
        endX: 5,
        endY: 2,
      );
      final msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 10,
        y: 5,
      );
      expect(zone.inBounds(msg), isFalse);
    });

    test('pos returns relative coordinates when in bounds', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );
      final msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 10,
        y: 5,
      );
      final pos = zone.pos(msg);
      expect(pos.x, equals(5)); // 10 - 5
      expect(pos.y, equals(3)); // 5 - 2
    });

    test('pos returns (-1, -1) when not in bounds', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );
      final msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 20,
        y: 10,
      );
      final pos = zone.pos(msg);
      expect(pos.x, equals(-1));
      expect(pos.y, equals(-1));
    });

    test('pos returns (0, 0) for top-left corner', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );
      final msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 5,
        y: 2,
      );
      final pos = zone.pos(msg);
      expect(pos.x, equals(0));
      expect(pos.y, equals(0));
    });

    test('width and height are calculated correctly', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );
      expect(zone.width, equals(11)); // 15 - 5 + 1
      expect(zone.height, equals(7)); // 8 - 2 + 1
    });

    test('withEnd creates copy with new end coordinates', () {
      final zone = ZoneInfo(
        id: 'test',
        iteration: 42,
        startX: 5,
        startY: 2,
        endX: 10,
        endY: 5,
      );
      final updated = zone.withEnd(endX: 20, endY: 10);

      expect(updated.id, equals('test'));
      expect(updated.iteration, equals(42));
      expect(updated.startX, equals(5));
      expect(updated.startY, equals(2));
      expect(updated.endX, equals(20));
      expect(updated.endY, equals(10));
    });

    test('equality works correctly', () {
      final zone1 = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );
      final zone2 = ZoneInfo(
        id: 'test',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );
      final zone3 = ZoneInfo(
        id: 'different',
        startX: 5,
        startY: 2,
        endX: 15,
        endY: 8,
      );

      expect(zone1, equals(zone2));
      expect(zone1, isNot(equals(zone3)));
    });
  });

  group('ZoneManager', () {
    late ZoneManager manager;

    setUp(() {
      manager = ZoneManager();
    });

    tearDown(() {
      manager.close();
    });

    test('mark wraps content with invisible markers', () {
      final marked = manager.mark('test', 'Hello');

      // Should contain the original content
      expect(marked, contains('Hello'));

      // Should have markers (ESC [ <number> z format)
      expect(marked, contains('\x1B['));
      expect(marked, endsWith('z'));

      // Should be longer than original due to markers
      expect(marked.length, greaterThan('Hello'.length));
    });

    test('mark returns unchanged when disabled', () {
      manager.enabled = false;
      final marked = manager.mark('test', 'Hello');
      expect(marked, equals('Hello'));
    });

    test('mark returns unchanged for empty id', () {
      final marked = manager.mark('', 'Hello');
      expect(marked, equals('Hello'));
    });

    test('mark returns unchanged for empty content', () {
      final marked = manager.mark('test', '');
      expect(marked, equals(''));
    });

    test('mark uses same marker for same id', () {
      final marked1 = manager.mark('test', 'First');
      final marked2 = manager.mark('test', 'Second');

      // Extract the marker from the first marked string
      final marker1 = marked1.substring(0, marked1.indexOf('First'));
      final marker2 = marked2.substring(0, marked2.indexOf('Second'));

      expect(marker1, equals(marker2));
    });

    test('mark uses different markers for different ids', () {
      final marked1 = manager.mark('test1', 'First');
      final marked2 = manager.mark('test2', 'Second');

      // Extract the markers
      final marker1 = marked1.substring(0, marked1.indexOf('First'));
      final marker2 = marked2.substring(0, marked2.indexOf('Second'));

      expect(marker1, isNot(equals(marker2)));
    });

    test('scan strips markers from output', () {
      final marked = manager.mark('test', 'Hello World');
      final scanned = manager.scan(marked);

      expect(scanned, equals('Hello World'));
    });

    test('scan strips markers when disabled', () {
      final marked = manager.mark('test', 'Hello');
      manager.enabled = false;
      final scanned = manager.scan(marked);

      expect(scanned, equals('Hello'));
    });

    test('scan registers zone coordinates', () {
      final marked = manager.mark('test', 'Hello');
      manager.scan(marked);

      final zone = manager.get('test');
      expect(zone, isNotNull);
      expect(zone!.id, equals('test'));
      expect(zone.startX, equals(0));
      expect(zone.startY, equals(0));
      expect(zone.endX, equals(4)); // 'Hello' is 5 chars, end is 4 (0-indexed)
    });

    test('scan handles multiple zones', () {
      final button1 = manager.mark('btn1', 'OK');
      final button2 = manager.mark('btn2', 'Cancel');
      final content = '$button1 $button2';

      final scanned = manager.scan(content);
      expect(scanned, equals('OK Cancel'));

      final zone1 = manager.get('btn1');
      final zone2 = manager.get('btn2');

      expect(zone1, isNotNull);
      expect(zone2, isNotNull);
      expect(zone1!.startX, equals(0));
      expect(zone1.endX, equals(1)); // 'OK' ends at column 1
      expect(zone2!.startX, equals(3)); // 'Cancel' starts at column 3
      expect(zone2.endX, equals(8)); // 'Cancel' ends at column 8
    });

    test('scan handles zones across multiple lines', () {
      final line1 = manager.mark('line1', 'First');
      final line2 = manager.mark('line2', 'Second');
      final content = '$line1\n$line2';

      final scanned = manager.scan(content);
      expect(scanned, equals('First\nSecond'));

      final zone1 = manager.get('line1');
      final zone2 = manager.get('line2');

      expect(zone1, isNotNull);
      expect(zone2, isNotNull);
      expect(zone1!.startY, equals(0));
      expect(zone1.endY, equals(0));
      expect(zone2!.startY, equals(1));
      expect(zone2.endY, equals(1));
    });

    test('scan handles multiline zone content', () {
      final box = manager.mark('box', 'Line1\nLine2\nLine3');

      final scanned = manager.scan(box);
      expect(scanned, equals('Line1\nLine2\nLine3'));

      final zone = manager.get('box');
      expect(zone, isNotNull);
      expect(zone!.startY, equals(0));
      expect(zone.endY, equals(2)); // Spans 3 lines
    });

    test('get returns null for unknown zone', () {
      expect(manager.get('unknown'), isNull);
    });

    test('clear removes zone', () {
      final marked = manager.mark('test', 'Hello');
      manager.scan(marked);

      expect(manager.get('test'), isNotNull);

      manager.clear('test');
      expect(manager.get('test'), isNull);
    });

    test('newPrefix generates unique prefixes', () {
      final prefix1 = manager.newPrefix();
      final prefix2 = manager.newPrefix();
      final prefix3 = manager.newPrefix();

      expect(prefix1, isNot(equals(prefix2)));
      expect(prefix2, isNot(equals(prefix3)));
      expect(prefix1, isNot(equals(prefix3)));
    });

    test('findInBounds returns zones containing mouse position', () {
      final btn1 = manager.mark('btn1', 'Button1');
      final btn2 = manager.mark('btn2', 'Button2');
      final content = '$btn1\n$btn2';

      manager.scan(content);

      final msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 3,
        y: 0,
      );

      final zones = manager.findInBounds(msg);
      expect(zones.length, equals(1));
      expect(zones.first.id, equals('btn1'));
    });

    test('findInBounds returns multiple overlapping zones', () {
      // Create overlapping zones
      final outer = manager.mark('outer', 'AAABBBCCC');
      manager.scan(outer);

      // Now mark a subset
      manager = ZoneManager();
      final content = manager.mark('outer', manager.mark('inner', 'BBB'));
      manager.scan('AAA${content}CCC');

      // The inner zone should be found when clicking on 'BBB'
      final msg = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 4,
        y: 0,
      );

      final zones = manager.findInBounds(msg);
      // Should find the inner zone at least
      expect(zones.isNotEmpty, isTrue);
    });

    test('scan cleans up zones from previous iterations', () {
      // First scan with two zones
      final btn1 = manager.mark('btn1', 'Button1');
      final btn2 = manager.mark('btn2', 'Button2');
      manager.scan('$btn1 $btn2');

      expect(manager.get('btn1'), isNotNull);
      expect(manager.get('btn2'), isNotNull);

      // Second scan with only one zone
      final btnOnly = manager.mark('btn1', 'Button1');
      manager.scan(btnOnly);

      expect(manager.get('btn1'), isNotNull);
      expect(manager.get('btn2'), isNull); // Should be cleaned up
    });

    test('scan advances zone iteration monotonically across renders', () {
      final marked = manager.mark('btn', 'Button');

      manager.scan(marked);
      final first = manager.get('btn');
      expect(first, isNotNull);

      manager.scan(marked);
      final second = manager.get('btn');
      expect(second, isNotNull);

      expect(second!.iteration, greaterThan(first!.iteration));
      expect(second.iteration, equals(first.iteration + 1));
    });

    test('enabled property works correctly', () {
      expect(manager.enabled, isTrue);

      manager.enabled = false;
      expect(manager.enabled, isFalse);

      manager.enabled = true;
      expect(manager.enabled, isTrue);
    });

    test('disabling clears existing zones', () {
      final marked = manager.mark('test', 'Hello');
      manager.scan(marked);

      expect(manager.get('test'), isNotNull);

      manager.enabled = false;
      expect(manager.get('test'), isNull);
    });
  });

  group('ZoneInBoundsMsg', () {
    test('has correct properties', () {
      final zone = ZoneInfo(
        id: 'test',
        startX: 0,
        startY: 0,
        endX: 10,
        endY: 5,
      );
      final event = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 5,
        y: 2,
      );

      final msg = ZoneInBoundsMsg(zone: zone, event: event);

      expect(msg.zone, equals(zone));
      expect(msg.event, equals(event));
    });

    test('toString includes zone id', () {
      final zone = ZoneInfo(
        id: 'my-button',
        startX: 0,
        startY: 0,
        endX: 10,
        endY: 5,
      );
      final event = MouseMsg(
        action: MouseAction.press,
        button: MouseButton.left,
        x: 5,
        y: 2,
      );

      final msg = ZoneInBoundsMsg(zone: zone, event: event);

      expect(msg.toString(), contains('my-button'));
    });
  });

  group('Global zone manager', () {
    tearDown(() {
      closeGlobalZone();
    });

    test('initGlobalZone creates global instance', () {
      initGlobalZone();
      expect(() => zone, returnsNormally);
    });

    test('zone throws before initialization', () {
      expect(() => zone, throwsA(isA<StateError>()));
    });

    test('closeGlobalZone cleans up', () {
      initGlobalZone();
      closeGlobalZone();
      expect(() => zone, throwsA(isA<StateError>()));
    });

    test('initGlobalZone can be called multiple times', () {
      initGlobalZone();
      final first = zone;

      initGlobalZone();
      final second = zone;

      // Should be a new instance
      expect(identical(first, second), isFalse);
    });
  });

  group('ANSI handling', () {
    late ZoneManager manager;

    setUp(() {
      manager = ZoneManager();
    });

    tearDown(() {
      manager.close();
    });

    test('markers do not affect visible content', () {
      final marked = manager.mark('test', 'Hello World');
      final scanned = manager.scan(marked);

      expect(scanned, equals('Hello World'));
    });

    test('scan handles content with existing ANSI codes', () {
      // Content with color codes
      final colored = '\x1B[31mRed\x1B[0m';
      final marked = manager.mark('test', colored);
      final scanned = manager.scan(marked);

      // Should preserve the color codes
      expect(scanned, equals(colored));

      // Zone should still be tracked
      final zone = manager.get('test');
      expect(zone, isNotNull);
    });

    test('markers use private CSI sequences', () {
      final marked = manager.mark('test', 'Hello');

      // Should use 'z' as the terminator (private use)
      expect(marked, contains('z'));

      // Should follow format: ESC [ <number> z
      final pattern = RegExp(r'\x1B\[\d+z');
      expect(pattern.hasMatch(marked), isTrue);
    });
  });
}
