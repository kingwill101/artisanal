/// Text wrapping utilities.
///
/// Provides ANSI-aware text wrapping that preserves SGR and OSC 8 state
/// across line breaks.
///
/// {@category Ultraviolet}
/// {@subCategory Styling}
///
/// {@macro artisanal_uv_performance_tips}
library;

import 'ansi.dart';
import 'cell.dart';
import 'color_utils.dart' as color_utils;
import '../unicode/width.dart';

import '../unicode/grapheme.dart' as uni;

/// Wraps a string to [width] while preserving ANSI pen state (SGR + OSC 8)
/// across inserted and existing newlines.
///
String wrapAnsiPreserving(String input, int width, {String breakpoints = ''}) {
  if (width <= 0) return input;

  final out = StringBuffer();

  var style = const UvStyle();
  var link = const Link();

  void resetIfNeeded() {
    if (!style.isZero) out.write(UvAnsi.resetStyle);
    if (!link.isZero) out.write(UvAnsi.resetHyperlink());
  }

  void reapplyIfNeeded() {
    if (!link.isZero) out.write(UvAnsi.setHyperlink(link.url, link.params));
    if (!style.isZero) out.write(_styleToSgr(style));
  }

  // Tokenize input into a stream of "units" with display widths.
  final tokens = _tokenize(input);

  final breakChars = <int>{
    0x20, // space
    ...uni.codePoints(breakpoints),
  };

  var lineStart = 0;
  var lineWidth = 0;
  int? lastBreakToken;
  int? widthAtBreak;

  void emitRange(int start, int endExclusive) {
    for (var i = start; i < endExclusive; i++) {
      final t = tokens[i];
      if (t.kind == _TokenKind.csiSgr) {
        style = _applySgr(t.payload, style);
        out.write(t.raw);
      } else if (t.kind == _TokenKind.osc8) {
        link = _applyOsc8(t.payload);
        out.write(t.raw);
      } else if (t.kind == _TokenKind.newline) {
        resetIfNeeded();
        out.write('\n');
        reapplyIfNeeded();
      } else {
        out.write(t.raw);
      }
    }
  }

  var i = 0;
  while (i < tokens.length) {
    final t = tokens[i];
    if (t.kind == _TokenKind.newline) {
      emitRange(lineStart, i + 1);
      i++;
      lineStart = i;
      lineWidth = 0;
      lastBreakToken = null;
      widthAtBreak = null;
      continue;
    }

    final w = t.visibleWidth;
    if (t.kind == _TokenKind.text && breakChars.contains(t.rune)) {
      lastBreakToken = i;
      widthAtBreak = lineWidth + w;
    }

    if (lineWidth + w > width) {
      // A grapheme is indivisible. If it is wider than an otherwise empty
      // line, consume it as that line's content even though it exceeds the
      // requested width. Retrying the same token would never make progress.
      if (lineWidth == 0 && w > width) {
        lineWidth = w;
        i++;
        continue;
      }

      if (lastBreakToken != null &&
          widthAtBreak != null &&
          lastBreakToken >= lineStart) {
        // Emit up to break, drop the break token itself.
        emitRange(lineStart, lastBreakToken);
        resetIfNeeded();
        out.write('\n');
        reapplyIfNeeded();

        i = lastBreakToken + 1;
        lineStart = i;
        lineWidth = 0;
        lastBreakToken = null;
        widthAtBreak = null;
        continue;
      }

      // Hard break at current token.
      emitRange(lineStart, i);
      resetIfNeeded();
      out.write('\n');
      reapplyIfNeeded();

      lineStart = i;
      lineWidth = 0;
      lastBreakToken = null;
      widthAtBreak = null;
      continue;
    }

    lineWidth += w;
    i++;
  }

  emitRange(lineStart, tokens.length);
  resetIfNeeded();
  return out.toString();
}

