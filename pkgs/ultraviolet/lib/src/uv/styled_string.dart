/// Parses and renders styled text (ANSI/OSC) into grid-aligned cells.
///
/// [StyledString] converts a string with terminal sequences into positioned
/// [Cell]s and draws them into a [Screen] region, complementing [Buffer]
/// rendering. During parsing, [readStyle] updates the active [StyleState]
/// for SGR attributes and colors, while [readLink] updates [LinkState]
/// for OSC 8 hyperlinks.
///
/// {@category Ultraviolet}
/// {@subCategory Text Rendering}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final s = StyledString('\x1b[1mHello\x1b[0m'); // bold Hello
/// s.draw(screen, screen.bounds());
/// ```
library;

import 'buffer.dart';
import 'cell.dart';
import 'color_utils.dart' as color_utils;
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import 'terminal_graphics.dart' as terminal_graphics;
import '../unicode/width.dart';
import '../ansi.dart' as term_ansi;

import '../unicode/grapheme.dart' as uni;

/// StyledString is a string that can be decomposed into a series of styled
/// lines and cells.
///
/// Upstream: `third_party/ultraviolet/styled.go` (`StyledString`).
final class StyledString implements Drawable {
  /// Creates a styled string from [text] with optional [wrap] and [tail].
  StyledString(this.text, {this.wrap = false, this.tail = ''});

  /// The raw text content, which may include ANSI escape sequences.
  final String text;

  /// Whether long lines should wrap to the next row.
  bool wrap;

  /// Trailing content appended after the main text when truncating.
  String tail;

  @override
  /// Returns the original text content.
  String toString() => text;

  /// The number of lines in the original text.
  int height() => text.split('\n').length;

  /// Returns the bounds required to render [text] using grapheme widths.
  @override
  Rectangle bounds() => styledStringBounds(text, WidthMethod.grapheme);

  @override
  /// Draws this styled string into [screen] inside [area], clearing first.
  void draw(Screen screen, Rectangle area) {
    final clearable = screen is ClearAreaScreen ? screen : null;
    if (clearable == null) {
      // Clear the area before drawing.
      for (var y = area.minY; y < area.maxY; y++) {
        for (var x = area.minX; x < area.maxX; x++) {
          screen.setCell(x, y, null);
        }
      }
    } else {
      clearable.clearArea(area);
    }

    // Normalize CRLF to NL to emulate raw terminal output.
    final normalized = text.contains('\r')
        ? text.replaceAll('\r\n', '\n')
        : text;
    final expanded = term_ansi.Ansi.expandTabs(normalized);

    _printString(
      screen,
      WidthMethod.grapheme,
      area.minX,
      area.minY,
      area,
      expanded,
      truncate: !wrap,
      tail: tail,
    );
  }
}

/// Factory function to create a [StyledString] from [str].
StyledString newStyledString(String str) => StyledString(str);

// --- ANSI parsing helpers ----------------------------------------------------

const _sgrParamCacheLimit = 256;
final _sgrParamCache = <String, List<SgrParam>>{};

/// Represents a parsed SGR (Select Graphic Rendition) parameter.
final class SgrParam {
  /// Creates an SGR parameter with [value] and optional [sub]-parameters.
  const SgrParam(this.value, this.sub);

  /// The main parameter value.
  final int value;

  /// The sub-parameter values, or empty if none.
  final List<int> sub;

  /// Whether this parameter has a sub-parameter.
  bool get hasSub => sub.isNotEmpty;
}

List<SgrParam> _parseSgrParams(String raw) {
  if (raw.isEmpty) return const [];
  final cached = _sgrParamCache[raw];
  if (cached != null) return cached;

  final parts = raw.split(';');
  final out = <SgrParam>[];
  for (final part in parts) {
    if (part.isEmpty) {
      out.add(const SgrParam(0, []));
      continue;
    }
    final subParts = part.split(':');
    final value = int.tryParse(subParts[0]) ?? 0;
    final sub = <int>[];
    for (var i = 1; i < subParts.length; i++) {
      final s = subParts[i];
      sub.add(int.tryParse(s.isEmpty ? '0' : s) ?? 0);
    }
    out.add(SgrParam(value, sub));
  }
  if (_sgrParamCache.length >= _sgrParamCacheLimit) {
    _sgrParamCache.clear();
  }
  _sgrParamCache[raw] = out;
  return out;
}

