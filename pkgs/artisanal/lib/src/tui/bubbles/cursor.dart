import 'dart:async';

import 'package:artisanal/src/style/style.dart';

import '../cmd.dart';
import '../component.dart';
import '../msg.dart';

/// Cursor display mode.
enum CursorMode {
  /// Cursor blinks on and off.
  blink,

  /// Cursor is always visible.
  static,

  /// Cursor is hidden.
  hide,
}

/// Internal message to initialize cursor blinking.
class _InitialBlinkMsg extends Msg {
  const _InitialBlinkMsg();
}

/// Message indicating the cursor should toggle its blink state.
class CursorBlinkMsg extends Msg {
  const CursorBlinkMsg({required this.id, required this.tag});

  /// The ID of the cursor this message is for.
  final int id;

  /// Tag to prevent duplicate blink messages.
  final int tag;
}

/// Internal message when blink is canceled.
class _BlinkCanceledMsg extends Msg {
  const _BlinkCanceledMsg();
}

/// Global ID counter for cursor instances.
int _lastCursorId = 0;

int _nextCursorId() => ++_lastCursorId;

/// A blinking cursor widget for text input components.
///
/// The cursor can be configured to blink, remain static, or be hidden.
/// It follows the Elm Architecture pattern and can be composed into
/// larger text input components.
///
/// ## Example
///
/// ```dart
/// class TextInputModel implements Model {
///   final CursorModel cursor;
///   final String text;
///
///   TextInputModel({CursorModel? cursor, this.text = ''})
///       : cursor = cursor ?? CursorModel();
///
///   @override
///   Cmd? init() => cursor.focus(); // Start blinking
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     // Let cursor handle its messages
///     final (newCursor, cmd) = cursor.update(msg);
///     return (
///       TextInputModel(cursor: newCursor, text: text),
///       cmd,
///     );
///   }
///
///   @override
///   String view() => '$text${cursor.view()}';
/// }
/// ```
class CursorModel extends ViewComponent {
  /// Creates a new cursor model.
  CursorModel({
    this.blinkSpeed = const Duration(milliseconds: 530),
    CursorMode mode = CursorMode.blink,
    String char = ' ',
    Style? style,
    Style? textStyle,
  }) : _mode = mode,
       _char = char,
       _id = _nextCursorId(),
       _blink = true,
       _focus = false,
       _blinkTag = 0,
       style = style ?? Style(),
       textStyle = textStyle ?? Style();

  /// The speed at which the cursor blinks.
  final Duration blinkSpeed;

  /// Style for the cursor itself (when visible).
  final Style style;

  /// Style for the text under the cursor.
  final Style textStyle;

  final CursorMode _mode;
  final String _char;
  final int _id;
  final bool _blink;
  final bool _focus;
  final int _blinkTag;

  // Cancellation for blink timer
  Timer? _blinkTimer;

  /// The cursor's unique ID.
  int get id => _id;

  /// Whether the cursor is currently focused.
  bool get focused => _focus;

  /// Whether the cursor is currently visible (not in blink-off state).
  bool get visible => !_blink;

  /// The current cursor mode.
  CursorMode get mode => _mode;

  /// The character displayed under the cursor.
  String get char => _char;

  /// Creates a copy with the given fields replaced.
  CursorModel copyWith({
    Duration? blinkSpeed,
    CursorMode? mode,
    String? char,
    bool? blink,
    bool? focus,
    int? blinkTag,
    Style? style,
    Style? textStyle,
  }) {
    // Copy internal state using a workaround since fields are final
    return CursorModel._internal(
      blinkSpeed: blinkSpeed ?? this.blinkSpeed,
      mode: mode ?? _mode,
      char: char ?? _char,
      id: _id,
      blink: blink ?? _blink,
      focus: focus ?? _focus,
      blinkTag: blinkTag ?? _blinkTag,
      style: style ?? this.style,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  CursorModel._internal({
    required this.blinkSpeed,
    required CursorMode mode,
    required String char,
    required int id,
    required bool blink,
    required bool focus,
    required int blinkTag,
    required this.style,
    required this.textStyle,
  }) : _mode = mode,
       _char = char,
       _id = id,
       _blink = blink,
       _focus = focus,
       _blinkTag = blinkTag;

  @override
  Cmd? init() => null;

  @override
  (CursorModel, Cmd?) update(Msg msg) {
    switch (msg) {
      case _InitialBlinkMsg():
        if (_mode != CursorMode.blink || !_focus) {
          return (this, null);
        }
        return (this, _blinkCmd());

      case FocusMsg(focused: true):
        return focus();

      case FocusMsg(focused: false):
        return (blur(), null);

      case CursorBlinkMsg(:final id, :final tag):
        // Only accept blink messages for this cursor
        if (_mode != CursorMode.blink || !_focus) {
          return (this, null);
        }
        if (id != _id || tag != _blinkTag) {
          return (this, null);
        }

        // Toggle blink state
        final newCursor = copyWith(blink: !_blink, blinkTag: _blinkTag + 1);
        return (newCursor, newCursor._blinkCmd());

      case _BlinkCanceledMsg():
        return (this, null);

      default:
        return (this, null);
    }
  }

  /// Focuses the cursor, starting the blink animation if in blink mode.
  (CursorModel, Cmd?) focus() {
    final newCursor = copyWith(
      focus: true,
      blink: _mode == CursorMode.hide, // Show cursor unless hidden
    );

    if (_mode == CursorMode.blink) {
      return (newCursor, newCursor._blinkCmd());
    }
    return (newCursor, null);
  }

  /// Blurs the cursor, stopping the blink animation.
  CursorModel blur() {
    _blinkTimer?.cancel();
    return copyWith(focus: false, blink: true);
  }

  /// Sets the character displayed under the cursor.
  CursorModel setChar(String char) {
    return copyWith(char: char);
  }

  /// Sets the cursor mode.
  (CursorModel, Cmd?) setMode(CursorMode mode) {
    final newCursor = copyWith(
      mode: mode,
      blink: mode == CursorMode.hide || !_focus,
    );

    if (mode == CursorMode.blink && _focus) {
      return (newCursor, _startBlink());
    }
    return (newCursor, null);
  }

  /// Creates a command to start blinking.
  static Cmd _startBlink() {
    return Cmd(() async => const _InitialBlinkMsg());
  }

  /// Creates a command that triggers a blink after the blink speed duration.
  Cmd _blinkCmd() {
    if (_mode != CursorMode.blink) {
      return Cmd.none();
    }

    final id = _id;
    final tag = _blinkTag;

    // Cancel previous timer if any
    _blinkTimer?.cancel();

    return Cmd(() async {
      // We use a Completer to allow cancellation if needed,
      // but for now Future.delayed is fine as long as we check tags.
      await Future.delayed(blinkSpeed);
      return CursorBlinkMsg(id: id, tag: tag);
    });
  }

  @override
  String view() {
    if (_blink || _mode == CursorMode.hide) {
      // Cursor is in "off" state or hidden - show character with text style
      return textStyle.inline(true).render(_char);
    }
    // Cursor is in "on" state - show with cursor style and inverse
    return style.inline(true).inverse().render(_char);
  }
}
