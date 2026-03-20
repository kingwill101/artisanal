library;

import 'package:artisanal/bubbles.dart'
    show
        TextDecorationRange,
        TextLineDecoration,
        textDefaultDecorationLayerPriority,
        textDefaultLineDecorationLayerPriority;

import 'input_widgets.dart' show TextAreaController;

/// Builds range decorations from plain text.
typedef TextDecorationLayerBuilder =
    Iterable<TextDecorationRange> Function(String text);

/// Builds whole-line decorations from plain text.
typedef TextLineDecorationLayerBuilder =
    Iterable<TextLineDecoration> Function(String text);

/// Keeps one named range-decoration layer in sync with a text controller.
final class TextDecorationLayerBinding {
  TextDecorationLayerBinding({
    required TextAreaController controller,
    required this.layerKey,
    required TextDecorationLayerBuilder buildDecorations,
    this.priority = textDefaultDecorationLayerPriority,
    this.isActive,
    bool syncImmediately = true,
  }) : _controller = controller,
       _buildDecorations = buildDecorations {
    _controller.addListener(_handleControllerChanged);
    if (syncImmediately) {
      sync(force: true);
    }
  }

  TextAreaController _controller;
  final TextDecorationLayerBuilder _buildDecorations;
  String? _lastText;
  bool _disposed = false;

  /// Named layer updated by this binding.
  final String layerKey;

  /// Priority used when applying decorations to [layerKey].
  final int priority;

  /// Whether this binding should actively manage [layerKey].
  ///
  /// When inactive, controller changes are ignored until [sync] is called
  /// again while the binding is active.
  final bool Function()? isActive;

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

  /// Recomputes range decorations from the controller's current text.
  void sync({bool force = false}) {
    if (_disposed) return;
    if (isActive != null && !isActive!()) {
      return;
    }
    final text = _controller.text;
    if (!force && text == _lastText) {
      return;
    }
    _lastText = text;
    final decorations = _buildDecorations(text).toList(growable: false);
    if (decorations.isEmpty) {
      _controller.clearDecorationLayer(layerKey);
      return;
    }
    _controller.setDecorationLayer(layerKey, decorations, priority: priority);
  }

  /// Clears the managed range-decoration layer.
  void clear() {
    if (_disposed) return;
    _lastText = _controller.text;
    _controller.clearDecorationLayer(layerKey);
  }

  /// Detaches the binding from its controller.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_handleControllerChanged);
  }
}

/// Keeps one named whole-line decoration layer in sync with a text controller.
final class TextLineDecorationLayerBinding {
  TextLineDecorationLayerBinding({
    required TextAreaController controller,
    required this.layerKey,
    required TextLineDecorationLayerBuilder buildDecorations,
    this.priority = textDefaultLineDecorationLayerPriority,
    bool syncImmediately = true,
  }) : _controller = controller,
       _buildDecorations = buildDecorations {
    _controller.addListener(_handleControllerChanged);
    if (syncImmediately) {
      sync(force: true);
    }
  }

  TextAreaController _controller;
  final TextLineDecorationLayerBuilder _buildDecorations;
  String? _lastText;
  bool _disposed = false;

  /// Named layer updated by this binding.
  final String layerKey;

  /// Priority used when applying decorations to [layerKey].
  final int priority;

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

  /// Recomputes whole-line decorations from the controller's current text.
  void sync({bool force = false}) {
    if (_disposed) return;
    final text = _controller.text;
    if (!force && text == _lastText) {
      return;
    }
    _lastText = text;
    final decorations = _buildDecorations(text).toList(growable: false);
    if (decorations.isEmpty) {
      _controller.clearLineDecorationLayer(layerKey);
      return;
    }
    _controller.setLineDecorationLayer(
      layerKey,
      decorations,
      priority: priority,
    );
  }

  /// Clears the managed whole-line decoration layer.
  void clear() {
    if (_disposed) return;
    _lastText = _controller.text;
    _controller.clearLineDecorationLayer(layerKey);
  }

  /// Detaches the binding from its controller.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_handleControllerChanged);
  }
}
