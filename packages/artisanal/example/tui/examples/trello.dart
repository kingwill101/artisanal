/// Trello-style kanban board example.
///
/// Run:
///   dart run packages/artisanal/example/tui/examples/trello.dart
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart'
    show Colors, Style, ThemePalette, Color, NoColor;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/src/style/ranges.dart' as ranges;
import 'package:artisanal/src/tui/view.dart' show View;
import 'package:artisanal/src/tui/bubbles/debug_overlay.dart';
import 'package:artisanal/src/uv/uv.dart' as uv;

const _colWidth = 26;
const _colGap = 2;
const _cardPanelHeight = 3;
const _cardGap = 1;
const _boardTop = 2;

// Accents are derived from the active theme palette.

final class _BoardColumn {
  const _BoardColumn({required this.title, required this.cards});

  final String title;
  final List<String> cards;

  _BoardColumn copyWith({String? title, List<String>? cards}) {
    return _BoardColumn(title: title ?? this.title, cards: cards ?? this.cards);
  }
}

final class _DragState {
  const _DragState({
    required this.fromCol,
    required this.fromIndex,
    required this.card,
    required this.x,
    required this.y,
    required this.hoverCol,
    required this.hoverIndex,
  });

  final int fromCol;
  final int fromIndex;
  final String card;
  final int x;
  final int y;
  final int? hoverCol;
  final int? hoverIndex;

  _DragState copyWith({
    int? x,
    int? y,
    Object? hoverCol = _undefined,
    Object? hoverIndex = _undefined,
  }) {
    return _DragState(
      fromCol: fromCol,
      fromIndex: fromIndex,
      card: card,
      x: x ?? this.x,
      y: y ?? this.y,
      hoverCol: hoverCol == _undefined ? this.hoverCol : hoverCol as int?,
      hoverIndex: hoverIndex == _undefined
          ? this.hoverIndex
          : hoverIndex as int?,
    );
  }
}

const _undefined = Object();

final class _ModalState {
  const _ModalState({
    required this.targetCol,
    required this.insertIndex,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.input,
  });

  final int targetCol;
  final int insertIndex;
  final int width;
  final int height;
  final int x;
  final int y;
  final tui.TextInputModel input;

  _ModalState copyWith({
    int? targetCol,
    int? insertIndex,
    int? width,
    int? height,
    int? x,
    int? y,
    tui.TextInputModel? input,
  }) {
    return _ModalState(
      targetCol: targetCol ?? this.targetCol,
      insertIndex: insertIndex ?? this.insertIndex,
      width: width ?? this.width,
      height: height ?? this.height,
      x: x ?? this.x,
      y: y ?? this.y,
      input: input ?? this.input,
    );
  }
}

final class TrelloModel implements tui.Model {
  const TrelloModel({
    required this.columns,
    required this.width,
    required this.height,
    required this.focusCol,
    required this.focusIndex,
    required this.colScroll,
    required this.drag,
    required this.modal,
    required this.debug,
    required this.theme,
  });

  factory TrelloModel.initial() {
    return TrelloModel(
      columns: const [
        _BoardColumn(
          title: 'Backlog',
          cards: [
            'Add Trello example',
            'Mouse drag+drop',
            'Keyboard fallback',
            'Scroll columns',
          ],
        ),
        _BoardColumn(
          title: 'Doing',
          cards: ['Viewport selection parity', 'UV renderer fixes'],
        ),
        _BoardColumn(
          title: 'Done',
          cards: [
            'Kitchen sink split files',
            'Tab wrap hit testing',
            'Emoji width probe script',
          ],
        ),
      ],
      width: 80,
      height: 24,
      focusCol: 0,
      focusIndex: 0,
      colScroll: const [0, 0, 0],
      drag: null,
      modal: null,
      debug: DebugOverlayModel.initial(
        title: 'Render Metrics',
        rendererLabel: 'UV',
      ),
      theme: 'dark',
    );
  }

  final List<_BoardColumn> columns;
  final int width;
  final int height;
  final int focusCol;
  final int focusIndex;
  final List<int> colScroll;
  final _DragState? drag;
  final _ModalState? modal;
  final DebugOverlayModel debug;
  final String theme;

