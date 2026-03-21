import '../../unicode/grapheme.dart' as uni;

import 'text_decorations.dart';
import 'text_document.dart';

final class TextPatternDiagnosticRule {
  const TextPatternDiagnosticRule({
    required this.pattern,
    required this.severity,
    this.code,
    this.message,
    this.source,
    this.caseSensitive = false,
    this.wholeWord = false,
  });

  final String pattern;
  final TextDiagnosticSeverity severity;
  final String? code;
  final String? message;
  final String? source;
  final bool caseSensitive;
  final bool wholeWord;
}

List<TextPositionDiagnosticRange> textPatternDiagnostics({
  required String text,
  required Iterable<TextPatternDiagnosticRule> rules,
}) {
  return textPatternDiagnosticsForDocument(
    document: TextDocument(text: text),
    rules: rules,
  );
}

List<TextPositionDiagnosticRange> textPatternDiagnosticsForDocument({
  required TextDocument document,
  required Iterable<TextPatternDiagnosticRule> rules,
}) {
  final diagnostics = <TextPositionDiagnosticRange>[];

  for (final rule in rules) {
    final needle = uni.graphemes(rule.pattern).toList(growable: false);
    if (needle.isEmpty) {
      continue;
    }

    final normalizedNeedle = rule.caseSensitive
        ? needle
        : needle.map((token) => token.toLowerCase()).toList(growable: false);

    for (var lineIndex = 0; lineIndex < document.lineCount; lineIndex++) {
      final haystack = document.lineGraphemesAt(lineIndex);
      final normalizedHaystack = rule.caseSensitive
          ? haystack
          : haystack
                .map((token) => token.toLowerCase())
                .toList(growable: false);

      var cursor = 0;
      while (cursor <= normalizedHaystack.length - normalizedNeedle.length) {
        var matched = true;
        for (var index = 0; index < normalizedNeedle.length; index++) {
          if (normalizedHaystack[cursor + index] != normalizedNeedle[index]) {
            matched = false;
            break;
          }
        }
        if (!matched) {
          cursor += 1;
          continue;
        }

        final startColumn = cursor;
        final endColumn = cursor + normalizedNeedle.length;
        if (rule.wholeWord &&
            !_isWholeWordMatch(
              haystack,
              startColumn: startColumn,
              endColumn: endColumn,
            )) {
          cursor += 1;
          continue;
        }

        diagnostics.add(
          TextPositionDiagnosticRange(
            startLine: lineIndex,
            startColumn: startColumn,
            endLine: lineIndex,
            endColumn: endColumn,
            severity: rule.severity,
            code: rule.code,
            message: rule.message,
            source: rule.source,
          ).clamp(document).normalized(),
        );
        cursor = endColumn;
      }
    }
  }

  diagnostics.sort((a, b) {
    final startLineComparison = a.startLine.compareTo(b.startLine);
    if (startLineComparison != 0) {
      return startLineComparison;
    }
    final startColumnComparison = a.startColumn.compareTo(b.startColumn);
    if (startColumnComparison != 0) {
      return startColumnComparison;
    }
    final endLineComparison = a.endLine.compareTo(b.endLine);
    if (endLineComparison != 0) {
      return endLineComparison;
    }
    final endColumnComparison = a.endColumn.compareTo(b.endColumn);
    if (endColumnComparison != 0) {
      return endColumnComparison;
    }
    return _diagnosticSeverityRank(
      b.severity,
    ).compareTo(_diagnosticSeverityRank(a.severity));
  });

  return List<TextPositionDiagnosticRange>.unmodifiable(diagnostics);
}

bool _isWholeWordMatch(
  List<String> graphemes, {
  required int startColumn,
  required int endColumn,
}) {
  final before = startColumn > 0 ? graphemes[startColumn - 1] : null;
  final after = endColumn < graphemes.length ? graphemes[endColumn] : null;
  return (before == null || !_isWordGrapheme(before)) &&
      (after == null || !_isWordGrapheme(after));
}

bool _isWordGrapheme(String grapheme) {
  if (grapheme.isEmpty) {
    return false;
  }
  final codePoint = uni.firstCodePoint(grapheme);
  final isAsciiDigit = codePoint >= 0x30 && codePoint <= 0x39;
  final isAsciiUpper = codePoint >= 0x41 && codePoint <= 0x5a;
  final isAsciiLower = codePoint >= 0x61 && codePoint <= 0x7a;
  return isAsciiDigit || isAsciiUpper || isAsciiLower || codePoint == 0x5f;
}

int _diagnosticSeverityRank(TextDiagnosticSeverity severity) {
  return switch (severity) {
    TextDiagnosticSeverity.error => 4,
    TextDiagnosticSeverity.warning => 3,
    TextDiagnosticSeverity.info => 2,
    TextDiagnosticSeverity.hint => 1,
  };
}
