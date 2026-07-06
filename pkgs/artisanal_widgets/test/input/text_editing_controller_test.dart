import 'package:artisanal/bubbles.dart' show TextInputModel;
import 'package:artisanal/terminal.dart' show Key, KeyType;
import 'package:artisanal/artisanal.dart' hide TextSelection;
import 'package:artisanal/tui.dart' show KeyMsg;
import 'package:artisanal_widgets/artisanal_widgets.dart' hide Key;
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // TextEditingController unit tests (no widget needed)
  // ---------------------------------------------------------------------------
  group('TextEditingController', () {
    test('initial value is empty', () {
      final ctrl = TextEditingController();
      expect(ctrl.text, isEmpty);
      expect(ctrl.value, equals(const TextEditingValue()));
      expect(ctrl.selection.isCollapsed, isTrue);
      expect(ctrl.selection.baseOffset, 0);
    });

    test('creates with initial text', () {
      final ctrl = TextEditingController(text: 'hello');
      expect(ctrl.text, 'hello');
      expect(ctrl.value.text, 'hello');
      // Cursor should be at end of text
      expect(ctrl.selection.extentOffset, 5);
    });

    test('setting text updates value and notifies', () {
      final ctrl = TextEditingController();
      var notified = false;
      ctrl.addListener(() => notified = true);

      ctrl.text = 'world';
      expect(notified, isTrue);
      expect(ctrl.text, 'world');
      expect(ctrl.value.text, 'world');
      // Selection collapses to end when text is set
      expect(ctrl.selection.isCollapsed, isTrue);
      expect(ctrl.selection.baseOffset, 5);
    });

    test('setting same text does not notify', () {
      final ctrl = TextEditingController(text: 'abc');
      var count = 0;
      ctrl.addListener(() => count++);

      ctrl.text = 'abc';
      expect(count, 0);
    });

    test('setting selection updates model and notifies', () {
      final ctrl = TextEditingController(text: 'hello');
      var notified = false;
      ctrl.addListener(() => notified = true);

      ctrl.selection = const TextSelection(baseOffset: 1, extentOffset: 3);
      expect(notified, isTrue);
      expect(ctrl.selection.baseOffset, 1);
      expect(ctrl.selection.extentOffset, 3);
      expect(ctrl.selection.isCollapsed, isFalse);
      expect(ctrl.selection.start, 1);
      expect(ctrl.selection.end, 3);
    });

    test('setting collapsed selection clears model selection', () {
      final ctrl = TextEditingController(text: 'hello');
      // First set a selection
      ctrl.selection = const TextSelection(baseOffset: 1, extentOffset: 3);
      expect(ctrl.model.selectionStart, 1);
      expect(ctrl.model.selectionEnd, 3);

      // Now collapse it
      ctrl.selection = const TextSelection.collapsed(offset: 2);
      expect(ctrl.model.selectionStart, isNull);
      expect(ctrl.model.selectionEnd, isNull);
      expect(ctrl.model.position, 2);
    });

    test('setting same selection does not notify', () {
      final ctrl = TextEditingController(text: 'hello');
      ctrl.selection = const TextSelection(baseOffset: 1, extentOffset: 3);
      var count = 0;
      ctrl.addListener(() => count++);

      ctrl.selection = const TextSelection(baseOffset: 1, extentOffset: 3);
      expect(count, 0);
    });

    test('value setter updates text and selection', () {
      final ctrl = TextEditingController();
      var notified = false;
      ctrl.addListener(() => notified = true);

      ctrl.value = const TextEditingValue(
        text: 'hello',
        selection: TextSelection(baseOffset: 2, extentOffset: 4),
      );

      expect(notified, isTrue);
      expect(ctrl.text, 'hello');
      expect(ctrl.selection.baseOffset, 2);
      expect(ctrl.selection.extentOffset, 4);
    });

    test('clear resets to empty', () {
      final ctrl = TextEditingController(text: 'hello');
      ctrl.selection = const TextSelection(baseOffset: 1, extentOffset: 3);

      ctrl.clear();
      expect(ctrl.text, isEmpty);
      expect(ctrl.selection.isCollapsed, isTrue);
      expect(ctrl.selection.baseOffset, 0);
    });

    test('undo and redo track programmatic text changes', () {
      final ctrl = TextEditingController();

      ctrl.text = 'hello';
      ctrl.text = 'hello world';

      expect(ctrl.canUndo, isTrue);
      expect(ctrl.undo(), isTrue);
      expect(ctrl.text, 'hello');
      expect(ctrl.canRedo, isTrue);
      expect(ctrl.redo(), isTrue);
      expect(ctrl.text, 'hello world');
    });

    test('setting value participates in undo history', () {
      final ctrl = TextEditingController(text: 'hello');

      ctrl.value = const TextEditingValue(
        text: 'world',
        selection: TextSelection(baseOffset: 1, extentOffset: 3),
      );

      expect(ctrl.undo(), isTrue);
      expect(ctrl.text, 'hello');
      expect(ctrl.selection.baseOffset, 5);
      expect(ctrl.selection.extentOffset, 5);
    });

    test('programmatic edit helpers mutate text and selection', () {
      final ctrl = TextEditingController(text: 'hello world');

      ctrl.selection = const TextSelection(baseOffset: 6, extentOffset: 11);
      ctrl.replaceSelection('dart');
      expect(ctrl.text, 'hello dart');

      ctrl.selection = const TextSelection.collapsed(offset: 5);
      ctrl.insertText(' amazing');
      expect(ctrl.text, 'hello amazing dart');

      expect(ctrl.deleteBackward(word: true), isTrue);
      expect(ctrl.text, 'hello  dart');
    });

    test('pushHistoryBoundary splits programmatic coalesced inserts', () {
      final ctrl = TextEditingController();

      ctrl.insertText('a', coalesce: true);
      ctrl.insertText('b', coalesce: true);
      ctrl.pushHistoryBoundary();
      ctrl.insertText('c', coalesce: true);

      expect(ctrl.text, 'abc');
      expect(ctrl.undo(), isTrue);
      expect(ctrl.text, 'ab');
      expect(ctrl.undo(), isTrue);
      expect(ctrl.text, isEmpty);
    });

    test('selectAll selects entire text', () {
      final ctrl = TextEditingController(text: 'hello world');
      var notified = false;
      ctrl.addListener(() => notified = true);

      ctrl.selectAll();
      expect(notified, isTrue);
      expect(ctrl.model.selectionStart, 0);
      expect(ctrl.model.selectionEnd, 11);
      expect(ctrl.model.position, 11);
    });

    test('model getter returns underlying model', () {
      final model = TextInputModel(prompt: 'Q: ');
      final ctrl = TextEditingController(model: model);
      expect(ctrl.model, same(model));
    });

    test('model setter swaps model and notifies', () {
      final ctrl = TextEditingController(text: 'old');
      final newModel = TextInputModel();
      newModel.value = 'new';

      var notified = false;
      ctrl.addListener(() => notified = true);

      ctrl.model = newModel;
      expect(notified, isTrue);
      expect(ctrl.text, 'new');
      expect(ctrl.model, same(newModel));
    });

    test('model setter does not notify for same model', () {
      final ctrl = TextEditingController(text: 'hello');
      final model = ctrl.model;
      var count = 0;
      ctrl.addListener(() => count++);

      ctrl.model = model;
      expect(count, 0);
    });

    test('implements ValueListenable<TextEditingValue>', () {
      final ctrl = TextEditingController(text: 'test');
      // Should be usable as ValueListenable
      final ValueListenable<TextEditingValue> listenable = ctrl;
      expect(listenable.value.text, 'test');
    });

    test('dispose removes all listeners', () {
      final ctrl = TextEditingController();
      var count = 0;
      ctrl.addListener(() => count++);

      ctrl.dispose();
      // After dispose, notifyListeners should not call listeners
      // (ChangeNotifier clears _listeners on dispose)
    });
  });

  // ---------------------------------------------------------------------------
  // TextSelection unit tests
  // ---------------------------------------------------------------------------
  group('TextSelection', () {
    test('collapsed has equal offsets', () {
      const sel = TextSelection.collapsed(offset: 3);
      expect(sel.baseOffset, 3);
      expect(sel.extentOffset, 3);
      expect(sel.isCollapsed, isTrue);
      expect(sel.start, 3);
      expect(sel.end, 3);
    });

    test('forward selection', () {
      const sel = TextSelection(baseOffset: 2, extentOffset: 5);
      expect(sel.isCollapsed, isFalse);
      expect(sel.start, 2);
      expect(sel.end, 5);
    });

    test('backward selection normalizes start/end', () {
      const sel = TextSelection(baseOffset: 5, extentOffset: 2);
      expect(sel.isCollapsed, isFalse);
      expect(sel.start, 2);
      expect(sel.end, 5);
    });

    test('equality', () {
      const a = TextSelection(baseOffset: 1, extentOffset: 3);
      const b = TextSelection(baseOffset: 1, extentOffset: 3);
      const c = TextSelection(baseOffset: 1, extentOffset: 4);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith', () {
      const sel = TextSelection(baseOffset: 1, extentOffset: 3);
      final copied = sel.copyWith(extentOffset: 5);
      expect(copied.baseOffset, 1);
      expect(copied.extentOffset, 5);
    });
  });

  // ---------------------------------------------------------------------------
  // TextEditingValue unit tests
  // ---------------------------------------------------------------------------
  group('TextEditingValue', () {
    test('empty constant', () {
      expect(TextEditingValue.empty.text, isEmpty);
      expect(TextEditingValue.empty.selection.isCollapsed, isTrue);
      expect(TextEditingValue.empty.selection.baseOffset, 0);
    });

    test('equality', () {
      const a = TextEditingValue(
        text: 'hi',
        selection: TextSelection.collapsed(offset: 2),
      );
      const b = TextEditingValue(
        text: 'hi',
        selection: TextSelection.collapsed(offset: 2),
      );
      const c = TextEditingValue(
        text: 'hi',
        selection: TextSelection.collapsed(offset: 1),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // ---------------------------------------------------------------------------
  // Controller <-> TextField widget integration
  // ---------------------------------------------------------------------------
  group('TextEditingController with TextField widget', () {
    test('keyboard selection updates controller.selection', () async {
      final tester = WidgetTester();
      try {
        final controller = TextEditingController(text: 'hello');

        await tester.pumpWidget(
          FocusScope(child: TextField(controller: controller, autofocus: true)),
        );

        // Move to start
        tester.sendSpecialKey(KeyType.home);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 0);

        // Shift+Right selects 'h'
        tester.sendMsg(KeyMsg(const Key(KeyType.right, shift: true)));
        expect(controller.selection.isCollapsed, isFalse);
        // selectionStart is 0 (anchor), selectionEnd is 1 (extent)
        expect(controller.model.selectionStart, 0);
        expect(controller.model.selectionEnd, 1);
        expect(controller.model.position, 1);
      } finally {
        await tester.dispose();
      }
    });

    test('programmatic selection reflects in controller.value', () async {
      final tester = WidgetTester();
      try {
        final controller = TextEditingController(text: 'hello world');

        await tester.pumpWidget(
          FocusScope(child: TextField(controller: controller, autofocus: true)),
        );

        // Programmatically select "world"
        controller.selection = const TextSelection(
          baseOffset: 6,
          extentOffset: 11,
        );

        expect(controller.value.text, 'hello world');
        expect(controller.value.selection.baseOffset, 6);
        expect(controller.value.selection.extentOffset, 11);
        expect(controller.model.selectionStart, 6);
        expect(controller.model.selectionEnd, 11);
        expect(controller.model.position, 11);
      } finally {
        await tester.dispose();
      }
    });

    test(
      'typing after programmatic selection replaces selected text',
      () async {
        final tester = WidgetTester();
        try {
          final controller = TextEditingController(text: 'hello world');

          await tester.pumpWidget(
            FocusScope(
              child: TextField(controller: controller, autofocus: true),
            ),
          );

          // Select "hello"
          controller.selection = const TextSelection(
            baseOffset: 0,
            extentOffset: 5,
          );

          // Type replacement
          tester.sendKey('H');
          tester.sendKey('i');
          expect(controller.text, 'Hi world');
        } finally {
          await tester.dispose();
        }
      },
    );

    test('controller.value reflects keyboard input', () async {
      final tester = WidgetTester();
      try {
        final controller = TextEditingController();

        await tester.pumpWidget(
          FocusScope(child: TextField(controller: controller, autofocus: true)),
        );

        tester.sendKey('a');
        tester.sendKey('b');

        // The controller's value should reflect the updated model state
        expect(controller.text, 'ab');
        expect(controller.value.text, 'ab');
      } finally {
        await tester.dispose();
      }
    });

    test('programmatic text change notifies listeners', () {
      final controller = TextEditingController(text: 'old');
      final values = <TextEditingValue>[];
      controller.addListener(() => values.add(controller.value));

      controller.text = 'new';
      expect(values.length, 1);
      expect(values.last.text, 'new');
    });

    test('selectAll via controller then type replaces all', () async {
      final tester = WidgetTester();
      try {
        final controller = TextEditingController(text: 'old text');

        await tester.pumpWidget(
          FocusScope(child: TextField(controller: controller, autofocus: true)),
        );

        controller.selectAll();
        expect(controller.model.selectionStart, 0);
        expect(controller.model.selectionEnd, 8);

        tester.sendKey('N');
        expect(controller.text, 'N');
      } finally {
        await tester.dispose();
      }
    });
  });
}