  TrelloModel copyWith({
    List<_BoardColumn>? columns,
    int? width,
    int? height,
    int? focusCol,
    int? focusIndex,
    List<int>? colScroll,
    Object? drag = _undefined,
    Object? modal = _undefined,
    DebugOverlayModel? debug,
    String? theme,
  }) {
    return TrelloModel(
      columns: columns ?? this.columns,
      width: width ?? this.width,
      height: height ?? this.height,
      focusCol: focusCol ?? this.focusCol,
      focusIndex: focusIndex ?? this.focusIndex,
      colScroll: colScroll ?? this.colScroll,
      drag: drag == _undefined ? this.drag : drag as _DragState?,
      modal: modal == _undefined ? this.modal : modal as _ModalState?,
      debug: debug ?? this.debug,
      theme: theme ?? this.theme,
    );
  }

  ThemePalette get _palette => ThemePalette.byName(theme);

  Style _accentBoldStyle() => Style().foreground(_palette.accentBold).bold();
  Style _textDimStyle() => Style().foreground(_palette.textDim).dim();
  Style _borderStyle() => Style().foreground(_palette.border).dim();

  List<Color> _accentColors() => [
    _palette.accent,
    _palette.info,
    _palette.highlight,
    _palette.success,
    _palette.warning,
  ];

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final debugUpdate = debug.update(msg);
    final nextDebug = debugUpdate.model;
    if (debugUpdate.consumed) {
      return (copyWith(debug: nextDebug), debugUpdate.cmd);
    }

