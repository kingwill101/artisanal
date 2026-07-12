/// Shared terminal graphics protocol helpers.
///
/// Higher-level packages should use this module instead of parsing graphics
/// escape sequences directly. The protocol-specific details stay in UV, while
/// renderers and widgets deal with generic retained/display graphics behavior.
library;

import 'dart:math' as math;

import 'kitty.dart';

/// Terminal graphics protocols that can appear as display payloads.
enum TerminalGraphicsProtocol {
  /// Kitty Graphics Protocol APC sequences.
  kitty,

  /// Sixel DCS image payloads.
  sixel,
}

/// One parsed terminal graphics control sequence.
final class TerminalGraphicsControl {
  const TerminalGraphicsControl({
    required this.protocol,
    required this.start,
    required this.end,
    required this.sequence,
    required this.action,
    required this.imageId,
    required this.columns,
    required this.rows,
    required this.more,
    required this.cursorMovementSuppressed,
  });

  /// The graphics protocol used by this control sequence.
  final TerminalGraphicsProtocol protocol;

  /// Start offset in the scanned string.
  final int start;

  /// End offset, exclusive, in the scanned string.
  final int end;

  /// The complete escape/control sequence.
  final String sequence;

  /// Protocol action parameter, if present.
  final String? action;

  /// Retained image identifier, if present.
  final int? imageId;

  /// Requested terminal-cell columns, if present.
  final int? columns;

  /// Requested terminal-cell rows, if present.
  final int? rows;

  /// Chunk continuation flag, if present.
  final int? more;

  /// Whether the control sequence suppresses terminal cursor movement.
  final bool cursorMovementSuppressed;

  /// Whether this sequence displays graphics at the current cursor location.
  bool get displaysImage => action == 'T' || action == 'p';

  /// Whether this sequence deletes retained graphics.
  bool get deletesImage => action == 'd';

  /// Whether more chunks follow this sequence.
  bool get hasMoreChunks => more == 1;

  /// Display width in terminal cells, clamped to a usable minimum.
  int get displayColumns => math.max(1, columns ?? 1);

  /// Display height in terminal cells, clamped to a usable minimum.
  int get displayRows => math.max(1, rows ?? 1);

  /// Whether the sequence displays graphics without moving the real cursor.
  bool get displaysWithoutCursorMovement =>
      displaysImage && cursorMovementSuppressed;
}

/// Retained graphics state visible in a rendered frame.
final class TerminalGraphicsFrame {
  const TerminalGraphicsFrame({
    required this.hasRetainedGraphics,
    required this.retainedImageIds,
  });

  /// Empty retained graphics frame.
  static const empty = TerminalGraphicsFrame(
    hasRetainedGraphics: false,
    retainedImageIds: <int>{},
  );

  /// Scans [value] for retained graphics visible in the frame.
  factory TerminalGraphicsFrame.scan(String value) {
    var hasRetainedGraphics = false;
    final retainedImageIds = <int>{};

    for (final control in parseTerminalGraphicsControls(value)) {
      if (control.protocol != TerminalGraphicsProtocol.kitty ||
          !control.displaysImage) {
        continue;
      }
      hasRetainedGraphics = true;
      final id = control.imageId;
      if (id != null) retainedImageIds.add(id);
    }

    if (!hasRetainedGraphics && retainedImageIds.isEmpty) {
      return TerminalGraphicsFrame.empty;
    }
    return TerminalGraphicsFrame(
      hasRetainedGraphics: hasRetainedGraphics,
      retainedImageIds: retainedImageIds,
    );
  }

  /// Whether this frame contains retained terminal graphics.
  final bool hasRetainedGraphics;

  /// Retained image IDs displayed by this frame.
  final Set<int> retainedImageIds;

  /// Deletion sequences needed before rendering this frame after [previous].
  Iterable<String> deletionSequencesSince(
    TerminalGraphicsFrame previous, {
    int quiet = 2,
  }) sync* {
    if (!hasRetainedGraphics && previous.hasRetainedGraphics) {
      yield deleteAllRetainedGraphics(quiet: quiet);
      return;
    }

    if (!hasRetainedGraphics || previous.retainedImageIds.isEmpty) {
      if (hasRetainedGraphics &&
          previous.hasRetainedGraphics &&
          previous.retainedImageIds.isEmpty) {
        yield deleteAllRetainedGraphics(quiet: quiet);
      }
      return;
    }

    if (retainedImageIds.isEmpty) {
      yield deleteAllRetainedGraphics(quiet: quiet);
      return;
    }

    for (final staleId in previous.retainedImageIds.difference(
      retainedImageIds,
    )) {
      yield deleteRetainedGraphic(staleId, quiet: quiet);
    }
  }
}

