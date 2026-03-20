library;

import 'package:artisanal/bubbles.dart'
    show
        TextDiagnosticRange,
        TextPatternDiagnosticRule,
        TextPositionDiagnosticRange,
        textPatternDiagnostics;

import '../animation/listenable.dart' show ValueListenable;
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
  }) : this._(
         controller: controller,
         buildDiagnostics: buildDiagnostics,
         syncImmediately: syncImmediately,
       );

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

  factory TextDiagnosticsBinding.fromRangeListenable({
    required TextAreaController controller,
    required ValueListenable<Iterable<TextDiagnosticRange>> diagnostics,
    bool syncImmediately = true,
  }) {
    return TextDiagnosticsBinding._(
      controller: controller,
      rangeDiagnostics: diagnostics,
      syncImmediately: syncImmediately,
    );
  }

  factory TextDiagnosticsBinding.fromPositionListenable({
    required TextAreaController controller,
    required ValueListenable<Iterable<TextPositionDiagnosticRange>> diagnostics,
    bool syncImmediately = true,
  }) {
    return TextDiagnosticsBinding._(
      controller: controller,
      positionDiagnostics: diagnostics,
      syncImmediately: syncImmediately,
    );
  }

  TextDiagnosticsBinding._({
    required TextAreaController controller,
    TextDiagnosticsBuilder? buildDiagnostics,
    ValueListenable<Iterable<TextDiagnosticRange>>? rangeDiagnostics,
    ValueListenable<Iterable<TextPositionDiagnosticRange>>? positionDiagnostics,
    bool syncImmediately = true,
  }) : _controller = controller,
       _buildDiagnostics = buildDiagnostics,
       _rangeDiagnostics = rangeDiagnostics,
       _positionDiagnostics = positionDiagnostics {
    _attachListeners();
    if (syncImmediately) {
      sync(force: true);
    }
  }

  TextAreaController _controller;
  final TextDiagnosticsBuilder? _buildDiagnostics;
  final ValueListenable<Iterable<TextDiagnosticRange>>? _rangeDiagnostics;
  final ValueListenable<Iterable<TextPositionDiagnosticRange>>?
  _positionDiagnostics;
  String? _lastText;
  bool _disposed = false;

  /// The controller currently synced by this binding.
  TextAreaController get controller => _controller;
  set controller(TextAreaController value) {
    if (identical(_controller, value)) return;
    if (!_disposed) {
      _detachControllerListener();
    }
    _controller = value;
    _lastText = null;
    if (!_disposed) {
      _attachControllerListener();
      sync(force: true);
    }
  }

  void _attachListeners() {
    _attachControllerListener();
    _rangeDiagnostics?.addListener(_handleDiagnosticsChanged);
    _positionDiagnostics?.addListener(_handleDiagnosticsChanged);
  }

  void _attachControllerListener() {
    if (_buildDiagnostics != null) {
      _controller.addListener(_handleControllerChanged);
    }
  }

  void _detachControllerListener() {
    if (_buildDiagnostics != null) {
      _controller.removeListener(_handleControllerChanged);
    }
  }

  void _handleControllerChanged() {
    sync();
  }

  void _handleDiagnosticsChanged() {
    sync(force: true);
  }

  /// Recomputes diagnostics from the controller's current text.
  void sync({bool force = false}) {
    if (_disposed) return;
    if (_rangeDiagnostics case final diagnosticsSource?) {
      final diagnostics = diagnosticsSource.value.toList(growable: false);
      if (diagnostics.isEmpty) {
        _controller.clearDiagnostics();
        return;
      }
      _controller.setDiagnostics(diagnostics);
      return;
    }
    if (_positionDiagnostics case final diagnosticsSource?) {
      final diagnostics = diagnosticsSource.value.toList(growable: false);
      if (diagnostics.isEmpty) {
        _controller.clearDiagnostics();
        return;
      }
      _controller.setDiagnosticsFromPositions(diagnostics);
      return;
    }
    final text = _controller.text;
    if (!force && text == _lastText) {
      return;
    }
    _lastText = text;
    final diagnostics = _buildDiagnostics!(text).toList(growable: false);
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
    _detachControllerListener();
    _rangeDiagnostics?.removeListener(_handleDiagnosticsChanged);
    _positionDiagnostics?.removeListener(_handleDiagnosticsChanged);
  }
}
