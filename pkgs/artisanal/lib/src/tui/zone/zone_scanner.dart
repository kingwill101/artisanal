// Copyright (c) 2024. All rights reserved.
// Use of this source code is governed by the MIT license that can be found in
// the LICENSE file.
//
// Port of github.com/lrstanley/bubblezone for Dart/Artisanal.

import '../../terminal/ansi.dart' show Ansi;
import '../../tui/bubbles/runeutil.dart' show stringWidth;
import 'zone_info.dart';

/// ANSI escape code marker constants.
///
/// Uses private CSI sequences to avoid conflicts with standard ANSI codes.
/// The format is: `ESC [ <number> z`
///
/// Refs:
/// - https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_(Control_Sequence_Introducer)_sequences
///   > A subset of arrangements was declared "private" so that terminal manufacturers
///   > could insert their own sequences without conflicting with the standard.
///   > Sequences containing the parameter bytes <=>? or the final bytes 0x70-0x7E
///   > (p-z{|}~) are private.
const int _identStart = 0x1B; // ESC
const int _identBracket = 0x5B; // [
const int _identEnd = 0x7A; // z

/// Callback for emitting completed zones.
typedef ZoneEmitter = void Function(ZoneInfo zone);

/// Callback for removing markers from the output.
typedef MarkerRemover = void Function(int start, int end);

/// Scanner parses zone markers from view output.
///
/// The scanner is a state machine that scans through the input string,
/// looking for zone markers in the format: `ESC [ <number> z`
///
/// When a marker is found:
/// 1. If it's a start marker (first occurrence of that ID), it records the position
/// 2. If it's an end marker (second occurrence), it calculates the zone bounds
///    and emits the completed ZoneInfo
///
/// The scanner also tracks newlines to calculate Y coordinates.
class ZoneScanner {
  /// Creates a scanner for the given input.
  ZoneScanner({
    required this.input,
    required this.iteration,
    required this.enabled,
    required this.onZone,
    required this.resolveId,
  });

  /// The input string to scan.
  String input;

  /// The current iteration (used for zone cleanup).
  final int iteration;

  /// Whether the zone manager is enabled.
  final bool enabled;

  /// Callback when a zone is complete.
  final ZoneEmitter onZone;

  /// Resolves a generated marker ID to the user-provided ID.
  final String Function(String markerId) resolveId;

  /// Current position in the input.
  int _pos = 0;

  /// Start position of the current marker.
  int _start = 0;

  /// Width of the current rune.
  int _width = 0;

  /// Number of newlines encountered.
  int _newlines = 0;

  /// Position of the last newline.
  int _lastNewline = 0;

  /// Temporary storage for start markers.
  final Map<String, ZoneInfo> _tracked = {};

  /// Runs the scanner and returns the input with markers stripped.
  String run() {
    while (true) {
      final state = _scanMain();
      if (state == null) break;
    }
    return input;
  }

  /// Main scan state - looks for markers or newlines.
  bool? _scanMain() {
    final r = _next();
    if (r == null) return null; // EOF

    if (r == 0x0A) {
      // Newline
      _newlines++;
      _lastNewline = _pos;
      return true;
    }

    if (r == _identStart) {
      _start = _pos - 1;
      return _scanId();
    }

    return true;
  }

  /// Scans a potential marker ID.
  bool? _scanId() {
    // Check for bracket
    final peek1 = _peek();
    if (peek1 != _identBracket) return true;
    _next();

    // Check for number
    final peek2 = _peek();
    if (peek2 == null || !_isDigit(peek2)) return true;

    // Consume all digits
    while (true) {
      final p = _peek();
      if (p == null || !_isDigit(p)) break;
      _next();
    }

    // Check for terminator
    final peek3 = _peek();
    if (peek3 != _identEnd) return true;
    _next();

    // Emit the marker
    _emit();
    return true;
  }

  /// Emits a marker - either recording it as a start or completing as an end.
  void _emit() {
    // Always strip the marker from the output
    final markerId = input.substring(_start, _pos);

    if (!enabled) {
      // If disabled, just strip the markers
      input = input.substring(0, _start) + input.substring(_pos);
      _pos = _start;
      return;
    }

    // Check if this is a start or end marker
    final existing = _tracked[markerId];
    if (existing != null) {
      // This is an end marker - complete the zone
      // The end should be -1 because it's the end of the encapsulation
      final endX = _printableWidth(input.substring(_lastNewline, _start)) - 1;
      final endY = _newlines;

      final userId = resolveId(markerId);
      final completed = existing.withEnd(endX: endX, endY: endY);
      final withUserId = ZoneInfo(
        id: userId,
        iteration: iteration,
        startX: completed.startX,
        startY: completed.startY,
        endX: completed.endX,
        endY: completed.endY,
      );

      onZone(withUserId);
      _tracked.remove(markerId);
    } else {
      // This is a start marker - record the position
      _tracked[markerId] = ZoneInfo(
        id: markerId,
        iteration: iteration,
        startX: _printableWidth(input.substring(_lastNewline, _start)),
        startY: _newlines,
        endX: 0,
        endY: 0,
      );
    }

    // Strip the marker from the output
    input = input.substring(0, _start) + input.substring(_pos);
    _pos = _start;
  }

  /// Returns the next rune, or null if at EOF.
  int? _next() {
    if (_pos >= input.length) {
      _width = 0;
      return null;
    }

    final unit = input.codeUnitAt(_pos);
    if (unit >= 0xD800 && unit <= 0xDBFF && _pos + 1 < input.length) {
      // Surrogate pair
      final next = input.codeUnitAt(_pos + 1);
      if (next >= 0xDC00 && next <= 0xDFFF) {
        _width = 2;
        _pos += 2;
        return 0x10000 + ((unit - 0xD800) << 10) + (next - 0xDC00);
      }
    }

    _width = 1;
    _pos += 1;
    return unit;
  }

  /// Returns the next rune without advancing.
  int? _peek() {
    final r = _next();
    _backup();
    return r;
  }

  /// Steps back one rune.
  void _backup() {
    _pos -= _width;
  }

  /// Checks if a code point is a digit.
  bool _isDigit(int r) => r >= 0x30 && r <= 0x39; // '0' - '9'

  /// Calculates the printable width of a string (ignoring ANSI sequences).
  int _printableWidth(String s) {
    return stringWidth(Ansi.stripAnsi(s));
  }
}
