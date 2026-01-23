import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

/// Simple counter model for testing.
class CounterModel implements Model {
  const CounterModel([this.count = 0]);

  final int count;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.up)) => (CounterModel(count + 1), null),
      KeyMsg(key: Key(type: KeyType.down)) => (CounterModel(count - 1), null),
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (
        this,
        Cmd.quit(),
      ), // 'q'
      _ => (this, null),
    };
  }

  @override
  String view() => 'Count: $count';
}

/// Model that returns an init command.
class InitModel implements Model {
  const InitModel({this.initialized = false});

  final bool initialized;

  @override
  Cmd? init() {
    return Cmd.message(const _InitializedMsg());
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      _InitializedMsg() => (const InitModel(initialized: true), null),
      _ => (this, null),
    };
  }

  @override
  String view() => initialized ? 'Initialized!' : 'Not initialized';
}

class _InitializedMsg extends Msg {
  const _InitializedMsg();
}

/// Model that tracks window size.
class WindowModel implements Model {
  const WindowModel({this.width = 0, this.height = 0});

  final int width;
  final int height;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      WindowSizeMsg(:final width, :final height) => (
        WindowModel(width: width, height: height),
        null,
      ),
      _ => (this, null),
    };
  }

  @override
  String view() => 'Size: $width x $height';
}

/// Model that demonstrates copyWith pattern.
class CopyWithTestModel with CopyWithModel implements Model {
  const CopyWithTestModel({this.name = '', this.age = 0});

  final String name;
  final int age;

  CopyWithTestModel copyWith({String? name, int? age}) {
    return CopyWithTestModel(name: name ?? this.name, age: age ?? this.age);
  }

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      _SetNameMsg(:final name) => (copyWith(name: name), null),
      _SetAgeMsg(:final age) => (copyWith(age: age), null),
      _ => (this, null),
    };
  }

  @override
  String view() => 'Name: $name, Age: $age';
}

class _SetNameMsg extends Msg {
  const _SetNameMsg(this.name);
  final String name;
}

class _SetAgeMsg extends Msg {
  const _SetAgeMsg(this.age);
  final int age;
}

void main() {
  group('Model interface', () {
    test('init returns optional command', () {
      const counter = CounterModel();
      expect(counter.init(), isNull);

      const initModel = InitModel();
      expect(initModel.init(), isNotNull);
    });

    test('update returns new model and optional command', () {
      const model = CounterModel(5);

      // Update with up key
      final (newModel1, cmd1) = model.update(const KeyMsg(Key(KeyType.up)));
      expect(newModel1, isA<CounterModel>());
      expect((newModel1 as CounterModel).count, 6);
      expect(cmd1, isNull);

      // Update with down key
      final (newModel2, cmd2) = model.update(const KeyMsg(Key(KeyType.down)));
      expect((newModel2 as CounterModel).count, 4);
      expect(cmd2, isNull);
    });

    test('update can return quit command', () {
      const model = CounterModel();

      final (_, cmd) = model.update(
        const KeyMsg(Key(KeyType.runes, runes: [0x71])),
      );
      expect(cmd, isNotNull);
    });

    test('view returns string representation', () {
      const model = CounterModel(42);
      expect(model.view(), contains('42'));
    });

    test('model is immutable - update returns new instance', () {
      const original = CounterModel(0);
      final (updated, _) = original.update(const KeyMsg(Key(KeyType.up)));

      expect(identical(original, updated), isFalse);
      expect(original.count, 0);
      expect((updated as CounterModel).count, 1);
    });
  });

  group('Model with init command', () {
    test('init returns command that triggers update', () async {
      const model = InitModel();
      expect(model.initialized, isFalse);

      final initCmd = model.init();
      expect(initCmd, isNotNull);

      // Execute the init command
      final msg = await initCmd!.execute();
      expect(msg, isA<_InitializedMsg>());

      // Process the message
      final (newModel, _) = model.update(msg!);
      expect((newModel as InitModel).initialized, isTrue);
    });
  });

  group('Model handling WindowSizeMsg', () {
    test('update responds to window size', () {
      const model = WindowModel();
      expect(model.width, 0);
      expect(model.height, 0);

      final (newModel, _) = model.update(const WindowSizeMsg(80, 24));
      expect((newModel as WindowModel).width, 80);
      expect(newModel.height, 24);
    });

    test('view reflects window size', () {
      const model = WindowModel(width: 100, height: 50);
      final view = model.view();
      expect(view, contains('100'));
      expect(view, contains('50'));
    });
  });

  group('CopyWithModel mixin', () {
    test('copyWith creates modified copy', () {
      const model = CopyWithTestModel(name: 'Alice', age: 30);

      final modified = model.copyWith(age: 31);
      expect(modified.name, 'Alice');
      expect(modified.age, 31);
      expect(model.age, 30); // Original unchanged
    });

    test('update uses copyWith pattern', () {
      const model = CopyWithTestModel();

      final (m1, _) = model.update(const _SetNameMsg('Bob'));
      expect((m1 as CopyWithTestModel).name, 'Bob');
      expect(m1.age, 0);

      final (m2, _) = m1.update(const _SetAgeMsg(25));
      expect((m2 as CopyWithTestModel).name, 'Bob');
      expect(m2.age, 25);
    });
  });

  group('UpdateResult typedef', () {
    test('can be used as return type', () {
      UpdateResult handleKey(Model model, KeyMsg msg) {
        return (model, null);
      }

      const model = CounterModel();
      final result = handleKey(model, const KeyMsg(Key(KeyType.enter)));
      expect(result.$1, equals(model));
      expect(result.$2, isNull);
    });
  });

  group('noCmd helper', () {
    test('creates tuple with null command', () {
      const model = CounterModel(10);
      final result = noCmd(model);

      expect(result.$1, equals(model));
      expect(result.$2, isNull);
    });
  });

  group('quit helper', () {
    test('creates tuple with quit command', () async {
      const model = CounterModel(10);
      final result = quit(model);

      expect(result.$1, equals(model));
      expect(result.$2, isNotNull);

      final msg = await result.$2!.execute();
      expect(msg, isA<QuitMsg>());
    });
  });

  group('Pattern matching in update', () {
    test('matches key type', () {
      const model = CounterModel();

      final (m1, _) = model.update(const KeyMsg(Key(KeyType.up)));
      expect((m1 as CounterModel).count, 1);

      final (m2, _) = model.update(const KeyMsg(Key(KeyType.down)));
      expect((m2 as CounterModel).count, -1);
    });

    test('matches specific rune', () {
      const model = CounterModel();

      // 'q' key should return quit command
      final (_, cmd) = model.update(
        const KeyMsg(Key(KeyType.runes, runes: [0x71])),
      );
      expect(cmd, isNotNull);

      // Other runes should be ignored
      final (_, cmd2) = model.update(
        const KeyMsg(Key(KeyType.runes, runes: [0x61])),
      ); // 'a'
      expect(cmd2, isNull);
    });

    test('ignores unhandled messages', () {
      const model = CounterModel(5);

      // Tab key is not handled
      final (newModel, cmd) = model.update(const KeyMsg(Key(KeyType.tab)));
      expect(identical(newModel, model), isTrue);
      expect(cmd, isNull);
    });

    test('pattern matching with WindowSizeMsg destructuring', () {
      const model = WindowModel();

      final (newModel, _) = model.update(const WindowSizeMsg(120, 40));

      final windowModel = newModel as WindowModel;
      expect(windowModel.width, 120);
      expect(windowModel.height, 40);
    });
  });
}
