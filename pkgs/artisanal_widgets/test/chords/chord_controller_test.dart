import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('ChordController', () {
    late ChordController chords;

    setUp(() {
      chords = ChordController(
        bindings: [
          tui.KeyChordBinding.simple(
            id: 'sidebar',
            leader: 'ctrl+x',
            key: 'b',
            description: 'toggle sidebar',
            group: 'session',
          ),
          tui.KeyChordBinding.simple(
            id: 'models',
            leader: 'ctrl+x',
            key: 'm',
            description: 'models',
            group: 'session',
          ),
        ],
      );
    });

    tearDown(() => chords.dispose());

    test('entries and status are empty when idle', () {
      expect(chords.isActive, isFalse);
      expect(chords.entries, isEmpty);
      expect(chords.statusHint, isEmpty);
    });

    test('applyMessage prefix derives entries from bindings', () {
      chords.applyMessage(tui.KeyChordPrefixMsg(tui.Keys.ctrl('x')));
      expect(chords.isActive, isTrue);
      expect(chords.prefixLabel, 'ctrl+x');
      expect(chords.statusHint, 'ctrl+x …');
      expect(chords.entries, hasLength(2));
      expect(chords.entries.map((e) => e.keyLabel), containsAll(['b', 'm']));
      expect(chords.continuationKeysLabel, 'b m');
      expect(chords.whichKeyBanner(), contains('ctrl+x then:'));
    });

    test('applyMessage resolve clears state and returns id', () {
      chords.applyMessage(tui.KeyChordPrefixMsg(tui.Keys.ctrl('x')));
      final id = chords.applyMessage(
        tui.KeyChordResolvedMsg(
          id: 'sidebar',
          prefix: tui.Keys.ctrl('x'),
          key: tui.Key.char('b'),
        ),
      );
      expect(id, 'sidebar');
      expect(chords.isActive, isFalse);
      expect(chords.entries, isEmpty);
    });

    test('applyMessage cancel clears state', () {
      chords.applyMessage(tui.KeyChordPrefixMsg(tui.Keys.ctrl('x')));
      chords.applyMessage(
        tui.KeyChordCancelledMsg(prefix: tui.Keys.ctrl('x')),
      );
      expect(chords.isActive, isFalse);
    });

    test('interceptor is backed by the same bindings', () {
      expect(chords.interceptor, same(chords.keyChordInterceptor));
      expect(chords.keyChordInterceptor.bindings, hasLength(2));
      final out = chords.interceptor.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      expect(out, isA<tui.KeyChordPrefixMsg>());
    });
  });

  group('ChordHost + WhichKeySlot', () {
    test('prefix message shows which-key without manual entries', () async {
      final chords = ChordController(
        bindings: [
          tui.KeyChordBinding.simple(
            id: 'sidebar',
            leader: 'ctrl+x',
            key: 'b',
            description: 'toggle sidebar',
          ),
        ],
      );
      addTearDown(chords.dispose);

      String? resolved;
      final tester = WidgetTester();
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ChordHost(
            controller: chords,
            onResolved: (id) => resolved = id,
            child: Column(
              children: [
                Expanded(child: Text('body')),
                WhichKeySlot(),
              ],
            ),
          ),
        ),
        width: 80,
        height: 24,
      );

      expect(tester.find.text('which-key'), isFalse);

      tester.sendMsg(tui.KeyChordPrefixMsg(tui.Keys.ctrl('x')));
      expect(tester.find.text('which-key'), isTrue, reason: tester.view);
      expect(tester.find.text('toggle sidebar'), isTrue);

      tester.sendMsg(
        tui.KeyChordResolvedMsg(
          id: 'sidebar',
          prefix: tui.Keys.ctrl('x'),
          key: tui.Key.char('b'),
        ),
      );
      expect(resolved, 'sidebar');
      expect(tester.find.text('which-key'), isFalse);
    });
  });
}
