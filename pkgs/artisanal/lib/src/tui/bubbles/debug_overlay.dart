import 'package:artisanal/src/tui/bubbles/bubbles.dart' show RenderConfig;
import 'package:artisanal/style.dart' show Colors, Style;
import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal/uv.dart' as uv;

import '../msg.dart';
import 'components/panel.dart';

/// Draggable render-metrics overlay for debugging TUI performance.
///
/// Intended to be composed by parent models:
/// - feed it `RenderMetricsMsg` + `WindowSizeMsg`
/// - call [compose] to overlay it above your main view
/// - use [toggle] to show/hide (the caller decides which key)
final class DebugOverlayModel {
  DebugOverlayModel({
    required this.enabled,
    required this.terminalWidth,
    required this.terminalHeight,
    required this.metrics,
    required this.panelX,
    required this.panelY,
    required this.dragging,
    required this.dragOffsetX,
    required this.dragOffsetY,
    this.panelWidth = 40,
    this.marginRight = 2,
    this.marginTop = 0,
    this.marginBottom = 2,
    this.title = 'Render Metrics',
    this.rendererLabel = 'UV',
  });

  // Cached panel render - only rebuild when metrics change
  String? _cachedPanel;
  int _cachedPanelWidth = 0;
  int _cachedPanelHeight = 0;
  int? _cachedMetricsFrame;

  factory DebugOverlayModel.initial({
    bool enabled = false,
    int terminalWidth = 0,
    int terminalHeight = 0,
    String title = 'Render Metrics',
    String rendererLabel = 'UV',
    int panelWidth = 40,
    int marginRight = 2,
    int marginTop = 0,
    int marginBottom = 2,
  }) {
    return DebugOverlayModel(
      enabled: enabled,
      terminalWidth: terminalWidth,
      terminalHeight: terminalHeight,
      metrics: null,
      panelX: null,
      panelY: null,
      dragging: false,
      dragOffsetX: 0,
      dragOffsetY: 0,
      panelWidth: panelWidth,
      marginRight: marginRight,
      marginTop: marginTop,
      marginBottom: marginBottom,
      title: title,
      rendererLabel: rendererLabel,
    );
  }

  final bool enabled;
  final int terminalWidth;
  final int terminalHeight;
  final uv.RenderMetrics? metrics;

  /// Stored top-left position. When null, uses default placement.
  final int? panelX;
  final int? panelY;

  // Drag state.
  final bool dragging;
  final int dragOffsetX;
  final int dragOffsetY;

  // Layout config.
  final int panelWidth;
  final int marginRight;
  final int marginTop;
  final int marginBottom;
  final String title;
  final String rendererLabel;

  DebugOverlayModel copyWith({
    bool? enabled,
    int? terminalWidth,
    int? terminalHeight,
    uv.RenderMetrics? metrics,
    Object? panelX = _unset,
    Object? panelY = _unset,
    bool? dragging,
    int? dragOffsetX,
    int? dragOffsetY,
    int? panelWidth,
    int? marginRight,
    int? marginTop,
    int? marginBottom,
    String? title,
    String? rendererLabel,
  }) {
    return DebugOverlayModel(
      enabled: enabled ?? this.enabled,
      terminalWidth: terminalWidth ?? this.terminalWidth,
      terminalHeight: terminalHeight ?? this.terminalHeight,
      metrics: metrics ?? this.metrics,
      panelX: panelX == _unset ? this.panelX : panelX as int?,
      panelY: panelY == _unset ? this.panelY : panelY as int?,
      dragging: dragging ?? this.dragging,
      dragOffsetX: dragOffsetX ?? this.dragOffsetX,
      dragOffsetY: dragOffsetY ?? this.dragOffsetY,
      panelWidth: panelWidth ?? this.panelWidth,
      marginRight: marginRight ?? this.marginRight,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      title: title ?? this.title,
      rendererLabel: rendererLabel ?? this.rendererLabel,
    );
  }

  DebugOverlayModel toggle() =>
      copyWith(enabled: !enabled, panelX: null, panelY: null, dragging: false);

  DebugOverlayModel setEnabled(bool v) =>
      v == enabled ? this : copyWith(enabled: v);

