import 'package:test/test.dart';
import 'package:artisanal/tui.dart';

class CounterComponent extends ViewComponent {
  int count = 0;

  @override
  (CounterComponent, Cmd?) update(Msg msg) {
    if (msg is KeyMsg && msg.key.type == KeyType.runes) {
      if (msg.key.runes.first == 0x2b) {
        // '+'
        count++;
      } else if (msg.key.runes.first == 0x2d) {
        // '-'
        count--;
      }
    }
    return (this, null);
  }

  @override
  String view() => 'Count: $count';
}

class ParentModel extends Model with ComponentHost {
  CounterComponent counter = CounterComponent();

  @override
  Cmd? init() => null;

  @override
  (ParentModel, Cmd?) update(Msg msg) {
    // Use the helper to update the child component
    return updateComponent<CounterComponent, ParentModel>(
      counter,
      msg,
      (newCounter) => counter = newCounter,
    );
  }

  @override
  String view() => 'Parent [\n  ${counter.view()}\n]';
}

class MyStatic extends StaticComponent {
  @override
  String view() => 'Static';
}

void main() {
  group('ViewComponent Architecture', () {
    test('CounterComponent updates state', () {
      var counter = CounterComponent();
      final msg = KeyMsg(Key(KeyType.runes, runes: [0x2b])); // '+'

      final (newCounter, _) = counter.update(msg);
      expect((newCounter).count, 1);
    });

    test('ParentModel delegates to child via ComponentHost', () {
      var model = ParentModel();
      final msg = KeyMsg(Key(KeyType.runes, runes: [0x2b])); // '+'

      final (newModel, _) = model.update(msg);
      expect((newModel).counter.count, 1);
      expect(newModel.view(), contains('Count: 1'));
    });

    test('StaticComponent provides default update', () {
      final component = MyStatic();
      final (newComp, cmd) = component.update(KeyMsg(Key(KeyType.enter)));

      expect(newComp, same(component));
      expect(cmd, isNull);
      expect(component.view(), 'Static');
    });
  });
}
