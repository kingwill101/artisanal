/// Strongly-typed Ultraviolet input events (keys, mouse, window, paste, focus).
///
/// Events in the UV subsystem cover key presses, mouse interactions, window
/// lifecycle (resize/visibility), paste payloads, focus changes, and device
/// capability reports like [KittyGraphicsEvent] and [PrimaryDeviceAttributesEvent].
/// They are produced by the streaming [EventDecoder], which translates raw
/// terminal bytes and normalizes reporting based on [MouseMode]/[MouseButton].
///
/// {@category Ultraviolet}
/// {@subCategory Input and Events}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_events_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final dec = EventDecoder();
/// for (final e in dec.decode(bytes)) {
///   if (e is MouseEvent) {
///     // handle mouse per current [MouseMode]
///   } else if (e is KeyEvent) {
///     // handle keyboard
///   }
/// }
/// ```
library;

import 'dart:convert' show jsonEncode;

import 'cell.dart' show UvRgb;
import 'color_utils.dart';
import 'geometry.dart';
import 'key.dart';
import 'mouse.dart';

/// Base type for UV-style input events.
///
/// Upstream: `third_party/ultraviolet/event.go` (`type Event interface{}`).
/// Base type for all UV input and terminal events.
sealed class Event {
  const Event();
}

/// Internal event holding a quoted string payload.
sealed class _QuotedStringEvent extends Event {
  const _QuotedStringEvent(this.value);
  final String value;

  @override
  String toString() => jsonEncode(value);
}

/// Unknown event with raw payload.
final class UnknownEvent extends _QuotedStringEvent {
  const UnknownEvent(super.value);
}

/// Unknown CSI event with raw payload.
final class UnknownCsiEvent extends _QuotedStringEvent {
  const UnknownCsiEvent(super.value);
}

/// Unknown SS3 event with raw payload.
final class UnknownSs3Event extends _QuotedStringEvent {
  const UnknownSs3Event(super.value);
}

/// Unknown OSC event with raw payload.
final class UnknownOscEvent extends _QuotedStringEvent {
  const UnknownOscEvent(super.value);
}

/// Unknown DCS event with raw payload.
final class UnknownDcsEvent extends _QuotedStringEvent {
  const UnknownDcsEvent(super.value);
}

/// Unknown SOS event with raw payload.
final class UnknownSosEvent extends _QuotedStringEvent {
  const UnknownSosEvent(super.value);
}

/// Unknown PM event with raw payload.
final class UnknownPmEvent extends _QuotedStringEvent {
  const UnknownPmEvent(super.value);
}

/// Unknown APC event with raw payload.
final class UnknownApcEvent extends _QuotedStringEvent {
  const UnknownApcEvent(super.value);
}

/// Aggregates multiple events decoded from a single input.
final class MultiEvent extends Event {
  const MultiEvent(this.events);
  final List<Event> events;

  @override
  String toString() {
    final sb = StringBuffer();
    for (final ev in events) {
      sb.write(ev);
      sb.write('\n');
    }
    return sb.toString();
  }
}

/// Reports terminal size in cells and optional pixels.
final class Size extends Event {
  const Size({
    required this.width,
    required this.height,
    this.widthPx = 0,
    this.heightPx = 0,
  });
  final int width;
  final int height;
  final int widthPx;
  final int heightPx;

  /// Returns bounds corresponding to the cell size.
  Rectangle bounds() => Rectangle(minX: 0, minY: 0, maxX: width, maxY: height);

  @override
  String toString() =>
      'Size(width: $width, height: $height, widthPx: $widthPx, heightPx: $heightPx)';
}

/// Reports window size in cells and optional pixels.
final class WindowSizeEvent extends Event {
  const WindowSizeEvent({
    required this.width,
    required this.height,
    this.widthPx = 0,
    this.heightPx = 0,
  });
  final int width;
  final int height;
  final int widthPx;
  final int heightPx;

  /// Returns bounds corresponding to the cell size.
  Rectangle bounds() => Rectangle(minX: 0, minY: 0, maxX: width, maxY: height);

  @override
  String toString() =>
      'WindowSizeEvent(width: $width, height: $height, widthPx: $widthPx, heightPx: $heightPx)';
}

/// Reports window size in pixels.
final class WindowPixelSizeEvent extends Event {
  const WindowPixelSizeEvent({required this.width, required this.height});
  final int width;
  final int height;

  /// Returns bounds corresponding to the pixel size.
  Rectangle bounds() => Rectangle(minX: 0, minY: 0, maxX: width, maxY: height);

  @override
  String toString() => 'WindowPixelSizeEvent($width, $height)';
}