  /// Updates overlay state and reports whether the message was consumed.
  ({DebugOverlayModel model, Cmd? cmd, bool consumed}) update(Msg msg) {
    switch (msg) {
      case RenderMetricsMsg(:final metrics):
        return (model: copyWith(metrics: metrics), cmd: null, consumed: false);

      case WindowSizeMsg(:final width, :final height):
        final next = copyWith(terminalWidth: width, terminalHeight: height);
        // Clamp stored position if set.
        if (next.panelX != null || next.panelY != null) {
          final (:x, :y, :w, :h) = next._panelRect();
          final clampedX = x.clamp(0, (width - w).clamp(0, width));
          final clampedY = y.clamp(0, (height - h).clamp(0, height));
          return (
            model: next.copyWith(panelX: clampedX, panelY: clampedY),
            cmd: null,
            consumed: false,
          );
        }
        return (model: next, cmd: null, consumed: false);

      case MouseMsg(:final x, :final y, :final button, :final action):
        if (!enabled) return (model: this, cmd: null, consumed: false);

        // When dragging, consume ALL mouse events to prevent selection bleed.
        if (dragging) {
          if (action == MouseAction.release) {
            return (
              model: copyWith(dragging: false),
              cmd: null,
              consumed: true,
            );
          }
          if (action == MouseAction.motion) {
            // Use fixed panel dimensions to avoid expensive re-render during drag
            const panelHeight = 8; // 6 content lines + 2 border lines
            final maxX = (terminalWidth - panelWidth).clamp(0, terminalWidth);
            final maxY = (terminalHeight - panelHeight).clamp(
              0,
              terminalHeight,
            );
            final nx = (x - dragOffsetX).clamp(0, maxX);
            final ny = (y - dragOffsetY).clamp(0, maxY);
            return (
              model: copyWith(panelX: nx, panelY: ny),
              cmd: null,
              consumed: true,
            );
          }
          return (model: this, cmd: null, consumed: true);
        }

        // Start dragging when clicking inside the panel.
        if (action == MouseAction.press && button == MouseButton.left) {
          // Use approximate bounds for hit testing (avoids rendering panel)
          const panelHeight = 8;
          final px = panelX ?? (terminalWidth - panelWidth - marginRight);
          final py = panelY ?? (terminalHeight - panelHeight - marginBottom);
          final inPanel =
              x >= px && x < px + panelWidth && y >= py && y < py + panelHeight;
          if (inPanel) {
            return (
              model: copyWith(
                dragging: true,
                dragOffsetX: x - px,
                dragOffsetY: y - py,
              ),
              cmd: null,
              consumed: true,
            );
          }
        }

        return (model: this, cmd: null, consumed: false);

      default:
        return (model: this, cmd: null, consumed: false);
    }
  }

  /// Renders just the debug panel (cached for performance).
  String panel({int? terminalWidthOverride}) {
    final m = metrics;
    final currentFrame = m?.frameCount ?? 0;

    // Use cached panel if metrics haven't changed
    if (_cachedPanel != null &&
        _cachedMetricsFrame == currentFrame &&
        _cachedPanelWidth == panelWidth) {
      return _cachedPanel!;
    }

    final label = Style().foreground(Colors.yellow).bold();
    final avgFps = m?.averageFps ?? 0.0;
    final avgFrameTimeUs = m?.averageFrameTime.inMicroseconds ?? 0;
    final avgRenderTimeUs = m?.averageRenderDuration.inMicroseconds ?? 0;
    final frameCount = m?.frameCount ?? 0;
    final skippedFrames = m?.skippedFrames ?? 0;
    final renderPct = m?.renderTimePercentage ?? 0.0;

    final content =
        '${label.render('FPS:')} ${avgFps.toStringAsFixed(1)} (${m?.minFps.toStringAsFixed(0) ?? 0}-${m?.maxFps.toStringAsFixed(0) ?? 0})\n'
        '${label.render('Frame Time:')} ${(avgFrameTimeUs / 1000).toStringAsFixed(2)}ms\n'
        '${label.render('Render Time:')} $avgRenderTimeUsµs (${renderPct.toStringAsFixed(1)}%)\n'
        '${label.render('Frames:')} $frameCount (skipped: $skippedFrames)\n'
        '${label.render('Cells:')} ${terminalWidth * terminalHeight}\n'
        '${label.render('Renderer:')} $rendererLabel';

    final rendered = PanelComponent(
      title: title,
      content: content,
      width: panelWidth,
      renderConfig: RenderConfig(
        terminalWidth: terminalWidthOverride ?? terminalWidth,
      ),
    ).render();

    // Cache the result
    _cachedPanel = rendered;
    _cachedMetricsFrame = currentFrame;
    _cachedPanelWidth = panelWidth;
    final lines = rendered.split('\n');
    _cachedPanelHeight = lines.length;

    return rendered;
  }

