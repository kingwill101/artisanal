/// Viewport wrapper that renders a 1-column scrollbar and supports drag.
library;

import 'dart:math' as math;

import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'viewport.dart';

final class ScrollbarChars {
  const ScrollbarChars({this.track = '│', this.thumb = '█', this.empty = ' '});
  final String track;
  final String thumb;
  final String empty;
}

final class ViewportScrollPane extends ViewComponent {
  ViewportScrollPane({
    required this.viewport,
    this.separator = ' ',
    this.chars = const ScrollbarChars(),
  });

  ViewportModel viewport;
  final String separator;
  final ScrollbarChars chars;

  /// Screen-space origin (top-left) where this pane is rendered.
  ///
  /// Mouse events are reported in screen coordinates, so we translate them into
  /// the viewport's local coordinate system using this origin.
  int originX = 0;
  int originY = 0;

  bool _dragging = false;

  // Cached from last view() so update(MouseMsg) can hit-test the bar.
  int _barX = 0;
  int _height = 0;

  @override
  Cmd? init() => null;

  @override
  (ViewportScrollPane, Cmd?) update(Msg msg) {
    if (msg is MouseMsg) {
      final local = _toLocal(msg);
      final candidates = _localCandidates(local);

      if (msg.button == MouseButton.left && _height > 0 && _maxOffset > 0) {
        switch (msg.action) {
          case MouseAction.press:
            if (candidates.any(_isOnBar)) {
              _dragging = true;
              _scrollToCandidateY(candidates);
              return (this, null);
            }
            break;
          case MouseAction.release:
            _dragging = false;
            return (this, null);
          case MouseAction.motion:
            if (_dragging) {
              _scrollToCandidateY(candidates);
              return (this, null);
            }
            break;
          default:
            break;
        }
      }

      // Fall through: let viewport handle clicks/selection, etc.
      final (vp, cmd) = viewport.update(local);
      viewport = vp;
      return (this, cmd);
    }

    final (vp, cmd) = viewport.update(msg);
    viewport = vp;
    return (this, cmd);
  }

  /// Returns true when this mouse event should not be treated as a "content"
  /// interaction by the parent (e.g. focus changes) because it's intended to
  /// scroll/drag the scrollbar.
  bool consumesMouse(MouseMsg msg) {
    if (msg.action == MouseAction.wheel) return true;
    if (switch (msg.button) {
      MouseButton.wheelUp ||
      MouseButton.wheelDown ||
      MouseButton.wheelLeft ||
      MouseButton.wheelRight => true,
      _ => false,
    }) {
      return true;
    }

    if (msg.button == MouseButton.left) {
      return switch (msg.action) {
        MouseAction.press => _localCandidates(_toLocal(msg)).any(_isOnBar),
        MouseAction.motion => _dragging,
        MouseAction.release => _dragging,
        _ => false,
      };
    }
    return false;
  }

  int get _maxOffset {
    final h = viewport.height;
    if (h == null || h <= 0) return 0;
    return math.max(0, viewport.lines.length - h);
  }

  MouseMsg _toLocal(MouseMsg msg) =>
      msg.copyWith(x: msg.x - originX, y: msg.y - originY);

  List<(int x, int y)> _localCandidates(MouseMsg local) => <(int x, int y)>[
    (local.x, local.y),
    (local.x - 1, local.y),
    (local.x, local.y - 1),
    (local.x - 1, local.y - 1),
  ];

  bool _isOnBar((int x, int y) p) {
    final (x, y) = p;
    if (x != _barX) return false;
    final h = viewport.height;
    if (h == null || h <= 0) return false;
    return y >= 0 && y < h;
  }

  void _scrollToCandidateY(List<(int x, int y)> candidates) {
    for (final p in candidates) {
      if (_isOnBar(p)) {
        _scrollToBarY(p.$2);
        return;
      }
    }
  }

  void _scrollToBarY(int localY) {
    final h = viewport.height;
    if (h == null || h <= 0) return;
    final maxOffset = _maxOffset;
    if (maxOffset <= 0) return;

    final yIn = localY.clamp(0, h - 1);
    final denom = math.max(1, h - 1);
    final pct = (yIn / denom).clamp(0.0, 1.0);
    final off = (pct * maxOffset).round().clamp(0, maxOffset);
    viewport = viewport.setYOffset(off);
  }

  int? contentLineAtMouse(MouseMsg msg) {
    final local = _toLocal(msg);
    final candidates = _localCandidates(local);
    for (final (x, y) in candidates) {
      final h = viewport.height ?? viewport.lines.length;
      if (y < 0 || y >= h) continue;
      // Ignore clicks on the scrollbar column.
      if (x == _barX) continue;
      return viewport.yOffset + y;
    }
    return null;
  }

  (int line, int col)? contentPosAtMouse(MouseMsg msg) {
    final local = _toLocal(msg);
    final candidates = _localCandidates(local);
    for (final (x, y) in candidates) {
      final h = viewport.height ?? viewport.lines.length;
      if (y < 0 || y >= h) continue;
      if (x == _barX) continue;
      if (x < 0 || x >= viewport.width) continue;
      return (viewport.yOffset + y, viewport.xOffset + x);
    }
    return null;
  }

  @override
  String view() {
    final h = viewport.height ?? 0;
    _height = h;

    final viewLines = viewport.view().split('\n');
    final bar = _scrollbarLines(
      height: viewLines.length,
      contentLines: viewport.lines.length,
      scrollPercent: viewport.scrollPercent,
      chars: chars,
    );

    // content width + separator => bar column
    _barX = viewport.width + separator.length;

    final out = <String>[];
    for (var i = 0; i < viewLines.length; i++) {
      out.add('${viewLines[i]}$separator${bar[i]}');
    }
    return out.join('\n');
  }
}

List<String> _scrollbarLines({
  required int height,
  required int contentLines,
  required double scrollPercent,
  required ScrollbarChars chars,
}) {
  if (height <= 0) return const [];
  if (contentLines <= height) {
    return List<String>.filled(height, chars.empty);
  }

  final track = List<String>.filled(height, chars.track);
  final thumbHeight = math.max(1, ((height * height) / contentLines).round());
  final maxTop = math.max(0, height - thumbHeight);
  final top = (scrollPercent * maxTop).round().clamp(0, maxTop);

  for (var i = 0; i < thumbHeight; i++) {
    track[top + i] = chars.thumb;
  }
  return track;
}
