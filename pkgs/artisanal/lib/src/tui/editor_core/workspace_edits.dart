library;

/// Atomic multi-file edit sets for tooling (formatters, refactors, agents).
///
/// Pure string in / string out — no file I/O, no documents — so scripts,
/// tests, and servers share one rule: validate overlap per file, apply
/// descending, preview before committing. Hosts own reading files,
/// constructing [TextDocument]s, and writing back.

/// One replacement of `[startOffset, endOffset)` with [replacement].
final class FileTextEdit {
  const FileTextEdit({
    required this.startOffset,
    required this.endOffset,
    this.replacement = '',
  });

  final int startOffset;
  final int endOffset;
  final String replacement;
}

/// Two edits in one file whose ranges overlap.
final class EditConflict {
  const EditConflict({
    required this.filePath,
    required this.first,
    required this.second,
  });

  final String filePath;
  final FileTextEdit first;
  final FileTextEdit second;

  @override
  String toString() =>
      'EditConflict($filePath: [${first.startOffset}, ${first.endOffset}) '
      'overlaps [${second.startOffset}, ${second.endOffset}))';
}

/// Named file edits applied together.
final class WorkspaceEdit {
  const WorkspaceEdit({this.files = const <String, List<FileTextEdit>>{}});

  final Map<String, List<FileTextEdit>> files;

  bool get isEmpty => files.values.every((edits) => edits.isEmpty);
}

/// Result of applying one file's edits.
final class AppliedFileEdit {
  const AppliedFileEdit({
    required this.filePath,
    required this.newText,
    required this.appliedRanges,
    required this.conflicts,
  });

  final String filePath;

  /// Original text when [conflicts] is non-empty (rejected), else edited.
  final String newText;

  /// Post-edit offsets of each applied replacement.
  final List<({int startOffset, int endOffset})> appliedRanges;

  final List<EditConflict> conflicts;

  bool get applied => conflicts.isEmpty;
}

/// Returns the overlap conflicts in [edits] for [filePath] (empty = clean).
List<EditConflict> validateFileEdits(
  String filePath,
  List<FileTextEdit> edits,
) {
  final ordered = edits.toList(growable: false)..sort(
    (a, b) => a.startOffset.compareTo(b.startOffset),
  );
  final conflicts = <EditConflict>[];
  for (var i = 1; i < ordered.length; i++) {
    final previous = ordered[i - 1];
    final current = ordered[i];
    final prevEnd = previous.endOffset < previous.startOffset
        ? previous.startOffset
        : previous.endOffset;
    if (current.startOffset < prevEnd ||
        (current.startOffset == prevEnd &&
            current.startOffset == current.endOffset &&
            previous.startOffset == previous.endOffset)) {
      // Touching insertions at the same offset are ambiguous in order.
      conflicts.add(
        EditConflict(filePath: filePath, first: previous, second: current),
      );
    }
  }
  return conflicts;
}

/// Applies [edits] to [text], descending by offset.
///
/// When conflicts exist the edit is rejected whole-file: [AppliedFileEdit]
/// carries the original text plus [EditConflict]s.
AppliedFileEdit applyFileEdits(
  String filePath,
  String text,
  List<FileTextEdit> edits,
) {
  final conflicts = validateFileEdits(filePath, edits);
  if (conflicts.isNotEmpty) {
    return AppliedFileEdit(
      filePath: filePath,
      newText: text,
      appliedRanges: const [],
      conflicts: conflicts,
    );
  }
  final ordered = edits.toList(growable: false)
    ..sort((a, b) => b.startOffset.compareTo(a.startOffset));
  var result = text;
  final applied = <({int startOffset, int endOffset})>[];
  for (final edit in ordered) {
    final start = edit.startOffset.clamp(0, result.length);
    final end = edit.endOffset.clamp(start, result.length);
    result =
        result.substring(0, start) + edit.replacement + result.substring(end);
    applied.add(
      (
        startOffset: start,
        endOffset: start + edit.replacement.length,
      ),
    );
  }
  applied.sort((a, b) => a.startOffset.compareTo(b.startOffset));
  return AppliedFileEdit(
    filePath: filePath,
    newText: result,
    appliedRanges: applied,
    conflicts: const [],
  );
}

/// Applies [edit] to every file in [files] (missing files count as empty).
Map<String, AppliedFileEdit> applyWorkspaceEdit(
  Map<String, String> files,
  WorkspaceEdit edit,
) {
  return {
    for (final entry in edit.files.entries)
      entry.key: applyFileEdits(
        entry.key,
        files[entry.key] ?? '',
        entry.value,
      ),
  };
}

/// Renders a unified-style dry-run preview of [edit] against [files].
///
/// Unchanged files and files with conflicts are noted, not diffed. Hunks
/// derive from the exact edit spans (not a re-diff), so `-`/`+` lines line
/// up with what apply would do.
String previewWorkspaceEdit(
  Map<String, String> files,
  WorkspaceEdit edit, {
  int contextLines = 3,
}) {
  final buffer = StringBuffer();
  final paths = edit.files.keys.toList(growable: false)..sort();
  for (final path in paths) {
    final before = files[path] ?? '';
    final applied = applyFileEdits(path, before, edit.files[path]!);
    buffer.writeln('--- a/$path');
    buffer.writeln('+++ b/$path');
    if (applied.conflicts.isNotEmpty) {
      for (final conflict in applied.conflicts) {
        buffer.writeln('! $conflict');
      }
      continue;
    }
    if (applied.newText == before) {
      buffer.writeln('(no changes)');
      continue;
    }
    buffer.write(
      _previewHunks(
        before,
        edit.files[path]!,
        applied.newText,
        applied.appliedRanges,
        contextLines: contextLines < 0 ? 0 : contextLines,
      ),
    );
  }
  return buffer.toString();
}

