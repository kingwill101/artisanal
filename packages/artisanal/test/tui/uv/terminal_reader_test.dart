import 'dart:async';
import 'package:test/test.dart';
import 'package:artisanal/src/uv/uv.dart';

class MockCancelReader extends CancelReader {
  MockCancelReader(this.controller) : super(controller.stream);
  final StreamController<List<int>> controller;

  @override
  bool cancel() => true;

  @override
  Future<void> close() async {
    await controller.close();
  }
}

void main() {
  group('TerminalReader', () {
    late StreamController<List<int>> controller;
    late MockCancelReader mockReader;
    late TerminalReader reader;

    setUp(() {
      controller = StreamController<List<int>>();
      mockReader = MockCancelReader(controller);
      reader = TerminalReader(
        mockReader,
        escTimeout: Duration(milliseconds: 10),
      );
    });

    tearDown(() async {
      await reader.close();
    });

    test('decodes simple key', () async {
      reader.start();
      final eventFuture = reader.events.first;
      controller.add('a'.codeUnits);

      final result = await eventFuture;
      expect(result, isA<KeyPressEvent>());
      expect((result as KeyPressEvent).key().code, 'a'.codeUnitAt(0));
    });

    test('decodes ESC as escape key after timeout', () async {
      reader.start();
      final eventFuture = reader.events.first;
      controller.add([0x1b]); // ESC

      final result = await eventFuture;
      expect(result, isA<KeyPressEvent>());
      expect((result as KeyPressEvent).key().code, keyEscape);
    });

    test('decodes ESC + key as Alt+key', () async {
      reader.start();
      final eventFuture = reader.events.first;
      controller.add([0x1b, 'a'.codeUnitAt(0)]); // ESC a

      final result = await eventFuture;
      expect(result, isA<KeyPressEvent>());
      final key = (result as KeyPressEvent).key();
      expect(key.code, 'a'.codeUnitAt(0));
      expect(key.mod & KeyMod.alt, KeyMod.alt);
    });

    test('decodes CSI sequence', () async {
      reader.start();
      final eventFuture = reader.events.first;
      controller.add([0x1b, 0x5b, 0x41]); // ESC [ A (Up)

      final result = await eventFuture;
      expect(result, isA<KeyPressEvent>());
      expect((result as KeyPressEvent).key().code, keyUp);
    });

    test('decodes sequence from lookup table', () async {
      reader.start();
      final eventFuture = reader.events.first;
      // \x1b[Z is Shift+Tab in the table
      controller.add([0x1b, 0x5b, 0x5a]);

      final result = await eventFuture;
      expect(result, isA<KeyPressEvent>());
      final key = (result as KeyPressEvent).key();
      expect(key.code, keyTab);
      expect(key.mod & KeyMod.shift, KeyMod.shift);
    });
  });
}
