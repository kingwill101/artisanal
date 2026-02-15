/// Stream utilities for terminal events.
///
/// Implements the [UvEventStreamParser] which handles the complexities of
/// decoding ANSI sequences into structured [Event]s, including escape
/// timeouts and bracketed paste handling.
///
/// {@category Ultraviolet}
/// {@subCategory Input}
///
/// {@macro artisanal_uv_events_overview}
library;

import 'dart:convert' show utf8;

import 'decoder.dart';
import 'event.dart';

/// Streaming UV event scanner with ESC-timeout compatibility.
///
/// This mirrors the key behavior of upstream `TerminalReader.scanEvents`:
/// - buffers incomplete sequences across reads
/// - defers emitting `ESC`-prefixed sequences shorter than 3 bytes unless
///   `expired=true` (escape timeout reached / EOF)
/// - when `expired=true`, allows the decoder to flush incomplete sequences
///   as `UnknownEvent`
/// - collapses bracketed paste start/end into a single `PasteEvent`
final class UvEventStreamParser {
  UvEventStreamParser({EventDecoder? decoder})
    : _decoder = decoder ?? EventDecoder();

  final EventDecoder _decoder;
  final List<int> _buffer = <int>[];

  bool _inPaste = false;
  final List<int> _pasteBytes = <int>[];

  // Win32 VT input mode UTF-16 buffers (serialized input records with vk==0).
  //
  // Upstream: `third_party/ultraviolet/terminal_reader.go` (deserializeWin32Input)
  final List<bool> _win32Utf16Half = <bool>[false, false]; // 0 up, 1 down
  final List<int> _win32Utf16First = <int>[0, 0];
  final List<List<int>> _win32GraphemeBuf = <List<int>>[<int>[], <int>[]];

  static const List<int> _pasteEndEsc = <int>[
    0x1b,
    0x5b,
    0x32,
    0x30,
    0x31,
    0x7e,
  ]; // ESC [ 201 ~

  static const List<int> _pasteEndCsi8 = <int>[
    0x9b,
    0x32,
    0x30,
    0x31,
    0x7e,
  ]; // CSI 201 ~

  bool get hasPending => _buffer.isNotEmpty || _inPaste;

  /// Parses input bytes and returns any decoded events.
  ///
  /// When `expired=false`, short `ESC`-prefixed sequences are held in the buffer
  /// so they can be completed by subsequent reads.
  ///
  /// When `expired=true`, incomplete sequences are flushed (e.g. at EOF or after
  /// an escape timeout).
  List<Event> parseAll(List<int> bytes, {bool expired = false}) {
    if (bytes.isNotEmpty) _buffer.addAll(bytes);
    final out = <Event>[];

    _deserializeWin32VtInputMode();

    while (_buffer.isNotEmpty) {
      if (_inPaste) {
        final ev = _consumePasteIfComplete(expired: expired);
        if (ev == null) break;
        out.add(ev);
        continue;
      }

      final esc = _buffer.isNotEmpty && _buffer[0] == 0x1b;
      final (n, ev) = _decoder.decode(_buffer, allowIncompleteEsc: expired);
      if (n == 0) break;

      // Upstream `TerminalReader` waits before committing ESC-prefixed sequences
      // shorter than 3 bytes.
      if (esc && n <= 2 && !expired) break;

      // If the decoder reported an unknown event and we haven't expired yet,
      // assume it may be incomplete and wait for more bytes.
      if (ev is UnknownEvent && !expired) break;

      _buffer.removeRange(0, n);
      if (ev == null) continue;
      if (ev is IgnoredEvent) continue;

      if (ev is PasteStartEvent) {
        _inPaste = true;
        _pasteBytes.clear();
        continue;
      }
      if (ev is PasteEndEvent) {
        _inPaste = false;
        out.add(const PasteEvent(''));
        continue;
      }

      if (ev is MultiEvent) {
        out.addAll(ev.events);
      } else {
        out.add(ev);
      }
    }

    return out;
  }

  List<Event> flush() => parseAll(const [], expired: true);

  void clear() {
    _buffer.clear();
    _pasteBytes.clear();
    _inPaste = false;
    _win32Utf16Half[0] = false;
    _win32Utf16Half[1] = false;
    _win32Utf16First[0] = 0;
    _win32Utf16First[1] = 0;
    _win32GraphemeBuf[0].clear();
    _win32GraphemeBuf[1].clear();
  }

