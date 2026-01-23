import 'dart:async';
import 'package:test/test.dart';
import 'package:artisanal/src/uv/uv.dart';

void main() {
  group('CancelReader', () {
    test('reads data from source', () async {
      final controller = StreamController<List<int>>();
      final reader = CancelReader(controller.stream);

      final received = <int>[];
      reader.stream.listen((data) => received.addAll(data));
      reader.start();

      controller.add([1, 2, 3]);
      await Future.delayed(Duration.zero);
      expect(received, equals([1, 2, 3]));

      controller.add([4, 5]);
      await Future.delayed(Duration.zero);
      expect(received, equals([1, 2, 3, 4, 5]));

      await reader.close();
      await controller.close();
    });

    test('cancel stops reading', () async {
      final controller = StreamController<List<int>>();
      final reader = CancelReader(controller.stream);

      final received = <int>[];
      reader.stream.listen((data) => received.addAll(data));
      reader.start();

      controller.add([1, 2]);
      await Future.delayed(Duration.zero);
      expect(received, equals([1, 2]));

      reader.cancel();
      controller.add([3, 4]);
      await Future.delayed(Duration.zero);

      // Should not have received [3, 4]
      expect(received, equals([1, 2]));

      await reader.close();
      await controller.close();
    });

    test('isCanceled reflects state', () {
      final controller = StreamController<List<int>>();
      final reader = CancelReader(controller.stream);

      expect(reader.isCanceled, isFalse);
      reader.cancel();
      expect(reader.isCanceled, isTrue);
    });
  });
}
