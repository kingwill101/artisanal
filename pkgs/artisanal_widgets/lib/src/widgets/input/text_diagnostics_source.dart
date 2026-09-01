library;

import 'package:artisanal/text_editing.dart'
    show
        TextPatternDiagnosticRule,
        TextPositionDiagnosticRange,
        textPatternDiagnostics;

import '../animation/listenable.dart' show ChangeNotifier, ValueListenable;

/// Builds positional diagnostics from plain text.
typedef TextPositionDiagnosticsBuilder =
    Iterable<TextPositionDiagnosticRange> Function(String text);

/// Produces positional diagnostics from a listenable text source.
///
/// Consumers can observe [value] directly or route it through
/// [TextDiagnosticsBinding.fromPositionListenable] to apply the diagnostics to
/// an editor controller.
final class TextPositionDiagnosticsSource extends ChangeNotifier
    implements ValueListenable<Iterable<TextPositionDiagnosticRange>> {
  TextPositionDiagnosticsSource({
    required ValueListenable<String> text,
    required TextPositionDiagnosticsBuilder buildDiagnostics,
    bool syncImmediately = true,
  }) : _text = text,
       _buildDiagnostics = buildDiagnostics {
    _text.addListener(_handleTextChanged);
    if (syncImmediately) {
      sync(force: true);
    }
  }

  factory TextPositionDiagnosticsSource.patternRules({
    required ValueListenable<String> text,
    required Iterable<TextPatternDiagnosticRule> rules,
    bool syncImmediately = true,
  }) {
    final frozenRules = List<TextPatternDiagnosticRule>.unmodifiable(rules);
    return TextPositionDiagnosticsSource(
      text: text,
      buildDiagnostics: (String text) =>
          textPatternDiagnostics(text: text, rules: frozenRules),
      syncImmediately: syncImmediately,
    );
  }

  ValueListenable<String> _text;
  final TextPositionDiagnosticsBuilder _buildDiagnostics;
  List<TextPositionDiagnosticRange> _value = const [];
  String? _lastText;
  bool _disposed = false;

  /// Current positional diagnostics.
  @override
  Iterable<TextPositionDiagnosticRange> get value => _value;

  /// The text source currently driving this producer.
  ValueListenable<String> get text => _text;
  set text(ValueListenable<String> value) {
    if (identical(_text, value)) return;
    if (!_disposed) {
      _text.removeListener(_handleTextChanged);
    }
    _text = value;
    _lastText = null;
    if (!_disposed) {
      _text.addListener(_handleTextChanged);
      sync(force: true);
    }
  }

  void _handleTextChanged() {
    sync();
  }

  /// Recomputes diagnostics from the current text source.
  void sync({bool force = false}) {
    if (_disposed) return;
    final currentText = _text.value;
    if (!force && currentText == _lastText) {
      return;
    }
    _lastText = currentText;
    final next = _buildDiagnostics(currentText).toList(growable: false);
    if (_diagnosticListsEqual(_value, next)) {
      return;
    }
    _value = next;
    notifyListeners();
  }

  /// Clears the current diagnostics without changing the source text.
  void clear() {
    if (_disposed || _value.isEmpty) return;
    _lastText = _text.value;
    _value = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _text.removeListener(_handleTextChanged);
    super.dispose();
  }
}

bool _diagnosticListsEqual(
  List<TextPositionDiagnosticRange> a,
  List<TextPositionDiagnosticRange> b,
) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
