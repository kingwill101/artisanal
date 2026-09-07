library;

import 'text_document.dart';

/// IDE selection ingestion for prompt composers.
///
/// Normalizes external IDE selections into one shape: a file plus one or
/// more ranges with 1-based `{line, character}` endpoints. Hosts resolve
/// ranges against their [TextDocument] to highlight selections and build the
/// context sent with the prompt. Positions are 1-based on the wire to match
/// the LSP/editor convention; document offsets are 0-based.

/// A 1-based line/character position on the wire.
final class EditorSelectionPosition {
  const EditorSelectionPosition({required this.line, required this.character});

  /// 1-based line number.
  final int line;

  /// 1-based character offset within the line.
  final int character;
}

/// One selected range inside [EditorSelection.filePath].
final class EditorSelectionRange {
  const EditorSelectionRange({
    required this.text,
    required this.start,
    required this.end,
  });

  final String text;
  final EditorSelectionPosition start;
  final EditorSelectionPosition end;

  bool get isCollapsed =>
      start.line == end.line && start.character == end.character;
}

/// External editor selection attached to a prompt.
final class EditorSelection {
  const EditorSelection({
    required this.filePath,
    required this.ranges,
    this.source,
  });

  final String filePath;
  final List<EditorSelectionRange> ranges;
  final String? source;

  bool get isEmpty => ranges.isEmpty;
}

/// Stable key for dismiss tracking (dismissed context stays cleared until
/// the selection changes again).
String editorSelectionKey(EditorSelection? selection) {
  if (selection == null) return '';
  final parts = <String>[selection.filePath];
  for (final range in selection.ranges) {
    parts.addAll([
      '${range.start.line}',
      '${range.start.character}',
      '${range.end.line}',
      '${range.end.character}',
      range.text,
    ]);
  }
  return parts.join('\x00');
}

/// Resolves a wire range to clamped document offsets.
///
/// Wire lines/characters are 1-based; values outside the document clamp to
/// the nearest valid offset and the endpoints normalize so `start <= end`.
({int startOffset, int endOffset}) resolveEditorSelectionRange(
  TextDocument document,
  EditorSelectionRange range,
) {
  int offsetFor(int line, int character) {
    final lineIndex = (line - 1).clamp(0, document.lineCount - 1);
    final column = (character - 1).clamp(0, document.lineLength(lineIndex));
    return document.lineStartOffset(lineIndex) + column;
  }

  final start = offsetFor(range.start.line, range.start.character);
  final end = offsetFor(range.end.line, range.end.character);
  if (start <= end) return (startOffset: start, endOffset: end);
  return (startOffset: end, endOffset: start);
}

/// Short `#line` / `#start-end` label for a range (single-line ranges show
/// just the line).
String? editorSelectionRangeLabel(EditorSelectionRange range) {
  if (range.isCollapsed) return null;
  if (range.start.line == range.end.line) return '#${range.start.line}';
  return '#${range.start.line}-${range.end.line}';
}

/// Builds the context block sent with the prompt for [selection].
///
/// Ranges without a selection degrade to an "opened file" note; selected
/// ranges embed their text, so the model sees what the user highlighted.
String formatEditorSelectionContext(EditorSelection selection) {
  final selected = [
    for (final range in selection.ranges)
      if (!range.isCollapsed) range,
  ];
  if (selected.isEmpty) {
    return '<system-reminder>Note: The user opened the file '
        '"${selection.filePath}". This may or may not be relevant to the '
        'current task.</system-reminder>\n';
  }
  final buffer = StringBuffer('<system-reminder>');
  for (var i = 0; i < selected.length; i++) {
    final range = selected[i];
    final prefix = selected.length > 1 ? 'Selection ${i + 1}: ' : '';
    buffer.write(
      'Note: The user selected $prefix${editorSelectionRangeLabel(range)} '
      'from "${selection.filePath}". ```${range.text}```\n\n',
    );
  }
  buffer.write(
    'This may or may not be relevant to the current task.</system-reminder>\n',
  );
  return buffer.toString();
}
