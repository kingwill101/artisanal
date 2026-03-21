library;

import 'editor_state.dart' show TextPosition;
import 'text_highlighting.dart';
import 'text_document.dart';

const String textDefaultDecorationLayerKey = 'default';
const String textSyntaxDecorationLayerKey = 'syntax';
const String textSearchDecorationLayerKey = 'search';
const String textDiagnosticsDecorationLayerKey = 'diagnostics';
const String textDefaultLineDecorationLayerKey = 'line.default';
const String textDiagnosticsLineDecorationLayerKey = 'line.diagnostics';
const String textActiveLineDecorationLayerKey = 'line.active';

const int textDefaultDecorationLayerPriority = 0;
const int textSyntaxDecorationLayerPriority = 50;
const int textDiagnosticsDecorationLayerPriority = 75;
const int textSearchDecorationLayerPriority = 100;
const int textDefaultLineDecorationLayerPriority = 0;
const int textDiagnosticsLineDecorationLayerPriority = 75;
const int textActiveLineDecorationLayerPriority = 50;

const String textSearchMatchDecorationKey = 'search.match';
const String textSearchActiveMatchDecorationKey = 'search.match.active';
const String textDiagnosticErrorDecorationKey = 'diagnostic.error';
const String textDiagnosticWarningDecorationKey = 'diagnostic.warning';
const String textDiagnosticInfoDecorationKey = 'diagnostic.info';
const String textDiagnosticHintDecorationKey = 'diagnostic.hint';
const String textDiagnosticErrorLineDecorationKey = 'line.diagnostic.error';
const String textDiagnosticWarningLineDecorationKey = 'line.diagnostic.warning';
const String textDiagnosticInfoLineDecorationKey = 'line.diagnostic.info';
const String textDiagnosticHintLineDecorationKey = 'line.diagnostic.hint';
const String textDiagnosticErrorLineNumberDecorationKey =
    'line.diagnostic.error.number';
const String textDiagnosticWarningLineNumberDecorationKey =
    'line.diagnostic.warning.number';
const String textDiagnosticInfoLineNumberDecorationKey =
    'line.diagnostic.info.number';
const String textDiagnosticHintLineNumberDecorationKey =
    'line.diagnostic.hint.number';
const String textActiveLineDecorationKey = 'line.active';
const String textActiveLineNumberDecorationKey = 'line.active.number';

final class TextDecorationRange {
  const TextDecorationRange({
    required this.startOffset,
    required this.endOffset,
    required this.styleKey,
  });

  final int startOffset;
  final int endOffset;
  final String styleKey;

  int get length => endOffset - startOffset;
  bool get isEmpty => startOffset >= endOffset;

  TextDecorationRange normalized() {
    if (startOffset <= endOffset) {
      return this;
    }
    return TextDecorationRange(
      startOffset: endOffset,
      endOffset: startOffset,
      styleKey: styleKey,
    );
  }

  TextDecorationRange clamp(int maxLength) {
    final normalizedRange = normalized();
    return TextDecorationRange(
      startOffset: normalizedRange.startOffset.clamp(0, maxLength),
      endOffset: normalizedRange.endOffset.clamp(0, maxLength),
      styleKey: styleKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TextDecorationRange &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.styleKey == styleKey;
  }

  @override
  int get hashCode => Object.hash(startOffset, endOffset, styleKey);

  @override
  String toString() {
    return 'TextDecorationRange($startOffset, $endOffset, $styleKey)';
  }
}

final class TextLineDecoration {
  const TextLineDecoration({
    required this.lineIndex,
    required this.styleKey,
    this.lineNumberMarker,
    this.lineNumberStyleKey,
  });

  final int lineIndex;
  final String styleKey;
  final String? lineNumberMarker;
  final String? lineNumberStyleKey;

