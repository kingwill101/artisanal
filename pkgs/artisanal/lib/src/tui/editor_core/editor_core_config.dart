library;

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
