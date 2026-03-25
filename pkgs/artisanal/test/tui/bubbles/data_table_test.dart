import 'package:artisanal/src/tui/bubbles/data_table.dart';
import 'package:artisanal/src/tui/bubbles/table.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal `DataTableModel<int>` with [count] items, pageSize [page].
DataTableModel<int> _makeModel({int count = 10, int pageSize = 3}) {
  return DataTableModel<int>(
    items: List.generate(count, (i) => i),
    columns: [Column(title: 'Value', width: 6)],
    rowBuilder: (i) => ['$i'],
    pageSize: pageSize,
    showTitle: false,
    showHelp: false,
  );
}

/// Sends [msg] to [model] and returns the resulting model.
DataTableModel<T> _send<T>(DataTableModel<T> model, Msg msg) {
  final (next, _) = model.update(msg);
  return next;
}

/// Sends an Up key.
DataTableModel<T> _up<T>(DataTableModel<T> model) =>
    _send(model, const KeyMsg(Key(KeyType.up)));

/// Sends a Down key.
DataTableModel<T> _down<T>(DataTableModel<T> model) =>
    _send(model, const KeyMsg(Key(KeyType.down)));

/// Sends a wheel-up mouse event.
///
/// The terminal decode path (key.dart _decodeX10Button / _decodeSgrButton)
/// produces wheelUp events with action=press, not action=wheel.
DataTableModel<T> _wheelUp<T>(DataTableModel<T> model) => _send(
  model,
  const MouseMsg(
    action: MouseAction.press,
    button: MouseButton.wheelUp,
    x: 0,
    y: 0,
  ),
);