/// Parses terminal graphics controls in [value].
Iterable<TerminalGraphicsControl> parseTerminalGraphicsControls(
  String value,
) sync* {
  var i = 0;
  while (i < value.length) {
    final codeUnit = value.codeUnitAt(i);
    final isEscKittyApc =
        codeUnit == 0x1B &&
        i + 2 < value.length &&
        value.codeUnitAt(i + 1) == 0x5F &&
        value.codeUnitAt(i + 2) == 0x47;
    final isC1KittyApc =
        codeUnit == 0x9F &&
        i + 1 < value.length &&
        value.codeUnitAt(i + 1) == 0x47;

    if (!isEscKittyApc && !isC1KittyApc) {
      i++;
      continue;
    }

    final bodyStart = i + (isEscKittyApc ? 3 : 2);
    final bodyEnd = isEscKittyApc
        ? _findEscStringTerminator(value, bodyStart)
        : _findC1StringTerminator(value, bodyStart);
    if (bodyEnd == -1) break;

    final sequenceEnd = isEscKittyApc ? bodyEnd + 2 : bodyEnd + 1;
    final parsed = _parseKittyGraphicsControl(
      value.substring(bodyStart, bodyEnd),
      start: i,
      end: sequenceEnd,
      sequence: value.substring(i, sequenceEnd),
    );
    yield parsed;
    i = sequenceEnd;
  }
}

/// Whether [value] contains any terminal graphics display sequence.
bool containsTerminalGraphicsDisplay(String value) {
  if (containsSixelDisplay(value)) return true;
  for (final control in parseTerminalGraphicsControls(value)) {
    if (control.displaysImage) return true;
  }
  return false;
}

/// Whether [value] contains retained graphics.
bool containsRetainedTerminalGraphics(String value) =>
    TerminalGraphicsFrame.scan(value).hasRetainedGraphics;

/// Whether [value] displays graphics while suppressing terminal cursor motion.
bool terminalGraphicsSuppressesCursorMovement(String value) {
  for (final control in parseTerminalGraphicsControls(value)) {
    if (control.displaysWithoutCursorMovement) return true;
  }
  return false;
}

/// Additional cell width contributed by graphics controls embedded in [line].
int terminalGraphicsCellWidth(String line) {
  var width = 0;
  int? pendingWidth;

  for (final control in parseTerminalGraphicsControls(line)) {
    if (control.deletesImage) continue;
    if (control.hasMoreChunks) {
      pendingWidth ??= control.displayColumns;
    } else {
      width += pendingWidth ?? control.displayColumns;
      pendingWidth = null;
    }
  }

  return width;
}

/// Cell width for a pending control sequence group.
int terminalGraphicsControlCellWidth(String controls) {
  var sawGraphics = false;
  var sawDisplay = false;
  var width = 0;

  for (final control in parseTerminalGraphicsControls(controls)) {
    sawGraphics = true;
    if (!control.displaysImage) continue;
    sawDisplay = true;
    width = control.displayColumns;
  }

  if (sawDisplay) return width;
  if (sawGraphics) return 0;
  return 1;
}

/// Whether a pending control sequence group displays graphics.
bool terminalGraphicsControlsDisplayImage(String controls) {
  for (final control in parseTerminalGraphicsControls(controls)) {
    if (control.displaysImage) return true;
  }
  return false;
}

/// Whether [value] can contain one of the graphics protocols handled here.
///
/// This is intentionally a cheap prefilter for hot renderer paths. It may
/// return true for malformed payloads, but it must not return false for any
/// sequence recognized by the parsing helpers in this library.
bool mayContainTerminalGraphics(String value) {
  if (value.length <= 3) {
    // Short strings (most common cell content).  Terminal graphics introducers
    // are 0x1B (ESC), 0x90 (DCS), or 0x9F (APC) — none are printable ASCII.
    var hasControlOrHigh = false;
    for (var i = 0; i < value.length; i++) {
      final cu = value.codeUnitAt(i);
      if (cu < 0x20 || cu >= 0x80) {
        hasControlOrHigh = true;
        break;
      }
    }
    if (!hasControlOrHigh) return false;
  }

  var escIndex = value.indexOf('\x1b');
  while (escIndex != -1) {
    if (escIndex + 2 < value.length) {
      final next = value.codeUnitAt(escIndex + 1);
      final third = value.codeUnitAt(escIndex + 2);
      if ((next == 0x5F && third == 0x47) || (next == 0x50 && third == 0x71)) {
        return true;
      }
    }
    escIndex = value.indexOf('\x1b', escIndex + 1);
  }

  return value.contains('\x9fG') || value.contains('\x90q');
}

