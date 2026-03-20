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
    return extractSelectedText(
      lines,
      selectionStart: _selectionStart,
      selectionEnd: _selectionEnd,
    );
  }
}
