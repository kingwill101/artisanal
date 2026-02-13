import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('ChangeNotifier', () {
    test('add/remove listener updates hasListeners and notifications', () {
      final notifier = ChangeNotifier();
      var callCount = 0;

      void listener() => callCount += 1;

      expect(notifier.hasListeners, isFalse);
      notifier.addListener(listener);
      expect(notifier.hasListeners, isTrue);

      notifier.notifyListeners();
      expect(callCount, 1);

      notifier.removeListener(listener);
      expect(notifier.hasListeners, isFalse);

      notifier.notifyListeners();
      expect(callCount, 1);
    });

    test('notifyListeners preserves registration order once per cycle', () {
      final notifier = ChangeNotifier();
      final calls = <String>[];

      notifier.addListener(() => calls.add('first'));
      notifier.addListener(() => calls.add('second'));
      notifier.addListener(() => calls.add('third'));

      notifier.notifyListeners();

      expect(calls, ['first', 'second', 'third']);
    });

    test('removeListener only removes one matching registration', () {
      final notifier = ChangeNotifier();
      var callCount = 0;

      void listener() => callCount += 1;

      notifier.addListener(listener);
      notifier.addListener(listener);

      notifier.notifyListeners();
      expect(callCount, 2);

      notifier.removeListener(listener);
      notifier.notifyListeners();
      expect(callCount, 3);
    });

    test('removing a listener during notification skips it in that cycle', () {
      final notifier = ChangeNotifier();
      final calls = <String>[];

      late void Function() second;
      void first() {
        calls.add('first');
        notifier.removeListener(second);
      }

      second = () => calls.add('second');

      notifier.addListener(first);
      notifier.addListener(second);

      notifier.notifyListeners();
      expect(calls, ['first']);

      notifier.notifyListeners();
      expect(calls, ['first', 'first']);
    });

    test(
      'adding a listener during notification does not fire it in same cycle',
      () {
        final notifier = ChangeNotifier();
        final calls = <String>[];
        var added = false;

        void second() => calls.add('second');

        void first() {
          calls.add('first');
          if (!added) {
            notifier.addListener(second);
            added = true;
          }
        }

        notifier.addListener(first);

        notifier.notifyListeners();
        expect(calls, ['first']);

        notifier.notifyListeners();
        expect(calls, ['first', 'first', 'second']);
      },
    );

    test('dispose enforces runtime guards and removeListener remains safe', () {
      final notifier = ChangeNotifier();
      void listener() {}

      notifier.addListener(listener);
      notifier.dispose();

      expect(notifier.hasListeners, isFalse);
      expect(() => notifier.removeListener(listener), returnsNormally);
      expect(() => notifier.addListener(listener), throwsStateError);
      expect(notifier.notifyListeners, throwsStateError);
      expect(notifier.dispose, throwsStateError);
    });

    test('dispose during notification throws', () {
      final notifier = ChangeNotifier();

      notifier.addListener(notifier.dispose);

      expect(notifier.notifyListeners, throwsStateError);
    });
  });

  group('ValueNotifier', () {
    test('initial value is accessible', () {
      final notifier = ValueNotifier<int>(42);
      expect(notifier.value, 42);
    });

    test('notifies when value changes and skips equal assignments', () {
      final notifier = ValueNotifier<int>(1);
      var notifications = 0;

      notifier.addListener(() => notifications += 1);

      notifier.value = 1;
      expect(notifications, 0);

      notifier.value = 2;
      expect(notifier.value, 2);
      expect(notifications, 1);

      notifier.value = 2;
      expect(notifications, 1);
    });

    test('setter throws after dispose', () {
      final notifier = ValueNotifier<String>('a');
      notifier.dispose();

      expect(() => notifier.value = 'b', throwsStateError);
    });

    test('implements ValueListenable', () {
      final notifier = ValueNotifier<double>(3.14);
      // ignore: unnecessary_type_check
      expect(notifier is ValueListenable<double>, isTrue);
      expect(notifier.value, 3.14);
    });

    test('works with nullable types', () {
      final notifier = ValueNotifier<String?>(null);
      var callCount = 0;
      notifier.addListener(() => callCount += 1);

      expect(notifier.value, isNull);

      notifier.value = 'hello';
      expect(callCount, 1);
      expect(notifier.value, 'hello');

      notifier.value = null;
      expect(callCount, 2);
      expect(notifier.value, isNull);

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
      merged.addListener(() => callCount += 1);

      a.notifyListeners();
      expect(callCount, 1);

      b.notifyListeners();
      expect(callCount, 2);
    });

    test('handles null entries gracefully', () {
      final a = ChangeNotifier();
      final merged = Listenable.merge([a, null]);

      var callCount = 0;
      merged.addListener(() => callCount += 1);

      a.notifyListeners();
      expect(callCount, 1);
    });

    test('removeListener unsubscribes from all children', () {
      final a = ChangeNotifier();
      final b = ChangeNotifier();
      final merged = Listenable.merge([a, b]);

      var callCount = 0;
      void listener() => callCount += 1;
      merged.addListener(listener);

      a.notifyListeners();
      expect(callCount, 1);

      merged.removeListener(listener);

      a.notifyListeners();
      b.notifyListeners();
      expect(callCount, 1);
    });

    test('empty merge does not error', () {
      final merged = Listenable.merge([]);
      var callCount = 0;
      merged.addListener(() => callCount += 1);

      expect(callCount, 0);
    });
  });
}