/// Parses an OSC 8 hyperlink sequence from [data] into [out].
void readLink(String data, LinkState out) {
  // Upstream: `third_party/ultraviolet/styled.go` (`ReadLink`).
  // OSC 8 format: ESC ] 8 ; params ; url ST
  // Here `data` is the portion after "8;" in our parser.
  final firstSep = data.indexOf(';');
  if (firstSep < 0) return;
  final params = data.substring(0, firstSep);
  final url = data.substring(firstSep + 1);
  out.link = Link(url: url, params: params);
}

/// Holds the parsed hyperlink URL from an OSC 8 sequence.
final class LinkState {
  /// Creates a link state with the given [link].
  LinkState(this.link);

  /// The hyperlink URL and parameters.
  Link link;
}

/// Parses SGR [params] and applies them to the style in [out].
void readStyle(List<SgrParam> params, StyleState out) {
  // Upstream: `third_party/ultraviolet/styled.go` (`ReadStyle`).
  if (params.isEmpty) {
    out.style = const UvStyle();
    return;
  }

  var style = out.style;

  for (var i = 0; i < params.length; i++) {
    final p = params[i];
    final param = p.value;

    switch (param) {
      case 0:
        style = const UvStyle();
      case 1:
        style = style.copyWith(attrs: style.attrs | Attr.bold);
      case 2:
        style = style.copyWith(attrs: style.attrs | Attr.faint);
      case 3:
        style = style.copyWith(attrs: style.attrs | Attr.italic);
      case 4:
        // Underline with optional subparameter (4:3 etc).
        if (p.hasSub) {
          final next = p.sub.first;
          style = style.copyWith(
            underline: switch (next) {
              0 => UnderlineStyle.none,
              1 => UnderlineStyle.single,
              2 => UnderlineStyle.double,
              3 => UnderlineStyle.curly,
              4 => UnderlineStyle.dotted,
              5 => UnderlineStyle.dashed,
              _ => UnderlineStyle.single,
            },
          );
        } else {
          style = style.copyWith(underline: UnderlineStyle.single);
        }
      case 5:
        style = style.copyWith(attrs: style.attrs | Attr.blink);
      case 6:
        style = style.copyWith(attrs: style.attrs | Attr.rapidBlink);
      case 7:
        style = style.copyWith(attrs: style.attrs | Attr.reverse);
      case 8:
        style = style.copyWith(attrs: style.attrs | Attr.conceal);
      case 9:
        style = style.copyWith(attrs: style.attrs | Attr.strikethrough);

      // Reset variants used in upstream tests.
      case 22:
        style = style.copyWith(attrs: style.attrs & ~(Attr.bold | Attr.faint));
      case 23:
        style = style.copyWith(attrs: style.attrs & ~Attr.italic);
      case 24:
        style = style.copyWith(underline: UnderlineStyle.none);
      case 25:
        style = style.copyWith(
          attrs: style.attrs & ~(Attr.blink | Attr.rapidBlink),
        );
      case 27:
        style = style.copyWith(attrs: style.attrs & ~Attr.reverse);
      case 28:
        style = style.copyWith(attrs: style.attrs & ~Attr.conceal);
      case 29:
        style = style.copyWith(attrs: style.attrs & ~Attr.strikethrough);

      // Foreground colors: 30-37, 90-97
      case >= 30 && <= 37:
        style = style.copyWith(fg: UvColor.basic16(param - 30));
      case >= 90 && <= 97:
        style = style.copyWith(fg: UvColor.basic16(param - 90, bright: true));

      // Background colors: 40-47, 100-107
      case >= 40 && <= 47:
        style = style.copyWith(bg: UvColor.basic16(param - 40));
      case >= 100 && <= 107:
        style = style.copyWith(bg: UvColor.basic16(param - 100, bright: true));

      // Default colors
      case 39:
        style = style.copyWith(clearFg: true);
      case 49:
        style = style.copyWith(clearBg: true);
      case 59:
        style = style.copyWith(clearUnderlineColor: true);

      // Extended colors, semicolon form:
      // 38;5;<n>, 48;5;<n>, 38;2;r;g;b, 48;2;r;g;b
      // Underline color:
      // - 58;5;<n>, 58;2;r;g;b
      // - 58:5:<n>, 58:2::r:g:b
      case 38 || 48:
        final isFg = param == 38;

        // Colon form groups (e.g. 38:2::r:g:b) come in as a single param with sub.
        if (p.hasSub) {
          if (p.sub.isEmpty) break;
          final mode = p.sub[0];
          if (mode == 5 && p.sub.length >= 2) {
            final idx = p.sub[1];
            style = isFg
                ? style.copyWith(fg: UvColor.indexed256(idx))
                : style.copyWith(bg: UvColor.indexed256(idx));
          } else if (mode == 2 && p.sub.length >= 5) {
            // 38:2::<r>:<g>:<b>
            final r = color_utils.shift(p.sub[2]);
            final g = color_utils.shift(p.sub[3]);
            final b = color_utils.shift(p.sub[4]);
            style = isFg
                ? style.copyWith(fg: UvColor.rgb(r, g, b))
                : style.copyWith(bg: UvColor.rgb(r, g, b));
          }
          break;
        }

        if (i + 1 >= params.length) break;
        final mode = params[i + 1].value;
        if (mode == 5 && i + 2 < params.length) {
          final idx = params[i + 2].value;
          style = isFg
              ? style.copyWith(fg: UvColor.indexed256(idx))
              : style.copyWith(bg: UvColor.indexed256(idx));
          i += 2;
        } else if (mode == 2 && i + 4 < params.length) {
          final r = color_utils.shift(params[i + 2].value);
          final g = color_utils.shift(params[i + 3].value);
          final b = color_utils.shift(params[i + 4].value);
          style = isFg
              ? style.copyWith(fg: UvColor.rgb(r, g, b))
              : style.copyWith(bg: UvColor.rgb(r, g, b));
          i += 4;
        }
      case 58:
        // Underline color (SGR 58). Supports both semicolon and colon forms.
        // - Semicolon: 58;5;<n> or 58;2;r;g;b
        // - Colon: 58:5:<n> or 58:2::r:g:b
        if (p.hasSub) {
          if (p.sub.isEmpty) break;
          final mode = p.sub[0];
          if (mode == 5 && p.sub.length >= 2) {
            style = style.copyWith(
              underlineColor: UvColor.indexed256(p.sub[1]),
            );
          } else if (mode == 2) {
            // 58:2::r:g:b  -> sub = [2,0,r,g,b]
            // 58:2:r:g:b   -> sub = [2,r,g,b]
            if (p.sub.length >= 5) {
              final r = color_utils.shift(p.sub[2]);
              final g = color_utils.shift(p.sub[3]);
              final b = color_utils.shift(p.sub[4]);
              style = style.copyWith(underlineColor: UvColor.rgb(r, g, b));
            } else if (p.sub.length >= 4) {
              final r = color_utils.shift(p.sub[1]);
              final g = color_utils.shift(p.sub[2]);
              final b = color_utils.shift(p.sub[3]);
              style = style.copyWith(underlineColor: UvColor.rgb(r, g, b));
            }
          }
          break;
        }

        if (i + 1 >= params.length) break;
        final mode = params[i + 1].value;
        if (mode == 5 && i + 2 < params.length) {
          style = style.copyWith(
            underlineColor: UvColor.indexed256(params[i + 2].value),
          );
          i += 2;
        } else if (mode == 2 && i + 4 < params.length) {
          final r = color_utils.shift(params[i + 2].value);
          final g = color_utils.shift(params[i + 3].value);
          final b = color_utils.shift(params[i + 4].value);
          style = style.copyWith(underlineColor: UvColor.rgb(r, g, b));
          i += 4;
        }
    }
  }

  out.style = style;
}