/// Reports terminal cell size in pixels.
final class CellSizeEvent extends Event {
  const CellSizeEvent({required this.width, required this.height});
  final int width;
  final int height;

  /// Returns bounds corresponding to the pixel cell size.
  Rectangle bounds() => Rectangle(minX: 0, minY: 0, maxX: width, maxY: height);

  @override
  String toString() => 'CellSizeEvent($width, $height)';
}

/// Base type for key press/release events.
sealed class KeyEvent extends Event {
  const KeyEvent(this._key);
  final Key _key;

  /// Returns the underlying [Key] descriptor.
  Key key() => _key;

  /// Returns whether the keystroke matches any of the given strings.
  bool matchString(
    String s, [
    String? s2,
    String? s3,
    String? s4,
    String? s5,
  ]) => _key.matchString(s, s2, s3, s4, s5);

  /// Returns a human-readable keystroke (e.g., `ctrl+shift+A`).
  String keystroke() => _key.keystroke();

  @override
  String toString() => _key.toString();
}

/// Key press event.
final class KeyPressEvent extends KeyEvent {
  const KeyPressEvent(super.key);
}

/// Key release event.
final class KeyReleaseEvent extends KeyEvent {
  const KeyReleaseEvent(super.key);
}

/// Base type for mouse click/release/wheel/motion events.
sealed class MouseEvent extends Event {
  const MouseEvent(this._mouse);
  final Mouse _mouse;

  /// Returns the underlying [Mouse] payload (position, button, modifiers).
  Mouse mouse() => _mouse;

  static String _mouseKeystroke(Mouse m) {
    // Upstream event formatting ignores coordinates.
    if (m.button == MouseButton.none) return '';

    var s = '';
    if (KeyMod.contains(m.mod, KeyMod.ctrl)) s += 'ctrl+';
    if (KeyMod.contains(m.mod, KeyMod.alt)) s += 'alt+';
    if (KeyMod.contains(m.mod, KeyMod.shift)) s += 'shift+';

    final name = MouseButton.toName(m.button);
    if (name.isEmpty || name == 'none') {
      s += 'unknown';
    } else {
      s += name;
    }
    return s;
  }

  @override
  String toString() => _mouseKeystroke(_mouse);
}

/// Mouse click event.
final class MouseClickEvent extends MouseEvent {
  const MouseClickEvent(super.mouse);
}

/// Mouse button release event.
final class MouseReleaseEvent extends MouseEvent {
  const MouseReleaseEvent(super.mouse);
}

/// Mouse wheel (scroll) event.
final class MouseWheelEvent extends MouseEvent {
  const MouseWheelEvent(super.mouse);
}

/// Mouse motion (move/drag) event.
final class MouseMotionEvent extends MouseEvent {
  const MouseMotionEvent(super.mouse);

  @override
  String toString() {
    final m = mouse();
    final base = MouseEvent._mouseKeystroke(m);
    if (base.isEmpty) return 'motion';
    return '$base+motion';
  }
}

/// Reports cursor position.
final class CursorPositionEvent extends Event {
  const CursorPositionEvent({required this.x, required this.y});
  final int x;
  final int y;
}

/// Terminal focus gained event.
final class FocusEvent extends Event {
  const FocusEvent();
}

/// Terminal focus lost event.
final class BlurEvent extends Event {
  const BlurEvent();
}

/// Terminal reports dark color scheme preference.
final class DarkColorSchemeEvent extends Event {
  const DarkColorSchemeEvent();
}

/// Terminal reports light color scheme preference.
final class LightColorSchemeEvent extends Event {
  const LightColorSchemeEvent();
}

/// Bracketed paste content.
final class PasteEvent extends Event {
  const PasteEvent(this.content);
  final String content;

  @override
  String toString() => content;
}

/// Bracketed paste start.
final class PasteStartEvent extends Event {
  const PasteStartEvent();
}

/// Bracketed paste end.
final class PasteEndEvent extends Event {
  const PasteEndEvent();
}

/// Terminal version string (e.g., `xterm-kitty 0.32.0`).
final class TerminalVersionEvent extends Event {
  const TerminalVersionEvent(this.name);
  final String name;

  @override
  String toString() => name;
}

/// Xterm ModifyOtherKeys mode report.
final class ModifyOtherKeysEvent extends Event {
  const ModifyOtherKeysEvent(this.mode);
  final int mode;
}

// Kitty graphics events.
/// Options parsed from a Kitty graphics report.
final class KittyOptions {
  const KittyOptions({
    this.action = '',
    this.id = 0,
    this.number = 0,
    this.quiet = 0,
  });

  /// Kitty graphics action (`a=`), e.g. `t` for transmit.
  final String action;

  /// Image id (`i=`).
  final int id;