String _styleToSgr(UvStyle style) {
  if (style.isZero) return UvAnsi.resetStyle;
  final codes = <String>[];
  final attrs = style.attrs;
  if ((attrs & Attr.bold) != 0) codes.add('1');
  if ((attrs & Attr.faint) != 0) codes.add('2');
  if ((attrs & Attr.italic) != 0) codes.add('3');
  if ((attrs & Attr.blink) != 0) codes.add('5');
  if ((attrs & Attr.rapidBlink) != 0) codes.add('6');
  if ((attrs & Attr.reverse) != 0) codes.add('7');
  if ((attrs & Attr.conceal) != 0) codes.add('8');
  if ((attrs & Attr.strikethrough) != 0) codes.add('9');

  switch (style.underline) {
    case UnderlineStyle.none:
      break;
    case UnderlineStyle.single:
      codes.add('4');
    case UnderlineStyle.double:
      codes.add('4:2');
    case UnderlineStyle.curly:
      codes.add('4:3');
    case UnderlineStyle.dotted:
      codes.add('4:4');
    case UnderlineStyle.dashed:
      codes.add('4:5');
  }

  void addColor(String prefix, UvColor? c) {
    if (c == null) return;
    switch (c) {
      case UvBasic16(:final index, :final bright):
        if (prefix == 'ul') {
          codes.add('58:5:${index + (bright ? 8 : 0)}');
        } else {
          final base = bright
              ? (prefix == 'fg' ? 90 : 100)
              : (prefix == 'fg' ? 30 : 40);
          codes.add('${base + index}');
        }
      case UvIndexed256(:final index):
        codes.add(switch (prefix) {
          'fg' => '38;5;$index',
          'bg' => '48;5;$index',
          _ => '58:5:$index',
        });
      case UvRgb(:final r, :final g, :final b):
        final rr = color_utils.clampRgbChannel(r);
        final gg = color_utils.clampRgbChannel(g);
        final bb = color_utils.clampRgbChannel(b);
        codes.add(switch (prefix) {
          'fg' => '38;2;$rr;$gg;$bb',
          'bg' => '48;2;$rr;$gg;$bb',
          _ => '58:2::$rr:$gg:$bb',
        });
    }
  }

  addColor('fg', style.fg);
  addColor('bg', style.bg);
  addColor('ul', style.underlineColor);

  return '\x1b[${codes.join(';')}m';
}

// --- Minimal tokenization / SGR + OSC8 decoding -----------------------------

enum _TokenKind { text, newline, csiSgr, osc8 }

final class _Token {
  const _Token({
    required this.kind,
    required this.raw,
    required this.visibleWidth,
    this.payload = '',
    this.rune,
  });

  final _TokenKind kind;
  final String raw;
  final int visibleWidth;
  final String payload;
  final int? rune;
}

List<_Token> _tokenize(String input) {
  final tokens = <_Token>[];
  var i = 0;
  while (i < input.length) {
    final cu = input.codeUnitAt(i);
    if (cu == 0x1B && i + 1 < input.length) {
      final next = input.codeUnitAt(i + 1);
      if (next == 0x5B) {
        final finalIdx = _findCsiFinal(input, i + 2);
        if (finalIdx != -1 && input.codeUnitAt(finalIdx) == 0x6D) {
          final raw = input.substring(i, finalIdx + 1);
          final params = input.substring(i + 2, finalIdx);
          tokens.add(
            _Token(
              kind: _TokenKind.csiSgr,
              raw: raw,
              payload: params,
              visibleWidth: 0,
            ),
          );
          i = finalIdx + 1;
          continue;
        }
      } else if (next == 0x5D) {
        final osc = _parseOsc(input, i + 2);
        if (osc != null && osc.cmd == 8) {
          tokens.add(
            _Token(
              kind: _TokenKind.osc8,
              raw: osc.raw,
              payload: osc.data,
              visibleWidth: 0,
            ),
          );
          i = osc.endIndex;
          continue;
        }
      }
    }

    if (cu == 0x0A) {
      tokens.add(
        const _Token(kind: _TokenKind.newline, raw: '\n', visibleWidth: 0),
      );
      i++;
      continue;
    }

    final (:grapheme, :nextIndex) = uni.readGraphemeAt(input, i);
    final rune = uni.firstCodePoint(grapheme);
    tokens.add(
      _Token(
        kind: _TokenKind.text,
        raw: grapheme,
        visibleWidth: stringWidth(grapheme),
        rune: rune,
      ),
    );
    i = nextIndex;
  }
  return tokens;
}