/// Holds the result of parsing an SGR sequence.
final class StyleState {
  /// Creates a style state with the given [style].
  StyleState(this.style);

  /// The parsed [UvStyle] value.
  UvStyle style;
}

// --- Drawing ----------------------------------------------------------------

void _printString(
  Screen screen,
  WidthMethod method,
  int startX,
  int startY,
  Rectangle bounds,
  String input, {
  required bool truncate,
  required String tail,
}) {
  Cell? tailCell;
  if (truncate && tail.isNotEmpty) {
    tailCell = Cell.newCell(method, tail);
  }

  var x = startX;
  var y = startY;
  final pen = StyleState(const UvStyle());
  final link = LinkState(const Link());
  var currentStyle = const UvStyle();
  var currentLink = const Link();
  var hasCurrentAttributes = false;
  final OwnedCellScreen? ownedScreen = screen is OwnedCellScreen
      ? screen
      : null;
  final pendingEscapes = StringBuffer();
  var pendingGraphicsDisplaysImage = false;
  int? lastCellX;
  int? lastCellY;

  void refreshCurrentAttributes() {
    currentStyle = pen.style;
    currentLink = link.link;
    hasCurrentAttributes = !currentStyle.isZero || !currentLink.isZero;
  }

  void applyCurrentAttributes(Cell cell) {
    if (!currentStyle.isZero) cell.style = currentStyle;
    if (!currentLink.isZero) cell.link = currentLink;
  }

  void setFreshCell(int cellX, int cellY, Cell cell) {
    final owned = ownedScreen;
    if (owned == null) {
      screen.setCell(cellX, cellY, cell);
    } else {
      owned.setCellOwned(cellX, cellY, cell);
    }
  }

  void clearPendingEscapes() {
    pendingEscapes.clear();
    pendingGraphicsDisplaysImage = false;
  }

  void flushPendingToLastCell() {
    if (pendingEscapes.isEmpty) return;
    final cellX = lastCellX;
    final cellY = lastCellY;
    if (cellX == null || cellY == null) return;
    final cell = screen.cellAt(cellX, cellY);
    if (cell == null || cell.isZero) return;
    cell.content = '${cell.content}${pendingEscapes.toString()}';
    screen.setCell(cellX, cellY, cell);
    clearPendingEscapes();
  }

  void writePendingControlCell() {
    if (pendingEscapes.isEmpty) return;
    final cellWidth = _pendingControlCellWidth(pendingEscapes.toString());
    if (!truncate &&
        cellWidth > 0 &&
        x + cellWidth > bounds.maxX &&
        y + 1 < bounds.maxY) {
      x = bounds.minX;
      y++;
    }

    final pos = Position(x, y);
    if (bounds.contains(pos)) {
      final cell = Cell(content: pendingEscapes.toString(), width: cellWidth);
      if (hasCurrentAttributes) applyCurrentAttributes(cell);
      setFreshCell(x, y, cell);
      lastCellX = x;
      lastCellY = y;
    }
    clearPendingEscapes();
    x += cellWidth;
  }

  void writePrintableCell(Cell cell, {bool attributesApplied = false}) {
    if (pendingEscapes.isNotEmpty) {
      cell.content = '${pendingEscapes.toString()}${cell.content}';
      clearPendingEscapes();
      attributesApplied = false;
    }
    if (hasCurrentAttributes && !attributesApplied) {
      applyCurrentAttributes(cell);
    }

    if (!truncate && x + cell.width > bounds.maxX && y + 1 < bounds.maxY) {
      // Wrap to next line.
      x = bounds.minX;
      y++;
    }

    final pos = Position(x, y);
    if (bounds.contains(pos)) {
      if (truncate &&
          tailCell != null &&
          tailCell.width > 0 &&
          x + cell.width > bounds.maxX - tailCell.width) {
        final t = tailCell.clone();
        if (hasCurrentAttributes) applyCurrentAttributes(t);
        setFreshCell(x, y, t);
        lastCellX = x;
        lastCellY = y;
        x += t.width;
        // Stop drawing further content on this line.
        x = bounds.maxX;
      } else {
        setFreshCell(x, y, cell);
        lastCellX = x;
        lastCellY = y;
        x += cell.width;
      }
    } else {
      x += cell.width;
    }
  }

  var i = 0;
  while (i < input.length) {
    final codeUnit = input.codeUnitAt(i);

    // ESC sequences.
    if (codeUnit == 0x1B /* ESC */ && i + 1 < input.length) {
      final next = input.codeUnitAt(i + 1);
      if (next == 0x5B /* '[' */ ) {
        // CSI: ESC [ ... <final>
        final finalIndex = _findCsiFinal(input, i + 2);
        if (finalIndex != -1) {
          final finalByte = input.codeUnitAt(finalIndex);
          final paramsRaw = input.substring(i + 2, finalIndex);
          if (finalByte == 0x6D /* 'm' */ ) {
            readStyle(_parseSgrParams(paramsRaw), pen);
            refreshCurrentAttributes();
          } else if (_isPrivateCsiFinal(finalByte)) {
            pendingEscapes.write(input.substring(i, finalIndex + 1));
          }
          i = finalIndex + 1;
          continue;
        }
      } else if (next == 0x5D /* ']' */ ) {
        // OSC: ESC ] <cmd> ; <data> (BEL or ST)
        final osc = _parseOsc(input, i + 2);
        if (osc != null) {
          if (osc.cmd == 8) {
            // For cmd=8, `data` is "<params>;<url>".
            readLink(osc.data, link);
            refreshCurrentAttributes();
          }
          i = osc.endIndex;
          continue;
        }
      } else if (_isControlStringIntroducer(next)) {
        // DCS/SOS/PM/APC control strings. Graphics protocols such as Sixel
        // (DCS) and Kitty (APC) are terminal payloads, not printable text.
        final endIndex = _findStringTerminator(input, i + 2);
        if (endIndex != -1) {
          final sequence = input.substring(i, endIndex);
          pendingEscapes.write(sequence);
          final (
            :sawControl,
            :firstHasMoreChunks,
            :firstDisplaysImage,
            :anyDisplaysImage,
          ) = _scanGraphicsControls(
            sequence,
          );
          pendingGraphicsDisplaysImage =
              pendingGraphicsDisplaysImage || anyDisplaysImage;
          if (sawControl &&
              (firstHasMoreChunks ||
                  (!firstDisplaysImage && !pendingGraphicsDisplaysImage))) {
            i = endIndex;
            continue;
          }
          writePendingControlCell();
          i = endIndex;
          continue;
        }
      }
    } else if (_isEightBitControlStringIntroducer(codeUnit)) {
      final endIndex = _findEightBitStringTerminator(input, i + 1);
      if (endIndex != -1) {
        final sequence = input.substring(i, endIndex);
        pendingEscapes.write(sequence);
        final (
          :sawControl,
          :firstHasMoreChunks,
          :firstDisplaysImage,
          :anyDisplaysImage,
        ) = _scanGraphicsControls(
          sequence,
        );
        pendingGraphicsDisplaysImage =
            pendingGraphicsDisplaysImage || anyDisplaysImage;
        if (sawControl &&
            (firstHasMoreChunks ||
                (!firstDisplaysImage && !pendingGraphicsDisplaysImage))) {
          i = endIndex;
          continue;
        }
        writePendingControlCell();
        i = endIndex;
        continue;
      }
    }

    // Newline / carriage return.
    if (codeUnit == 0x0A /* \n */ ) {
      flushPendingToLastCell();
      y++;
      x = bounds.minX;
      i++;
      continue;
    }
    if (codeUnit == 0x0D /* \r */ ) {
      flushPendingToLastCell();
      x = bounds.minX;
      i++;
      continue;
    }

    if (_isStandalonePrintableAscii(input, i, codeUnit)) {
      final attributesApplied = pendingEscapes.isEmpty && hasCurrentAttributes;
      final cell = attributesApplied
          ? Cell.asciiStyled(codeUnit, style: currentStyle, link: currentLink)
          : Cell.ascii(codeUnit);
      writePrintableCell(cell, attributesApplied: attributesApplied);
      i++;
      continue;
    }

    final (:grapheme, :nextIndex) = uni.readGraphemeAt(input, i);
    writePrintableCell(Cell.newCell(method, grapheme));

    i = nextIndex;
  }

  flushPendingToLastCell();
}