  /// Overlays the debug panel above [base] using direct string manipulation.
  ///
  /// If not enabled, returns [base] unchanged.
  ///
  /// This is a lightweight alternative to using the UV Compositor, avoiding
  /// the overhead of Canvas allocation and cell-by-cell rendering.
  String compose(String base) {
    if (!enabled) return base;
    final p = panel();
    // Use cached dimensions from panel() call
    final panelH = _cachedPanelHeight;
    final x = panelX ?? (terminalWidth - panelWidth - marginRight);
    final y = panelY ?? (terminalHeight - panelH - marginBottom);

    // Fast path: overlay panel onto base using string manipulation
    return _overlayStrings(base, p, x, y, terminalWidth, terminalHeight);
  }

  /// Overlays [overlay] onto [base] at position (x, y) using string manipulation.
  /// Much faster than Compositor for simple overlays.
  static String _overlayStrings(
    String base,
    String overlay,
    int x,
    int y,
    int screenW,
    int screenH,
  ) {
    final baseLines = base.split('\n');
    final overlayLines = overlay.split('\n');

    // Ensure we have enough base lines
    while (baseLines.length < screenH) {
      baseLines.add('');
    }

    // Overlay each line
    for (
      var i = 0;
      i < overlayLines.length && (y + i) < baseLines.length;
      i++
    ) {
      final targetY = y + i;
      if (targetY < 0) continue;

      final baseLine = baseLines[targetY];
      final overlayLine = overlayLines[i];

      baseLines[targetY] = _overlayLine(baseLine, overlayLine, x, screenW);
    }

    return baseLines.join('\n');
  }

  /// Overlays [overlay] onto [base] at column [x].
  static String _overlayLine(String base, String overlay, int x, int screenW) {
    // Pad base to reach x position if needed
    final baseVisLen = Style.visibleLength(base);
    final overlayVisLen = Style.visibleLength(overlay);

    if (x >= screenW) return base;

    // Build the result: [prefix][overlay][suffix]
    final buf = StringBuffer();

    // Get prefix (content before x)
    if (x > 0) {
      if (baseVisLen <= x) {
        // Base is shorter than x, use base + padding
        buf.write(base);
        buf.write(' ' * (x - baseVisLen));
      } else {
        // Truncate base at position x (respecting ANSI)
        buf.write(_truncateAtVisiblePos(base, x));
      }
    }

    // Add the overlay
    buf.write(overlay);

    // Add suffix if base extends past overlay
    final endX = x + overlayVisLen;
    if (baseVisLen > endX) {
      buf.write(_substringFromVisiblePos(base, endX));
    }

    return buf.toString();
  }

  /// Truncates a string at the given visible position, preserving ANSI codes.
  static String _truncateAtVisiblePos(String s, int visPos) {
    final buf = StringBuffer();
    var visible = 0;
    var i = 0;

    while (i < s.length && visible < visPos) {
      if (s[i] == '\x1B' && i + 1 < s.length && s[i + 1] == '[') {
        // ANSI escape sequence - copy it entirely
        final start = i;
        i += 2;
        while (i < s.length && s[i] != 'm') {
          i++;
        }
        if (i < s.length) i++; // include 'm'
        buf.write(s.substring(start, i));
      } else {
        buf.write(s[i]);
        visible++;
        i++;
      }
    }

    return buf.toString();
  }

  /// Returns substring starting from the given visible position.
  static String _substringFromVisiblePos(String s, int visPos) {
    var visible = 0;
    var i = 0;

    while (i < s.length && visible < visPos) {
      if (s[i] == '\x1B' && i + 1 < s.length && s[i + 1] == '[') {
        // ANSI escape sequence - skip it (don't count as visible)
        i += 2;
        while (i < s.length && s[i] != 'm') {
          i++;
        }
        if (i < s.length) i++; // skip 'm'
      } else {
        visible++;
        i++;
      }
    }

    return i < s.length ? s.substring(i) : '';
  }

  ({int w, int h}) _panelSize() {
    // Ensure panel is rendered to populate cache
    panel();
    return (w: panelWidth, h: _cachedPanelHeight);
  }

  ({int x, int y, int w, int h}) _panelRect() {
    final (:w, :h) = _panelSize();
    final x = panelX ?? (terminalWidth - w - marginRight);
    final y = panelY ?? (terminalHeight - h - marginBottom);
    return (x: x, y: y, w: w, h: h);
  }
}

const _unset = Object();

int mathMax(int a, int b) => a > b ? a : b;
