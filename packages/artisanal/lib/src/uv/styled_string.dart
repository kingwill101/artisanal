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
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import '../unicode/width.dart';
import '../terminal/ansi.dart' as term_ansi;

import '../unicode/grapheme.dart' as uni;

/// StyledString is a string that can be decomposed into a series of styled
/// lines and cells.
///
/// Upstream: `third_party/ultraviolet/styled.go` (`StyledString`).
final class StyledString implements Drawable {
  StyledString(this.text, {this.wrap = false, this.tail = ''});

  final String text;
  bool wrap;
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
    // Clear the area before drawing.
    for (var y = area.minY; y < area.maxY; y++) {
      for (var x = area.minX; x < area.maxX; x++) {
        screen.setCell(x, y, null);
      }
    }

    // Normalize CRLF to NL to emulate raw terminal output.
    final normalized = text.replaceAll('\r\n', '\n');
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

StyledString newStyledString(String str) => StyledString(str);

// --- ANSI parsing helpers ----------------------------------------------------

final class _SgrParam {
  const _SgrParam(this.value, this.sub);
  final int value;
  final List<int> sub;
  bool get hasSub => sub.isNotEmpty;
}

List<_SgrParam> _parseSgrParams(String raw) {
  if (raw.isEmpty) return const [];
  final parts = raw.split(';');
  final out = <_SgrParam>[];
  for (final part in parts) {
    if (part.isEmpty) {
      out.add(const _SgrParam(0, []));
      continue;
    }
    final subParts = part.split(':');
    final value = int.tryParse(subParts[0]) ?? 0;
    final sub = <int>[];
    for (var i = 1; i < subParts.length; i++) {
      final s = subParts[i];
      sub.add(int.tryParse(s.isEmpty ? '0' : s) ?? 0);
    }
    out.add(_SgrParam(value, sub));
  }
  return out;
}

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

final class LinkState {
  LinkState(this.link);
  Link link;
}

void readStyle(List<_SgrParam> params, StyleState out) {
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
            final r = p.sub[2];
            final g = p.sub[3];
            final b = p.sub[4];
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
          final r = params[i + 2].value;
          final g = params[i + 3].value;
          final b = params[i + 4].value;
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
              final r = p.sub[2];
              final g = p.sub[3];
              final b = p.sub[4];
              style = style.copyWith(underlineColor: UvColor.rgb(r, g, b));
            } else if (p.sub.length >= 4) {
              final r = p.sub[1];
              final g = p.sub[2];
              final b = p.sub[3];
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
          final r = params[i + 2].value;
          final g = params[i + 3].value;
          final b = params[i + 4].value;
          style = style.copyWith(underlineColor: UvColor.rgb(r, g, b));
          i += 4;
        }
    }
  }

  out.style = style;
}

final class StyleState {
  StyleState(this.style);
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
          }
          i = osc.endIndex;
          continue;
        }
      }
    }

    // Newline / carriage return.
    if (codeUnit == 0x0A /* \n */ ) {
      y++;
      x = bounds.minX;
      i++;
      continue;
    }
    if (codeUnit == 0x0D /* \r */ ) {
      x = bounds.minX;
      i++;
      continue;
    }

    final (:grapheme, :nextIndex) = uni.readGraphemeAt(input, i);
    var cell = Cell.newCell(method, grapheme);
    cell.style = pen.style;
    cell.link = link.link;

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
        t.style = pen.style;
        t.link = link.link;
        screen.setCell(x, y, t);
        x += t.width;
        // Stop drawing further content on this line.
        x = bounds.maxX;
      } else {
        screen.setCell(x, y, cell);
        x += cell.width;
      }
    } else {
      x += cell.width;
    }

    i = nextIndex;
  }
}

int _findCsiFinal(String s, int start) {
  for (var i = start; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    // Final byte range: 0x40..0x7E (ASCII @..~)
    if (c >= 0x40 && c <= 0x7E) return i;
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