  void _deserializeWin32VtInputMode() {
    // Fast exit: only worth scanning if we might have CSI '_' sequences.
    if (_buffer.length < 4) return;
    if (!_buffer.contains(0x5f) /* '_' */ ) return;
    if (!_buffer.contains(0x1b) && !_buffer.contains(0x9b)) return;

    final src = List<int>.from(_buffer);
    final out = <int>[];
    var i = 0;

    void flushGraphemes() {
      for (var kd = 0; kd < 2; kd++) {
        final cps = _win32GraphemeBuf[kd];
        if (cps.isEmpty) continue;
        out.addAll(utf8.encode(String.fromCharCodes(cps)));
        cps.clear();
      }
    }

    bool isDigit(int b) => b >= 0x30 && b <= 0x39;

    List<int> parseParams(List<int> bytes) {
      final params = <int>[];
      var cur = 0;
      var has = false;
      for (final b in bytes) {
        if (isDigit(b)) {
          has = true;
          cur = (cur * 10) + (b - 0x30);
          continue;
        }
        if (b == 0x3b /* ; */ ) {
          params.add(has ? cur : 0);
          cur = 0;
          has = false;
          continue;
        }
        return const <int>[];
      }
      params.add(has ? cur : 0);
      return params;
    }

    void storeUtf16(int kd, int unit) {
      kd = kd.clamp(0, 1);
      if (_win32Utf16Half[kd]) {
        _win32Utf16Half[kd] = false;
        final a = _win32Utf16First[kd];
        final b = unit;
        int cp;
        final isHigh = a >= 0xD800 && a <= 0xDBFF;
        final isLow = b >= 0xDC00 && b <= 0xDFFF;
        if (isHigh && isLow) {
          cp = 0x10000 + ((a - 0xD800) << 10) + (b - 0xDC00);
        } else {
          cp = 0xfffd;
        }
        _win32GraphemeBuf[kd].add(cp);
        return;
      }

      final isSurrogate = unit >= 0xD800 && unit <= 0xDFFF;
      if (isSurrogate) {
        _win32Utf16Half[kd] = true;
        _win32Utf16First[kd] = unit;
        return;
      }
      _win32GraphemeBuf[kd].add(unit);
    }

    while (i < src.length) {
      final b = src[i];

      final isCsi7 = b == 0x1b && i + 1 < src.length && src[i + 1] == 0x5b;
      final isCsi8 = b == 0x9b;
      if (isCsi7 || isCsi8) {
        final start = i;
        var p = isCsi7 ? i + 2 : i + 1;
        while (p < src.length && (src[p] < 0x40 || src[p] > 0x7e)) {
          p++;
        }
        if (p >= src.length) break; // incomplete sequence; keep tail

        final finalByte = src[p];
        final end = p + 1;

        if (finalByte == 0x5f /* '_' */ ) {
          final paramsBytes = src.sublist(isCsi7 ? i + 2 : i + 1, p);
          final params = parseParams(paramsBytes);
          if (params.length >= 6) {
            final vk = params[0];
            if (vk == 0) {
              final uc = params[2];
              final kd = params[3];
              storeUtf16(kd, uc);
              i = end;
              continue; // drop this sequence
            }
          }
        }

        flushGraphemes();
        out.addAll(src.sublist(start, end));
        i = end;
        continue;
      }

      flushGraphemes();
      out.add(b);
      i++;
    }

    flushGraphemes();
    if (i < src.length) out.addAll(src.sublist(i));

    _buffer
      ..clear()
      ..addAll(out);
  }

  PasteEvent? _consumePasteIfComplete({required bool expired}) {
    final endIndex = _indexOfSubsequence(_buffer, _pasteEndEsc);
    final endIndex8 = _indexOfSubsequence(_buffer, _pasteEndCsi8);
    final idx = switch ((endIndex, endIndex8)) {
      (>= 0, >= 0) => endIndex < endIndex8 ? endIndex : endIndex8,
      (>= 0, _) => endIndex,
      (_, >= 0) => endIndex8,
      _ => -1,
    };

    if (idx < 0) {
      if (!expired) {
        _pasteBytes.addAll(_buffer);
        _buffer.clear();
        return null;
      }

      // EOF/timeout while in paste: best-effort emit what we have.
      _pasteBytes.addAll(_buffer);
      _buffer.clear();
      _inPaste = false;
      final text = utf8.decode(_pasteBytes, allowMalformed: true);
      _pasteBytes.clear();
      return PasteEvent(text);
    }

    _pasteBytes.addAll(_buffer.sublist(0, idx));
    final endLen = (idx == endIndex8)
        ? _pasteEndCsi8.length
        : _pasteEndEsc.length;
    _buffer.removeRange(0, idx + endLen);

    _inPaste = false;
    final text = utf8.decode(_pasteBytes, allowMalformed: true);
    _pasteBytes.clear();
    return PasteEvent(text);
  }

  static int _indexOfSubsequence(List<int> haystack, List<int> needle) {
    if (needle.isEmpty) return 0;
    if (haystack.length < needle.length) return -1;
    outer:
    for (var i = 0; i <= haystack.length - needle.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}
