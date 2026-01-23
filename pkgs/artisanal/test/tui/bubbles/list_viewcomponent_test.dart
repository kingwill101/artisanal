import 'package:artisanal/src/tui/bubbles/list.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/tui.dart' show Key, KeyMsg, KeyType;
import 'package:test/test.dart';

void main() {
  group('ListModel (ViewComponent)', () {
    test('updates via base type', () {
      final list = ListModel(items: [StringItem('a'), StringItem('b')]);
      ViewComponent model = list;

      final beforeCursor = list.cursor;
      final (updated, _) = model.update(const KeyMsg(Key(KeyType.down)));

      expect(updated, isA<ListModel>());
      expect((updated as ListModel).cursor, greaterThanOrEqualTo(beforeCursor));
    });

    group('Parity Features', () {
      test('setItems parity', () {
        final list = ListModel();
        list.setItems([StringItem('a')]);
        expect(list.items.length, 1);
      });

      test('insertItem parity', () {
        final list = ListModel(items: [StringItem('a')]);
        list.insertItem(0, StringItem('b'));
        expect(list.items.length, 2);
        expect(list.items[0].filterValue(), 'b');
      });

      test('removeItem parity', () {
        final list = ListModel(items: [StringItem('a'), StringItem('b')]);
        list.removeItem(0);
        expect(list.items.length, 1);
        expect(list.items[0].filterValue(), 'b');
      });

      test('setItem parity', () {
        final list = ListModel(items: [StringItem('a')]);
        list.setItem(0, StringItem('b'));
        expect(list.items[0].filterValue(), 'b');
      });

      test('select parity', () {
        final list = ListModel(items: [StringItem('a'), StringItem('b')]);
        list.select(1);
        expect(list.index, 1);
      });

      test('resetSelected parity', () {
        final list = ListModel(items: [StringItem('a'), StringItem('b')]);
        list.select(1);
        list.resetSelected();
        expect(list.index, 0);
      });

      test('resetFilter parity', () {
        final list = ListModel(
          items: [StringItem('apple'), StringItem('banana')],
        );
        // Start filtering
        list.update(const KeyMsg(Key(KeyType.runes, runes: [0x2f]))); // '/'
        list.update(const KeyMsg(Key(KeyType.runes, runes: [0x61]))); // 'a'
        expect(list.isFiltered, isFalse); // Still in filtering state
        list.update(const KeyMsg(Key(KeyType.enter))); // Apply
        expect(list.isFiltered, isTrue);
        list.resetFilter();
        expect(list.isFiltered, isFalse);
      });

      test('status message auto-clear', () {
        final list = ListModel();
        final cmd = list.newStatusMessage('test');
        expect(list.statusMessage, equals('test'));
        expect(cmd, isNotNull);
        // Simulate timeout
        final (updated, _) = list.update(StatusMessageTimeoutMsg());
        expect(updated.statusMessage, isEmpty);
      });

      test('quit-unbind behavior', () {
        final list = ListModel();
        expect(list.keyMap.quit.enabled, isTrue);

        list.disableQuitKeybindings();
        expect(list.keyMap.quit.enabled, isFalse);

        list.enableQuitKeybindings();
        expect(list.keyMap.quit.enabled, isTrue);
      });

      test('spinner parity', () {
        final list = ListModel();
        expect(list.isShowingSpinner, isFalse);

        final cmd = list.startSpinner();
        expect(list.isShowingSpinner, isTrue);
        expect(cmd, isNotNull);

        list.stopSpinner();
        expect(list.isShowingSpinner, isFalse);

        list.toggleSpinner();
        expect(list.isShowingSpinner, isTrue);
      });
    });
  });
}
