/// ANSI-aware string slicing by visible cell width.
///
/// Extracts substrings from ANSI-escaped text using cell indices (terminal
/// columns), properly restoring pen state (SGR attributes, OSC 8 hyperlinks)
/// at cut boundaries.
library;

import 'ansi.dart' as uv_ansi;
import 'cell.dart';
import 'color_utils.dart' as color_utils;
import 'style_ops.dart' as uv_ops;
import '../unicode/grapheme.dart' as uni;
import '../unicode/width.dart';

/// Cuts an ANSI string by visible cell indices, preserving any active SGR/OSC 8
/// state at the start boundary.
///
/// This is useful for viewport-style horizontal scrolling and truncation.
String cutAnsiByCells(String s, int start, int end) =>
    _cutAnsiByCells(s, start, end);

/// Truncates an ANSI string from the left by visible cell indices.
String truncateLeftAnsiByCells(String s, int start) =>
    _truncateLeftAnsiByCells(s, start);

// --- ANSI slicing with pen-state restoration --------------------------------

enum _TokenKind { text, newline, csi, osc }

final class _Token {
  const _Token({
    required this.kind,
    required this.raw,
    required this.visibleWidth,
    this.csiFinal = '',
    this.csiParams = '',
    this.oscCmd = -1,
    this.oscData = '',
  });

  final _TokenKind kind;
  final String raw;
  final int visibleWidth;

  // CSI
  final String csiFinal;
  final String csiParams;

  // OSC
  final int oscCmd;
  final String oscData;
}

String _cutAnsiByCells(String s, int start, int end) {
  if (end <= start) return '';
  if (start < 0) start = 0;

  final tokens = _tokenizeAnsi(s);
  start = _snapAnsiCellBoundary(tokens, start);
  end = _snapAnsiCellBoundary(tokens, end);
  if (end <= start) return '';

  final prefix = _penStateAt(tokens, start);

  final out = StringBuffer()..write(prefix);

  var cell = 0;
  var inRange = false;

  for (final t in tokens) {
    if (!inRange && cell >= start) {
      inRange = true;
    }

    if (inRange && cell >= end) break;

    switch (t.kind) {
      case _TokenKind.csi || _TokenKind.osc:
        if (inRange) out.write(t.raw);

      case _TokenKind.newline:
        if (inRange) out.write(t.raw);

      case _TokenKind.text:
        final nextCell = cell + t.visibleWidth;
        final intersects = nextCell > start && cell < end;
        if (intersects && inRange) out.write(t.raw);
        cell = nextCell;
    }
  }

  return out.toString();
}

String _truncateLeftAnsiByCells(String s, int start) {
  if (start <= 0) return s;
  return _cutAnsiByCells(s, start, 1 << 30);
}

int _snapAnsiCellBoundary(List<_Token> tokens, int index) {
  if (index <= 0) return 0;
  var cell = 0;

  for (final t in tokens) {
    if (t.kind != _TokenKind.text) continue;

    final nextCell = cell + t.visibleWidth;
    if (index > cell && index < nextCell) return cell;
    if (index == nextCell) return nextCell;
    cell = nextCell;
  }

  return cell;
}

String _penStateAt(List<_Token> tokens, int cellIndex) {
  var style = const UvStyle();
  var link = const Link();
  var cell = 0;

  for (final t in tokens) {
    switch (t.kind) {
      case _TokenKind.csi:
        if (t.csiFinal == 'm') {
          style = _applySgr(t.csiParams, style);
        }

      case _TokenKind.osc:
        if (t.oscCmd == 8) {
          link = _applyOsc8(t.oscData);
        }

      case _TokenKind.newline:
      // ANSI pen state typically carries across newlines; keep state.

      case _TokenKind.text:
        final nextCell = cell + t.visibleWidth;
        if (nextCell > cellIndex) {
          final prefix = StringBuffer();
          if (!link.isZero) {
            prefix.write(uv_ansi.UvAnsi.setHyperlink(link.url, link.params));
          }
          if (!style.isZero) {
            prefix.write(uv_ops.styleToSgr(style));
          }
          return prefix.toString();
        }
        cell = nextCell;
    }
  }

  final prefix = StringBuffer();
  if (!link.isZero) {
    prefix.write(uv_ansi.UvAnsi.setHyperlink(link.url, link.params));
  }
  if (!style.isZero) prefix.write(uv_ops.styleToSgr(style));
  return prefix.toString();
}