  TextLineDecoration clamp(int lineCount) {
    if (lineCount <= 0) {
      return TextLineDecoration(
        lineIndex: 0,
        styleKey: styleKey,
        lineNumberMarker: lineNumberMarker,
        lineNumberStyleKey: lineNumberStyleKey,
      );
    }
    return TextLineDecoration(
      lineIndex: lineIndex.clamp(0, lineCount - 1),
      styleKey: styleKey,
      lineNumberMarker: lineNumberMarker,
      lineNumberStyleKey: lineNumberStyleKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TextLineDecoration &&
        other.lineIndex == lineIndex &&
        other.styleKey == styleKey &&
        other.lineNumberMarker == lineNumberMarker &&
        other.lineNumberStyleKey == lineNumberStyleKey;
  }

  @override
  int get hashCode =>
      Object.hash(lineIndex, styleKey, lineNumberMarker, lineNumberStyleKey);

  @override
  String toString() {
    return 'TextLineDecoration('
        '$lineIndex, $styleKey, $lineNumberMarker, $lineNumberStyleKey'
        ')';
  }
}

enum TextDiagnosticSeverity { error, warning, info, hint }

final class TextDiagnosticRange {
  const TextDiagnosticRange({
    required this.startOffset,
    required this.endOffset,
    required this.severity,
    this.code,
    this.message,
    this.source,
  });

  final int startOffset;
  final int endOffset;
  final TextDiagnosticSeverity severity;
  final String? code;
  final String? message;
  final String? source;

  TextDiagnosticRange normalized() {
    if (startOffset <= endOffset) {
      return this;
    }
    return TextDiagnosticRange(
      startOffset: endOffset,
      endOffset: startOffset,
      severity: severity,
      code: code,
      message: message,
      source: source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TextDiagnosticRange &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.severity == severity &&
        other.code == code &&
        other.message == message &&
        other.source == source;
  }

  @override
  int get hashCode =>
      Object.hash(startOffset, endOffset, severity, code, message, source);
}

final class TextPositionDiagnosticRange {
  const TextPositionDiagnosticRange({
    required this.startLine,
    required this.startColumn,
    required this.endLine,
    required this.endColumn,
    required this.severity,
    this.code,
    this.message,
    this.source,
  });

  final int startLine;
  final int startColumn;
  final int endLine;
  final int endColumn;
  final TextDiagnosticSeverity severity;
  final String? code;
  final String? message;
  final String? source;

  TextPositionDiagnosticRange normalized() {
    if (_compareTextPositions(startLine, startColumn, endLine, endColumn) <=
        0) {
      return this;
    }
    return TextPositionDiagnosticRange(
      startLine: endLine,
      startColumn: endColumn,
      endLine: startLine,
      endColumn: startColumn,
      severity: severity,
      code: code,
      message: message,
      source: source,
    );
  }

  TextPositionDiagnosticRange clamp(TextDocument document) {
    final start = document.clampPosition(
      TextPosition(line: startLine, column: startColumn),
    );
    final end = document.clampPosition(
      TextPosition(line: endLine, column: endColumn),
    );
    return TextPositionDiagnosticRange(
      startLine: start.line,
      startColumn: start.column,
      endLine: end.line,
      endColumn: end.column,
      severity: severity,
      code: code,
      message: message,
      source: source,
    );
  }

