import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('ChangeNotifier', () {
    test('notifyListeners calls registered listeners', () {
      final notifier = ChangeNotifier();
      var callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.notifyListeners();
      expect(callCount, 1);

      notifier.notifyListeners();
      expect(callCount, 2);
    });

    test('addListener allows multiple listeners', () {
      final notifier = ChangeNotifier();
      var count1 = 0;
      var count2 = 0;
      notifier.addListener(() => count1++);
      notifier.addListener(() => count2++);

      notifier.notifyListeners();
      expect(count1, 1);
      expect(count2, 1);
    });

    test('removeListener stops notifications for that listener', () {
      final notifier = ChangeNotifier();
      var callCount = 0;
      void listener() => callCount++;

      notifier.addListener(listener);
      notifier.notifyListeners();
      expect(callCount, 1);

      notifier.removeListener(listener);
      notifier.notifyListeners();
      expect(callCount, 1); // unchanged
    });

    test('removeListener only removes first occurrence', () {
      final notifier = ChangeNotifier();
      var callCount = 0;
      void listener() => callCount++;

      notifier.addListener(listener);
      notifier.addListener(listener);
      notifier.notifyListeners();
      expect(callCount, 2);

      notifier.removeListener(listener);
      notifier.notifyListeners();
      expect(callCount, 3); // one removed, one still fires
    });

    test('hasListeners reflects current state', () {
      final notifier = ChangeNotifier();
      expect(notifier.hasListeners, isFalse);

      void listener() {}
      notifier.addListener(listener);
      expect(notifier.hasListeners, isTrue);

      notifier.removeListener(listener);
      expect(notifier.hasListeners, isFalse);
    });

    test('dispose clears all listeners', () {
      final notifier = ChangeNotifier();
      var callCount = 0;
      notifier.addListener(() => callCount++);
      notifier.addListener(() => callCount++);

      notifier.dispose();
      expect(notifier.hasListeners, isFalse);

      notifier.notifyListeners();
      expect(callCount, 0); // no listeners after dispose
    });

    test('listener can add another listener during notification', () {
      final notifier = ChangeNotifier();
      var innerCalled = false;

      notifier.addListener(() {
        notifier.addListener(() => innerCalled = true);
      });

      notifier.notifyListeners();
      // Inner listener was added during iteration over a copy,
      // so it should not have been called yet.
      expect(innerCalled, isFalse);

      // Now it should fire on the next notification.
      notifier.notifyListeners();
      expect(innerCalled, isTrue);
    });

    test('listener can remove itself during notification', () {
      final notifier = ChangeNotifier();
      var callCount = 0;
      late void Function() selfRemover;
      selfRemover = () {
        callCount++;
        notifier.removeListener(selfRemover);
      };

      notifier.addListener(selfRemover);
      notifier.notifyListeners();
      expect(callCount, 1);

      // Self-removed — should not fire again.
      notifier.notifyListeners();
      expect(callCount, 1);
    });
  });

  group('ValueNotifier', () {
    test('initial value is accessible', () {
      final notifier = ValueNotifier<int>(42);
      expect(notifier.value, 42);
    });

    test('setting value notifies listeners', () {
      final notifier = ValueNotifier<int>(0);
      var callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.value = 1;
      expect(callCount, 1);
      expect(notifier.value, 1);
    });

    test('setting same value does not notify', () {
      final notifier = ValueNotifier<int>(5);
      var callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.value = 5;
      expect(callCount, 0);
    });

    test('multiple value changes notify each time', () {
      final notifier = ValueNotifier<String>('a');
      final values = <String>[];
      notifier.addListener(() => values.add(notifier.value));

      notifier.value = 'b';
      notifier.value = 'c';
      notifier.value = 'd';

      expect(values, ['b', 'c', 'd']);
    });

    test('implements ValueListenable', () {
      final notifier = ValueNotifier<double>(3.14);
      // ignore: unnecessary_type_check
      expect(notifier is ValueListenable<double>, isTrue);
      expect(notifier.value, 3.14);
    });

    test('dispose prevents further notifications', () {
      final notifier = ValueNotifier<int>(0);
      var callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.dispose();
      notifier.value = 10;
      // value is updated but no listeners to call
      expect(notifier.value, 10);
      expect(callCount, 0);
    });

    test('works with nullable types', () {
      final notifier = ValueNotifier<String?>(null);
      var callCount = 0;
      notifier.addListener(() => callCount++);

      expect(notifier.value, isNull);

      notifier.value = 'hello';
      expect(callCount, 1);
      expect(notifier.value, 'hello');

      notifier.value = null;
      expect(callCount, 2);
      expect(notifier.value, isNull);

      // Setting null again should not notify.
      notifier.value = null;
      expect(callCount, 2);
    });
  });

  group('Listenable.merge', () {
    test('fires when any child fires', () {
      final a = ChangeNotifier();
      final b = ChangeNotifier();
      final merged = Listenable.merge([a, b]);

      var callCount = 0;
      merged.addListener(() => callCount++);

      a.notifyListeners();
      expect(callCount, 1);

      b.notifyListeners();
      expect(callCount, 2);
    });

    test('handles null entries gracefully', () {
      final a = ChangeNotifier();
      final merged = Listenable.merge([a, null]);

      var callCount = 0;
      merged.addListener(() => callCount++);

      a.notifyListeners();
      expect(callCount, 1);
    });

    test('removeListener unsubscribes from all children', () {
      final a = ChangeNotifier();
      final b = ChangeNotifier();
      final merged = Listenable.merge([a, b]);

      var callCount = 0;
      void listener() => callCount++;
      merged.addListener(listener);

      a.notifyListeners();
      expect(callCount, 1);

      merged.removeListener(listener);

      a.notifyListeners();
      b.notifyListeners();
      expect(callCount, 1); // unchanged
    });

    test('empty merge does not error', () {
      final merged = Listenable.merge([]);
      var callCount = 0;
      merged.addListener(() => callCount++);
      // Nothing fires, and no error.
      expect(callCount, 0);
    });

    test('multiple listeners on merged listenable', () {
      final a = ChangeNotifier();
      final b = ChangeNotifier();
      final merged = Listenable.merge([a, b]);

      var count1 = 0;
      var count2 = 0;
      merged.addListener(() => count1++);
      merged.addListener(() => count2++);

      a.notifyListeners();
      expect(count1, 1);
      expect(count2, 1);

      b.notifyListeners();
      expect(count1, 2);
      expect(count2, 2);
    });
  });
}
