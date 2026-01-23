/// Mouse input modes and buttons for UV terminal interaction.
///
/// [MouseMode] controls how terminals report mouse activity (click/drag/motion),
/// and [MouseButton] identifies physical buttons (left/middle/right, wheel,
/// extra). Use with [EventDecoder] and [Terminal] to enable/disable reporting
/// and to handle pointer input consistently across emulators.
///
/// {@category Ultraviolet}
/// {@subCategory Input}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_events_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final mode = MouseMode.drag;
/// final name = MouseButton.toName(MouseButton.left); // "left"
/// ```
library;

import 'key.dart';

/// Mouse mode.
///
/// Upstream: `third_party/ultraviolet/mouse.go` (`MouseMode`).
enum MouseMode { none, click, drag, motion }

/// Mouse button codes (X11-style).
///
/// Upstream: `github.com/charmbracelet/x/ansi` (`MouseButton`) + `mouse.go`.
abstract final class MouseButton {
  static const int none = 0;
  static const int left = 1;
  static const int middle = 2;
  static const int right = 3;
  static const int wheelUp = 4;
  static const int wheelDown = 5;
  static const int wheelLeft = 6;
  static const int wheelRight = 7;
  static const int backward = 8;
  static const int forward = 9;
  static const int button10 = 10;
  static const int button11 = 11;

  /// Returns a human-readable name for a mouse [button] code.
  static String toName(int button) {
    switch (button) {
      case none:
        return 'none';
      case left:
        return 'left';
      case middle:
        return 'middle';
      case right:
        return 'right';
      case wheelUp:
        return 'wheelup';
      case wheelDown:
        return 'wheeldown';
      case wheelLeft:
        return 'wheelleft';
      case wheelRight:
        return 'wheelright';
      case backward:
        return 'backward';
      case forward:
        return 'forward';
      case button10:
        return 'button10';
      case button11:
        return 'button11';
      default:
        return '';
    }
  }
}

/// Mouse event payload.
///
/// Upstream: `third_party/ultraviolet/mouse.go` (`Mouse`).
final class Mouse {
  const Mouse({
    required this.x,
    required this.y,
    required this.button,
    this.mod = 0,
  });

  final int x;
  final int y;
  final int button;
  final int mod;

  @override
  String toString() {
    var s = '';
    if (KeyMod.contains(mod, KeyMod.ctrl)) s += 'ctrl+';
    if (KeyMod.contains(mod, KeyMod.alt)) s += 'alt+';
    if (KeyMod.contains(mod, KeyMod.shift)) s += 'shift+';

    final str = MouseButton.toName(button);
    if (str.isEmpty) {
      s += 'unknown';
    } else if (str != 'none') {
      s += str;
    }
    if (s.isNotEmpty && !s.endsWith('+')) {
      s += ' ';
    }
    s += '($x,$y)';
    return s;
  }

  @override
  bool operator ==(Object other) =>
      other is Mouse &&
      other.x == x &&
      other.y == y &&
      other.button == button &&
      other.mod == mod;

  @override
  int get hashCode => Object.hash(x, y, button, mod);
}
