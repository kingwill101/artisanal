library;

/// Code folding: indent-based ranges plus collapse state.
///
/// [computeIndentFolds] derives ranges without any language knowledge;
/// syntax-aware backends (Tree-sitter `fold` queries via `syntax_tree.dart`)
/// produce [FoldRange]s the same way. [FoldState] tracks collapsed headers
/// and maps visible lines; hosts recompute ranges on change and carry
/// collapse state forward with [FoldState.retain].

enum FoldKind { indent, syntax, manual }

/// Foldable line range (both ends inclusive, 0-based).
final class FoldRange {
  const FoldRange({
    required this.startLine,
    required this.endLine,
    this.kind = FoldKind.indent,
  });

  final int startLine;
  final int endLine;
  final FoldKind kind;

  int get lineCount => endLine - startLine + 1;
  bool contains(int line) => line > startLine && line <= endLine;
}

/// Computes indent folds over [lineTexts].
///
/// A fold starts at a non-blank line followed by a deeper-indented
/// non-blank line, and ends at the last consecutively deeper line (trailing
/// blank lines belong to the enclosing scope, not the fold). Tabs count
/// [tabWidth] columns.
List<FoldRange> computeIndentFolds(List<String> lineTexts, {int tabWidth = 4}) {
  final width = tabWidth < 1 ? 1 : tabWidth;
  final indents = [for (final line in lineTexts) _indentWidth(line, width)];
  final folds = <FoldRange>[];
  for (var i = 0; i < lineTexts.length; i++) {
    final indent = indents[i];
    if (indent < 0) continue;
    final next = _nextNonBlank(indents, i + 1);
    if (next < 0 || indents[next] <= indent) continue;
    var end = next;
    for (var j = next + 1; j < lineTexts.length; j++) {
      final current = indents[j];
      if (current < 0) continue;
      if (current <= indent) break;
      end = j;
    }
    folds.add(FoldRange(startLine: i, endLine: end));
  }
  return List<FoldRange>.unmodifiable(folds);
}

/// Collapse state over a fold list.
final class FoldState {
  FoldState({List<FoldRange> ranges = const []}) : _ranges = ranges;

  final List<FoldRange> _ranges;
  final Set<int> _collapsed = <int>{};

  List<FoldRange> get ranges => List<FoldRange>.unmodifiable(_ranges);
  Set<int> get collapsedStarts => Set<int>.unmodifiable(_collapsed);

  FoldRange? foldStartingAt(int line) {
    for (final range in _ranges) {
      if (range.startLine == line) return range;
    }
    return null;
  }

  bool isCollapsedAt(int startLine) => _collapsed.contains(startLine);

  /// Whether [line] is hidden inside a collapsed fold (headers show).
  bool isLineHidden(int line) {
    for (final range in _ranges) {
      if (_collapsed.contains(range.startLine) && range.contains(line)) {
        return true;
      }
    }
    return false;
  }

  /// Maps [line] to the visible header that represents it.
  ///
  /// Visible lines map to themselves. A line hidden by nested collapsed folds
  /// maps to the outermost visible collapsed header.
  int visibleLineFor(int line) {
    var visible = line;
    while (true) {
      FoldRange? containing;
      for (final range in _ranges) {
        if (_collapsed.contains(range.startLine) && range.contains(visible)) {
          containing = range;
          break;
        }
      }
      if (containing == null) return visible;
      visible = containing.startLine;
    }
  }

  /// Toggles the fold starting at [line]; no-op when none starts there.
  bool toggle(int line) {
    if (foldStartingAt(line) == null) return false;
    if (_collapsed.contains(line)) {
      _collapsed.remove(line);
    } else {
      _collapsed.add(line);
    }
    return true;
  }

  void collapseAll() {
    _collapsed.addAll(_ranges.map((range) => range.startLine));
  }

  void expandAll() => _collapsed.clear();

  /// Visible (non-hidden) line indexes in `[0, lineCount)`.
  List<int> visibleLines(int lineCount) {
    final visible = <int>[];
    for (var line = 0; line < lineCount; line++) {
      if (!isLineHidden(line)) visible.add(line);
    }
    return visible;
  }

  /// Carries collapse state onto freshly computed [ranges] (e.g. after an
  /// edit), keeping headers that still start a fold.
  FoldState retain(List<FoldRange> ranges) {
    final next = FoldState(ranges: ranges);
    final starts = {for (final range in ranges) range.startLine};
    next._collapsed.addAll(_collapsed.where(starts.contains));
    return next;
  }
}

int _indentWidth(String line, int tabWidth) {
  var width = 0;
  for (var i = 0; i < line.length; i++) {
    final unit = line.codeUnitAt(i);
    if (unit == 0x20) {
      width++;
    } else if (unit == 0x09) {
      width += tabWidth;
    } else {
      return width == 0 && line.trim().isEmpty ? -1 : width;
    }
  }
  return -1; // Blank line.
}

int _nextNonBlank(List<int> indents, int from) {
  for (var i = from; i < indents.length; i++) {
    if (indents[i] >= 0) return i;
  }
  return -1;
}
