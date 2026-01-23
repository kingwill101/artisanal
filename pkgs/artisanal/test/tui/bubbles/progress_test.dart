import 'package:artisanal/src/tui/bubbles/progress.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:test/test.dart';

void main() {
  group('ProgressModel', () {
    group('New', () {
      test('creates with default values', () {
        final progress = ProgressModel();
        expect(progress.width, 40);
        expect(progress.full, '▌');
        expect(progress.empty, '░');
        expect(progress.showPercentage, isTrue);
        expect(progress.percent, 0);
      });

      test('creates with custom width', () {
        final progress = ProgressModel(width: 60);
        expect(progress.width, 60);
      });

      test('creates with custom characters', () {
        final progress = ProgressModel(full: '#', empty: '-');
        expect(progress.full, '#');
        expect(progress.empty, '-');
      });

      test('creates with gradient enabled', () {
        final progress = ProgressModel(
          useGradient: true,
          gradientColorA: '#FF0000',
          gradientColorB: '#00FF00',
        );
        expect(progress.useGradient, isTrue);
        expect(progress.gradientColorA, '#FF0000');
        expect(progress.gradientColorB, '#00FF00');
      });

      test('each model gets unique ID', () {
        final progress1 = ProgressModel();
        final progress2 = ProgressModel();
        expect(progress1.id, isNot(progress2.id));
      });

      test('starts at 0 percent', () {
        final progress = ProgressModel();
        expect(progress.percent, 0);
        expect(progress.percentShown, 0);
      });
    });

    group('SetPercent', () {
      test('sets target percentage', () {
        final progress = ProgressModel();
        final (updated, _) = progress.setPercent(0.5);
        expect(updated.percent, 0.5);
      });

      test('clamps to 0-1 range', () {
        final progress = ProgressModel();
        final (low, _) = progress.setPercent(-0.5);
        expect(low.percent, 0);

        final (high, _) = progress.setPercent(1.5);
        expect(high.percent, 1);
      });

      test('returns animation command', () {
        final progress = ProgressModel();
        final (_, cmd) = progress.setPercent(0.5);
        expect(cmd, isNotNull);
      });
    });

    group('IncrPercent', () {
      test('increments percentage', () {
        final progress = ProgressModel();
        final (first, _) = progress.setPercent(0.3);
        final (updated, _) = first.incrPercent(0.2);
        expect(updated.percent, 0.5);
      });

      test('clamps to max 1.0', () {
        final progress = ProgressModel();
        final (first, _) = progress.setPercent(0.8);
        final (updated, _) = first.incrPercent(0.5);
        expect(updated.percent, 1.0);
      });
    });

    group('DecrPercent', () {
      test('decrements percentage', () {
        final progress = ProgressModel();
        final (first, _) = progress.setPercent(0.5);
        final (updated, _) = first.decrPercent(0.2);
        expect(updated.percent, 0.3);
      });

      test('clamps to min 0.0', () {
        final progress = ProgressModel();
        final (first, _) = progress.setPercent(0.2);
        final (updated, _) = first.decrPercent(0.5);
        expect(updated.percent, 0.0);
      });
    });

    group('ViewAs', () {
      test('renders 0% progress', () {
        final progress = ProgressModel(width: 15, showPercentage: true);
        final view = progress.viewAs(0.0);
        // Should contain percentage display
        expect(view, contains('0'));
        expect(view, contains('%'));
      });

      test('renders 50% progress', () {
        final progress = ProgressModel(width: 15, showPercentage: true);
        final view = progress.viewAs(0.5);
        expect(view, contains('50'));
        expect(view, contains('%'));
      });

      test('renders 100% progress', () {
        final progress = ProgressModel(width: 15, showPercentage: true);
        final view = progress.viewAs(1.0);
        expect(view, contains('100'));
        expect(view, contains('%'));
      });

      test('renders without percentage when disabled', () {
        final progress = ProgressModel(width: 10, showPercentage: false);
        final view = progress.viewAs(0.5);
        expect(view, isNot(contains('%')));
      });
    });

    group('View', () {
      test('renders current percent shown', () {
        final progress = ProgressModel(
          width: 15,
          showPercentage: true,
          percentShown: 0.5,
          targetPercent: 0.5,
        );
        final view = progress.view();
        expect(view, isNotEmpty);
      });
    });

    group('Update', () {
      test('ignores non-progress messages', () {
        final progress = ProgressModel();
        final (updated, cmd) = progress.update(_MockMsg());
        expect(updated, progress);
        expect(cmd, isNull);
      });

      test('ignores messages for other progress bars', () {
        final progress = ProgressModel();
        final (first, _) = progress.setPercent(0.5);
        final msg = ProgressFrameMsg(id: first.id + 999, tag: 0);
        final (updated, cmd) = first.update(msg);
        expect(updated, first);
        expect(cmd, isNull);
      });

      test('updates animation on valid frame message', () {
        final progress = ProgressModel();
        final (first, _) = progress.setPercent(0.5);
        final msg = ProgressFrameMsg(id: first.id, tag: 0);
        // Since percentShown starts at 0 and target is 0.5, it should animate
        final (updated, cmd) = first.update(msg);
        // Animation command may or may not be returned depending on state
        expect(updated, isNotNull);
      });
    });

    group('IsAnimating', () {
      test('returns false when at equilibrium', () {
        final progress = ProgressModel(
          percentShown: 0.5,
          targetPercent: 0.5,
          velocity: 0,
        );
        expect(progress.isAnimating, isFalse);
      });

      test('returns true when not at equilibrium', () {
        final progress = ProgressModel(percentShown: 0.0, targetPercent: 0.5);
        expect(progress.isAnimating, isTrue);
      });
    });

    group('CopyWith', () {
      test('creates copy with changed width', () {
        final progress = ProgressModel(width: 40);
        final copy = progress.copyWith(width: 60);
        expect(copy.width, 60);
        expect(progress.width, 40);
      });

      test('creates copy with changed characters', () {
        final progress = ProgressModel(full: '█', empty: '░');
        final copy = progress.copyWith(full: '#', empty: '-');
        expect(copy.full, '#');
        expect(copy.empty, '-');
      });

      test('preserves ID on copy', () {
        final progress = ProgressModel();
        final copy = progress.copyWith(width: 50);
        expect(copy.id, progress.id);
      });
    });

    group('Init', () {
      test('returns null', () {
        final progress = ProgressModel();
        expect(progress.init(), isNull);
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final progress = ProgressModel();
      ViewComponent model = progress;
      final msg = ProgressFrameMsg(id: progress.id, tag: 0);
      final (updated, _) = model.update(msg);
      expect(updated, isA<ProgressModel>());
    });

    group('Gradient', () {
      test('renders with gradient when enabled', () {
        final progress = ProgressModel(
          width: 15,
          useGradient: true,
          gradientColorA: '#FF0000',
          gradientColorB: '#00FF00',
          showPercentage: false,
        );
        final view = progress.viewAs(0.5);
        // Gradient view should contain styled output
        expect(view, isNotEmpty);
      });

      test('scaled gradient affects rendering', () {
        final scaled = ProgressModel(
          width: 15,
          useGradient: true,
          scaleGradient: true,
          showPercentage: false,
        );
        final unscaled = ProgressModel(
          width: 15,
          useGradient: true,
          scaleGradient: false,
          showPercentage: false,
        );
        // Both should render but potentially with different gradient distributions
        final scaledView = scaled.viewAs(0.5);
        final unscaledView = unscaled.viewAs(0.5);
        expect(scaledView, isNotEmpty);
        expect(unscaledView, isNotEmpty);
      });
    });

    group('Parity Features', () {
      test('blend colors', () {
        final progress = ProgressModel(
          width: 20,
          blend: ['#FF0000', '#00FF00', '#0000FF'],
          showPercentage: false,
        );
        final view = progress.viewAs(0.5);
        expect(view, isNotEmpty);
      });

      test('colorFunc', () {
        final progress = ProgressModel(
          width: 20,
          colorFunc: (p, current) => const AnsiColor(212),
          showPercentage: false,
        );
        final view = progress.viewAs(0.5);
        expect(view, isNotEmpty);
      });

      test('half-block rendering', () {
        final progress = ProgressModel(
          width: 20,
          full: '▌',
          blend: ['#FF0000', '#00FF00'],
          showPercentage: false,
        );
        final view = progress.viewAs(0.5);
        expect(view, isNotEmpty);
      });

      test('spring tuning', () {
        final progress = ProgressModel(frequency: 5.0, damping: 0.5);
        expect(progress.frequency, 5.0);
        expect(progress.damping, 0.5);
      });
    });
  });

  group('ProgressFrameMsg', () {
    test('creates with id and tag', () {
      final msg = ProgressFrameMsg(id: 1, tag: 2);
      expect(msg.id, 1);
      expect(msg.tag, 2);
    });
  });
}

class _MockMsg implements Msg {}
