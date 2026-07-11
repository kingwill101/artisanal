import 'package:html_unescape/html_unescape.dart';
import 'package:markdown/markdown.dart' show Element;

import '../../style/style.dart';
import '../../tui/bubbles/components/table.dart' as table_component;
import 'options.dart';
import 'html_context.dart';
import 'syntax_highlighter.dart' show SyntaxHighlighter;

/// Mutable rendering context passed through all markdown render functions.
///
/// Holds the output buffer and all state needed during rendering.
/// This is the core of the re-architected renderer: all state is public
/// so rendering functions can be defined in separate files.
class MarkdownRenderContext {
  MarkdownRenderContext({
    required this.options,
    required this.styleToAnsi,
    required this.headingStyleOf,
  });

  // ─── Configuration ────────────────────────────────────────────────

  final AnsiRendererOptions options;
  final String Function(Style style) styleToAnsi;
  final Style Function(String tag) headingStyleOf;

  // ─── Output ───────────────────────────────────────────────────────

  /// Main output buffer.
  final StringBuffer buffer = StringBuffer();

  /// Active buffer — points to [buffer] or a sub-buffer (e.g., paragraph).
  StringBuffer activeBuffer = StringBuffer();

  // ─── Element tracking ─────────────────────────────────────────────

  /// Stack of active elements for context tracking.
  final List<Element> elementStack = [];

  // ─── List state ───────────────────────────────────────────────────

  int listDepth = 0;
  final List<int> listCounters = [];
  final List<ListItemContext> listItemStack = [];

  // ─── Blockquote state ─────────────────────────────────────────────

  bool inBlockquote = false;
  int blockquoteDepth = 0;

  // ─── Output tracking ─────────────────────────────────────────────

  bool lastWasBlock = false;

  // ─── Link state ───────────────────────────────────────────────────

  String? pendingLinkUrl;
  String? imageAltText;

  // ─── Details state ────────────────────────────────────────────────

  final List<DetailsContext> detailsStack = [];

  // ─── Table state ──────────────────────────────────────────────────

  final List<String> tableHeaders = [];
  final List<List<String>> tableRows = [];
  final List<table_component.TableAlign> tableAlignments = [];
  final List<String> currentTableRow = [];
  final StringBuffer currentCellBuffer = StringBuffer();
  bool inTableHeader = false;
  bool inTableCell = false;

  // ─── Code block state ─────────────────────────────────────────────

  bool inCodeBlock = false;
  String? codeBlockLanguage;
  SyntaxHighlighter? syntaxHighlighter;

  // ─── Paragraph state ──────────────────────────────────────────────

  bool inParagraph = false;
  final StringBuffer paragraphBuffer = StringBuffer();

  // ─── Inline text style state ──────────────────────────────────────

  bool textStyleActive = false;

  // ─── Utilities ────────────────────────────────────────────────────

  final HtmlUnescape htmlUnescape = HtmlUnescape();

  // ─── Helpers ──────────────────────────────────────────────────────

  static const ansiReset = '\x1b[0m';
}

/// Context for tracking list item rendering state.
class ListItemContext {
  ListItemContext({
    this.continuationIndent = 0,
    this.taskCheckboxRendered = false,
    this.trimLeadingWhitespace = true,
  });

  final int continuationIndent;
  final bool taskCheckboxRendered;
  final StringBuffer buffer = StringBuffer();
  bool trimLeadingWhitespace;
}