int _pendingControlCellWidth(String controls) {
  return terminal_graphics.terminalGraphicsControlCellWidth(controls);
}

bool _isStandalonePrintableAscii(String input, int index, int codeUnit) {
  if (codeUnit < 0x20 || codeUnit >= 0x7F) return false;
  final nextIndex = index + 1;
  if (nextIndex >= input.length) return true;
  final next = input.codeUnitAt(nextIndex);
  return !_continuesPreviousGrapheme(next);
}

bool _continuesPreviousGrapheme(int codeUnit) {
  if (codeUnit >= 0x0300 && codeUnit <= 0x036F) return true;
  if (codeUnit >= 0x1AB0 && codeUnit <= 0x1AFF) return true;
  if (codeUnit >= 0x1DC0 && codeUnit <= 0x1DFF) return true;
  if (codeUnit >= 0x20D0 && codeUnit <= 0x20FF) return true;
  if (codeUnit >= 0xFE20 && codeUnit <= 0xFE2F) return true;
  if (codeUnit >= 0xFE00 && codeUnit <= 0xFE0F) return true;
  return codeUnit == 0x200D;
}

({
  bool sawControl,
  bool firstHasMoreChunks,
  bool firstDisplaysImage,
  bool anyDisplaysImage,
})
_scanGraphicsControls(String sequence) {
  var sawControl = false;
  var firstHasMoreChunks = false;
  var firstDisplaysImage = false;
  var anyDisplaysImage = false;

  for (final control in terminal_graphics.parseTerminalGraphicsControls(
    sequence,
  )) {
    if (!sawControl) {
      sawControl = true;
      firstHasMoreChunks = control.hasMoreChunks;
      firstDisplaysImage = control.displaysImage;
    }
    anyDisplaysImage = anyDisplaysImage || control.displaysImage;
  }

  return (
    sawControl: sawControl,
    firstHasMoreChunks: firstHasMoreChunks,
    firstDisplaysImage: firstDisplaysImage,
    anyDisplaysImage: anyDisplaysImage,
  );
}

