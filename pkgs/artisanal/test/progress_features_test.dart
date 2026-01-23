import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Progress Features', () {
    test('indeterminate mode', () {
      final progress = ProgressModel(width: 10, indeterminate: true);
      final view = progress.view();
      // Should contain some full and some empty characters
      expect(view, contains(progress.full));
      expect(view, contains(progress.empty));
      expect(Style.visibleLength(view), equals(10));
    });

    test('ETA calculation', () {
      final startTime = DateTime.now().subtract(const Duration(seconds: 10));
      final progress = ProgressModel(startTime: startTime, targetPercent: 0.5);

      // 10 seconds for 50% means 10 seconds remaining
      final eta = progress.eta;
      expect(eta, equals('00:10'));
    });

    test('ETA calculation at 100%', () {
      final startTime = DateTime.now().subtract(const Duration(seconds: 10));
      final progress = ProgressModel(startTime: startTime, targetPercent: 1.0);

      expect(progress.eta, equals('00:00'));
    });

    test('ETA calculation at 0%', () {
      final startTime = DateTime.now();
      final progress = ProgressModel(startTime: startTime, targetPercent: 0.0);

      expect(progress.eta, equals('--:--'));
    });

    test('MultiProgressModel', () {
      var multi = MultiProgressModel(width: 10).add('Task A').add('Task B');

      expect(multi.bars.length, equals(2));
      expect(multi.view(), contains('Task A:'));
      expect(multi.view(), contains('Task B:'));

      final (updated, cmd) = multi.setPercent('Task A', 0.5, animate: false);
      expect(updated.bars['Task A']!.percentShown, equals(0.5));
      expect(updated.bars['Task B']!.percentShown, equals(0.0));
    });
  });
}
