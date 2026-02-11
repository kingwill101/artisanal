part of 'selection_widgets.dart';

/// Manages text selection state independently of scroll.
///
/// Holds selection start/end coordinates, a selecting flag, and provides
/// methods for text extraction and highlighting. Used by both
/// [SelectableText] (per-widget) and [SelectionArea] (cross-widget).
class SelectionController {
  /// Start of selection in widget-local coordinates (column, line).
  ({int x, int y})? _selectionStart;

  /// End of selection in widget-local coordinates (column, line).
  ({int x, int y})? _selectionEnd;

  /// Whether a drag-selection is in progress.
  bool _selecting = false;

  /// Timestamp of the last click, for double-click word selection.
  DateTime? _lastClickTime;

  /// Position of the last click, for double-click detection.
  ({int x, int y})? _lastClickPos;

  final Set<void Function()> _listeners = <void Function()>{};

  // ---- Public API ----

  /// The selection start point, or null.
  ({int x, int y})? get selectionStart => _selectionStart;

  /// The selection end point, or null.
  ({int x, int y})? get selectionEnd => _selectionEnd;

  /// Whether a selection is currently active.
  bool get hasSelection => _selectionStart != null && _selectionEnd != null;

  /// Whether a drag-selection is in progress.
  bool get selecting => _selecting;

  /// Sets the selection and notifies listeners.
  void setSelection({
    required ({int x, int y}) start,
    required ({int x, int y}) end,
  }) {
    _selectionStart = start;
    _selectionEnd = end;
    _notifyListeners();
  }

  /// Clears the selection and notifies listeners.
  void clearSelection() {
    if (_selectionStart == null && _selectionEnd == null) return;
    _selectionStart = null;
    _selectionEnd = null;
    _selecting = false;
    _notifyListeners();
  }

  /// Adds a listener that is called when the selection changes.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners.toList()) {
      listener();
    }
  }

  /// Extracts the selected text from content [lines].
  String getSelectedText(List<String> lines) {
    if (!hasSelection) return '';

    final s = _selectionStart!;
    final e = _selectionEnd!;

    final startY = math.min(s.y, e.y);
    final endY = math.max(s.y, e.y);

    if (startY < 0 || endY >= lines.length) return '';

    final sb = StringBuffer();
    for (var y = startY; y <= endY; y++) {
      final line = lines[y];
      final plain = Style.stripAnsi(line);

      int startX, endX;
      if (startY == endY) {
        startX = math.min(s.x, e.x);
        endX = math.max(s.x, e.x);
      } else if (y == startY) {
        startX = s.y < e.y ? s.x : e.x;
        endX = Style.visibleLength(plain);
      } else if (y == endY) {
        startX = 0;
        endX = s.y < e.y ? e.x : s.x;
      } else {
        startX = 0;
        endX = Style.visibleLength(plain);
      }

      final maxX = Style.visibleLength(plain);
      startX = startX.clamp(0, maxX);
      endX = endX.clamp(0, maxX);

      if (startX < endX) {
        sb.write(cutAnsiByCells(plain, startX, endX));
      }
      if (y < endY) {
        sb.write('\n');
      }
    }

    return sb.toString();
  }
}
