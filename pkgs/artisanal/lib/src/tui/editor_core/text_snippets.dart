library;

/// Snippet parsing (`${1:default}`, `$1`, `$0`) with tabstop sessions.
///
/// Covers the reusable core: parsing, placeholder expansion, ordered
/// tabstop navigation. Live mirror-sync while typing stays with the host
/// (mirrors resolve to the placeholder value at expand time — documented
/// below); the parser and session are what every snippet consumer shares.

/// One tabstop in expanded snippet text.
final class SnippetTabstop {
  const SnippetTabstop({
    required this.index,
    required this.startOffset,
    required this.endOffset,
    this.placeholder,
    this.isMirror = false,
  });

  /// Tabstop number (`0` is the final stop).
  final int index;
  final int startOffset;
  final int endOffset;
  final String? placeholder;

  /// Repeat occurrence echoing the first occurrence's placeholder value.
  final bool isMirror;

  bool get isFinal => index == 0;
}

/// A parsed snippet: expanded text plus tabstops in document coordinates.
final class ParsedSnippet {
  const ParsedSnippet({required this.text, required this.tabstops});

  final String text;
  final List<SnippetTabstop> tabstops;
}

/// Parses [source] into expanded text and tabstops. Never throws:
/// malformed sequences (`${x}`, unterminated `${1:`) emit literally.
///
/// Supported syntax: `$1`, `${1}`, `${1:default}`, `$0`/`${0:default}`
/// (final stop), `$$` (literal `$`), plus `\$`, `\}`, `\\` escapes.
/// Repeated indexes are mirrors of the first occurrence. Nesting inside
/// `${n:...}` is not supported and emits literally.
ParsedSnippet parseSnippet(String source) {
  final text = StringBuffer();
  final tabstops = <SnippetTabstop>[];
  final defaults = <int, String?>{};
  var i = 0;
  int takeDigits(int from) {
    var j = from;
    while (j < source.length &&
        source.codeUnitAt(j) >= 0x30 &&
        source.codeUnitAt(j) <= 0x39) {
      j++;
    }
    return j;
  }

  void addStop(int index, int start, int end, [String? placeholder]) {
    tabstops.add(
      SnippetTabstop(
        index: index,
        startOffset: start,
        endOffset: end,
        placeholder: placeholder,
      ),
    );
    defaults.putIfAbsent(index, () => placeholder);
  }

  /// Records a mirror: echoes the first occurrence's placeholder value.
  void addMirror(int index) {
    final echo = defaults[index];
    if (echo != null && echo.isNotEmpty) {
      final start = text.length;
      text.write(echo);
      tabstops.add(
        SnippetTabstop(
          index: index,
          startOffset: start,
          endOffset: text.length,
          isMirror: true,
        ),
      );
    } else {
      tabstops.add(
        SnippetTabstop(
          index: index,
          startOffset: text.length,
          endOffset: text.length,
          isMirror: true,
        ),
      );
    }
  }

  while (i < source.length) {
    final char = source[i];
    if (char == '\\' && i + 1 < source.length) {
      final next = source[i + 1];
      if (next == r'$' || next == '}' || next == '\\') {
        text.write(next);
        i += 2;
        continue;
      }
      text.write(char);
      i++;
      continue;
    }
    if (char != r'$') {
      text.write(char);
      i++;
      continue;
    }
    // '$$' → literal '$'.
    if (i + 1 < source.length && source[i + 1] == r'$') {
      text.write(r'$');
      i += 2;
      continue;
    }
    // '${n}' / '${n:default}'.
    if (i + 1 < source.length && source[i + 1] == '{') {
      final digitsEnd = takeDigits(i + 2);
      if (digitsEnd > i + 2) {
        final index = int.parse(source.substring(i + 2, digitsEnd));
        if (digitsEnd < source.length && source[digitsEnd] == '}') {
          if (defaults.containsKey(index)) {
            addMirror(index);
          } else {
            addStop(index, text.length, text.length);
          }
          i = digitsEnd + 1;
          continue;
        }
        if (digitsEnd < source.length && source[digitsEnd] == ':') {
          final close = source.indexOf('}', digitsEnd + 1);
          if (close >= 0) {
            final placeholder = source.substring(digitsEnd + 1, close);
            if (defaults.containsKey(index)) {
              // Repeated definition: emit literally as a mirror of the
              // first occurrence's value.
              addMirror(index);
            } else {
              final start = text.length;
              text.write(placeholder);
              addStop(index, start, text.length, placeholder);
            }
            i = close + 1;
            continue;
          }
        }
      }
      text.write(char);
      i++;
      continue;
    }
    // '$n'.
    final digitsEnd = takeDigits(i + 1);
    if (digitsEnd > i + 1) {
      final index = int.parse(source.substring(i + 1, digitsEnd));
      if (defaults.containsKey(index)) {
        addMirror(index);
      } else {
        addStop(index, text.length, text.length);
      }
      i = digitsEnd;
      continue;
    }
    text.write(char);
    i++;
  }
  return ParsedSnippet(
    text: text.toString(),
    tabstops: List<SnippetTabstop>.unmodifiable(tabstops),
  );
}

/// Ordered tabstop navigation over a [ParsedSnippet].
///
/// Stops order by index (`$0` final always last), then by offset. Mirrors
/// are skipped: each index is visited once, at its first occurrence.
final class SnippetSession {
  SnippetSession(ParsedSnippet snippet)
    : _stops = _orderedStops(snippet.tabstops);

  final List<SnippetTabstop> _stops;
  int _index = -1;

  List<SnippetTabstop> get stops => List<SnippetTabstop>.unmodifiable(_stops);
  int get index => _index;
  SnippetTabstop? get current =>
      _index >= 0 && _index < _stops.length ? _stops[_index] : null;
  bool get isDone => _index >= _stops.length;

  /// Advances to the next stop; `null` when the final stop was passed.
  SnippetTabstop? next() {
    if (_index + 1 >= _stops.length) {
      _index = _stops.length;
      return null;
    }
    _index++;
    return _stops[_index];
  }

  /// Steps back; `null` when already before the first stop.
  SnippetTabstop? previous() {
    if (_index < 0) return null;
    _index--;
    return _index >= 0 ? _stops[_index] : null;
  }

  static List<SnippetTabstop> _orderedStops(List<SnippetTabstop> tabstops) {
    final first = <int, SnippetTabstop>{};
    for (final stop in tabstops) {
      first.putIfAbsent(stop.index, () => stop);
    }
    final ordered = first.values.toList(growable: false)
      ..sort((a, b) {
        if (a.isFinal != b.isFinal) return a.isFinal ? 1 : -1;
        final byIndex = a.index.compareTo(b.index);
        if (byIndex != 0) return byIndex;
        return a.startOffset.compareTo(b.startOffset);
      });
    return List<SnippetTabstop>.unmodifiable(ordered);
  }
}