List<_Token> _tokenizeAnsi(String input) {
  final tokens = <_Token>[];
  var i = 0;

  while (i < input.length) {
    final cu = input.codeUnitAt(i);

    if (cu == 0x1B && i + 1 < input.length) {
      final next = input.codeUnitAt(i + 1);
      if (next == 0x5B) {
        final finalIdx = _findCsiFinal(input, i + 2);
        if (finalIdx != -1) {
          final raw = input.substring(i, finalIdx + 1);
          final params = input.substring(i + 2, finalIdx);
          final fin = input[finalIdx];
          tokens.add(
            _Token(
              kind: _TokenKind.csi,
              raw: raw,
              visibleWidth: 0,
              csiFinal: fin,
              csiParams: params,
            ),
          );
          i = finalIdx + 1;
          continue;
        }
      } else if (next == 0x5D) {
        final osc = _parseOsc(input, i + 2);
        if (osc != null) {
          tokens.add(
            _Token(
              kind: _TokenKind.osc,
              raw: osc.raw,
              visibleWidth: 0,
              oscCmd: osc.cmd,
              oscData: osc.data,
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
    tokens.add(
      _Token(
        kind: _TokenKind.text,
        raw: grapheme,
        visibleWidth: stringWidth(grapheme),
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

Link _applyOsc8(String data) {
  final sep = data.indexOf(';');
  if (sep < 0) return const Link();
  final params = data.substring(0, sep);
  final url = data.substring(sep + 1);
  return Link(url: url, params: params);
}

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

UvStyle _applySgr(String rawParams, UvStyle style) {
  final params = rawParams.isEmpty
      ? const <_SgrParam>[]
      : _parseSgrParams(rawParams);
  if (params.isEmpty) return const UvStyle();

  var out = style;

  for (var i = 0; i < params.length; i++) {
    final p = params[i];
    final param = p.value;

    switch (param) {
      case 0:
        out = const UvStyle();
      case 1:
        out = out.copyWith(attrs: out.attrs | Attr.bold);
      case 2:
        out = out.copyWith(attrs: out.attrs | Attr.faint);
      case 3:
        out = out.copyWith(attrs: out.attrs | Attr.italic);
      case 4:
        if (p.hasSub) {
          final u = p.sub.first;
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
        out = out.copyWith(fg: UvColor.basic16(param - 30));
      case >= 90 && <= 97:
        out = out.copyWith(fg: UvColor.basic16(param - 90, bright: true));
      case >= 40 && <= 47:
        out = out.copyWith(bg: UvColor.basic16(param - 40));
      case >= 100 && <= 107:
        out = out.copyWith(bg: UvColor.basic16(param - 100, bright: true));
      case 39:
        out = out.copyWith(clearFg: true);
      case 49:
        out = out.copyWith(clearBg: true);

      // Extended colors (38/48): best-effort, semicolon and colon forms.
      case 38 || 48:
        final isFg = param == 38;

        if (p.hasSub) {
          if (p.sub.isEmpty) break;
          final mode = p.sub[0];
          if (mode == 5 && p.sub.length >= 2) {
            final idx = p.sub[1];
            out = isFg
                ? out.copyWith(fg: UvColor.indexed256(idx))
                : out.copyWith(bg: UvColor.indexed256(idx));
          } else if (mode == 2 && p.sub.length >= 5) {
            final r = color_utils.shift(p.sub[2]);
            final g = color_utils.shift(p.sub[3]);
            final b = color_utils.shift(p.sub[4]);
            out = isFg
                ? out.copyWith(fg: UvColor.rgb(r, g, b))
                : out.copyWith(bg: UvColor.rgb(r, g, b));
          }
          break;
        }

        if (i + 1 >= params.length) break;
        final mode = params[i + 1].value;
        if (mode == 5 && i + 2 < params.length) {
          final idx = params[i + 2].value;
          out = isFg
              ? out.copyWith(fg: UvColor.indexed256(idx))
              : out.copyWith(bg: UvColor.indexed256(idx));
          i += 2;
        } else if (mode == 2 && i + 4 < params.length) {
          final r = color_utils.shift(params[i + 2].value);
          final g = color_utils.shift(params[i + 3].value);
          final b = color_utils.shift(params[i + 4].value);
          out = isFg
              ? out.copyWith(fg: UvColor.rgb(r, g, b))
              : out.copyWith(bg: UvColor.rgb(r, g, b));
          i += 4;
        }
    }
  }

  return out;
}
