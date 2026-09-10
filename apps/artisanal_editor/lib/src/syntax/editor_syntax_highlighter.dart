import 'package:artisanal/editor_core.dart'
    show TextDecorationRange, TextDocument;

/// App-owned syntax-highlighting boundary for editor buffers.
abstract interface class EditorSyntaxHighlighter {
  /// Whether this highlighter can parse [languageId].
  bool supports(String languageId);

  /// Produces decoration ranges for one immutable document snapshot.
  Future<List<TextDecorationRange>> highlight({
    required String languageId,
    required TextDocument document,
  });
}