int _findCsiFinal(String s, int start) {
  for (var i = start; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c >= 0x40 && c <= 0x7E) return i;
  }
  return -1;
}

final class _Osc {
  const _Osc({
    required this.cmd,
    required this.data,
    required this.raw,
    required this.endIndex,
  });
  final int cmd;
  final String data;
  final String raw;
  final int endIndex;
}

_Osc? _parseOsc(String s, int start) {
  var i = start;
  final cmdBuf = StringBuffer();
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == 0x3B) break;
    cmdBuf.writeCharCode(c);
    i++;
  }
  if (i >= s.length || s.codeUnitAt(i) != 0x3B) return null;
  final cmd = int.tryParse(cmdBuf.toString());
  if (cmd == null) return null;
  i++; // skip ';'

  final dataStart = i;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == 0x07) {
      final data = s.substring(dataStart, i);
      return _Osc(
        cmd: cmd,
        data: data,
        raw: s.substring(start - 2, i + 1),
        endIndex: i + 1,
      );
    }
    if (c == 0x1B && i + 1 < s.length && s.codeUnitAt(i + 1) == 0x5C) {
      final data = s.substring(dataStart, i);
      return _Osc(
        cmd: cmd,
        data: data,
        raw: s.substring(start - 2, i + 2),
        endIndex: i + 2,
      );
    }
    i++;
  }
  return null;
}

