import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

void main() {
  group('KeymapHub stack', () {
    test('push / pop / top / surfaceIds', () {
      final hub = tui.KeymapHub();
      expect(hub.top, isNull);
      expect(hub.stack, isEmpty);

      hub.push(tui.ShortcutSurface(id: 'session'));
      hub.push(tui.ShortcutSurface(id: 'dialog', exclusive: true));

      expect(hub.surfaceIds, ['session', 'dialog']);
      expect(hub.top!.id, 'dialog');
      expect(hub.contains('session'), isTrue);

      final popped = hub.pop();
      expect(popped!.id, 'dialog');
      expect(hub.top!.id, 'session');

      expect(hub.pop('missing'), isNull);
      expect(hub.pop('session')!.id, 'session');
      expect(hub.top, isNull);
    });

    test('push same id replaces and moves to top', () {
      final hub = tui.KeymapHub();
      hub.push(tui.ShortcutSurface(id: 'a'));
      hub.push(tui.ShortcutSurface(id: 'b'));
      hub.push(tui.ShortcutSurface(id: 'a', exclusive: true));

      expect(hub.surfaceIds, ['b', 'a']);
      expect(hub.top!.exclusive, isTrue);
    });

    test('replace updates in place', () {
      final hub = tui.KeymapHub();
      hub.push(tui.ShortcutSurface(id: 'session'));
      hub.push(tui.ShortcutSurface(id: 'dialog'));
      hub.replace(tui.ShortcutSurface(id: 'session', exclusive: true));

      expect(hub.surfaceIds, ['session', 'dialog']);
      expect(hub.stack.first.exclusive, isTrue);
      expect(hub.top!.id, 'dialog');
    });

    test('popUntil removes layers above id', () {
      final hub = tui.KeymapHub();
      hub.push(tui.ShortcutSurface(id: 'home'));
      hub.push(tui.ShortcutSurface(id: 'session'));
      hub.push(tui.ShortcutSurface(id: 'dialog'));
      hub.popUntil('session');
      expect(hub.surfaceIds, ['home', 'session']);
      expect(hub.top!.id, 'session');
    });

    test('clearSurfaces keeps base', () {
      final base = _TrackingInterceptor('base');
      final hub = tui.KeymapHub(base: [base]);
      hub.push(tui.ShortcutSurface(id: 'session'));
      hub.clearSurfaces();
      expect(hub.stack, isEmpty);
      expect(hub.base, hasLength(1));
    });

    test('onStackChanged fires', () {
      var n = 0;
      final hub = tui.KeymapHub(onStackChanged: () => n++);
      hub.push(tui.ShortcutSurface(id: 'a'));
      hub.pop();
      expect(n, 2);
    });

    test('activate reorders without dropping siblings', () {
      final hub = tui.KeymapHub();
      hub.push(tui.ShortcutSurface(id: 'home'));
      hub.push(tui.ShortcutSurface(id: 'session'));
      expect(hub.surfaceIds, ['home', 'session']);
      hub.activate('home');
      expect(hub.surfaceIds, ['session', 'home']);
      hub.activate('session');
      expect(hub.surfaceIds, ['home', 'session']);
      expect(hub.top!.id, 'session');
    });

    test('replace keeps stack position', () {
      final hub = tui.KeymapHub();
      hub.push(tui.ShortcutSurface(id: 'home'));
      hub.push(tui.ShortcutSurface(id: 'session'));
      hub.replace(
        tui.ShortcutSurface(id: 'home', exclusive: true),
      );
      expect(hub.surfaceIds, ['home', 'session']);
      expect(hub.stack.first.exclusive, isTrue);
      expect(hub.top!.id, 'session');
    });
  });

  group('KeymapHub onSend surface-first', () {
    test('top surface claims before lower and base', () {
      final base = _ClaimIf('base', 'b');
      final hub = tui.KeymapHub(base: [base]);

      hub.push(
        tui.ShortcutSurface(
          id: 'session',
          onMessage: (msg) {
            if (msg is _TagMsg && msg.tag == 's') {
              return tui.KeymapLayerClaim(_TagMsg('session-claimed'));
            }
            return const tui.KeymapLayerPass();
          },
        ),
      );
      hub.push(
        tui.ShortcutSurface(
          id: 'dialog',
          onMessage: (msg) {
            if (msg is _TagMsg && msg.tag == 'd') {
              return tui.KeymapLayerClaim(_TagMsg('dialog-claimed'));
            }
            return const tui.KeymapLayerPass();
          },
        ),
      );

      final dialogHit = hub.onSend(const _TagMsg('d'));
      expect(dialogHit, isA<_TagMsg>());
      expect((dialogHit as _TagMsg).tag, 'dialog-claimed');

      final sessionHit = hub.onSend(const _TagMsg('s'));
      expect((sessionHit as _TagMsg).tag, 'session-claimed');

      final baseHit = hub.onSend(const _TagMsg('b'));
      expect((baseHit as _TagMsg).tag, 'base-claimed');
    });

    test('exclusive pass drops without fallthrough', () {
      final base = _TrackingInterceptor('base');
      final hub = tui.KeymapHub(base: [base]);

      hub.push(
        tui.ShortcutSurface(
          id: 'session',
          onMessage: (msg) {
            if (msg is _TagMsg && msg.tag == 's') {
              return tui.KeymapLayerClaim(_TagMsg('session'));
            }
            return const tui.KeymapLayerPass();
          },
        ),
      );
      hub.push(
        tui.ShortcutSurface(
          id: 'dialog',
          exclusive: true,
          onMessage: (_) => const tui.KeymapLayerPass(),
        ),
      );

      // Unclaimed under exclusive dialog → dropped (not session, not base).
      expect(hub.onSend(const _TagMsg('s')), isNull);
      expect(base.seen, isEmpty);

      // Explicit drop also null.
      hub.replace(
        tui.ShortcutSurface(
          id: 'dialog',
          exclusive: true,
          onMessage: (_) => const tui.KeymapLayerDrop(),
        ),
      );
      expect(hub.onSend(const _TagMsg('x')), isNull);
    });

    test('non-exclusive pass falls through to lower surface', () {
      final hub = tui.KeymapHub();
      hub.push(
        tui.ShortcutSurface(
          id: 'session',
          onMessage: (msg) {
            if (msg is _TagMsg && msg.tag == 's') {
              return tui.KeymapLayerClaim(_TagMsg('session'));
            }
            return const tui.KeymapLayerPass();
          },
        ),
      );
      hub.push(
        tui.ShortcutSurface(
          id: 'overlay',
          exclusive: false,
          onMessage: (_) => const tui.KeymapLayerPass(),
        ),
      );

      final out = hub.onSend(const _TagMsg('s'));
      expect((out as _TagMsg).tag, 'session');
    });

    test('base runs only after stack passes', () {
      final order = <String>[];
      final hub = tui.KeymapHub(
        base: [
          _OrderInterceptor('base', order),
        ],
      );
      hub.push(
        tui.ShortcutSurface(
          id: 'session',
          onMessage: (msg) {
            order.add('session');
            return const tui.KeymapLayerPass();
          },
        ),
      );

      final out = hub.onSend(const _TagMsg('x'));
      expect(out, isA<_TagMsg>());
      expect(order, ['session', 'base']);
    });

    test('chord interceptor as surface layer', () {
      final chords = tui.KeyChordInterceptor(
        bindings: [
          tui.KeyChordBinding.simple(
            id: 'sidebar',
            leader: 'ctrl+x',
            key: 'b',
            description: 'toggle sidebar',
          ),
        ],
      );
      final hub = tui.KeymapHub();
      hub.push(
        tui.ShortcutSurface(id: 'session', interceptor: chords),
      );

      final prefix = hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      expect(prefix, isA<tui.KeyChordPrefixMsg>());
      expect(chords.isPending, isTrue);

      final resolved = hub.onSend(tui.KeyMsg(tui.Key.char('b')));
      expect(resolved, isA<tui.KeyChordResolvedMsg>());
      expect((resolved as tui.KeyChordResolvedMsg).id, 'sidebar');
    });

    test('pop resets nested ResettableInterceptor', () {
      final chords = tui.KeyChordInterceptor(
        bindings: [
          tui.KeyChordBinding.simple(
            id: 'sidebar',
            leader: 'ctrl+x',
            key: 'b',
            description: 'toggle sidebar',
          ),
        ],
      );
      final hub = tui.KeymapHub();
      hub.push(tui.ShortcutSurface(id: 'session', interceptor: chords));
      hub.onSend(tui.KeyMsg(tui.Keys.ctrl('x')));
      expect(chords.isPending, isTrue);

      hub.pop('session');
      expect(chords.isPending, isFalse);
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

final class _TagMsg extends tui.Msg {
  const _TagMsg(this.tag);
  final String tag;
}

final class _TrackingInterceptor extends tui.ProgramInterceptor {
  _TrackingInterceptor(this.name);
  final String name;
  final seen = <tui.Msg>[];

  @override
  tui.Msg? onSend(tui.Msg msg) {
    seen.add(msg);
    return msg;
  }
}

final class _ClaimIf extends tui.ProgramInterceptor {
  _ClaimIf(this.name, this.tag);
  final String name;
  final String tag;

  @override
  tui.Msg? onSend(tui.Msg msg) {
    if (msg is _TagMsg && msg.tag == tag) {
      return _TagMsg('$name-claimed');
    }
    return msg;
  }
}

final class _OrderInterceptor extends tui.ProgramInterceptor {
  _OrderInterceptor(this.name, this.order);
  final String name;
  final List<String> order;

  @override
  tui.Msg? onSend(tui.Msg msg) {
    order.add(name);
    return msg;
  }
}
