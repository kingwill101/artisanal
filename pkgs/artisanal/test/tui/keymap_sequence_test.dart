import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

void main() {
  group('ShortcutBinding', () {
    test('fromChord preserves id and labels', () {
      final b = tui.ShortcutBinding.fromChord(
        tui.KeyChordBinding.simple(
          id: 'sidebar_toggle',
          leader: 'ctrl+x',
          key: 'b',
          description: 'toggle sidebar',
          group: 'session',
        ),
      );
      expect(b.id, 'sidebar_toggle');
      expect(b.keys, ['ctrl+x', 'b']);
      expect(b.description, 'toggle sidebar');
      expect(b.group, 'session');
      expect(b.isSequence, isTrue);
    });

    test('toChordBinding round-trip for length-2', () {
      final b = tui.ShortcutBinding.chord(
        id: 'models',
        leader: 'ctrl+x',
        key: 'm',
        description: 'models',
      );
      final chord = b.toChordBinding();
      expect(chord, isNotNull);
      expect(chord!.id, 'models');
    });
  });

  group('KeymapHub sequences', () {
    late tui.KeymapHub hub;

    setUp(() {
      hub = tui.KeymapHub();
      hub.push(
        tui.ShortcutSurface(
          id: 'session',
          bindings: [
            tui.ShortcutBinding.chord(
              id: 'sidebar_toggle',
              leader: 'ctrl+x',
              key: 'b',
              description: 'toggle sidebar',
              group: 'session',
            ),
            tui.ShortcutBinding.chord(
              id: 'model_list',
              leader: 'ctrl+x',
              key: 'm',
              description: 'models',
              group: 'session',
            ),
            tui.ShortcutBinding.single(
              id: 'command_list',
              key: 'ctrl+p',
              description: 'commands',
            ),
          ],
        ),
      );
    });

    test('single-key binding resolves to KeymapActionMsg', () {
      final out = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('p')));
      expect(out, isA<tui.KeymapActionMsg>());
      final action = out as tui.KeymapActionMsg;
      expect(action.id, 'command_list');
      expect(action.surfaceId, 'session');
      expect(action.sequence, ['ctrl+p']);
    });

    test('leader prefix then continuation resolves action', () {
      final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      expect(prefix, isA<tui.KeymapSequencePrefixMsg>());
      expect(hub.isSequencePending, isTrue);
      expect(hub.pendingPrefixLabel, 'ctrl+x');
      expect(hub.pendingStatusHint, 'ctrl+x …');
      expect(hub.activeContinuations, hasLength(2));
      expect(
        hub.activeContinuations.map((c) => c.keyLabel),
        containsAll(['b', 'm']),
      );

      final resolved = hub.onSend(tui.KeyMsg(tui.Key.char('b')));
      expect(resolved, isA<tui.KeymapActionMsg>());
      expect((resolved as tui.KeymapActionMsg).id, 'sidebar_toggle');
      expect(hub.isSequencePending, isFalse);
      expect(hub.activeContinuations, isEmpty);
    });

    test('unmatched continuation cancels and forwards key', () {
      hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      final out = hub.onSend(tui.KeyMsg(tui.Key.char('z')));
      expect(out, isA<tui.BatchMsg>());
      final batch = out as tui.BatchMsg;
      expect(batch.messages[0], isA<tui.KeymapSequenceCancelledMsg>());
      expect(batch.messages[1], isA<tui.KeyMsg>());
      expect(hub.isSequencePending, isFalse);
    });

    test('push exclusive dialog cancels session pending', () {
      hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      expect(hub.isSequencePending, isTrue);

      hub.push(
        tui.ShortcutSurface(
          id: 'dialog',
          exclusive: true,
          bindings: [
            tui.ShortcutBinding.single(
              id: 'confirm',
              key: 'y',
              description: 'confirm',
            ),
          ],
        ),
      );
      expect(hub.isSequencePending, isFalse);
      expect(hub.top!.id, 'dialog');

      final y = hub.onSend(tui.KeyMsg(tui.Key.char('y')));
      expect((y as tui.KeymapActionMsg).id, 'confirm');

      // Session chord does not fire under exclusive dialog.
      expect(hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x'))), isNull);
    });

    test('pop dialog restores session bindings', () {
      hub.push(
        tui.ShortcutSurface(
          id: 'dialog',
          exclusive: true,
          bindings: [
            tui.ShortcutBinding.single(id: 'confirm', key: 'y'),
          ],
        ),
      );
      hub.pop();
      final out = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('p')));
      expect((out as tui.KeymapActionMsg).id, 'command_list');
    });

    test('resetPending clears sequence', () {
      hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      hub.resetPending();
      expect(hub.isSequencePending, isFalse);
    });

    test('exclusive dialog pass drops session actions', () {
      hub.push(
        tui.ShortcutSurface(
          id: 'dialog',
          exclusive: true,
          onMessage: (_) => const tui.KeymapLayerPass(),
        ),
      );
      expect(hub.onSend(tui.KeyMsg(tui.Keys.ctrl('p'))), isNull);
    });

    test('onPendingChanged fires', () {
      var n = 0;
      hub = tui.KeymapHub(onPendingChanged: () => n++);
      hub.push(
        tui.ShortcutSurface(
          id: 'session',
          bindings: [
            tui.ShortcutBinding.chord(
              id: 'sidebar_toggle',
              leader: 'ctrl+x',
              key: 'b',
              description: 'sidebar',
            ),
          ],
        ),
      );
      n = 0;
      hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      expect(n, greaterThan(0));
      final before = n;
      hub.onSend(tui.KeyMsg(tui.Key.char('b')));
      expect(n, greaterThan(before));
    });
  });
}