UvStyle _applySgr(String rawParams, UvStyle style) {
  final params = rawParams.isEmpty ? const ['0'] : rawParams.split(';');
  var out = style;

  var i = 0;
  while (i < params.length) {
    final part = params[i];
    if (part.isEmpty) {
      i++;
      continue;
    }
    final sub = part.split(':');
    final p = int.tryParse(sub[0]) ?? 0;
    switch (p) {
      case 0:
        out = const UvStyle();
      case 1:
        out = out.copyWith(attrs: out.attrs | Attr.bold);
      case 2:
        out = out.copyWith(attrs: out.attrs | Attr.faint);
      case 3:
        out = out.copyWith(attrs: out.attrs | Attr.italic);
      case 4:
        if (sub.length >= 2) {
          final u = int.tryParse(sub[1]) ?? 1;
          out = out.copyWith(
            underline: switch (u) {
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
          out = out.copyWith(underline: UnderlineStyle.single);
        }
      case 5:
        out = out.copyWith(attrs: out.attrs | Attr.blink);
      case 6:
        out = out.copyWith(attrs: out.attrs | Attr.rapidBlink);
      case 7:
        out = out.copyWith(attrs: out.attrs | Attr.reverse);
      case 8:
        out = out.copyWith(attrs: out.attrs | Attr.conceal);
      case 9:
        out = out.copyWith(attrs: out.attrs | Attr.strikethrough);
      case 21:
        out = out.copyWith(underline: UnderlineStyle.double);
      case 22:
        out = out.copyWith(attrs: out.attrs & ~(Attr.bold | Attr.faint));
      case 23:
        out = out.copyWith(attrs: out.attrs & ~Attr.italic);
      case 24:
        out = out.copyWith(underline: UnderlineStyle.none);
      case 25:
        out = out.copyWith(attrs: out.attrs & ~(Attr.blink | Attr.rapidBlink));
      case 27:
        out = out.copyWith(attrs: out.attrs & ~Attr.reverse);
      case 28:
        out = out.copyWith(attrs: out.attrs & ~Attr.conceal);
      case 29:
        out = out.copyWith(attrs: out.attrs & ~Attr.strikethrough);
      case >= 30 && <= 37:
        out = out.copyWith(fg: UvColor.basic16(p - 30));
      case >= 90 && <= 97:
        out = out.copyWith(fg: UvColor.basic16(p - 90, bright: true));
      case >= 40 && <= 47:
        out = out.copyWith(bg: UvColor.basic16(p - 40));
      case >= 100 && <= 107:
        out = out.copyWith(bg: UvColor.basic16(p - 100, bright: true));
      case 39:
        out = out.copyWith(clearFg: true);
      case 49:
        out = out.copyWith(clearBg: true);
      case 38:
        // Extended foreground color: 38;5;n (256-color) or 38;2;r;g;b (truecolor)
        final (color, consumed) = _parseExtendedColor(params, i + 1);
        if (color != null) {
          out = out.copyWith(fg: color);
        }
        i += consumed;
      case 48:
        // Extended background color: 48;5;n (256-color) or 48;2;r;g;b (truecolor)
        final (color, consumed) = _parseExtendedColor(params, i + 1);
        if (color != null) {
          out = out.copyWith(bg: color);
        }
        i += consumed;
      case 58:
        // Underline color supports both colon and semicolon forms.
        if (sub.length >= 3) {
          final mode = int.tryParse(sub[1]);
          if (mode == 5) {
            final index = int.tryParse(sub[2]);
            if (index != null) {
              out = out.copyWith(underlineColor: UvColor.indexed256(index));
            }
          } else if (mode == 2) {
            // The six-field form includes a color-space slot, which may be
            // empty or explicitly zero: 58:2:<cs>:r:g:b.
            final channelStart = sub.length >= 6 ? 3 : 2;
            if (sub.length >= channelStart + 3) {
              final r = int.tryParse(sub[channelStart]);
              final g = int.tryParse(sub[channelStart + 1]);
              final b = int.tryParse(sub[channelStart + 2]);
              if (r != null && g != null && b != null) {
                out = out.copyWith(underlineColor: UvColor.rgb(r, g, b));
              }
            }
          }
        } else {
          final (color, consumed) = _parseExtendedColor(params, i + 1);
          if (color != null) {
            out = out.copyWith(underlineColor: color);
          }
          i += consumed;
        }
      case 59:
        out = out.copyWith(clearUnderlineColor: true);
    }
    i++;
  }

  return out;
}

/// Parses extended color parameters (256-color or truecolor).
/// Returns the color and the number of additional parameters consumed.
(UvColor?, int) _parseExtendedColor(List<String> params, int start) {
  if (start >= params.length) return (null, 0);

  final mode = int.tryParse(params[start]);
  if (mode == 5) {
    // 256-color: 38;5;n or 48;5;n
    if (start + 1 < params.length) {
      final index = int.tryParse(params[start + 1]);
      if (index != null && index >= 0 && index <= 255) {
        return (UvColor.indexed256(index), 2);
      }
    }
    return (null, 1);
  } else if (mode == 2) {
    // Truecolor: 38;2;r;g;b or 48;2;r;g;b
    if (start + 3 < params.length) {
      final r = int.tryParse(params[start + 1]);
      final g = int.tryParse(params[start + 2]);
      final b = int.tryParse(params[start + 3]);
      if (r != null && g != null && b != null) {
        return (
          UvColor.rgb(
            color_utils.shift(r),
            color_utils.shift(g),
            color_utils.shift(b),
          ),
          4,
        );
      }
    }
    return (null, 1);
  }
  return (null, 0);
}

Link _applyOsc8(String data) {
  final sep = data.indexOf(';');
  if (sep < 0) return const Link();
  final params = data.substring(0, sep);
  final url = data.substring(sep + 1);
  return Link(url: url, params: params);
}
