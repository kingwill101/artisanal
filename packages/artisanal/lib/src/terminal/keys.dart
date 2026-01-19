/// Unified key types and constants for terminal input handling.
///
/// This module provides a single source of truth for keyboard input handling
/// used throughout the artisanal package, including both static components
/// and the TUI runtime.
///
/// ```dart
/// import 'package:artisanal/src/terminal/keys.dart';
///
/// // Check key types
/// if (key.type == KeyType.enter) { ... }
/// if (key.isArrow) { ... }
///
/// // Use key constants
/// if (keyCode == Keys.enter) { ... }
/// if (Keys.isPrintable(keyCode)) { ... }
/// ```
library;

import '../unicode/grapheme.dart' as uni;

// ─────────────────────────────────────────────────────────────────────────────
// Key Type Enumeration
// ─────────────────────────────────────────────────────────────────────────────

/// Types of keyboard input events.
///
/// Used to categorize parsed key events into semantic categories.
///
/// ## Extended Keys
///
/// This enum supports function keys F1-F20 and common navigation keys.
/// Extended function keys (F21-F63), media keys, and other specialized keys
/// from the Kitty keyboard protocol are mapped to [unknown].
///
/// For applications that need access to extended keys, use the raw UV events
/// directly via [UvEventMsg]. The UV layer provides full support for:
/// - Function keys F21-F63
/// - Media keys (play, pause, stop, etc.)
/// - Lock keys (CapsLock, NumLock, ScrollLock)
/// - Modifier-only keys (left/right Shift, Ctrl, Alt, etc.)
///
/// Example handling extended keys:
/// ```dart
/// (Msg msg, Model model) update(Msg msg) {
///   if (msg is UvEventMsg && msg.event is KeyPressEvent) {
///     final key = (msg.event as KeyPressEvent).key();
///     if (key.code == keyF21) {
///       // Handle F21
///     }
///   }
///   // ...
/// }
/// ```
enum KeyType {
  // ─────────────────────────────────────────────────────────────────────────────
  // Character Input
  // ─────────────────────────────────────────────────────────────────────────────

  /// Regular character input (letters, numbers, symbols).
  ///
  /// The actual character(s) are available in [Key.runes].
  runes,

  // ─────────────────────────────────────────────────────────────────────────────
  // Special Keys
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enter/Return key.
  enter,

  /// Tab key.
  tab,

  /// Backspace key.
  backspace,

  /// Delete key.
  delete,

  /// Escape key.
  escape,

  /// Space key (when treated as special rather than rune).
  space,

  // ─────────────────────────────────────────────────────────────────────────────
  // Arrow Keys
  // ─────────────────────────────────────────────────────────────────────────────

  /// Up arrow key.
  up,

  /// Down arrow key.
  down,

  /// Left arrow key.
  left,

  /// Right arrow key.
  right,

  // ─────────────────────────────────────────────────────────────────────────────
  // Navigation Keys
  // ─────────────────────────────────────────────────────────────────────────────

  /// Home key.
  home,

  /// End key.
  end,

  /// Page Up key.
  pageUp,

  /// Page Down key.
  pageDown,

  /// Insert key.
  insert,

  // ─────────────────────────────────────────────────────────────────────────────
  // Function Keys
  // ─────────────────────────────────────────────────────────────────────────────

  /// F1 function key.
  f1,

  /// F2 function key.
  f2,

  /// F3 function key.
  f3,

  /// F4 function key.
  f4,

  /// F5 function key.
  f5,

  /// F6 function key.
  f6,

  /// F7 function key.
  f7,

  /// F8 function key.
  f8,

  /// F9 function key.
  f9,

  /// F10 function key.
  f10,

  /// F11 function key.
  f11,

  /// F12 function key.
  f12,

  /// F13 function key (extended).
  f13,

  /// F14 function key (extended).
  f14,

  /// F15 function key (extended).
  f15,

