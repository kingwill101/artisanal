library;

import 'text_document.dart';

final class EditorCoreConfig {
  const EditorCoreConfig({
    this.tabWidth = 4,
    this.tabWidthSingleLine = 1,
    this.scrollMargin = 0,
    this.decorationLayerPriorityDefault = 0,
    this.decorationLayerPrioritySyntax = 50,
    this.decorationLayerPriorityDiagnostics = 75,
    this.decorationLayerPrioritySearch = 100,
    this.decorationLayerPriorityDefaultLine = 0,
    this.decorationLayerPriorityDiagnosticsLine = 75,
    this.decorationLayerPriorityActiveLine = 50,
    this.sourceBackedReplacementTextThreshold = 8192,
    this.extmarkMaxOffset = 1073741824,
  });

  final int tabWidth;
  final int tabWidthSingleLine;
  final int scrollMargin;
  final int decorationLayerPriorityDefault;
  final int decorationLayerPrioritySyntax;
  final int decorationLayerPriorityDiagnostics;
  final int decorationLayerPrioritySearch;
  final int decorationLayerPriorityDefaultLine;
  final int decorationLayerPriorityDiagnosticsLine;
  final int decorationLayerPriorityActiveLine;
  final int sourceBackedReplacementTextThreshold;
  final int extmarkMaxOffset;

  static EditorCoreConfig current = const EditorCoreConfig();
}

/// Coarse document-size class used to choose bounded editor strategies.
enum EditorDocumentScale {
  /// Normal interactive processing is expected to fit within a frame budget.
  normal,

  /// Expensive work should be asynchronous or restricted to visible ranges.
  large,

  /// Optional analysis should be disabled unless a host explicitly opts in.
  oversized,
}

/// Configurable limits for features whose cost grows with document size.
///
/// The policy reports limits rather than silently disabling features. Hosts
/// remain free to override recommendations for their parser, machine, or UX.
final class EditorWorkBudget {
  const EditorWorkBudget({
    this.largeDocumentLength = 200000,
    this.oversizedDocumentLength = 2000000,
    this.largeDocumentLines = 10000,
    this.oversizedDocumentLines = 100000,
    this.maxSynchronousSyntaxLength = 100000,
    this.maxSearchResults = 10000,
    this.maxDecorations = 20000,
  }) : assert(largeDocumentLength >= 0),
       assert(oversizedDocumentLength >= largeDocumentLength),
       assert(largeDocumentLines >= 0),
       assert(oversizedDocumentLines >= largeDocumentLines),
       assert(maxSynchronousSyntaxLength >= 0),
       assert(maxSearchResults >= 0),
       assert(maxDecorations >= 0);

  /// Grapheme count at which bounded strategies are recommended.
  final int largeDocumentLength;

  /// Grapheme count at which optional whole-document work should stop.
  final int oversizedDocumentLength;

  /// Line count at which bounded strategies are recommended.
  final int largeDocumentLines;

  /// Line count at which optional whole-document work should stop.
  final int oversizedDocumentLines;

  /// Largest document recommended for syntax work on the render isolate.
  final int maxSynchronousSyntaxLength;

  /// Recommended cap for materialized search matches.
  final int maxSearchResults;

  /// Recommended cap for materialized decoration ranges.
  final int maxDecorations;

  /// Assesses [document] against this budget.
  EditorWorkAssessment assess(TextDocument document) {
    final scale =
        document.length >= oversizedDocumentLength ||
            document.lineCount >= oversizedDocumentLines
        ? EditorDocumentScale.oversized
        : document.length >= largeDocumentLength ||
              document.lineCount >= largeDocumentLines
        ? EditorDocumentScale.large
        : EditorDocumentScale.normal;
    return EditorWorkAssessment(
      scale: scale,
      allowSynchronousSyntax:
          scale == EditorDocumentScale.normal &&
          document.length <= maxSynchronousSyntaxLength,
      preferVisibleRangeWork: scale != EditorDocumentScale.normal,
      maxSearchResults: maxSearchResults,
      maxDecorations: maxDecorations,
    );
  }
}

/// Feature recommendations derived from an [EditorWorkBudget].
final class EditorWorkAssessment {
  const EditorWorkAssessment({
    required this.scale,
    required this.allowSynchronousSyntax,
    required this.preferVisibleRangeWork,
    required this.maxSearchResults,
    required this.maxDecorations,
  });

  final EditorDocumentScale scale;
  final bool allowSynchronousSyntax;
  final bool preferVisibleRangeWork;
  final int maxSearchResults;
  final int maxDecorations;
}