String _previewHunks(
  String before,
  List<FileTextEdit> edits,
  String after,
  List<({int startOffset, int endOffset})> appliedRanges, {
  required int contextLines,
}) {
  final beforeTable = _LineTable(before);
  final afterTable = _LineTable(after);
  // Group edit indices into windows; windows merge when either side
  // overlaps (with context).
  final ordered = edits.toList(growable: false)
    ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
  final groups = <List<int>>[];
  final bounds = <({int from, int to, int afterFrom, int afterTo})>[];
  for (var i = 0; i < ordered.length; i++) {
    final edit = ordered[i];
    final startLine = beforeTable.lineForOffset(
      edit.startOffset.clamp(0, before.length),
    );
    final endLine = beforeTable.lineForOffset(
      edit.endOffset.clamp(0, before.length),
    );
    final applied = appliedRanges[i];
    final afterStart = afterTable.lineForOffset(
      applied.startOffset.clamp(0, after.length),
    );
    final afterEnd = afterTable.lineForOffset(
      applied.endOffset.clamp(0, after.length),
    );
    final from = (startLine - contextLines).clamp(0, beforeTable.lineCount);
    final to = (endLine + contextLines + 1).clamp(0, beforeTable.lineCount);
    final afterFrom = (afterStart - contextLines).clamp(
      0,
      afterTable.lineCount,
    );
    final afterTo = (afterEnd + contextLines + 1).clamp(
      0,
      afterTable.lineCount,
    );
    if (groups.isNotEmpty) {
      final last = bounds.last;
      if (from <= last.to && afterFrom <= last.afterTo) {
        groups.last.add(i);
        bounds[bounds.length - 1] = (
          from: last.from,
          to: to > last.to ? to : last.to,
          afterFrom: last.afterFrom,
          afterTo: afterTo > last.afterTo ? afterTo : last.afterTo,
        );
        continue;
      }
    }
    groups.add([i]);
    bounds.add((from: from, to: to, afterFrom: afterFrom, afterTo: afterTo));
  }
  // appliedRanges[i] aligns with ordered[i] (both descending sorts of the
  // same edits are stable, but re-derive explicitly to be safe).
  final buffer = StringBuffer();
  for (var g = 0; g < groups.length; g++) {
    final bound = bounds[g];
    buffer.writeln(
      '@@ -${bound.from},${bound.to - bound.from} '
      '+${bound.afterFrom},${bound.afterTo - bound.afterFrom} @@',
    );
    // Removed spans (before lines) and added spans (after lines) for
    // this group's edits, as window-relative half-open line ranges.
    final removed = <(int, int)>[];
    final added = <(int, int)>[];
    for (final i in groups[g]) {
      final edit = ordered[i];
      final applied = appliedRanges[i];
      final editStart = edit.startOffset.clamp(0, before.length);
      final editEnd = edit.endOffset.clamp(editStart, before.length);
      final appliedStart = applied.startOffset.clamp(0, after.length);
      final appliedEnd = applied.endOffset.clamp(appliedStart, after.length);
      // Pure insertions remove nothing; replacements remove whole lines.
      removed.add(
        editEnd > editStart
            ? (
                beforeTable.lineForOffset(editStart),
                beforeTable.lineForOffset(editEnd) + 1,
              )
            : (
                beforeTable.lineForOffset(editStart),
                beforeTable.lineForOffset(editStart),
              ),
      );
      added.add((
        afterTable.lineForOffset(appliedStart),
        afterTable.lineForOffset(appliedEnd) +
            (appliedEnd > appliedStart ? 1 : 0),
      ));
    }
    removed.sort((a, b) => a.$1.compareTo(b.$1));
    added.sort((a, b) => a.$1.compareTo(b.$1));
    var cursor = bound.from; // next before-line not yet emitted
    for (var s = 0; s < removed.length; s++) {
      final (removedStart, removedEnd) = removed[s];
      final (addedStart, addedEnd) = added[s];
      while (cursor < removedStart) {
        buffer.writeln(' ${beforeTable.lineAt(cursor)}');
        cursor++;
      }
      for (var line = removedStart; line < removedEnd; line++) {
        buffer.writeln('-${beforeTable.lineAt(line)}');
        cursor = line + 1;
      }
      for (var line = addedStart; line < addedEnd; line++) {
        buffer.writeln('+${afterTable.lineAt(line)}');
      }
    }
    while (cursor < bound.to) {
      buffer.writeln(' ${beforeTable.lineAt(cursor)}');
      cursor++;
    }
  }
  return buffer.toString();
}

/// Offset → line index table over a string.
final class _LineTable {
  _LineTable(String text) : _text = text {
    _starts.add(0);
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) _starts.add(i + 1);
    }
  }

  final String _text;
  final List<int> _starts = <int>[];

  int get length => _text.length;
  int get lineCount => _starts.length;

  int lineForOffset(int offset) {
    final clamped = offset.clamp(0, _text.length);
    var line = 0;
    for (var i = 0; i < _starts.length; i++) {
      if (_starts[i] <= clamped) {
        line = i;
      } else {
        break;
      }
    }
    return line;
  }

  List<String> get _allLines => _text.isEmpty ? const <String>[] : _text.split('\n');

  String lineAt(int index) {
    final lines = _allLines;
    return lines[index.clamp(0, lines.length - 1)];
  }
}