  /// F16 function key (extended).
  f16,

  /// F17 function key (extended).
  f17,

  /// F18 function key (extended).
  f18,

  /// F19 function key (extended).
  f19,

  /// F20 function key (extended).
  f20,

  // ─────────────────────────────────────────────────────────────────────────────
  // Other
  // ─────────────────────────────────────────────────────────────────────────────

  /// Unknown or unrecognized key.
  ///
  /// This includes extended keys not in this enum (F21-F63, media keys, etc.).
  /// For extended key support, use raw UV events via [UvEventMsg].
  unknown,
}

// ─────────────────────────────────────────────────────────────────────────────
// Key Class
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a parsed keyboard input event.
///
/// Contains the type of key, any character data, and modifier state.
///
/// ## Example
///
/// ```dart
/// // Regular character
/// final a = Key(KeyType.runes, runes: [0x61]); // 'a'
///
/// // Arrow key with modifier
/// final ctrlUp = Key(KeyType.up, ctrl: true);
///
/// // Check modifiers
/// if (key.hasModifier) { ... }
/// if (key.ctrl && key.type == KeyType.runes) { ... }
/// ```
class Key {
  /// Creates a key event.
  const Key(
    this.type, {
    this.runes = const [],
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
    this.hyper = false,
    this.superKey = false,
    this.isRelease = false,
    this.isRepeat = false,
  });

  /// The type of key.
  final KeyType type;

  /// The Unicode code points for character input.
  ///
  /// Non-empty for [KeyType.runes] events.
  final List<int> runes;

  /// Whether the Control key was held.
  final bool ctrl;

  /// Whether the Alt/Option key was held.
  final bool alt;

  /// Whether the Shift key was held.
  final bool shift;

  /// Whether the Meta key was held (Command on macOS, Windows key on Windows).
  ///
  /// Only available with Kitty keyboard protocol or similar enhancements.
  final bool meta;

  /// Whether the Hyper key was held.
  ///
  /// Only available with Kitty keyboard protocol or similar enhancements.
  final bool hyper;

  /// Whether the Super key was held.
  ///
  /// Only available with Kitty keyboard protocol or similar enhancements.
  /// Named `superKey` to avoid conflict with Dart's `super` keyword.
  final bool superKey;

  /// Whether this is a key release event.
  ///
  /// Requires terminal support and keyboard enhancements to be enabled.
  final bool isRelease;

  /// Whether this is a key repeat event.
  ///
  /// Requires terminal support and keyboard enhancements to be enabled.
  final bool isRepeat;

  // ─────────────────────────────────────────────────────────────────────────────
  // Modifier Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Whether any modifier key is held.
  bool get hasModifier => ctrl || alt || shift || meta || hyper || superKey;

  /// Whether this is a control character (Ctrl+letter).
  bool get isCtrlChar => ctrl && type == KeyType.runes && runes.isNotEmpty;

  /// Whether this is a regular character key (runes type with content).
  bool get isRune => type == KeyType.runes && runes.isNotEmpty;

  // ─────────────────────────────────────────────────────────────────────────────
  // Copy Method
  // ─────────────────────────────────────────────────────────────────────────────

