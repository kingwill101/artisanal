import 'dart:async';

import 'package:artisanal/src/terminal/ansi.dart' show Ansi;
import 'package:artisanal/src/tui/bubbles/components/progress_bar.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('ProgressBarModel', () {
    test('ignores messages for other ids', () {
      final a = ProgressBarModel(id: 1, total: 10);
      final (updated, _) = a.update(
        const ProgressBarSetMsg(id: 2, current: 5, total: 10),
      );
      expect(updated, same(a));
      expect(a.current, 0);
    });

    test('updates on set and advance', () {
      final model = ProgressBarModel(id: 1, total: 3);
      final (m1, _) = model.update(
        const ProgressBarSetMsg(id: 1, current: 1, total: 3),
      );
      final (m2, _) = m1.update(const ProgressBarAdvanceMsg(id: 1, step: 1));

      final view = Ansi.stripAnsi(m2.view().toString());
      expect(view, contains('2/3'));
      expect(view, contains('67%'));
    });
  });

  group('progressIterateCmd', () {
    test('emits progress updates and done', () async {
      final calls = <int>[];
      final model = ProgressBarModel(id: 42);

      final done = Completer<void>();
      final received = <Msg>[];

      final cmd = progressIterateCmd<int>(
        id: model.id,
        items: const [1, 2, 3],
        onItem: (i) async {
          calls.add(i);
        },
      );

      cmd.start((msg) {
        received.add(msg);
        if (msg is ProgressBarIterateDoneMsg && !done.isCompleted) {
          done.complete();
        }
      });

      await done.future.timeout(const Duration(seconds: 2));

      var current = model as ViewComponent;
      for (final msg in received) {
        final (next, _) = current.update(msg);
        current = next;
      }

      expect(calls, [1, 2, 3]);
      final view = Ansi.stripAnsi(current.view().toString());
      expect(view, contains('3/3'));
      expect(view, contains('100%'));
    });
  });
}
