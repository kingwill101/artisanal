import 'package:artisanal/src/tui/bubbles/pause.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('CountdownModel', () {
    test('start command uses custom nowProvider', () async {
      final expected = DateTime.fromMillisecondsSinceEpoch(20000, isUtc: true);
      final countdown = CountdownModel(
        duration: const Duration(seconds: 3),
        nowProvider: () => expected,
      );

      final msg = await countdown.init()!.execute() as TickMsg;
      expect(msg.time, equals(expected));
      expect(msg.id, equals('countdown:start'));
    });

    test('scheduled tick command uses custom nowProvider', () async {
      final expected = DateTime.fromMillisecondsSinceEpoch(21000, isUtc: true);
      final countdown = CountdownModel(
        duration: const Duration(seconds: 3),
        interval: const Duration(seconds: 1),
        nowProvider: () => expected,
      );

      final (_, cmd) = countdown.update(
        TickMsg(expected, id: 'countdown:start'),
      );
      final msg = await cmd!.execute() as TickMsg;
      expect(msg.time, equals(expected));
      expect(msg.id, equals('countdown:tick'));
    });
  });
}