  /// Image number (`I=`).
  final int number;

  /// Quiet level (`q=`).
  final int quiet;

  @override
  bool operator ==(Object other) =>
      other is KittyOptions &&
      other.action == action &&
      other.id == id &&
      other.number == number &&
      other.quiet == quiet;

  @override
  int get hashCode => Object.hash(action, id, number, quiet);
}

/// Kitty graphics payload (APC `G ... ST`).
final class KittyGraphicsEvent extends Event {
  const KittyGraphicsEvent({required this.options, required this.payload});
  final KittyOptions options;
  final List<int> payload;

  @override
  bool operator ==(Object other) =>
      other is KittyGraphicsEvent &&
      other.options == options &&
      _listEq(other.payload, payload);

  @override
  int get hashCode => Object.hash(options, Object.hashAll(payload));
}

bool _listEq(List<int> a, List<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Kitty keyboard enhancements support report.
final class KeyboardEnhancementsEvent extends Event {
  const KeyboardEnhancementsEvent(this.flags);
  final int flags;

  static const int disambiguateEscapeCodes = 0x01;
  static const int reportEventTypes = 0x02;
  static const int reportAlternateKeys = 0x04;
  static const int reportAllKeysAsEscapeCodes = 0x08;
  static const int reportAssociatedText = 0x10;

  /// Returns whether all [enhancements] bits are present in [flags].
  bool contains(int enhancements) => (flags & enhancements) == enhancements;

  bool get supportsKeyDisambiguation => contains(disambiguateEscapeCodes);
  bool get supportsKeyReleases => contains(reportEventTypes);
  bool get supportsUniformKeyLayout => contains(reportAllKeysAsEscapeCodes);
}

/// Primary device attributes (DA1) report.
final class PrimaryDeviceAttributesEvent extends Event {
  const PrimaryDeviceAttributesEvent(this.attrs);
  final List<int> attrs;
}

/// Secondary device attributes (DA2) report.
final class SecondaryDeviceAttributesEvent extends Event {
  const SecondaryDeviceAttributesEvent(this.attrs);
  final List<int> attrs;
}

/// Tertiary device attributes (DA3) report.
final class TertiaryDeviceAttributesEvent extends Event {
  const TertiaryDeviceAttributesEvent(this.value);
  final String value;
}

enum ModeSetting { notRecognized, reset, set, permanentlySet, permanentlyReset }

/// Terminal mode report.
final class ModeReportEvent extends Event {
  const ModeReportEvent({required this.mode, required this.value});
  final int mode;
  final ModeSetting value;
}

/// Foreground color report.
final class ForegroundColorEvent extends Event {
  const ForegroundColorEvent(this.color);
  final UvRgb? color;

  bool isDark() => isDarkColor(color);
  @override
  String toString() => colorToHex(color);
}

/// Background color report.
final class BackgroundColorEvent extends Event {
  const BackgroundColorEvent(this.color);
  final UvRgb? color;

  bool isDark() => isDarkColor(color);
  @override
  String toString() => colorToHex(color);
}

/// Palette color report for an [index].
final class ColorPaletteEvent extends Event {
  const ColorPaletteEvent(this.index, this.color);
  final int index;
  final UvRgb? color;

  @override
  String toString() => 'ColorPaletteEvent($index, ${colorToHex(color)})';
}

/// Cursor color report.
final class CursorColorEvent extends Event {
  const CursorColorEvent(this.color);
  final UvRgb? color;

  bool isDark() => isDarkColor(color);
  @override
  String toString() => colorToHex(color);
}

/// Window operation report (OSC 7/11/… payloads).
final class WindowOpEvent extends Event {
  const WindowOpEvent({required this.op, required this.args});
  final int op;
  final List<int> args;
}

/// Capability string event (e.g., terminal features).
final class CapabilityEvent extends Event {
  const CapabilityEvent(this.content);
  final String content;

  @override
  String toString() => content;
}

// Clipboard selection values (OSC 52).
abstract final class ClipboardSelection {
  /// Unspecified selection (used by upstream for malformed OSC 52 payloads).
  static const int none = 0;
  static const int system = 0x63; // 'c'
  static const int primary = 0x70; // 'p'
}

/// Clipboard selection and content (OSC 52).
final class ClipboardEvent extends Event {
  const ClipboardEvent({
    this.content = '',
    this.selection = ClipboardSelection.none,
  });
  final String content;
  final int selection;

  /// Returns the clipboard selection value.
  int clipboard() => selection;

  @override
  String toString() => content;
}

// Internal marker for ignored sequences.
/// Internal marker for sequences intentionally ignored.
final class IgnoredEvent extends Event {
  const IgnoredEvent(this.value);
  final String value;
}