/// Removes graphics displays that would paint outside [viewportHeight].
///
/// The terminal does not clip graphics protocol payloads to ordinary text
/// slicing. Replacing an overflowing display sequence with equivalent cell
/// padding keeps layout stable while preventing out-of-viewport image paints.
String suppressOverflowingTerminalGraphics(String text, int viewportHeight) {
  if (viewportHeight <= 0 ||
      (!text.contains('\x1b_G') && !text.contains('\x9fG'))) {
    return text;
  }

  final lines = text.split('\n');
  var changed = false;
  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    final remainingRows = viewportHeight - lineIndex;
    if (remainingRows <= 0) {
      lines[lineIndex] = '';
      changed = true;
      continue;
    }

    final clipped = _suppressOverflowingLineGraphics(
      lines[lineIndex],
      remainingRows: remainingRows,
    );
    if (clipped != lines[lineIndex]) {
      lines[lineIndex] = clipped;
      changed = true;
    }
  }

  return changed ? lines.join('\n') : text;
}

/// Whether [value] contains a Sixel display payload.
bool containsSixelDisplay(String value) {
  return value.contains('\x1bPq') || value.contains('\x90q');
}

/// Returns the retained-graphics delete-all sequence.
String deleteAllRetainedGraphics({int quiet = 2}) =>
    KittyImage.delete(quiet: quiet);

/// Returns the retained-graphics delete sequence for [imageId].
String deleteRetainedGraphic(int imageId, {int quiet = 2}) =>
    KittyImage.delete(imageId: imageId, quiet: quiet);

String _suppressOverflowingLineGraphics(
  String line, {
  required int remainingRows,
}) {
  if (!line.contains('\x1b_G') && !line.contains('\x9fG')) return line;

  final out = StringBuffer();
  var cursor = 0;
  var suppressContinuation = false;
  var changed = false;

  for (final control in parseTerminalGraphicsControls(line)) {
    out.write(line.substring(cursor, control.start));

    if (suppressContinuation) {
      changed = true;
      if (!control.hasMoreChunks) suppressContinuation = false;
      cursor = control.end;
      continue;
    }

    if (control.displaysImage && control.displayRows > remainingRows) {
      out.write(' ' * control.displayColumns);
      suppressContinuation = control.hasMoreChunks;
      changed = true;
      cursor = control.end;
      continue;
    }

    out.write(control.sequence);
    cursor = control.end;
  }

  out.write(line.substring(cursor));
  return changed ? out.toString() : line;
}

TerminalGraphicsControl _parseKittyGraphicsControl(
  String body, {
  required int start,
  required int end,
  required String sequence,
}) {
  final parameterEnd = body.indexOf(';');
  final parameters = parameterEnd == -1
      ? body
      : body.substring(0, parameterEnd);
  String? action;
  int? imageId;
  int? columns;
  int? rows;
  int? more;
  var cursorMovementSuppressed = false;

  for (final parameter in parameters.split(',')) {
    final equals = parameter.indexOf('=');
    if (equals <= 0) continue;

    final key = parameter.substring(0, equals);
    final value = parameter.substring(equals + 1);
    switch (key) {
      case 'a':
        action = value;
      case 'i':
        imageId = int.tryParse(value);
      case 'c':
        columns = int.tryParse(value);
      case 'r':
        rows = int.tryParse(value);
      case 'm':
        more = int.tryParse(value);
      case 'C':
        cursorMovementSuppressed = value == '1';
    }
  }

  return TerminalGraphicsControl(
    protocol: TerminalGraphicsProtocol.kitty,
    start: start,
    end: end,
    sequence: sequence,
    action: action,
    imageId: imageId,
    columns: columns,
    rows: rows,
    more: more,
    cursorMovementSuppressed: cursorMovementSuppressed,
  );
}

int _findEscStringTerminator(String value, int start) {
  for (var i = start; i + 1 < value.length; i++) {
    if (value.codeUnitAt(i) == 0x1B && value.codeUnitAt(i + 1) == 0x5C) {
      return i;
    }
  }
  return -1;
}

int _findC1StringTerminator(String value, int start) {
  for (var i = start; i < value.length; i++) {
    if (value.codeUnitAt(i) == 0x9C) return i;
  }
  return -1;
}