  TextDiagnosticRange toOffsetRange(TextDocument document) {
    final normalizedRange = clamp(document).normalized();
    return TextDiagnosticRange(
      startOffset: document.offsetForPosition(
        TextPosition(
          line: normalizedRange.startLine,
          column: normalizedRange.startColumn,
        ),
      ),
      endOffset: document.offsetForPosition(
        TextPosition(
          line: normalizedRange.endLine,
          column: normalizedRange.endColumn,
        ),
      ),
      severity: severity,
      code: code,
      message: message,
      source: source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TextPositionDiagnosticRange &&
        other.startLine == startLine &&
        other.startColumn == startColumn &&
        other.endLine == endLine &&
        other.endColumn == endColumn &&
        other.severity == severity &&
        other.code == code &&
        other.message == message &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(
    startLine,
    startColumn,
    endLine,
    endColumn,
    severity,
    code,
    message,
    source,
  );
}

List<TextDiagnosticRange> normalizeTextDiagnostics(
  Iterable<TextDiagnosticRange> diagnostics, {
  int? maxLength,
}) {
  final normalized =
      diagnostics
          .map((diagnostic) {
            final range = diagnostic.normalized();
            if (maxLength == null) {
              return range;
            }
            return TextDiagnosticRange(
              startOffset: range.startOffset.clamp(0, maxLength),
              endOffset: range.endOffset.clamp(0, maxLength),
              severity: range.severity,
              code: range.code,
              message: range.message,
              source: range.source,
            );
          })
          .toList(growable: false)
        ..sort((a, b) {
          final startComparison = a.startOffset.compareTo(b.startOffset);
          if (startComparison != 0) {
            return startComparison;
          }
          final endComparison = a.endOffset.compareTo(b.endOffset);
          if (endComparison != 0) {
            return endComparison;
          }
          return _diagnosticSeverityRank(
            b.severity,
          ).compareTo(_diagnosticSeverityRank(a.severity));
        });
  return List<TextDiagnosticRange>.unmodifiable(normalized);
}

List<TextDiagnosticRange> textDiagnosticsFromPositions({
  required TextDocument document,
  required Iterable<TextPositionDiagnosticRange> diagnostics,
}) {
  return normalizeTextDiagnostics(
    diagnostics.map((diagnostic) => diagnostic.toOffsetRange(document)),
    maxLength: document.length,
  );
}

TextPosition textDiagnosticStartPosition({
  required String text,
  required TextDiagnosticRange diagnostic,
}) {
  return textDiagnosticStartPositionForDocument(
    document: TextDocument(text: text),
    diagnostic: diagnostic,
  );
}

TextPosition textDiagnosticStartPositionForDocument({
  required TextDocument document,
  required TextDiagnosticRange diagnostic,
}) {
  final normalized = diagnostic.normalized();
  final startOffset = normalized.startOffset.clamp(0, document.length);
  return document.positionForOffset(startOffset);
}

String textDiagnosticSeverityLabel(TextDiagnosticSeverity severity) {
  return switch (severity) {
    TextDiagnosticSeverity.error => 'error',
    TextDiagnosticSeverity.warning => 'warning',
    TextDiagnosticSeverity.info => 'info',
    TextDiagnosticSeverity.hint => 'hint',
  };
}

String textDiagnosticLocationLabel({
  required String text,
  required TextDiagnosticRange diagnostic,
}) {
  return textDiagnosticLocationLabelForDocument(
    document: TextDocument(text: text),
    diagnostic: diagnostic,
  );
}

String textDiagnosticLocationLabelForDocument({
  required TextDocument document,
  required TextDiagnosticRange diagnostic,
}) {
  final start = textDiagnosticStartPositionForDocument(
    document: document,
    diagnostic: diagnostic,
  );
  return 'L${start.line + 1}:C${start.column + 1}';
}

String textDiagnosticSummaryLabel({
  required String text,
  required TextDiagnosticRange diagnostic,
}) {
  return textDiagnosticSummaryLabelForDocument(
    document: TextDocument(text: text),
    diagnostic: diagnostic,
  );
}

String textDiagnosticSummaryLabelForDocument({
  required TextDocument document,
  required TextDiagnosticRange diagnostic,
}) {
  final code = switch ((diagnostic.source, diagnostic.code)) {
    (final String source?, final String code?) => '[$source/$code]',
    (_, final String code?) => '[$code]',
    _ => null,
  };
  final message = diagnostic.message?.trim();
  return [
    textDiagnosticSeverityLabel(diagnostic.severity),
    ?code,
    textDiagnosticLocationLabelForDocument(
      document: document,
      diagnostic: diagnostic,
    ),
    if (message != null && message.isNotEmpty) message else 'diagnostic',
  ].join(' ');
}

int? textDiagnosticNavigationIndex({
  required List<TextDiagnosticRange> diagnostics,
  required int cursorOffset,
  int? activeIndex,
  bool forward = true,
  bool wrap = true,
}) {
  if (diagnostics.isEmpty) {
    return null;
  }

  final normalizedOffset = cursorOffset < 0 ? 0 : cursorOffset;
  final currentIndex =
      activeIndex ??
      textDiagnosticContainingIndex(
        diagnostics: diagnostics,
        offset: normalizedOffset,
      );

  if (forward) {
    if (currentIndex != null) {
      final nextIndex = currentIndex + 1;
      if (nextIndex < diagnostics.length) {
        return nextIndex;
      }
      return wrap ? 0 : null;
    }

    for (var index = 0; index < diagnostics.length; index++) {
      if (diagnostics[index].startOffset > normalizedOffset) {
        return index;
      }
    }
    return wrap ? 0 : null;
  }

  if (currentIndex != null) {
    final previousIndex = currentIndex - 1;
    if (previousIndex >= 0) {
      return previousIndex;
    }
    return wrap ? diagnostics.length - 1 : null;
  }

  for (var index = diagnostics.length - 1; index >= 0; index--) {
    if (diagnostics[index].startOffset < normalizedOffset) {
      return index;
    }
  }
  return wrap ? diagnostics.length - 1 : null;
}

int? textDiagnosticContainingIndex({
  required List<TextDiagnosticRange> diagnostics,
  required int offset,
}) {
  for (var index = 0; index < diagnostics.length; index++) {
    final diagnostic = diagnostics[index];
    final effectiveEnd = diagnostic.endOffset <= diagnostic.startOffset
        ? diagnostic.startOffset + 1
        : diagnostic.endOffset;
    if (offset >= diagnostic.startOffset && offset < effectiveEnd) {
      return index;
    }
  }
  return null;
}

TextDiagnosticRange? textDiagnosticAtOffset({
  required List<TextDiagnosticRange> diagnostics,
  required int offset,
}) {
  final index = textDiagnosticContainingIndex(
    diagnostics: diagnostics,
    offset: offset,
  );
  return index == null ? null : diagnostics[index];
}

String textDiagnosticStyleKey(TextDiagnosticSeverity severity) {
  return switch (severity) {
    TextDiagnosticSeverity.error => textDiagnosticErrorDecorationKey,
    TextDiagnosticSeverity.warning => textDiagnosticWarningDecorationKey,
    TextDiagnosticSeverity.info => textDiagnosticInfoDecorationKey,
    TextDiagnosticSeverity.hint => textDiagnosticHintDecorationKey,
  };
}

String textDiagnosticLineStyleKey(TextDiagnosticSeverity severity) {
  return switch (severity) {
    TextDiagnosticSeverity.error => textDiagnosticErrorLineDecorationKey,
    TextDiagnosticSeverity.warning => textDiagnosticWarningLineDecorationKey,
    TextDiagnosticSeverity.info => textDiagnosticInfoLineDecorationKey,
    TextDiagnosticSeverity.hint => textDiagnosticHintLineDecorationKey,
  };
}

String textDiagnosticLineNumberStyleKey(TextDiagnosticSeverity severity) {
  return switch (severity) {
    TextDiagnosticSeverity.error => textDiagnosticErrorLineNumberDecorationKey,
    TextDiagnosticSeverity.warning =>
      textDiagnosticWarningLineNumberDecorationKey,
    TextDiagnosticSeverity.info => textDiagnosticInfoLineNumberDecorationKey,
    TextDiagnosticSeverity.hint => textDiagnosticHintLineNumberDecorationKey,
  };
}

String textDiagnosticLineMarker(TextDiagnosticSeverity severity) {
  return switch (severity) {
    TextDiagnosticSeverity.error => '!',
    TextDiagnosticSeverity.warning => '~',
    TextDiagnosticSeverity.info => 'i',
    TextDiagnosticSeverity.hint => '.',
  };
}

List<TextDecorationRange> textSearchDecorations(
  Iterable<TextHighlightRange> matches, {
  int activeIndex = -1,
}) {
  final normalizedMatches = matches.toList(growable: false);
  if (normalizedMatches.isEmpty) {
    return const [];
  }

  final normalizedActiveIndex =
      activeIndex < 0 || activeIndex >= normalizedMatches.length
      ? -1
      : activeIndex;

  return List<TextDecorationRange>.unmodifiable([
    for (var index = 0; index < normalizedMatches.length; index++)
      TextDecorationRange(
        startOffset: normalizedMatches[index].startOffset,
        endOffset: normalizedMatches[index].endOffset,
        styleKey: index == normalizedActiveIndex
            ? textSearchActiveMatchDecorationKey
            : textSearchMatchDecorationKey,
      ),
  ]);
}

List<TextDecorationRange> textDiagnosticDecorations(
  Iterable<TextDiagnosticRange> diagnostics,
) {
  final normalizedDiagnostics = normalizeTextDiagnostics(diagnostics);
  if (normalizedDiagnostics.isEmpty) {
    return const [];
  }

  return List<TextDecorationRange>.unmodifiable([
    for (final diagnostic in normalizedDiagnostics)
      TextDecorationRange(
        startOffset: diagnostic.normalized().startOffset,
        endOffset: diagnostic.normalized().endOffset,
        styleKey: textDiagnosticStyleKey(diagnostic.severity),
      ),
  ]);
}

List<TextLineDecoration> textDiagnosticLineDecorations({
  required String text,
  required Iterable<TextDiagnosticRange> diagnostics,
}) {
  return textDiagnosticLineDecorationsForDocument(
    document: TextDocument(text: text),
    diagnostics: diagnostics,
  );
}

List<TextLineDecoration> textDiagnosticLineDecorationsForDocument({
  required TextDocument document,
  required Iterable<TextDiagnosticRange> diagnostics,
}) {
  final normalizedDiagnostics = normalizeTextDiagnostics(diagnostics);
  if (normalizedDiagnostics.isEmpty) {
    return const [];
  }
  final lineSeverities = <int, TextDiagnosticSeverity>{};

  for (final diagnostic in normalizedDiagnostics) {
    final normalized = diagnostic.normalized();
    final startOffset = normalized.startOffset.clamp(0, document.length);
    final endOffset = normalized.endOffset.clamp(startOffset, document.length);
    final startLine = document.positionForOffset(startOffset).line;
    final endLine = endOffset <= startOffset
        ? startLine
        : document.positionForOffset(endOffset - 1).line;

    for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
      final existing = lineSeverities[lineIndex];
      if (existing == null ||
          _diagnosticSeverityRank(normalized.severity) >
              _diagnosticSeverityRank(existing)) {
        lineSeverities[lineIndex] = normalized.severity;
      }
    }
  }

  final sortedLines = lineSeverities.keys.toList(growable: false)..sort();
  return List<TextLineDecoration>.unmodifiable([
    for (final lineIndex in sortedLines)
      TextLineDecoration(
        lineIndex: lineIndex,
        styleKey: textDiagnosticLineStyleKey(lineSeverities[lineIndex]!),
        lineNumberMarker: textDiagnosticLineMarker(lineSeverities[lineIndex]!),
        lineNumberStyleKey: textDiagnosticLineNumberStyleKey(
          lineSeverities[lineIndex]!,
        ),
      ),
  ]);
}

int _diagnosticSeverityRank(TextDiagnosticSeverity severity) {
  return switch (severity) {
    TextDiagnosticSeverity.error => 3,
    TextDiagnosticSeverity.warning => 2,
    TextDiagnosticSeverity.info => 1,
    TextDiagnosticSeverity.hint => 0,
  };
}

int _compareTextPositions(
  int startLine,
  int startColumn,
  int endLine,
  int endColumn,
) {
  final lineComparison = startLine.compareTo(endLine);
  if (lineComparison != 0) {
    return lineComparison;
  }
  return startColumn.compareTo(endColumn);
}