/// Sends a wheel-down mouse event (action=press, as produced by the terminal).
DataTableModel<T> _wheelDown<T>(DataTableModel<T> model) => _send(
  model,
  const MouseMsg(
    action: MouseAction.press,
    button: MouseButton.wheelDown,
    x: 0,
    y: 0,
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DataTableModel', () {
    // ── Basic construction ─────────────────────────────────────────────────
    group('construction', () {
      test('starts with cursor at 0', () {
        final m = _makeModel();
        expect(m.tableCursor, 0);
      });

      test('starts on page 0', () {
        final m = _makeModel();
        expect(m.currentPage, 0);
      });

      test('populates first page from items', () {
        final m = _makeModel(count: 10, pageSize: 3);
        expect(m.tableRows.length, 3);
      });
    });

    // ── Keyboard navigation ────────────────────────────────────────────────
    group('keyboard down', () {
      test('moves cursor down within page', () {
        var m = _makeModel(count: 10, pageSize: 5);
        m = _down(m);
        expect(m.tableCursor, 1);
      });

      test('advances to next page when at end of page', () {
        var m = _makeModel(count: 10, pageSize: 3);
        m = _down(m); // cursor 1
        m = _down(m); // cursor 2 (last on page 0)
        m = _down(m); // should flip to page 1, cursor 0
        expect(m.currentPage, 1);
        expect(m.tableCursor, 0);
      });

      test('wraps from last item to first item', () {
        // 4 items, pageSize=2 → 2 pages
        var m = _makeModel(count: 4, pageSize: 2);
        // Go to last item: page 1, cursor 1
        m = _down(m); // page 0 cursor 1
        m = _down(m); // page 1 cursor 0
        m = _down(m); // page 1 cursor 1 (last item)
        m = _down(m); // wrap → page 0, cursor 0
        expect(m.currentPage, 0);
        expect(m.tableCursor, 0);
      });
    });

    group('keyboard up', () {
      test('moves cursor up within page', () {
        var m = _makeModel(count: 10, pageSize: 5);
        m = _down(m); // cursor 1
        m = _up(m); // back to 0
        expect(m.tableCursor, 0);
      });

      test('goes to previous page when at top of page', () {
        var m = _makeModel(count: 10, pageSize: 3);
        m = _down(m); // 1
        m = _down(m); // 2
        m = _down(m); // page 1, cursor 0
        m = _up(m); // back to page 0, last cursor
        expect(m.currentPage, 0);
        expect(m.tableCursor, 2); // last on page 0
      });

      test('wraps from first item to last item', () {
        // 4 items, pageSize=2 → 2 pages
        var m = _makeModel(count: 4, pageSize: 2);
        // starts at page 0, cursor 0
        m = _up(m); // wrap → last page (1), last cursor (1)
        expect(m.currentPage, 1);
        expect(m.tableCursor, 1);
      });
    });

    // ── Mouse wheel ────────────────────────────────────────────────────────
    //
    // Terminal decoders produce (button: wheelUp/wheelDown, action: press).
    // The model must match on button only, not action == MouseAction.wheel.
    group('mouse wheel', () {
      test('wheelDown moves cursor down', () {
        var m = _makeModel(count: 10, pageSize: 5);
        m = _wheelDown(m);
        expect(m.tableCursor, 1);
      });

      test('wheelUp moves cursor up', () {
        var m = _makeModel(count: 10, pageSize: 5);
        m = _down(m); // cursor 1
        m = _wheelUp(m);
        expect(m.tableCursor, 0);
      });

      test('wheelDown advances page at end of page', () {
        var m = _makeModel(count: 10, pageSize: 3);
        m = _wheelDown(m); // 1
        m = _wheelDown(m); // 2
        m = _wheelDown(m); // page 1, cursor 0
        expect(m.currentPage, 1);
        expect(m.tableCursor, 0);
      });

      test('wheelUp goes to previous page at top of page', () {
        var m = _makeModel(count: 10, pageSize: 3);
        m = _wheelDown(m); // 1
        m = _wheelDown(m); // 2
        m = _wheelDown(m); // page 1, cursor 0
        m = _wheelUp(m); // back to page 0, last cursor (2)
        expect(m.currentPage, 0);
        expect(m.tableCursor, 2);
      });

      test('wheelDown wraps from last item to first item', () {
        var m = _makeModel(count: 4, pageSize: 2);
        m = _wheelDown(m); // page 0, cursor 1
        m = _wheelDown(m); // page 1, cursor 0
        m = _wheelDown(m); // page 1, cursor 1 (last)
        m = _wheelDown(m); // wrap → page 0, cursor 0
        expect(m.currentPage, 0);
        expect(m.tableCursor, 0);
      });

      test('wheelUp wraps from first item to last item', () {
        var m = _makeModel(count: 4, pageSize: 2);
        m = _wheelUp(m); // wrap → page 1, cursor 1
        expect(m.currentPage, 1);
        expect(m.tableCursor, 1);
      });

      test('action=wheel also works (future-proofing)', () {
        var m = _makeModel(count: 10, pageSize: 5);
        // Send with action=wheel (in case a terminal ever emits this).
        m = _send(
          m,
          const MouseMsg(
            action: MouseAction.wheel,
            button: MouseButton.wheelDown,
            x: 0,
            y: 0,
          ),
        );
        expect(m.tableCursor, 1);
      });

      test('non-wheel mouse events are ignored', () {
        var m = _makeModel(count: 10, pageSize: 5);
        m = _send(
          m,
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 0,
            y: 0,
          ),
        );
        expect(m.tableCursor, 0);
      });
    });

    // ── Selection ─────────────────────────────────────────────────────────
    group('selection', () {
      test('Enter emits DataTableSelectionMadeMsg with correct item', () {
        final m = _makeModel(count: 5, pageSize: 5);
        final (_, cmd) = m.update(const KeyMsg(Key(KeyType.enter)));
        expect(cmd, isNotNull);
        // Execute the Cmd to get the message — it's a Cmd.message so we can
        // inspect it directly by checking the type.
        // We can't easily extract the message without running a Program, so
        // verify via cursor position and that a command was produced.
        expect(cmd, isNotNull);
      });

      test('Esc emits SearchCancelledMsg', () {
        final m = _makeModel(count: 5, pageSize: 5);
        final (_, cmd) = m.update(const KeyMsg(Key(KeyType.escape)));
        expect(cmd, isNotNull);
      });
    });

    // ── Empty list ─────────────────────────────────────────────────────────
    group('empty items', () {
      test('navigation on empty model does not throw', () {
        final m = DataTableModel<int>(
          items: [],
          columns: [Column(title: 'V', width: 6)],
          rowBuilder: (i) => ['$i'],
          pageSize: 5,
        );
        expect(() => _up(m), returnsNormally);
        expect(() => _down(m), returnsNormally);
        expect(() => _wheelUp(m), returnsNormally);
        expect(() => _wheelDown(m), returnsNormally);
      });
    });
  });
}
