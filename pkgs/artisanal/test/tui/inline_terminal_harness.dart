import 'package:artisanal/src/terminal/ansi.dart';

/// Small terminal interpreter for inline-mode tests.
///
/// This intentionally implements only the ANSI subset emitted by Artisanal's
/// inline renderer: CUP/HVP, VPA, DEC save/restore, DECSTBM, erase line, CR,
/// LF, printable text, and synchronized-output wrappers as no-ops.
final class InlineVirtualTerminal {
  InlineVirtualTerminal({required this.width, required this.height})
    : _rows = List<String>.filled(height, '', growable: true);

  int width;
  int height;
  final List<String> _rows;
  final List<String> scrollback = <String>[];

  int _row = 1;
  int _col = 1;
  int _scrollTop = 1;
  int _scrollBottom = 0;
  bool _autoWrap = true;
  bool _pendingWrap = false;
  ({int row, int col})? _savedCursor;

  List<String> get visibleLines => List<String>.unmodifiable(_rows);

  String line(int row) => _rows[row - 1];

  void resize({required int width, required int height}) {
    final oldRows = List<String>.from(_rows);
    final flattened = oldRows.expand((row) => _wrapRow(row, width)).toList();
    _rows
      ..clear()
      ..addAll(List<String>.filled(height, '', growable: true));

    final visible = flattened.length <= height
        ? flattened
        : flattened.sublist(flattened.length - height);
    final spilled = flattened.length <= height
        ? const <String>[]
        : flattened.sublist(0, flattened.length - height);
    for (final row in spilled) {
      if (row.trim().isNotEmpty) scrollback.add(row.trimRight());
    }
    final start = height - visible.length;
    for (var i = 0; i < visible.length; i++) {
      _rows[start + i] = visible[i];
    }

    this.width = width;
    this.height = height;
    _row = _clamp(_row, 1, height);
    _col = _clamp(_col, 1, width);
    _scrollTop = 1;
    _scrollBottom = height;
    _pendingWrap = false;
  }

  List<String> _wrapRow(String row, int wrapWidth) {
    if (row.isEmpty) return const <String>[''];
    final chunks = <String>[];
    for (var i = 0; i < row.length; i += wrapWidth) {
      final end = i + wrapWidth > row.length ? row.length : i + wrapWidth;
      chunks.add(row.substring(i, end));
    }
    return chunks;
  }

  void feed(String data) {
    _scrollBottom = _scrollBottom == 0 ? height : _scrollBottom;
    for (var i = 0; i < data.length;) {
      final code = data.codeUnitAt(i);
      if (code == 0x1B) {
        i = _consumeEscape(data, i);
        continue;
      }
      if (code == 0x0D) {
        _col = 1;
        i++;
        continue;
      }
      if (code == 0x0A) {
        _lineFeed();
        i++;
        continue;
      }
      if (code >= 0x20 && code != 0x7F) {
        _put(String.fromCharCode(code));
      }
      i++;
    }
  }

  int _consumeEscape(String data, int start) {
    if (start + 1 >= data.length) return start + 1;
    final next = data.codeUnitAt(start + 1);
    if (next == 0x37) {
      _savedCursor = (row: _row, col: _col);
      return start + 2;
    }
    if (next == 0x38) {
      final saved = _savedCursor;
      if (saved != null) {
        _row = saved.row;
        _col = saved.col;
      }
      return start + 2;
    }
    if (next != 0x5B) return start + 2;

    var end = start + 2;
    while (end < data.length) {
      final b = data.codeUnitAt(end);
      if (b >= 0x40 && b <= 0x7E) break;
      end++;
    }
    if (end >= data.length) return data.length;

    final body = data.substring(start + 2, end);
    final finalByte = data[end];
    switch (finalByte) {
      case 'H':
      case 'f':
        _pendingWrap = false;
        final parts = body.isEmpty ? const <String>[] : body.split(';');
        _row = _clamp(
          parts.isNotEmpty && parts[0].isNotEmpty ? int.parse(parts[0]) : 1,
          1,
          height,
        );
        _col = _clamp(
          parts.length > 1 && parts[1].isNotEmpty ? int.parse(parts[1]) : 1,
          1,
          width,
        );
      case 'd':
        _pendingWrap = false;
        _row = _clamp(body.isEmpty ? 1 : int.parse(body), 1, height);
      case 'G':
        _pendingWrap = false;
        _col = _clamp(body.isEmpty ? 1 : int.parse(body), 1, width);
      case 'C':
        _pendingWrap = false;
        _col = _clamp(_col + (body.isEmpty ? 1 : int.parse(body)), 1, width);
      case 'D':
        _pendingWrap = false;
        _col = _clamp(_col - (body.isEmpty ? 1 : int.parse(body)), 1, width);
      case 'K':
        if (body == '2' || body.isEmpty) {
          _rows[_row - 1] = '';
          _col = 1;
          _pendingWrap = false;
        }
      case 'r':
        if (body.isEmpty) {
          _scrollTop = 1;
          _scrollBottom = height;
        } else {
          final parts = body.split(';');
          _scrollTop = _clamp(int.parse(parts[0]), 1, height);
          _scrollBottom = _clamp(int.parse(parts[1]), _scrollTop, height);
        }
      case 'h':
        if (body == '?7') {
          _autoWrap = true;
          return end + 1;
        }
      case 'l':
        if (body == '?7') {
          _autoWrap = false;
          _pendingWrap = false;
          return end + 1;
        }
        // DEC synchronized-output mode and private-mode toggles are state-free
        // for these tests.
        if (data.substring(start, end + 1) == Ansi.beginSynchronizedUpdate ||
            data.substring(start, end + 1) == Ansi.endSynchronizedUpdate) {
          return end + 1;
        }
      case 'J':
        // Erase Display: 0/absent = cursor to end, 1 = to beginning, 2/3 = all.
        // In the test virtual terminal, blanking any row to empty is sufficient
        // to detect regressions where ESC[2J destroys the log band.
        switch (body) {
          case '' || '0':
            for (var r = _row; r <= height; r++) {
              _rows[r - 1] = '';
            }
          case '1':
            for (var r = 1; r <= _row; r++) {
              _rows[r - 1] = '';
            }
          case '2' || '3':
            for (var r = 0; r < _rows.length; r++) {
              _rows[r] = '';
            }
        }
      case 's':
        _savedCursor = (row: _row, col: _col);
      case 'u':
        final saved = _savedCursor;
        if (saved != null) {
          _row = saved.row;
          _col = saved.col;
        }
    }
    return end + 1;
  }

  void _lineFeed() {
    _pendingWrap = false;
    if (_row == _scrollBottom) {
      final removed = _rows.removeAt(_scrollTop - 1);
      _rows.insert(_scrollBottom - 1, '');
      if (_scrollTop == 1 && removed.trim().isNotEmpty) {
        scrollback.add(removed.trimRight());
      }
      return;
    }
    _row = _clamp(_row + 1, 1, height);
  }

  void _put(String ch) {
    if (_pendingWrap) {
      _lineFeed();
      _col = 1;
      _pendingWrap = false;
    }
    if (_col > width) return;
    final index = _row - 1;
    final current = _rows[index].padRight(_col - 1);
    _rows[index] = (current.substring(0, _col - 1) + ch).padRight(_col);
    if (_rows[index].length > width) {
      _rows[index] = _rows[index].substring(0, width);
    }
    if (_col == width && _autoWrap) {
      _pendingWrap = true;
    } else {
      _col++;
    }
  }

  int _clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