  /// Creates a copy of this key with the given fields replaced.
  Key copyWith({
    KeyType? type,
    List<int>? runes,
    bool? ctrl,
    bool? alt,
    bool? shift,
    bool? meta,
    bool? hyper,
    bool? superKey,
    bool? isRelease,
    bool? isRepeat,
  }) {
    return Key(
      type ?? this.type,
      runes: runes ?? this.runes,
      ctrl: ctrl ?? this.ctrl,
      alt: alt ?? this.alt,
      shift: shift ?? this.shift,
      meta: meta ?? this.meta,
      hyper: hyper ?? this.hyper,
      superKey: superKey ?? this.superKey,
      isRelease: isRelease ?? this.isRelease,
      isRepeat: isRepeat ?? this.isRepeat,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Type Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Whether this is an arrow key.
  bool get isArrow =>
      type == KeyType.up ||
      type == KeyType.down ||
      type == KeyType.left ||
      type == KeyType.right;

  /// Whether this is a navigation key (arrows, home, end, page up/down).
  bool get isNavigation =>
      isArrow ||
      type == KeyType.home ||
      type == KeyType.end ||
      type == KeyType.pageUp ||
      type == KeyType.pageDown;

  /// Whether this is a function key (F1-F20).
  bool get isFunctionKey {
    final index = type.index;
    return index >= KeyType.f1.index && index <= KeyType.f20.index;
  }

  /// Whether this is a printable character.
  bool get isPrintable =>
      type == KeyType.runes &&
      runes.isNotEmpty &&
      runes.first >= 0x20 &&
      runes.first < 0x7F;

  // ─────────────────────────────────────────────────────────────────────────────
  // Character Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns the character if this is a single character key, or null.
  String? get char {
    if (type == KeyType.runes && runes.isNotEmpty) {
      return String.fromCharCodes(runes);
    }
    return null;
  }

  /// Returns the first rune if available, or -1.
  int get rune => runes.isNotEmpty ? runes.first : -1;

  /// Returns whether this key represents exactly the given code point.
  ///
  /// If [requireNoModifiers] is true (default), Ctrl/Alt/Shift must not be set.
  bool isRuneValue(int codePoint, {bool requireNoModifiers = true}) {
    if (requireNoModifiers && hasModifier) return false;
    return type == KeyType.runes &&
        runes.length == 1 &&
        runes.first == codePoint;
  }

  /// Returns whether this key represents the given character.
  ///
  /// This is intended for ergonomic checks like `key.isChar('q')` instead of
  /// rune lists. Prefer this over `key.char == 'q'` when modifiers matter:
  /// Ctrl+J reports as the rune `'j'`, which can conflict with vim-style `j/k`
  /// bindings unless you require no modifiers.
  ///
  /// If [requireNoModifiers] is true (default), Ctrl/Alt/Shift must not be set.
  /// If [caseSensitive] is false, performs a lowercase comparison.
  bool isChar(
    String c, {
    bool requireNoModifiers = true,
    bool caseSensitive = true,
  }) {
    if (c.isEmpty) return false;
    if (requireNoModifiers && hasModifier) return false;
    final ch = char;
    if (ch == null) return false;
    if (caseSensitive) return ch == c;
    return ch.toLowerCase() == c.toLowerCase();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Common Key Checks
  // ─────────────────────────────────────────────────────────────────────────────

  /// Whether this is the Enter key (with or without modifiers).
  bool get isEnter => type == KeyType.enter;

  /// Whether this key represents Enter/Return for input handling.
  ///
  /// This includes the canonical [KeyType.enter] as well as terminals/parsers
  /// that report Enter as Ctrl+J (LF) or Ctrl+M (CR), which may appear when
  /// using the Ultraviolet key table.
  bool get isEnterLike =>
      isEnter ||
      this == Keys.ctrlJ ||
      this == Keys.ctrlM ||
      // Some parsers may deliver raw CR/LF as runes.
      isRuneValue(Keys.lineFeed) ||
      isRuneValue(Keys.carriageReturn);

  /// Whether this is the Tab key (with or without modifiers).
  bool get isTab => type == KeyType.tab;

  /// Whether this is the Escape key.
  bool get isEscape => type == KeyType.escape;

  /// Whether this is the Backspace key.
  bool get isBackspace => type == KeyType.backspace;

  /// Whether this is the Delete key.
  bool get isDelete => type == KeyType.delete;

  /// Whether this key represents a space press for input handling.
  ///
  /// This includes [KeyType.space] as well as a plain space rune.
  bool get isSpaceLike => type == KeyType.space || isRuneValue(0x20);

  /// Whether this key should be treated as an “accept/select/confirm” action.
  ///
  /// Default convention: Enter or Space.
  bool get isAccept => isEnterLike || isSpaceLike;

  /// Whether this is Ctrl+C.
  bool get isCtrlC =>
      ctrl && type == KeyType.runes && runes.isNotEmpty && runes.first == 0x63;

  /// Whether this is Ctrl+D.
  bool get isCtrlD =>
      ctrl && type == KeyType.runes && runes.isNotEmpty && runes.first == 0x64;

  /// Whether this is Ctrl+Z.
  bool get isCtrlZ =>
      ctrl && type == KeyType.runes && runes.isNotEmpty && runes.first == 0x7A;

  // ─────────────────────────────────────────────────────────────────────────────
  // Factory Constructors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Creates a key from a single character.
  factory Key.char(
    String char, {
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
  }) {
    return Key(
      KeyType.runes,
      runes: uni.codePoints(char),
      ctrl: ctrl,
      alt: alt,
      shift: shift,
    );
  }

  /// Creates a key from a single rune.
  factory Key.fromRune(
    int rune, {
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
  }) {
    return Key(
      KeyType.runes,
      runes: [rune],
      ctrl: ctrl,
      alt: alt,
      shift: shift,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Equality and Hashing
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Key) return false;

    if (type != other.type) return false;
    if (ctrl != other.ctrl) return false;
    if (alt != other.alt) return false;
    if (shift != other.shift) return false;
    if (meta != other.meta) return false;
    if (hyper != other.hyper) return false;
    if (superKey != other.superKey) return false;
    if (runes.length != other.runes.length) return false;

    for (var i = 0; i < runes.length; i++) {
      if (runes[i] != other.runes[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    type,
    ctrl,
    alt,
    shift,
    meta,
    hyper,
    superKey,
    Object.hashAll(runes),
  );

  @override
  String toString() {
    final mods = [
      if (ctrl) 'Ctrl',
      if (alt) 'Alt',
      if (shift) 'Shift',
      if (meta) 'Meta',
      if (hyper) 'Hyper',
      if (superKey) 'Super',
    ];
    final modStr = mods.isEmpty ? '' : '${mods.join('+')}+';

    if (type == KeyType.runes && runes.isNotEmpty) {
      final char = String.fromCharCodes(runes);
      // Output without quotes for keyMatches compatibility
      return 'Key($modStr$char)';
    }

    // Capitalize key type name
    final typeName = type.name;
    final capitalizedName = typeName[0].toUpperCase() + typeName.substring(1);
    return 'Key($modStr$capitalizedName)';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Key Code Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Key constants and utilities for keyboard input handling.
///
/// This class provides:
/// - Raw byte constants for low-level input handling
/// - [Key] object constants for high-level TUI use
/// - Helper methods for character classification
///
/// ```dart
/// // High-level Key objects (for TUI)
/// if (key == Keys.enter) { ... }
/// if (key == Keys.ctrlC) { ... }
///
/// // Low-level byte constants
/// if (byte == Keys.enterByte) { ... }
///
/// // Helper methods
/// if (Keys.isPrintable(byte)) { ... }
/// if (Keys.isControlChar(byte)) { ... }
/// ```
abstract final class Keys {
  // ═══════════════════════════════════════════════════════════════════════════
  // Key Object Constants (for TUI)
  // ═══════════════════════════════════════════════════════════════════════════

  // Special keys
  /// Enter key.
  static const enter = Key(KeyType.enter);

  /// Tab key.
  static const tab = Key(KeyType.tab);

  /// Backspace key.
  static const backspace = Key(KeyType.backspace);

  /// Escape key.
  static const escape = Key(KeyType.escape);

  /// Space key.
  static const space = Key(KeyType.space);

  // Arrow keys
  /// Up arrow key.
  static const up = Key(KeyType.up);

  /// Down arrow key.
  static const down = Key(KeyType.down);

  /// Left arrow key.
  static const left = Key(KeyType.left);

  /// Right arrow key.
  static const right = Key(KeyType.right);

  // Navigation keys
  /// Home key.
  static const home = Key(KeyType.home);

  /// End key.
  static const end = Key(KeyType.end);

  /// Page Up key.
  static const pageUp = Key(KeyType.pageUp);

  /// Page Down key.
  static const pageDown = Key(KeyType.pageDown);

  /// Insert key.
  static const insert = Key(KeyType.insert);

  /// Delete key.
  static const delete = Key(KeyType.delete);

  // Common Ctrl combinations as Key objects
  /// Ctrl+A key.
  static const ctrlA = Key(KeyType.runes, runes: [0x61], ctrl: true);

  /// Ctrl+B key.
  static const ctrlB = Key(KeyType.runes, runes: [0x62], ctrl: true);

  /// Ctrl+C key.
  static const ctrlC = Key(KeyType.runes, runes: [0x63], ctrl: true);

  /// Ctrl+D key.
  static const ctrlD = Key(KeyType.runes, runes: [0x64], ctrl: true);

  /// Ctrl+E key.
  static const ctrlE = Key(KeyType.runes, runes: [0x65], ctrl: true);

  /// Ctrl+F key.
  static const ctrlF = Key(KeyType.runes, runes: [0x66], ctrl: true);

  /// Ctrl+G key.
  static const ctrlG = Key(KeyType.runes, runes: [0x67], ctrl: true);

  /// Ctrl+H key.
  static const ctrlH = Key(KeyType.runes, runes: [0x68], ctrl: true);

  /// Ctrl+I key.
  static const ctrlI = Key(KeyType.runes, runes: [0x69], ctrl: true);

  /// Ctrl+J key.
  static const ctrlJ = Key(KeyType.runes, runes: [0x6a], ctrl: true);

  /// Ctrl+K key.
  static const ctrlK = Key(KeyType.runes, runes: [0x6b], ctrl: true);

  /// Ctrl+L key.
  static const ctrlL = Key(KeyType.runes, runes: [0x6c], ctrl: true);

  /// Ctrl+M key.
  static const ctrlM = Key(KeyType.runes, runes: [0x6d], ctrl: true);

  /// Ctrl+N key.
  static const ctrlN = Key(KeyType.runes, runes: [0x6e], ctrl: true);

  /// Ctrl+O key.
  static const ctrlO = Key(KeyType.runes, runes: [0x6f], ctrl: true);

  /// Ctrl+P key.
  static const ctrlP = Key(KeyType.runes, runes: [0x70], ctrl: true);

  /// Ctrl+Q key.
  static const ctrlQ = Key(KeyType.runes, runes: [0x71], ctrl: true);

  /// Ctrl+R key.
  static const ctrlR = Key(KeyType.runes, runes: [0x72], ctrl: true);

  /// Ctrl+S key.
  static const ctrlS = Key(KeyType.runes, runes: [0x73], ctrl: true);

  /// Ctrl+T key.
  static const ctrlT = Key(KeyType.runes, runes: [0x74], ctrl: true);

  /// Ctrl+U key.
  static const ctrlU = Key(KeyType.runes, runes: [0x75], ctrl: true);

  /// Ctrl+V key.
  static const ctrlV = Key(KeyType.runes, runes: [0x76], ctrl: true);

  /// Ctrl+W key.
  static const ctrlW = Key(KeyType.runes, runes: [0x77], ctrl: true);

  /// Ctrl+X key.
  static const ctrlX = Key(KeyType.runes, runes: [0x78], ctrl: true);

  /// Ctrl+Y key.
  static const ctrlY = Key(KeyType.runes, runes: [0x79], ctrl: true);

  /// Ctrl+Z key.
  static const ctrlZ = Key(KeyType.runes, runes: [0x7a], ctrl: true);

  // Common printable single-character keys (as consts for pattern matching).
  //
  // Prefer `key.isChar('q')` etc for flexibility, but these constants are
  // convenient in switch patterns and avoid manual rune lists.
  static const q = Key(KeyType.runes, runes: [0x71]); // 'q'
  static const j = Key(KeyType.runes, runes: [0x6a]); // 'j'
  static const k = Key(KeyType.runes, runes: [0x6b]); // 'k'
  static const h = Key(KeyType.runes, runes: [0x68]); // 'h'
  static const l = Key(KeyType.runes, runes: [0x6c]); // 'l'
  static const g = Key(KeyType.runes, runes: [0x67]); // 'g'
  static const G = Key(KeyType.runes, runes: [0x47]); // 'G'
  static const slash = Key(KeyType.runes, runes: [0x2f]); // '/'
  static const questionMark = Key(KeyType.runes, runes: [0x3f]); // '?'

  // Shift combinations
  /// Shift+Tab key.
  static const shiftTab = Key(KeyType.tab, shift: true);

  // Function keys
  /// F1 key.
  static const f1 = Key(KeyType.f1);

  /// F2 key.
  static const f2 = Key(KeyType.f2);

  /// F3 key.
  static const f3 = Key(KeyType.f3);

  /// F4 key.
  static const f4 = Key(KeyType.f4);

  /// F5 key.
  static const f5 = Key(KeyType.f5);

  /// F6 key.
  static const f6 = Key(KeyType.f6);

  /// F7 key.
  static const f7 = Key(KeyType.f7);

  /// F8 key.
  static const f8 = Key(KeyType.f8);

  /// F9 key.
  static const f9 = Key(KeyType.f9);

  /// F10 key.
  static const f10 = Key(KeyType.f10);

  /// F11 key.
  static const f11 = Key(KeyType.f11);

  /// F12 key.
  static const f12 = Key(KeyType.f12);

  // Extended function keys F13-F20
  /// F13 key.
  static const f13 = Key(KeyType.f13);

  /// F14 key.
  static const f14 = Key(KeyType.f14);

  /// F15 key.
  static const f15 = Key(KeyType.f15);

  /// F16 key.
  static const f16 = Key(KeyType.f16);

  /// F17 key.
  static const f17 = Key(KeyType.f17);

  /// F18 key.
  static const f18 = Key(KeyType.f18);

  /// F19 key.
  static const f19 = Key(KeyType.f19);

  /// F20 key.
  static const f20 = Key(KeyType.f20);

  // Shift+arrow combinations
  /// Shift+Up key.
  static const shiftUp = Key(KeyType.up, shift: true);

  /// Shift+Down key.
  static const shiftDown = Key(KeyType.down, shift: true);

  /// Shift+Left key.
  static const shiftLeft = Key(KeyType.left, shift: true);

  /// Shift+Right key.
  static const shiftRight = Key(KeyType.right, shift: true);

  /// Shift+Home key.
  static const shiftHome = Key(KeyType.home, shift: true);

  /// Shift+End key.
  static const shiftEnd = Key(KeyType.end, shift: true);

  // Ctrl+arrow combinations
  /// Ctrl+Up key.
  static const ctrlUp = Key(KeyType.up, ctrl: true);

  /// Ctrl+Down key.
  static const ctrlDown = Key(KeyType.down, ctrl: true);

  /// Ctrl+Left key.
  static const ctrlLeft = Key(KeyType.left, ctrl: true);

  /// Ctrl+Right key.
  static const ctrlRight = Key(KeyType.right, ctrl: true);

  /// Ctrl+Home key.
  static const ctrlHome = Key(KeyType.home, ctrl: true);

  /// Ctrl+End key.
  static const ctrlEnd = Key(KeyType.end, ctrl: true);

  /// Ctrl+PageUp key.
  static const ctrlPgUp = Key(KeyType.pageUp, ctrl: true);

  /// Ctrl+PageDown key.
  static const ctrlPgDown = Key(KeyType.pageDown, ctrl: true);

  // Ctrl+Shift combinations
  /// Ctrl+Shift+Up key.
  static const ctrlShiftUp = Key(KeyType.up, ctrl: true, shift: true);

  /// Ctrl+Shift+Down key.
  static const ctrlShiftDown = Key(KeyType.down, ctrl: true, shift: true);

  /// Ctrl+Shift+Left key.
  static const ctrlShiftLeft = Key(KeyType.left, ctrl: true, shift: true);

  /// Ctrl+Shift+Right key.
  static const ctrlShiftRight = Key(KeyType.right, ctrl: true, shift: true);

  /// Ctrl+Shift+Home key.
  static const ctrlShiftHome = Key(KeyType.home, ctrl: true, shift: true);

  /// Ctrl+Shift+End key.
  static const ctrlShiftEnd = Key(KeyType.end, ctrl: true, shift: true);

  // ═══════════════════════════════════════════════════════════════════════════
  // Factory Methods for Key Objects
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a key for a single character.
  static Key char(String c) {
    return Key(KeyType.runes, runes: uni.codePoints(c));
  }

  /// Creates a Ctrl+key combination.
  static Key ctrl(String c) {
    return Key(
      KeyType.runes,
      runes: uni.codePoints(c.toLowerCase()),
      ctrl: true,
    );
  }

  /// Creates an Alt+key combination.
  static Key alt(String c) {
    return Key(KeyType.runes, runes: uni.codePoints(c), alt: true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Raw Byte Constants (for low-level input handling)
  // ═══════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────────
  // Control Character Bytes (0x00 - 0x1F)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Null character byte (Ctrl+@).
  static const null_ = 0;

  /// Ctrl+A byte.
  static const ctrlAByte = 1;

  /// Ctrl+B byte.
  static const ctrlBByte = 2;

  /// Ctrl+C byte (interrupt).
  static const ctrlCByte = 3;

  /// Ctrl+D byte (end of transmission).
  static const ctrlDByte = 4;

  /// Ctrl+E byte.
  static const ctrlEByte = 5;

  /// Ctrl+F byte.
  static const ctrlFByte = 6;

  /// Ctrl+G byte (bell).
  static const ctrlGByte = 7;

  /// Ctrl+H byte (backspace on some terminals).
  static const ctrlHByte = 8;

  /// Tab byte (Ctrl+I).
  static const tabByte = 9;

  /// Line feed byte / Enter on Unix (Ctrl+J).
  static const lineFeed = 10;

  /// Ctrl+K byte.
  static const ctrlKByte = 11;

  /// Ctrl+L byte (form feed / clear screen).
  static const ctrlLByte = 12;

  /// Carriage return byte / Enter on Windows (Ctrl+M).
  static const carriageReturn = 13;

  /// Ctrl+N byte.
  static const ctrlNByte = 14;

  /// Ctrl+O byte.
  static const ctrlOByte = 15;

  /// Ctrl+P byte.
  static const ctrlPByte = 16;

  /// Ctrl+Q byte (XON).
  static const ctrlQByte = 17;

  /// Ctrl+R byte.
  static const ctrlRByte = 18;

  /// Ctrl+S byte (XOFF).
  static const ctrlSByte = 19;

  /// Ctrl+T byte.
  static const ctrlTByte = 20;

  /// Ctrl+U byte.
  static const ctrlUByte = 21;

  /// Ctrl+V byte.
  static const ctrlVByte = 22;

  /// Ctrl+W byte.
  static const ctrlWByte = 23;

  /// Ctrl+X byte.
  static const ctrlXByte = 24;

  /// Ctrl+Y byte.
  static const ctrlYByte = 25;

  /// Ctrl+Z byte (suspend).
  static const ctrlZByte = 26;

  /// Escape byte (Ctrl+[).
  static const escapeByte = 27;

  /// File separator byte (Ctrl+\).
  static const ctrlBackslash = 28;

  /// Group separator byte (Ctrl+]).
  static const ctrlBracketRight = 29;

  /// Record separator byte (Ctrl+^).
  static const ctrlCaret = 30;

  /// Unit separator byte (Ctrl+_).
  static const ctrlUnderscore = 31;

  // ─────────────────────────────────────────────────────────────────────────────
  // Printable Character Bytes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Space character byte.
  static const spaceByte = 32;

  /// Delete byte (DEL, 0x7F).
  static const deleteByte = 127;

  // ─────────────────────────────────────────────────────────────────────────────
  // Byte Aliases
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enter key byte (line feed, 0x0A).
  ///
  /// On Unix-like systems, pressing Enter sends LF (line feed, 0x0A).
  /// This is the default "enter" byte used by the TUI parser.
  ///
  /// See also [enterCR] for Windows-style carriage return.
  static const enterByte = lineFeed;

  /// Enter key byte (carriage return, 0x0D).
  ///
  /// On Windows and some terminals, pressing Enter sends CR (carriage return, 0x0D).
  /// Most Unix terminals can be configured to send either LF or CR.
  ///
  /// See also [enterByte] for Unix-style line feed.
  static const enterCR = carriageReturn;

  /// Backspace key byte (DEL on most terminals).
  static const backspaceByte = deleteByte;

  /// Alternative backspace byte (Ctrl+H on some terminals).
  static const backspaceAlt = ctrlHByte;

  // ─────────────────────────────────────────────────────────────────────────────
  // Arrow Key Codes (after ESC [)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Up arrow byte (after ESC [).
  static const arrowUp = 65; // 'A'

  /// Down arrow byte (after ESC [).
  static const arrowDown = 66; // 'B'

  /// Right arrow byte (after ESC [).
  static const arrowRight = 67; // 'C'

  /// Left arrow byte (after ESC [).
  static const arrowLeft = 68; // 'D'

  // ─────────────────────────────────────────────────────────────────────────────
  // Helper Methods
  // ─────────────────────────────────────────────────────────────────────────────

  /// Whether [byte] is the escape character.
  static bool isEscape(int byte) => byte == escapeByte;

  /// Whether [byte] is a control character (0x00-0x1F or 0x7F).
  static bool isControlChar(int byte) => byte < 32 || byte == 127;

  /// Whether [byte] is a printable ASCII character (0x20-0x7E).
  static bool isPrintable(int byte) => byte >= spaceByte && byte < deleteByte;

  /// Whether [byte] is an ASCII letter (a-z or A-Z).
  static bool isLetter(int byte) =>
      (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122);

  /// Whether [byte] is an ASCII digit (0-9).
  static bool isDigit(int byte) => byte >= 48 && byte <= 57;

  /// Whether [byte] is alphanumeric (letter or digit).
  static bool isAlphanumeric(int byte) => isLetter(byte) || isDigit(byte);

  /// Whether [byte] is whitespace (space, tab, newline, etc.).
  static bool isWhitespace(int byte) =>
      byte == spaceByte ||
      byte == tabByte ||
      byte == lineFeed ||
      byte == carriageReturn;

  /// Converts a Ctrl+letter byte to the letter character.
  ///
  /// For example, 1 (Ctrl+A) returns 'a'.
  static String? ctrlToChar(int byte) {
    if (byte >= 1 && byte <= 26) {
      return String.fromCharCode(byte + 96); // 1 -> 'a' (97)
    }
    return null;
  }

  /// Converts a letter character to its Ctrl+letter byte value.
  ///
  /// For example, 'a' returns 1 (Ctrl+A).
  static int? charToCtrl(String char) {
    if (char.length != 1) return null;
    final code = char.toLowerCase().codeUnitAt(0);
    if (code >= 97 && code <= 122) {
      return code - 96; // 'a' (97) -> 1
    }
    return null;
  }
}