    switch (msg) {
      case tui.WindowSizeMsg(:final width, :final height):
        final base = copyWith(
          width: width,
          height: height,
          debug: nextDebug,
        )._clampScrolls();
        final m = base.modal;
        if (m == null) return (base, null);
        final nextModal = base._layoutModal(
          m.copyWith(width: width, height: height),
        );
        return (base.copyWith(modal: nextModal), null);

      case tui.FrameTickMsg():
        // FrameTickMsg drives the debug overlay updates automatically
        return (copyWith(debug: nextDebug), null);

      case tui.KeyMsg(:final key):
        if (key.isChar('d') || key.isChar('D')) {
          final toggled = nextDebug.toggle();
          return (copyWith(debug: toggled), null);
        }
        if (key.isChar('c') || key.isChar('C')) {
          final themes = ThemePalette.names;
          final idx = themes.indexOf(theme);
          final next = themes[(idx + 1) % themes.length];
          return (copyWith(debug: nextDebug, theme: next), null);
        }
        if (key.isChar('q') || key == tui.Keys.ctrlC) {
          return (copyWith(debug: nextDebug), tui.Cmd.quit());
        }

        if (modal case final m?) {
          return _updateModal(m, key);
        }

        if (key.type == tui.KeyType.escape) {
          // Escape cancels a drag (if any) but does not quit.
          if (drag != null) return (copyWith(drag: null), null);
          return (copyWith(debug: nextDebug), null);
        }

        if (key.type == tui.KeyType.enter || key.isChar(' ')) {
          // Keyboard pickup/drop (minimal).
          if (drag != null) {
            return (_commitDrag(), null);
          }
          return (_startKeyboardDrag(), null);
        }

        if (key.isChar('n') || key.isChar('a')) {
          return _openNewCardModal();
        }

        return (_handleNavKey(key), null);

      case tui.MouseMsg(:final button, :final action, :final x, :final y):
        if (modal case final m?) {
          if (action == tui.MouseAction.press) {
            final next = _modalPress(m, x, y);
            return (next.copyWith(debug: nextDebug), null);
          }
          return (copyWith(debug: nextDebug), null);
        }

        if (action == tui.MouseAction.wheel ||
            (action == tui.MouseAction.press &&
                (button == tui.MouseButton.wheelUp ||
                    button == tui.MouseButton.wheelDown))) {
          return (_onMouseWheel(button, x, y), null);
        }
        return switch ((action, button)) {
          (tui.MouseAction.press, tui.MouseButton.left) => (
            _onMousePress(x, y),
            null,
          ),
          (tui.MouseAction.motion, tui.MouseButton.left) => (
            _onMouseMotion(x, y),
            null,
          ),
          (tui.MouseAction.release, tui.MouseButton.left) => (
            _onMouseRelease(x, y),
            null,
          ),
          _ => (copyWith(debug: nextDebug), null),
        };

      default:
        return (copyWith(debug: nextDebug), null);
    }
  }

  TrelloModel _handleNavKey(tui.Key key) {
    final col = focusCol.clamp(0, columns.length - 1);
    final maxIdx = math.max(0, columns[col].cards.length - 1);
    var idx = focusIndex.clamp(0, maxIdx);

    if (key.type == tui.KeyType.tab) {
      final nextCol = key.shift ? (col - 1) : (col + 1);
      final nc = nextCol.clamp(0, columns.length - 1);
      return copyWith(focusCol: nc, focusIndex: 0)._ensureFocusVisible();
    }

    final next = switch (key.type) {
      tui.KeyType.left => copyWith(
        focusCol: (col - 1).clamp(0, columns.length - 1),
        focusIndex: 0,
      ),
      tui.KeyType.right => copyWith(
        focusCol: (col + 1).clamp(0, columns.length - 1),
        focusIndex: 0,
      ),
      tui.KeyType.up => copyWith(focusIndex: (idx - 1).clamp(0, maxIdx)),
      tui.KeyType.down => copyWith(focusIndex: (idx + 1).clamp(0, maxIdx)),
      tui.KeyType.pageUp => _scrollColumnBy(col, -_pageScrollAmount()),
      tui.KeyType.pageDown => _scrollColumnBy(col, _pageScrollAmount()),
      tui.KeyType.home => copyWith(focusIndex: 0),
      tui.KeyType.end => copyWith(focusIndex: maxIdx),
      _ => this,
    };
    return next._ensureFocusVisible();
  }

  int _boardHeight() => math.max(4, height - _boardTop);

  int _maxVisibleCards() {
    final cardViewport = _boardHeight() - 2; // header + divider
    if (cardViewport <= 0) return 0;
    final perCard = _cardPanelHeight + _cardGap;
    return math.max(1, cardViewport ~/ perCard);
  }

  int _pageScrollAmount() => _maxVisibleCards();

  int _maxScrollFor(int col) {
    final cards = columns[col].cards.length;
    final visible = _maxVisibleCards();
    return math.max(0, cards - visible);
  }

  TrelloModel _scrollColumnBy(int col, int delta) {
    if (delta == 0) return this;
    final c = col.clamp(0, columns.length - 1);
    final maxScroll = _maxScrollFor(c);
    final current = (c < colScroll.length ? colScroll[c] : 0);
    final next = (current + delta).clamp(0, maxScroll);
    final nextScroll = List<int>.from(colScroll);
    while (nextScroll.length < columns.length) {
      nextScroll.add(0);
    }
    nextScroll[c] = next;
    return copyWith(colScroll: nextScroll);
  }

  TrelloModel _ensureFocusVisible() {
    final c = focusCol.clamp(0, columns.length - 1);
    final cardsLen = columns[c].cards.length;
    if (cardsLen == 0) return this;

    final visible = _maxVisibleCards();
    final maxScroll = _maxScrollFor(c);
    final scroll = (c < colScroll.length ? colScroll[c] : 0).clamp(
      0,
      maxScroll,
    );
    final idx = focusIndex.clamp(0, cardsLen - 1);

    var nextScrollVal = scroll;
    if (idx < scroll) nextScrollVal = idx;
    if (idx >= scroll + visible) nextScrollVal = idx - visible + 1;
    nextScrollVal = nextScrollVal.clamp(0, maxScroll);

    if (nextScrollVal == scroll && idx == focusIndex) return this;
    final nextScroll = List<int>.from(colScroll);
    while (nextScroll.length < columns.length) {
      nextScroll.add(0);
    }
    nextScroll[c] = nextScrollVal;
    return copyWith(focusIndex: idx, colScroll: nextScroll);
  }

  TrelloModel _clampScrolls() {
    if (columns.isEmpty) return this;
    final next = List<int>.from(colScroll);
    while (next.length < columns.length) {
      next.add(0);
    }
    for (var i = 0; i < columns.length; i++) {
      next[i] = next[i].clamp(0, _maxScrollFor(i));
    }
    return copyWith(colScroll: next);
  }

  TrelloModel _onMouseWheel(tui.MouseButton button, int x, int y) {
    final col = _columnAt(x);
    if (col == null) return this;
    return switch (button) {
      tui.MouseButton.wheelUp => _scrollColumnBy(col, -1),
      tui.MouseButton.wheelDown => _scrollColumnBy(col, 1),
      _ => this,
    };
  }

  int? _columnAt(int x) {
    for (var c = 0; c < columns.length; c++) {
      final x0 = c * (_colWidth + _colGap);
      final x1 = x0 + _colWidth;
      if (x >= x0 && x < x1) return c;
    }
    return null;
  }

  (tui.Model, tui.Cmd?) _openNewCardModal() {
    final col = focusCol.clamp(0, columns.length - 1);
    final insertAt = (focusIndex + 1).clamp(0, columns[col].cards.length);

    final w = math.min(56, math.max(28, width - 8));
    final input = tui.TextInputModel(
      prompt: '',
      width: w - 8,
      placeholder: 'New card title…',
      useVirtualCursor: false,
    );
    final focusCmd = input.focus();

    final modal = _layoutModal(
      _ModalState(
        targetCol: col,
        insertIndex: insertAt,
        width: w,
        height: 5,
        x: 0,
        y: 0,
        input: input,
      ),
    );
    return (copyWith(modal: modal, drag: null), focusCmd);
  }

  _ModalState _layoutModal(_ModalState m) {
    final x = ((width - m.width) ~/ 2).clamp(0, math.max(0, width - 1)).toInt();
    final y = ((height - m.height) ~/ 2)
        .clamp(0, math.max(0, height - 1))
        .toInt();
    return m.copyWith(x: x, y: y);
  }

  (tui.Model, tui.Cmd?) _updateModal(_ModalState m, tui.Key key) {
    if (key.type == tui.KeyType.escape) {
      return (copyWith(modal: null), null);
    }

    if (key.type == tui.KeyType.enter || key.isEnterLike) {
      final title = m.input.value.trim();
      if (title.isEmpty) return (this, null);
      final updated = _insertCard(m.targetCol, m.insertIndex, title);
      return (updated.copyWith(modal: null), null);
    }

    final (nextInput, cmd) = m.input.update(tui.KeyMsg(key));
    final nextModal = m.copyWith(input: nextInput);
    return (copyWith(modal: nextModal), cmd);
  }

  TrelloModel _modalPress(_ModalState m, int x, int y) {
    final inside =
        x >= m.x && x < m.x + m.width && y >= m.y && y < m.y + m.height;
    if (!inside) return copyWith(modal: null);
    return this;
  }

  TrelloModel _insertCard(int col, int insertAt, String title) {
    final out = columns
        .map((c) => c.copyWith(cards: List.of(c.cards)))
        .toList();
    final c = col.clamp(0, out.length - 1);
    final cards = out[c].cards;
    final idx = insertAt.clamp(0, cards.length);
    cards.insert(idx, title);
    return copyWith(
      columns: out,
      focusCol: c,
      focusIndex: idx,
    )._clampScrolls()._ensureFocusVisible();
  }

  TrelloModel _startKeyboardDrag() {
    final col = focusCol.clamp(0, columns.length - 1);
    if (columns[col].cards.isEmpty) return this;
    final idx = focusIndex.clamp(0, columns[col].cards.length - 1);
    final card = columns[col].cards[idx];
    return copyWith(
      drag: _DragState(
        fromCol: col,
        fromIndex: idx,
        card: card,
        x: 0,
        y: 0,
        hoverCol: col,
        hoverIndex: idx,
      ),
    );
  }

  TrelloModel _onMousePress(int x, int y) {
    // Click on column header to focus the column.
    if (y == _boardTop) {
      final col = _columnAt(x);
      if (col != null) {
        return copyWith(
          focusCol: col,
          focusIndex: 0,
          drag: null,
        )._ensureFocusVisible();
      }
    }

    final hit = _hitCardAt(x, y);
    if (hit == null) {
      final col = _columnAt(x);
      if (col != null) {
        return copyWith(
          focusCol: col,
          focusIndex: 0,
          drag: null,
        )._ensureFocusVisible();
      }
      return copyWith(drag: null);
    }

    final (col, idx) = hit;
    final card = columns[col].cards[idx];
    return copyWith(
      focusCol: col,
      focusIndex: idx,
      drag: _DragState(
        fromCol: col,
        fromIndex: idx,
        card: card,
        x: x,
        y: y,
        hoverCol: col,
        hoverIndex: idx,
      ),
    );
  }

  TrelloModel _onMouseMotion(int x, int y) {
    final d = drag;
    if (d == null) return this;

    final hover = _hitInsertAt(x, y);
    if (hover == null) {
      return copyWith(
        drag: d.copyWith(x: x, y: y, hoverCol: null, hoverIndex: null),
      );
    }
    final (hc, hi) = hover;
    return copyWith(
      drag: d.copyWith(x: x, y: y, hoverCol: hc, hoverIndex: hi),
    );
  }

  TrelloModel _onMouseRelease(int x, int y) {
    if (drag == null) return this;
    // Use the last hover target; release position is noisy with terminals.
    return _commitDrag();
  }

  TrelloModel _commitDrag() {
    final d = drag;
    if (d == null) return this;
    final targetCol = d.hoverCol;
    final targetIndex = d.hoverIndex;
    if (targetCol == null || targetIndex == null) {
      return copyWith(drag: null);
    }

    final fromCol = d.fromCol;
    final fromIndex = d.fromIndex;
    if (fromCol < 0 || fromCol >= columns.length) return copyWith(drag: null);
    if (fromIndex < 0 || fromIndex >= columns[fromCol].cards.length) {
      return copyWith(drag: null);
    }

    final out = columns
        .map((c) => c.copyWith(cards: List.of(c.cards)))
        .toList();
    final card = out[fromCol].cards.removeAt(fromIndex);

    final toCol = targetCol.clamp(0, out.length - 1);
    final toCards = out[toCol].cards;

    var insertAt = targetIndex;
    if (toCol == fromCol && insertAt > fromIndex) insertAt -= 1;
    insertAt = insertAt.clamp(0, toCards.length);
    toCards.insert(insertAt, card);

    return copyWith(
      columns: out,
      focusCol: toCol,
      focusIndex: insertAt.clamp(0, math.max(0, toCards.length - 1)),
      drag: null,
    )._clampScrolls()._ensureFocusVisible();
  }

  /// Returns (columnIndex, cardIndex) for a click on a card, or null.
  (int, int)? _hitCardAt(int x, int y) {
    final boardY = y - _boardTop;
    if (boardY < 2) return null; // header lines inside the board region
    final cardAreaY = boardY - 2; // below column header & separator
    if (cardAreaY < 0) return null;

    for (var c = 0; c < columns.length; c++) {
      final x0 = c * (_colWidth + _colGap);
      final x1 = x0 + _colWidth;
      if (x < x0 || x >= x1) continue;

      final perCard = _cardPanelHeight + _cardGap;
      final scroll = (c < colScroll.length ? colScroll[c] : 0);
      final idx = scroll + (cardAreaY ~/ perCard);
      final within = cardAreaY % perCard;
      if (within >= _cardPanelHeight) return null; // gap between cards
      if (idx < 0 || idx >= columns[c].cards.length) return null;
      return (c, idx);
    }
    return null;
  }

  /// Returns (columnIndex, insertIndex) for hovering/dropping, or null.
  ///
  /// Unlike [_hitCardAt], this allows dropping:
  /// - into the gap between cards (inserts after)
  /// - below the last card (inserts at end)
  /// - into empty columns (inserts at 0)
  (int, int)? _hitInsertAt(int x, int y) {
    // Tolerate both 0-based and 1-based mouse coordinates.
    final candidates = <(int x, int y)>[
      (x, y),
      (x - 1, y),
      (x, y - 1),
      (x - 1, y - 1),
    ];

    for (final (cx, cy) in candidates) {
      final boardY = cy - _boardTop;
      if (boardY < 2) continue;
      final cardAreaY = boardY - 2;
      if (cardAreaY < 0) continue;

      for (var c = 0; c < columns.length; c++) {
        final x0 = c * (_colWidth + _colGap);
        final x1 = x0 + _colWidth;
        if (cx < x0 || cx >= x1) continue;

        final cardsLen = columns[c].cards.length;
        if (cardsLen == 0) return (c, 0);

        final perCard = _cardPanelHeight + _cardGap;
        final scroll = (c < colScroll.length ? colScroll[c] : 0);
        final idx = scroll + (cardAreaY ~/ perCard);
        final within = cardAreaY % perCard;

        if (idx < 0) return (c, 0);
        if (idx >= cardsLen) return (c, cardsLen);

        // If we're in the gap, insert *after* the preceding card.
        if (within >= _cardPanelHeight) {
          return (c, (idx + 1).clamp(0, cardsLen));
        }
        return (c, idx);
      }
    }
    return null;
  }

  @override
  Object view() {
    final title = _accentBoldStyle().render('Trello Board');
    final help = _textDimStyle().render(
      'mouse: drag/drop • tab/shift+tab: column • ↑/↓: move • enter/space: pickup/drop • n: new card • c: theme • d: debug • q: quit',
    );

    final base = [title, help, _renderColumns()].join('\n');
    final m = modal;
    if (m == null) {
      final composed = debug.compose(_padToScreen(base));
      return _padToScreen(composed);
    }

    final (modalPanel, cursor) = _renderModal(m);
    final comp = uv.Compositor([
      uv.Layer(uv.StyledString(base)).setId('base').setZ(0),
      uv.Layer(
        uv.StyledString(modalPanel),
      ).setId('modal').setX(m.x).setY(m.y).setZ(10),
    ]);
    final composed = debug.compose(_padToScreen(comp.render()));
    return View(content: _padToScreen(composed), cursor: cursor);
  }

  (String, uv.Cursor?) _renderModal(_ModalState m) {
    final prompt = _textDimStyle().render('Enter to add • Esc to cancel');
    final inputObj = m.input.view();
    final inputLine = switch (inputObj) {
      View(:final content) => content,
      final String s => s,
      _ => inputObj.toString(),
    };
    final body = [inputLine, '', prompt].join('\n');

    final panel = tui.PanelComponent(
      title: 'New card',
      content: body,
      padding: 1,
      width: m.width,
      chars: tui.PanelBoxChars.double,
      renderConfig: tui.RenderConfig(terminalWidth: width),
    ).render();
    final cursor = switch (inputObj) {
      View(cursor: final c?) => c,
      _ => null,
    };
    if (cursor == null) return (panel, null);

    // Translate the input's cursor (relative to the input line) into an absolute
    // cursor within the modal panel.
    //
    // PanelComponent layout:
    // - 1 border cell on each side
    // - horizontal padding spaces within content
    // - inputLine is the first content line
    final absX = (m.x + 2 + cursor.position.x).toInt();
    final absY = (m.y + 1 + cursor.position.y).toInt();
    return (
      panel,
      uv.Cursor(
        position: uv.Position(absX, absY),
        color: cursor.color,
        shape: cursor.shape,
        blink: cursor.blink,
      ),
    );
  }

  String _padToScreen(String content) {
    final w = width;
    final h = height;
    if (w <= 0 || h <= 0) return content;

    final inLines = content.split('\n');
    final out = <String>[];

    for (var i = 0; i < inLines.length && out.length < h; i++) {
      var line = inLines[i];
      // Hard cut to width (ANSI-aware) without wrapping.
      if (Style.visibleLength(line) > w) {
        line = ranges.cutAnsiByCells(line, 0, w);
      }
      final pad = w - Style.visibleLength(line);
      if (pad > 0) line = '$line${' ' * pad}';
      out.add(line);
    }

    while (out.length < h) {
      out.add(' ' * w);
    }

    return out.join('\n');
  }

  String _renderColumns() {
    final boardH = _boardHeight();
    final colBlocks = <List<String>>[];
    for (var i = 0; i < columns.length; i++) {
      colBlocks.add(_renderColumn(i, boardH));
    }

    final out = <String>[];
    for (var row = 0; row < boardH; row++) {
      final sb = StringBuffer();
      for (var c = 0; c < colBlocks.length; c++) {
        if (c > 0) sb.write(' ' * _colGap);
        sb.write(colBlocks[c][row]);
      }
      out.add(sb.toString());
    }
    return out.join('\n');
  }

  List<String> _renderColumn(int col, int boardH) {
    final isFocusedCol = col == focusCol;
    final accents = _accentColors();
    final accent = accents[col % accents.length];
    final headerStyle = isFocusedCol
        ? Style()
              .bold()
              .foreground(Colors.black)
              .background(accent)
              .padding(0, 1)
              .width(_colWidth)
        : Style()
              .bold()
              .foreground(_palette.textBold)
              .background(_palette.border)
              .padding(0, 1)
              .width(_colWidth);

    final lines = <String>[
      headerStyle.render(columns[col].title),
      _borderStyle().render('─' * _colWidth),
    ];

    final d = drag;
    final draggingFromThis = d != null && d.fromCol == col;

    final visible = _maxVisibleCards();
    final scroll = (col < colScroll.length ? colScroll[col] : 0).clamp(
      0,
      _maxScrollFor(col),
    );
    final cards = columns[col].cards;
    final start = scroll.clamp(0, cards.length);
    final end = (start + visible).clamp(start, cards.length);

    for (var i = start; i < end; i++) {
      final isFocused = isFocusedCol && i == focusIndex && d == null;
      final isPlaceholder = draggingFromThis && d.fromIndex == i;
      final isDropTarget =
          d != null &&
          d.hoverCol == col &&
          d.hoverIndex == i &&
          !(draggingFromThis && d.fromIndex == i);

      lines.addAll(
        _renderCard(
          cards[i],
          focused: isFocused,
          placeholder: isPlaceholder,
          dropTarget: isDropTarget,
          accent: accent,
        ),
      );
      lines.add(''); // gap
      if (lines.length >= boardH) break;
    }

    // If we're dragging and hovering a column that has no cards, show a target.
    if (d != null && columns[col].cards.isEmpty && d.hoverCol == col) {
      lines.addAll(
        _renderCard(
          'Drop here',
          focused: false,
          placeholder: false,
          dropTarget: true,
          accent: accent,
        ),
      );
    }

    // If we're dragging and hovering below the last card, show an end target.
    if (d != null &&
        columns[col].cards.isNotEmpty &&
        d.hoverCol == col &&
        d.hoverIndex == columns[col].cards.length) {
      lines.addAll(
        _renderCard(
          'Drop at end',
          focused: false,
          placeholder: false,
          dropTarget: true,
          accent: accent,
        ),
      );
    }

    // Ensure the column block fits the viewport height.
    final out = lines.map((l) => Style().width(_colWidth).render(l)).toList();
    while (out.length < boardH) {
      out.add(' ' * _colWidth);
    }
    if (out.length > boardH) return out.sublist(0, boardH);
    return out;
  }

  List<String> _renderCard(
    String text, {
    required bool focused,
    required bool placeholder,
    required bool dropTarget,
    required Color accent,
  }) {
    final fg = focused ? Colors.black : _palette.text;
    final bg = focused ? accent : _palette.background;
    var textStyle = Style().foreground(fg);
    if (bg != null && bg is! NoColor) {
      textStyle = textStyle.background(bg);
    }
    final marker = Style().foreground(accent).render('▌');

    final chars = dropTarget
        ? tui.PanelBoxChars.heavy
        : (focused ? tui.PanelBoxChars.double : tui.PanelBoxChars.rounded);

    if (placeholder) {
      return tui.PanelComponent(
        content: Style().dim().render('(moving)'),
        padding: 0,
        width: _colWidth,
        chars: chars,
        renderConfig: tui.RenderConfig(terminalWidth: width),
      ).render().split('\n');
    }

    final clipped = _ellipsize(text, _colWidth - 4);
    final content = textStyle.render('$marker $clipped');
    return tui.PanelComponent(
      content: content,
      padding: 0,
      width: _colWidth,
      chars: chars,
      renderConfig: tui.RenderConfig(terminalWidth: width),
    ).render().split('\n');
  }

  String _ellipsize(String text, int maxCells) {
    if (maxCells <= 0) return '';
    if (Style.visibleLength(text) <= maxCells) return text.padRight(maxCells);
    if (maxCells == 1) return '…';
    final cut = ranges.cutAnsiByCells(text, 0, maxCells - 1);
    return '$cut…';
  }
}

Future<void> main(List<String> args) async {
  final uvRenderer = args.contains('--uv-renderer');
  final uvInput = !args.contains('--legacy-input');

  await tui.runProgram(
    TrelloModel.initial(),
    options: tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      bracketedPaste: true,
      useUltravioletRenderer: uvRenderer,
      useUltravioletInputDecoder: uvInput,
      metricsInterval: const Duration(milliseconds: 250),
    ),
  );
}