int _findCsiFinal(String s, int start) {
  for (var i = start; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    // Final byte range: 0x40..0x7E (ASCII @..~)
    if (c >= 0x40 && c <= 0x7E) return i;
  }
  return -1;
}

bool _isPrivateCsiFinal(int byte) {
  return byte >= 0x70 && byte <= 0x7E; // 'p'..'~'
}

bool _isControlStringIntroducer(int byte) {
  return byte == 0x50 || // DCS: ESC P
      byte == 0x58 || // SOS: ESC X
      byte == 0x5E || // PM: ESC ^
      byte == 0x5F; // APC: ESC _
}

bool _isEightBitControlStringIntroducer(int byte) {
  return byte == 0x90 || // DCS
      byte == 0x98 || // SOS
      byte == 0x9E || // PM
      byte == 0x9F; // APC
}

int _findStringTerminator(String s, int start) {
  for (var i = start; i < s.length - 1; i++) {
    if (s.codeUnitAt(i) == 0x1B /* ESC */ &&
        s.codeUnitAt(i + 1) == 0x5C /* '\\' */ ) {
      return i + 2;
    }
  }
  return -1;
}

int _findEightBitStringTerminator(String s, int start) {
  for (var i = start; i < s.length; i++) {
    if (s.codeUnitAt(i) == 0x9C) return i + 1;
  }
  return -1;
}

final class _Osc {
  const _Osc({required this.cmd, required this.data, required this.endIndex});
  final int cmd;
  final String data;
  final int endIndex; // index after terminator
}

_Osc? _parseOsc(String s, int start) {
  // Parse cmd digits until ';'
  var i = start;
  final cmdBuf = StringBuffer();
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == 0x3B /* ';' */ ) break;
    cmdBuf.writeCharCode(c);
    i++;
  }
  if (i >= s.length || s.codeUnitAt(i) != 0x3B) return null;
  final cmd = int.tryParse(cmdBuf.toString());
  if (cmd == null) return null;
  i++; // skip ';'

  // Data until BEL (\x07) or ST (ESC \)
  final dataStart = i;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == 0x07 /* BEL */ ) {
      final data = s.substring(dataStart, i);
      return _Osc(cmd: cmd, data: data, endIndex: i + 1);
    }
    if (c == 0x1B /* ESC */ &&
        i + 1 < s.length &&
        s.codeUnitAt(i + 1) == 0x5C /* '\\' */ ) {
      final data = s.substring(dataStart, i);
      return _Osc(cmd: cmd, data: data, endIndex: i + 2);
    }
    i++;
  }
  return null;
}
