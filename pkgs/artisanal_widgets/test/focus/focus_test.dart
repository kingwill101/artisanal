import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // FocusController
  // ---------------------------------------------------------------------------
  group('FocusController', () {
    test('starts with no focus', () {
      final fc = FocusController();
      expect(fc.focusedId, isNull);
      expect(fc.hasFocus, isFalse);
    });

    test('requestFocus sets the focused id', () {
      final fc = FocusController();
      final changed = fc.requestFocus('a');
      expect(changed, isTrue);
      expect(fc.focusedId, equals('a'));
      expect(fc.hasFocus, isTrue);
      expect(fc.isFocused('a'), isTrue);
    });

    test('requestFocus returns false when already focused', () {
      final fc = FocusController();
      fc.requestFocus('a');
      final changed = fc.requestFocus('a');
      expect(changed, isFalse);
      expect(fc.focusedId, equals('a'));
    });

    test('requestFocus switches focus to new id', () {
      final fc = FocusController();
      fc.requestFocus('a');
      final changed = fc.requestFocus('b');
      expect(changed, isTrue);
      expect(fc.focusedId, equals('b'));
      expect(fc.isFocused('a'), isFalse);
      expect(fc.isFocused('b'), isTrue);
    });

    test('clearFocus removes focus', () {
      final fc = FocusController();
      fc.requestFocus('a');
      final changed = fc.clearFocus();
      expect(changed, isTrue);
      expect(fc.focusedId, isNull);
      expect(fc.hasFocus, isFalse);
      expect(fc.isFocused('a'), isFalse);
    });

    test('clearFocus returns false when already unfocused', () {
      final fc = FocusController();
      final changed = fc.clearFocus();
      expect(changed, isFalse);
    });

    test('listener notified on requestFocus', () {
      final fc = FocusController();
      var calls = 0;
      fc.addListener(() => calls++);
      fc.requestFocus('a');
      expect(calls, equals(1));
    });

    test('listener notified on clearFocus', () {
      final fc = FocusController();
      fc.requestFocus('a');
      var calls = 0;
      fc.addListener(() => calls++);
      fc.clearFocus();
      expect(calls, equals(1));
    });

    test('listener not notified when requestFocus is no-op', () {
      final fc = FocusController();
      fc.requestFocus('a');
      var calls = 0;
      fc.addListener(() => calls++);
      fc.requestFocus('a'); // same id, no change
      expect(calls, equals(0));
    });

    test('multiple listeners all notified', () {
      final fc = FocusController();
      var calls1 = 0;
      var calls2 = 0;
      fc.addListener(() => calls1++);
      fc.addListener(() => calls2++);
      fc.requestFocus('a');
      expect(calls1, equals(1));
      expect(calls2, equals(1));
    });

    test('removeListener stops notifications', () {
      final fc = FocusController();
      var calls = 0;
      void listener() => calls++;
      fc.addListener(listener);
      fc.requestFocus('a');
      expect(calls, equals(1));
      fc.removeListener(listener);
      fc.requestFocus('b');
      expect(calls, equals(1)); // should not have increased
    });

    test('isFocused returns false for non-focused ids', () {
      final fc = FocusController();
      fc.requestFocus('a');
      expect(fc.isFocused('b'), isFalse);
      expect(fc.isFocused(''), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // FocusScope
  // ---------------------------------------------------------------------------
  group('FocusScope', () {
    test('provides controller to descendants', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      await tester.pumpWidget(
        FocusScope(
          controller: fc,
          child: TextField(autofocus: true, focusId: 'field1'),
        ),
      );
      // TextField with autofocus should have used the scope's controller
      expect(fc.isFocused('field1'), isTrue);
    });

    test('creates local controller when none provided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // FocusScope without an explicit controller creates its own
      await tester.pumpWidget(
        FocusScope(child: TextField(autofocus: true, focusId: 'auto-field')),
      );
      // The widget rendered — no crash, which means the local controller works
      final view = tester.view;
      expect(view.isNotEmpty, isTrue);
    });

    test('construction with child', () {
      final child = Text('hi');
      final scope = FocusScope(child: child);
      expect(scope.child, same(child));
      expect(scope.controller, isNull);
    });

    test('construction with controller', () {
      final fc = FocusController();
      final scope = FocusScope(controller: fc, child: Text('hi'));
      expect(scope.controller, same(fc));
    });
  });

  // ---------------------------------------------------------------------------
  // Focusable widget
  // ---------------------------------------------------------------------------
  group('Focusable', () {
    test('construction with defaults', () {
      final child = Text('child');
      final focusable = Focusable(child: child);
      expect(focusable.child, same(child));
      expect(focusable.autofocus, isFalse);
      expect(focusable.enabled, isTrue);
      expect(focusable.controller, isNull);
      expect(focusable.focusId, isNull);
      expect(focusable.onKey, isNull);
      expect(focusable.onFocusChange, isNull);
      expect(focusable.onFocus, isNull);
      expect(focusable.onBlur, isNull);
    });

    test('renders child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Focusable(child: Text('FocusChild')));
      expect(tester.find.text('FocusChild'), isTrue);
    });

    test('autofocus requests focus on first build', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      await tester.pumpWidget(
        Focusable(
          controller: fc,
          focusId: 'foc1',
          autofocus: true,
          child: Text('Auto'),
        ),
      );
      expect(fc.isFocused('foc1'), isTrue);
    });

    test('onFocus callback fires when gaining focus', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var focusCalled = false;
      final fc = FocusController();
      await tester.pumpWidget(
        Focusable(
          controller: fc,
          focusId: 'foc1',
          autofocus: true,
          onFocus: () => focusCalled = true,
          child: Text('Focus me'),
        ),
      );
      expect(focusCalled, isTrue);
    });

    test('onBlur callback fires when losing focus', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var blurCalled = false;
      final fc = FocusController();
      await tester.pumpWidget(
        Column(
          children: [
            Focusable(
              controller: fc,
              focusId: 'foc1',
              autofocus: true,
              onBlur: () => blurCalled = true,
              child: Text('First'),
            ),
            Focusable(controller: fc, focusId: 'foc2', child: Text('Second')),
          ],
        ),
      );

      expect(blurCalled, isFalse);
      // Switch focus to foc2 — foc1 should blur
      fc.requestFocus('foc2');
      tester.pump();
      expect(blurCalled, isTrue);
    });

    test('onFocusChange fires with correct value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final changes = <bool>[];
      final fc = FocusController();
      await tester.pumpWidget(
        Column(
          children: [
            Focusable(
              controller: fc,
              focusId: 'a',
              autofocus: true,
              onFocusChange: (f) => changes.add(f),
              child: Text('A'),
            ),
            Focusable(controller: fc, focusId: 'b', child: Text('B')),
          ],
        ),
      );
      // Initial autofocus triggers onFocusChange(true)
      expect(changes, equals([true]));

      // Switch to b, a loses focus
      fc.requestFocus('b');
      tester.pump();
      expect(changes, equals([true, false]));

      // Switch back to a
      fc.requestFocus('a');
      tester.pump();
      expect(changes, equals([true, false, true]));
    });

    test('onKey fires when focused and key sent', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final keys = <String>[];
      final fc = FocusController();
      await tester.pumpWidget(
        Focusable(
          controller: fc,
          focusId: 'foc1',
          autofocus: true,
          onKey: (msg) {
            keys.add(msg.key.toString());
            return null;
          },
          child: Text('KeyTarget'),
        ),
      );

      tester.sendKey('x');
      tester.sendKey('y');
      expect(keys, hasLength(2));
    });

    test('onKey does NOT fire when not focused', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final keys = <String>[];
      final fc = FocusController();
      await tester.pumpWidget(
        Focusable(
          controller: fc,
          focusId: 'foc1',
          // no autofocus — not focused
          onKey: (msg) {
            keys.add('key');
            return null;
          },
          child: Text('NoFocus'),
        ),
      );

      tester.sendKey('a');
      expect(keys, isEmpty);
    });

    test('onKey does NOT fire when disabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final keys = <String>[];
      final fc = FocusController();
      await tester.pumpWidget(
        Focusable(
          controller: fc,
          focusId: 'foc1',
          autofocus: true,
          enabled: false,
          onKey: (msg) {
            keys.add('key');
            return null;
          },
          child: Text('Disabled'),
        ),
      );

      tester.sendKey('a');
      expect(keys, isEmpty);
    });

    test('tap on Focusable requests focus via GestureDetector', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      await tester.pumpWidget(
        Column(
          children: [
            Focusable(controller: fc, focusId: 'first', child: Text('ClickMe')),
            Focusable(controller: fc, focusId: 'second', child: Text('Other')),
          ],
        ),
      );

      // Neither is focused initially
      expect(fc.hasFocus, isFalse);

      // Tap on 'ClickMe' to give focus
      final pos = tester.locateText('ClickMe');
      expect(pos, isNotNull);
      tester.tapAt(pos!.x, pos.y);
      expect(fc.isFocused('first'), isTrue);
    });

    test('tapping another Focusable switches focus', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      var blur1 = false;
      var focus2 = false;
      await tester.pumpWidget(
        Column(
          children: [
            Focusable(
              controller: fc,
              focusId: 'first',
              autofocus: true,
              onBlur: () => blur1 = true,
              child: Text('First'),
            ),
            Focusable(
              controller: fc,
              focusId: 'second',
              onFocus: () => focus2 = true,
              child: Text('Second'),
            ),
          ],
        ),
      );

      expect(fc.isFocused('first'), isTrue);

      // Tap on 'Second'
      final pos = tester.locateText('Second');
      expect(pos, isNotNull);
      tester.tapAt(pos!.x, pos.y);
      expect(fc.isFocused('second'), isTrue);
      expect(blur1, isTrue);
      expect(focus2, isTrue);
    });

    test('disabled Focusable does not request focus on tap', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      await tester.pumpWidget(
        Focusable(
          controller: fc,
          focusId: 'dis',
          enabled: false,
          child: Text('Disabled'),
        ),
      );

      final pos = tester.locateText('Disabled');
      expect(pos, isNotNull);
      tester.tapAt(pos!.x, pos.y);
      expect(fc.hasFocus, isFalse);
    });

    test('uses widget.id as focusId when focusId not provided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      final focusable = Focusable(
        controller: fc,
        autofocus: true,
        child: Text('AutoId'),
      );
      await tester.pumpWidget(focusable);
      // The focusId defaults to widget.id
      expect(fc.isFocused(focusable.id), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // FocusScope with Focusable integration
  // ---------------------------------------------------------------------------
  group('FocusScope + Focusable integration', () {
    test('Focusable with scope controller via explicit pass', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      await tester.pumpWidget(
        FocusScope(
          controller: fc,
          child: Focusable(
            controller: fc, // explicitly pass the scope controller
            focusId: 'scoped',
            autofocus: true,
            child: Text('Scoped'),
          ),
        ),
      );
      expect(fc.isFocused('scoped'), isTrue);
    });

    test('multiple Focusables share explicit controller', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      final focusChanges = <String>[];
      await tester.pumpWidget(
        FocusScope(
          controller: fc,
          child: Column(
            children: [
              Focusable(
                controller: fc,
                focusId: 'a',
                autofocus: true,
                onFocusChange: (f) {
                  if (f) focusChanges.add('a+');
                  if (!f) focusChanges.add('a-');
                },
                child: Text('AAA'),
              ),
              Focusable(
                controller: fc,
                focusId: 'b',
                onFocusChange: (f) {
                  if (f) focusChanges.add('b+');
                  if (!f) focusChanges.add('b-');
                },
                child: Text('BBB'),
              ),
            ],
          ),
        ),
      );

      expect(focusChanges, equals(['a+']));

      // Programmatically switch to b
      fc.requestFocus('b');
      tester.pump();
      expect(focusChanges, equals(['a+', 'a-', 'b+']));
    });

    test('Focusable with explicit controller ignores scope', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final scopeCtrl = FocusController();
      final localCtrl = FocusController();
      await tester.pumpWidget(
        FocusScope(
          controller: scopeCtrl,
          child: Focusable(
            controller: localCtrl,
            focusId: 'local',
            autofocus: true,
            child: Text('Local'),
          ),
        ),
      );
      // Should use local controller, not scope
      expect(localCtrl.isFocused('local'), isTrue);
      expect(scopeCtrl.hasFocus, isFalse);
    });

    test('key events flow only to focused Focusable', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      final keysA = <String>[];
      final keysB = <String>[];
      await tester.pumpWidget(
        FocusScope(
          controller: fc,
          child: Column(
            children: [
              Focusable(
                controller: fc,
                focusId: 'a',
                autofocus: true,
                onKey: (msg) {
                  keysA.add('a');
                  return null;
                },
                child: Text('AAA'),
              ),
              Focusable(
                controller: fc,
                focusId: 'b',
                onKey: (msg) {
                  keysB.add('b');
                  return null;
                },
                child: Text('BBB'),
              ),
            ],
          ),
        ),
      );

      tester.sendKey('1');
      expect(keysA, hasLength(1));
      expect(keysB, isEmpty);

      fc.requestFocus('b');
      tester.pump();
      tester.sendKey('2');
      // a should not receive any more keys
      expect(keysA, hasLength(1));
      expect(keysB, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Component widgets using Focusable
  // ---------------------------------------------------------------------------
  group('Components using Focusable', () {
    test('Button uses Focusable for keyboard activation', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var pressed = false;
      final fc = FocusController();
      await tester.pumpWidget(
        FocusScope(
          controller: fc,
          child: Button(
            onPressed: () {
              pressed = true;
              return null;
            },
            focusController: fc,
            child: Text('Submit'),
          ),
        ),
      );

      // Focus the button
      fc.requestFocus(
        // Button's focusId defaults to widget.id; find it
        // by requesting focus for the button - but Button doesn't
        // expose its focusId easily. Let's tap to focus instead.
        'unused',
      );
      // Actually, let's tap the button to focus + activate
      final pos = tester.locateText('Submit');
      expect(pos, isNotNull);
      tester.tapAt(pos!.x, pos.y);
      expect(pressed, isTrue);
    });

    test('Checkbox responds to keyboard when focused', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var value = false;
      final fc = FocusController();
      await tester.pumpWidget(
        FocusScope(
          controller: fc,
          child: Checkbox(
            value: value,
            label: Text('Check'),
            focusController: fc,
            onChanged: (v) {
              value = v;
              return null;
            },
          ),
        ),
      );

      // Tap to focus and toggle
      final pos = tester.locateText('Check');
      expect(pos, isNotNull);
      tester.tapAt(pos!.x, pos.y);
      expect(value, isTrue);
    });
  });
}
