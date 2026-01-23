import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

import '../../example/tui/list.dart' as ex;

void main() {
  group('example/tui/list.dart', () {
    test('selects on KeyType.enter', () {
      const m = ex.ListModel(items: ['a', 'b', 'c']);
      final (next, cmd) = m.update(const KeyMsg(Key(KeyType.enter)));
      expect((next as ex.ListModel).selected, 'a');
      expect(cmd, isNotNull);
    });

    test('selects on Ctrl+J (LF via UV key table)', () {
      const m = ex.ListModel(items: ['a', 'b', 'c']);
      final (next, cmd) = m.update(const KeyMsg(Keys.ctrlJ));
      expect((next as ex.ListModel).selected, 'a');
      expect(cmd, isNotNull);
    });

    test('selects on CR char', () {
      const m = ex.ListModel(items: ['a', 'b', 'c']);
      final (next, cmd) = m.update(KeyMsg(Key.char('\r')));
      expect((next as ex.ListModel).selected, 'a');
      expect(cmd, isNotNull);
    });

    test('selects on space char', () {
      const m = ex.ListModel(items: ['a', 'b', 'c']);
      final (next, cmd) = m.update(KeyMsg(Key.char(' ')));
      expect((next as ex.ListModel).selected, 'a');
      expect(cmd, isNotNull);
    });

    test('does not treat Ctrl+J as down shortcut', () {
      const m = ex.ListModel(items: ['a', 'b', 'c'], cursor: 1);
      final (next, _) = m.update(const KeyMsg(Keys.ctrlJ));
      expect((next as ex.ListModel).cursor, 1, reason: 'Ctrl+J selects');
    });

    test('treats plain j as down shortcut', () {
      const m = ex.ListModel(items: ['a', 'b', 'c'], cursor: 0);
      final (next, cmd) = m.update(KeyMsg(Key.char('j')));
      expect((next as ex.ListModel).cursor, 1);
      expect(cmd, isNull);
    });
  });
}
