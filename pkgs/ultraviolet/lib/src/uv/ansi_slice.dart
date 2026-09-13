/// ANSI-aware string slicing by visible cell width.
///
/// Extracts substrings from ANSI-escaped text using cell indices (terminal
/// columns), properly restoring pen state (SGR attributes, OSC 8 hyperlinks)
/// at cut boundaries.
library;

import 'ansi.dart' as uv_ansi;
import 'cell.dart';
import 'styled_string.dart' show SgrParam, StyleState, readStyle;
import 'style_ops.dart' as uv_ops;
import '../unicode/grapheme.dart' as uni;
import '../unicode/width.dart';

/// Cuts an ANSI string by visible cell indices, preserving any active SGR/OSC 8
/// state at the start boundary.
///
/// This is useful for viewport-style horizontal scrolling and truncation.
String cutAnsiByCells(String s, int start, int end) =>
    _cutAnsiByCells(s, start, end);

/// Clips a styled line to the exact cell interval `[start, end)`.
///
/// Unlike [cutAnsiByCells], boundaries do not snap backward to whole graphemes.
/// A partially intersected wide glyph or graphics payload becomes spaces with
/// its active pen state, keeping overlays and following text at fixed columns.
/// Missing text beyond the line's end is not padded. SGR and OSC 8 state is
/// restored at the start; the caller owns resetting that state after the clip.
///
/// {@category Ultraviolet}
String clipAnsiByCells(String s, int start, int end) {
  if (start < 0) start = 0;
  if (end <= start) return '';
  final tokens = _tokenizeAnsi(s);
  final length = tokens.fold<int>(0, (sum, token) => sum + token.visibleWidth);
  if (start >= length) return '';
  final out = StringBuffer()..write(_penStateAt(tokens, start));
  var cell = 0;
  for (final token in tokens) {
    if (cell >= end) break;
    if (token.visibleWidth == 0) {
      if (cell >= start) out.write(token.raw);
      continue;
    }
    final next = cell + token.visibleWidth;
    if (next > start && cell < end) {
      if (cell >= start && next <= end) {
        out.write(token.raw);
      } else {
        final left = cell < start ? start : cell;
        final right = next > end ? end : next;
        out.write(' ' * (right - left));
      }
    }
    cell = next;
  }
  return out.toString();
}

/// Truncates an ANSI string from the left by visible cell indices.
String truncateLeftAnsiByCells(String s, int start) =>
    _truncateLeftAnsiByCells(s, start);

// --- ANSI slicing with pen-state restoration --------------------------------

enum _TokenKind { text, newline, csi, osc, deviceControl }

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

      case _TokenKind.text || _TokenKind.deviceControl:
        // Device-control payloads occupy their display width atomically:
        // included whole when intersecting, never split.
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
    if (t.kind != _TokenKind.text && t.kind != _TokenKind.deviceControl) {
      continue;
    }

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

      case _TokenKind.deviceControl:
      // Device-control payloads (Kitty/Sixel pixels) carry no SGR or
      // hyperlink pen state; the image occupies its cells opaquely.
      // Fall through to advance the cell counter below.
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
      } else if (next == 0x50 || next == 0x5E || next == 0x5F || next == 0x58) {
        // DCS/APC/PM/SOS: ESC P|^|_|X ... ST (Kitty graphics, Sixel).
        // Tokenized whole with pixel-display width so cuts never split
        // a payload — consistent with Ansi.visibleLength's c= rule.
        var end = _findStringTerminator(input, i + 2);
        var raw = input.substring(i, end);
        // A chunked Kitty transmission is one atomic display operation.
        // Continuation APCs have no c= width of their own, so leaving them as
        // separate zero-width tokens lets a cut stop after the first chunk and
        // silently corrupt the image payload.
        if (next == 0x5F && _kittyChunkHasMore(raw)) {
          final chunks = StringBuffer()..write(raw);
          while (end + 2 < input.length && input.startsWith('\x1b_G', end)) {
            final chunkEnd = _findStringTerminator(input, end + 3);
            final chunk = input.substring(end, chunkEnd);
            chunks.write(chunk);
            end = chunkEnd;
            if (!_kittyChunkHasMore(chunk)) break;
          }
          raw = chunks.toString();
        }
        tokens.add(
          _Token(
            kind: _TokenKind.deviceControl,
            raw: raw,
            visibleWidth: _deviceControlWidth(raw),
          ),
        );
        i = end;
        continue;
      }
    }

    // C1 device-control strings: 0x90/0x98/0x9E/0x9F ... 0x9C.
    if ((cu == 0x90 || cu == 0x98 || cu == 0x9E || cu == 0x9F) &&
        i + 1 < input.length) {
      var end = i + 1;
      while (end < input.length && input.codeUnitAt(end) != 0x9C) {
        end++;
      }
      if (end < input.length) end++;
      final raw = input.substring(i, end);
      tokens.add(
        _Token(
          kind: _TokenKind.deviceControl,
          raw: raw,
          visibleWidth: _deviceControlWidth(raw),
        ),
      );
      i = end;
      continue;
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

/// End index (exclusive) of a DCS/APC/PM/SOS string starting its payload
/// at [start]: first ST (`ESC \`) or BEL, else end of input.
int _findStringTerminator(String s, int start) {
  var i = start;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == 0x07) return i + 1;
    if (c == 0x1B && i + 1 < s.length && s.codeUnitAt(i + 1) == 0x5C) {
      return i + 2;
    }
    i++;
  }
  return s.length;
}

/// Display width of a device-control sequence, mirroring
/// `Ansi.visibleLength`: Kitty transmit/put actions occupy `c` columns,
/// Sixel occupies one, everything else is zero-width.
int _deviceControlWidth(String raw) {
  if (raw.startsWith('\x1bPq') || raw.startsWith('\x90q')) return 1;
  final params = _kittyDeviceParams(raw);
  if (params == null) return 0;
  var action = '';
  var columns = 0;
  for (final parameter in params.split(',')) {
    if (parameter.isEmpty) continue;
    final equals = parameter.indexOf('=');
    if (equals <= 0) continue;
    switch (parameter.substring(0, equals)) {
      case 'a':
        action = parameter.substring(equals + 1);
      case 'c':
        columns = int.tryParse(parameter.substring(equals + 1)) ?? 0;
    }
  }
  return (action == 'T' || action == 'p') ? columns : 0;
}

String? _kittyDeviceParams(String raw) {
  String body;
  if (raw.startsWith('\x1b_G') &&
      (raw.endsWith('\x1b\\') || raw.endsWith('\x07'))) {
    body = raw.endsWith('\x07')
        ? raw.substring(3, raw.length - 1)
        : raw.substring(3, raw.length - 2);
  } else if (raw.startsWith('\x9fG') && raw.endsWith('\x9c')) {
    body = raw.substring(3, raw.length - 1);
  } else {
    return null;
  }
  final parameterEnd = body.indexOf(';');
  return parameterEnd == -1 ? body : body.substring(0, parameterEnd);
}

bool _kittyChunkHasMore(String raw) {
  final params = _kittyDeviceParams(raw);
  if (params == null) return false;
  return params.split(',').contains('m=1');
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

List<SgrParam> _parseSgrParams(String raw) {
  if (raw.isEmpty) return const [];
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
  return out;
}

UvStyle _applySgr(String rawParams, UvStyle style) {
  final state = StyleState(style);
  readStyle(_parseSgrParams(rawParams), state);
  return state.style;
}
