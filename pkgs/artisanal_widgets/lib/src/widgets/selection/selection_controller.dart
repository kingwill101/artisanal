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

  /// Sequential click count at the last click position.
  int _lastClickCount = 0;

  final Map<Object, _SelectionParticipant> _participants =
      <Object, _SelectionParticipant>{};

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

  /// Whether any selectable fragments are registered with this controller.
  bool get hasParticipants => _participants.isNotEmpty;

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

  /// Extracts the selected text across all registered participants.
  ///
  /// Registered fragments are joined in reading order: top-to-bottom and then
  /// left-to-right, matching the behavior we want for shared drag selection
  /// inside a [SelectionArea].
  String getSelectedRegisteredText() {
    if (!hasSelection || _participants.isEmpty) return '';

    final fragments = _participants.values.toList()
      ..sort((a, b) {
        final aOrigin = a.globalOrigin;
        final bOrigin = b.globalOrigin;
        final byY = aOrigin.y.compareTo(bOrigin.y);
        if (byY != 0) return byY;
        return aOrigin.x.compareTo(bOrigin.x);
      });

    final selected = <String>[];
    for (final fragment in fragments) {
      final origin = fragment.globalOrigin;
      final localStart = (
        x: _selectionStart!.x - origin.x,
        y: _selectionStart!.y - origin.y,
      );
      final localEnd = (
        x: _selectionEnd!.x - origin.x,
        y: _selectionEnd!.y - origin.y,
      );
      final text = extractSelectedText(
        fragment.getContentLines(),
        selectionStart: localStart,
        selectionEnd: localEnd,
      );
      if (text.isNotEmpty) {
        selected.add(text);
      }
    }

    return selected.join('\n');
  }

  void _registerParticipant(_SelectionParticipant participant) {
    _participants[participant.owner] = participant;
  }

  void _unregisterParticipant(Object owner) {
    _participants.remove(owner);
  }
}

class _SelectionParticipant {
  const _SelectionParticipant({
    required this.owner,
    required this.getGlobalOrigin,
    required this.getContentLines,
  });

  final Object owner;
  final SelectionPoint Function() getGlobalOrigin;
  final List<String> Function() getContentLines;

  SelectionPoint get globalOrigin => getGlobalOrigin();
}
