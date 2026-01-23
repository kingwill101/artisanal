import 'package:artisanal/src/tui/bubbles/spinner.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/msg.dart' show Msg;
import 'package:test/test.dart';

void main() {
  group('Spinner', () {
    test('creates with frames and fps', () {
      final spinner = Spinner(
        frames: ['a', 'b', 'c'],
        fps: Duration(milliseconds: 100),
      );
      expect(spinner.frames, ['a', 'b', 'c']);
      expect(spinner.fps, Duration(milliseconds: 100));
    });

    test('default fps is 100ms', () {
      final spinner = Spinner(frames: ['a', 'b']);
      expect(spinner.fps, Duration(milliseconds: 100));
    });
  });

  group('Spinners', () {
    test('line spinner has correct frames', () {
      expect(Spinners.line.frames, ['|', '/', '-', '\\']);
    });

    test('dot spinner has braille frames', () {
      expect(Spinners.dot.frames, hasLength(8));
      expect(Spinners.dot.frames.first, '⣾');
    });

    test('miniDot spinner has mini braille frames', () {
      expect(Spinners.miniDot.frames, hasLength(10));
      expect(Spinners.miniDot.frames.first, '⠋');
    });

    test('jump spinner has frames', () {
      expect(Spinners.jump.frames, hasLength(7));
    });

    test('pulse spinner has gradient frames', () {
      expect(Spinners.pulse.frames, ['█', '▓', '▒', '░']);
    });

    test('points spinner has growing dots', () {
      expect(Spinners.points.frames, ['∙∙∙', '●∙∙', '∙●∙', '∙∙●']);
    });

    test('globe spinner has earth emoji', () {
      expect(Spinners.globe.frames, ['🌍', '🌎', '🌏']);
    });

    test('moon spinner has moon phases', () {
      expect(Spinners.moon.frames, hasLength(8));
    });

    test('monkey spinner has monkeys', () {
      expect(Spinners.monkey.frames, ['🙈', '🙉', '🙊']);
    });

    test('meter spinner has progress bar', () {
      expect(Spinners.meter.frames, hasLength(7));
    });

    test('hamburger spinner has trigrams', () {
      expect(Spinners.hamburger.frames, hasLength(4));
    });

    test('ellipsis spinner has dots', () {
      expect(Spinners.ellipsis.frames, ['', '.', '..', '...']);
    });

    test('growDots spinner has moving dots', () {
      expect(Spinners.growDots.frames, hasLength(6));
    });

    test('circle spinner has circle quarters', () {
      expect(Spinners.circle.frames, ['◐', '◓', '◑', '◒']);
    });

    test('arc spinner has arc segments', () {
      expect(Spinners.arc.frames, hasLength(6));
    });

    test('bounce spinner has bouncing dot', () {
      expect(Spinners.bounce.frames, hasLength(4));
    });

    test('arrows spinner has all directions', () {
      expect(Spinners.arrows.frames, hasLength(8));
    });

    test('clock spinner has clock faces', () {
      expect(Spinners.clock.frames, hasLength(12));
    });
  });

  group('SpinnerModel', () {
    group('New', () {
      test('creates with default spinner', () {
        final model = SpinnerModel();
        expect(model.spinner, Spinners.line);
        expect(model.frame, 0);
      });

      test('creates with custom spinner', () {
        final model = SpinnerModel(spinner: Spinners.dot);
        expect(model.spinner, Spinners.dot);
      });

      test('creates with initial frame', () {
        final model = SpinnerModel(frame: 2);
        expect(model.frame, 2);
      });

      test('each model gets unique ID', () {
        final model1 = SpinnerModel();
        final model2 = SpinnerModel();
        expect(model1.id, isNot(model2.id));
      });
    });

    group('View', () {
      test('returns current frame', () {
        final model = SpinnerModel(spinner: Spinners.line, frame: 0);
        expect(model.view(), '|');
      });

      test('returns correct frame for index', () {
        final model = SpinnerModel(spinner: Spinners.line, frame: 1);
        expect(model.view(), '/');
      });

      test('returns error for out of bounds frame', () {
        final model = SpinnerModel(spinner: Spinners.line, frame: 100);
        expect(model.view(), '(error)');
      });
    });

    group('Update', () {
      test('ignores non-spinner messages', () {
        final model = SpinnerModel();
        final (newModel, cmd) = model.update(MockMsg());
        expect(newModel, model);
        expect(cmd, isNull);
      });

      test('advances frame on tick', () {
        final model = SpinnerModel(spinner: Spinners.line, frame: 0);
        final tickMsg = SpinnerTickMsg(
          time: DateTime.now(),
          id: model.id,
          tag: 0,
        );
        final (newModel, _) = model.update(tickMsg);
        expect((newModel).frame, 1);
      });

      test('wraps frame at end of animation', () {
        final model = SpinnerModel(
          spinner: Spinners.line, // 4 frames
          frame: 3,
        );
        final tickMsg = SpinnerTickMsg(
          time: DateTime.now(),
          id: model.id,
          tag: 0,
        );
        final (newModel, _) = model.update(tickMsg);
        expect((newModel).frame, 0);
      });

      test('ignores tick for different spinner ID', () {
        final model = SpinnerModel();
        final tickMsg = SpinnerTickMsg(
          time: DateTime.now(),
          id: model.id + 999,
          tag: 0,
        );
        final (newModel, cmd) = model.update(tickMsg);
        expect(newModel, model);
        expect(cmd, isNull);
      });

      test('returns tick command for next frame', () {
        final model = SpinnerModel();
        final tickMsg = SpinnerTickMsg(
          time: DateTime.now(),
          id: model.id,
          tag: 0,
        );
        final (_, cmd) = model.update(tickMsg);
        expect(cmd, isNotNull);
      });
    });

    group('CopyWith', () {
      test('creates copy with new spinner', () {
        final model = SpinnerModel(spinner: Spinners.line);
        final copy = model.copyWith(spinner: Spinners.dot);
        expect(copy.spinner, Spinners.dot);
        expect(model.spinner, Spinners.line);
      });

      test('creates copy with new frame', () {
        final model = SpinnerModel(frame: 0);
        final copy = model.copyWith(frame: 5);
        expect(copy.frame, 5);
        expect(model.frame, 0);
      });

      test('preserves ID on copy', () {
        final model = SpinnerModel();
        final copy = model.copyWith(frame: 1);
        expect(copy.id, model.id);
      });
    });

    group('Init', () {
      test('returns null', () {
        final model = SpinnerModel();
        expect(model.init(), isNull);
      });
    });

    group('Tick', () {
      test('returns command', () {
        final model = SpinnerModel();
        expect(model.tick(), isNotNull);
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final spinner = SpinnerModel(spinner: Spinners.line, frame: 0);
      ViewComponent model = spinner;
      final tickMsg = SpinnerTickMsg(
        time: DateTime.now(),
        id: spinner.id,
        tag: 0,
      );
      final (updated, _) = model.update(tickMsg);
      expect(updated, isA<SpinnerModel>());
    });
  });

  group('SpinnerTickMsg', () {
    test('creates with time, id, and tag', () {
      final time = DateTime.now();
      final msg = SpinnerTickMsg(time: time, id: 1, tag: 2);
      expect(msg.time, time);
      expect(msg.id, 1);
      expect(msg.tag, 2);
    });
  });
}

/// Mock message for testing non-spinner message handling.
class MockMsg implements Msg {}
