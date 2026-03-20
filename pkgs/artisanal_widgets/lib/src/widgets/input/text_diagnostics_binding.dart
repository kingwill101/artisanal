library;

import 'package:artisanal/bubbles.dart'
    show
        TextPatternDiagnosticRule,
        TextPositionDiagnosticRange,
        textPatternDiagnostics;

import 'input_widgets.dart' show TextAreaController;

/// Builds positional diagnostics from plain text.
typedef TextDiagnosticsBuilder =
    Iterable<TextPositionDiagnosticRange> Function(String text);

/// Keeps a [TextAreaController]'s diagnostics in sync with its current text.
///
/// This is useful for lightweight producer-side integrations, such as pattern
/// rules or other text-derived diagnostics, without duplicating controller
/// listener and cache plumbing in each caller.
final class TextDiagnosticsBinding {
  TextDiagnosticsBinding({
    required TextAreaController controller,
    required TextDiagnosticsBuilder buildDiagnostics,
    bool syncImmediately = true,
  }) : _controller = controller,
       _buildDiagnostics = buildDiagnostics {
    _controller.addListener(_handleControllerChanged);
    if (syncImmediately) {
      sync(force: true);
    }
  }

  factory TextDiagnosticsBinding.patternRules({
    required TextAreaController controller,
    required Iterable<TextPatternDiagnosticRule> rules,
    bool syncImmediately = true,
  }) {
    final frozenRules = List<TextPatternDiagnosticRule>.unmodifiable(rules);
    return TextDiagnosticsBinding(
      controller: controller,
      buildDiagnostics: (String text) =>
          textPatternDiagnostics(text: text, rules: frozenRules),
      syncImmediately: syncImmediately,
    );
  }

  TextAreaController _controller;
  final TextDiagnosticsBuilder _buildDiagnostics;
  String? _lastText;
  bool _disposed = false;

  /// The controller currently synced by this binding.
  TextAreaController get controller => _controller;
  set controller(TextAreaController value) {
    if (identical(_controller, value)) return;
    if (!_disposed) {
      _controller.removeListener(_handleControllerChanged);
    }
    _controller = value;
    _lastText = null;
    if (!_disposed) {
      _controller.addListener(_handleControllerChanged);
      sync(force: true);
    }
  }

  void _handleControllerChanged() {
    sync();
  }

  /// Recomputes diagnostics from the controller's current text.
  void sync({bool force = false}) {
    if (_disposed) return;
    final text = _controller.text;
    if (!force && text == _lastText) {
      return;
    }
    _lastText = text;
    final diagnostics = _buildDiagnostics(text).toList(growable: false);
    if (diagnostics.isEmpty) {
      _controller.clearDiagnostics();
      return;
    }
    _controller.setDiagnosticsFromPositions(diagnostics);
  }

  /// Clears diagnostics managed by this binding.
  void clear() {
    if (_disposed) return;
    _lastText = _controller.text;
    _controller.clearDiagnostics();
  }

  /// Detaches the binding from its controller.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_handleControllerChanged);
  }
}
