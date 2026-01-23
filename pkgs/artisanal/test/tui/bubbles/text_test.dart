import 'package:artisanal/src/tui/bubbles/text.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('TextModel', () {
    test('creates with content', () {
      final text = TextModel('Hello World');
      expect(text.view(), contains('Hello World'));
    });

    test('auto-height by default', () {
      final text = TextModel('Line 1\nLine 2\nLine 3');
      // Viewport with null height should render all lines
      final view = text.view();
      expect(view, contains('Line 1'));
      expect(view, contains('Line 2'));
      expect(view, contains('Line 3'));
    });

    test('selection works', () {
      final text = TextModel('Hello World');
      // Press at (0, 0)
      var (v1, _) = text.update(
        const MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 0,
          y: 0,
        ),
      );
      // Drag to (5, 0)
      var (v2, _) = v1.update(
        const MouseMsg(
          action: MouseAction.motion,
          button: MouseButton.left,
          x: 5,
          y: 0,
        ),
      );
      expect(v2.getSelectedText(), equals('Hello'));
    });

    test('double click selects word', () {
      final text = TextModel('Hello World');
      // Click inside "Hello"
      var (v1, _) = text.update(
        const MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 2,
          y: 0,
        ),
      );
      var (v2, _) = v1.update(
        const MouseMsg(
          action: MouseAction.press,
          button: MouseButton.left,
          x: 2,
          y: 0,
        ),
      );
      expect(v2.getSelectedText(), equals('Hello'));
    });
  });
}
