import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/tui/bubbles/progress.dart';
import 'package:test/test.dart';

void main() {
  group('Progress parity', () {
    test('setPercent without animation jumps immediately', () {
      final model = ProgressModel();
      final (next, cmd) = model.setPercent(0.5, animate: false);
      expect(cmd, isNull);
      expect(next.percentShown, closeTo(0.5, 1e-6));
    });

    test('animated progress advances smoothly, not all at once', () {
      final model = ProgressModel();
      final (targeted, cmd) = model.setPercent(1.0);
      expect(cmd, isNotNull);
      expect(targeted.percentShown, closeTo(0, 1e-6));

      final msg = ProgressFrameMsg(id: targeted.id, tag: targeted.tag);
      final (advanced, _) = targeted.update(msg);
      final progressed = advanced;

      expect(progressed.percentShown, greaterThan(0));
      expect(progressed.percentShown, lessThan(1));
    });

    test('ColorFunc overrides static colors', () {
      final model = ProgressModel(
        width: 10,
        full: '█',
        colorFunc: (total, current) => BasicColor('#FF0000'),
      );
      final view = model.viewAs(0.5);
      // Should contain red color code (38;2;255;0;0)
      expect(view, contains('255;0;0'));
    });

    test('High-resolution blending with half-block', () {
      final model = ProgressModel(
        width: 10,
        full: defaultFullCharHalfBlock,
        blend: ['#FF0000', '#0000FF'],
      );
      final view = model.viewAs(0.5);
      // Should contain both foreground and background colors for the half-block
      // FG: 255;0;0, BG: some interpolation
      expect(view, contains('255;0;0'));
      expect(view, contains('\x1b[48;2;')); // Background color escape
    });

    test('Multi-color blend interpolation', () {
      final model = ProgressModel(
        width: 10,
        full: '█',
        blend: ['#FF0000', '#00FF00', '#0000FF'],
      );
      final view = model.viewAs(1.0);
      // Start should be red, end should be blue
      expect(view, contains('255;0;0'));
      expect(view, contains('0;0;255'));
    });
  });
}
