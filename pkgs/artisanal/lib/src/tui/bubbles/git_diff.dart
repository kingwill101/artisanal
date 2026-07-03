/// Git diff viewer bubble for displaying unified diffs in the terminal.
///
/// Provides [GitDiffModel] for parsing and rendering git unified diffs with
/// syntax-highlighted additions (green), deletions (red), file headers (bold),
/// and hunk headers (cyan). Scrolling is handled by an embedded
/// [ViewportModel].
///
/// ## Usage
///
/// ```dart
/// class DiffViewer implements Model {
///   final GitDiffModel diff;
///
///   DiffViewer({GitDiffModel? diff, String rawDiff = ''})
///       : diff = diff ?? GitDiffModel(width: 80, height: 24)
///             ..setDiff(rawDiff);
///
///   @override
///   Cmd? init() => null;
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     if (msg is WindowSizeMsg) {
///       return (
///         DiffViewer(
///           diff: diff.copyWith(width: msg.width, height: msg.height),
///         ),
///         null,
///       );
///     }
///     final (newDiff, cmd) = diff.update(msg);
///     return (DiffViewer(diff: newDiff as GitDiffModel), cmd);
///   }
///
///   @override
///   String view() => diff.view();
/// }
/// ```
///
/// {@category TUI}
/// {@category Bubbles}
library;

import '../../style/color.dart';
import '../../style/style.dart';
import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'key_binding.dart';
import 'viewport.dart';

/// The display mode for the diff viewer.
enum DiffViewMode {
  /// Unified diff — additions and deletions shown inline.
  unified,

  /// Side-by-side diff — old file on the left, new file on the right.
  sideBySide,

  /// Pretty diff — clean file headers, colored line backgrounds, single
  /// line-number column.
  pretty,
}

/// Key bindings for the git diff viewer.
///
/// Provides a [cycleViewMode] binding (default: `v`) to cycle between
/// [DiffViewMode] values (unified → sideBySide → pretty → unified…).
class GitDiffKeyMap implements KeyMap {
  /// Creates a git diff key map with optional overrides.
  GitDiffKeyMap({KeyBinding? cycleViewMode})
    : cycleViewMode =
          cycleViewMode ?? KeyBinding.withHelp(['v'], 'v', 'cycle view mode');

  /// Key to cycle through view modes.
  final KeyBinding cycleViewMode;

  @override
  List<KeyBinding> shortHelp() => [cycleViewMode];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [cycleViewMode],
  ];
}

/// Configuration for diff styling.
class DiffStyles {
  /// Creates diff styles with the given or default color settings.
  DiffStyles({
    Style? addedLine,
    Style? removedLine,
    Style? contextLine,
    Style? fileHeader,
    Style? hunkHeader,
    Style? addedGutter,
    Style? removedGutter,
    Style? contextGutter,
    Style? lineNumber,
    Style? prettyAddedLine,
    Style? prettyRemovedLine,
    Style? prettyContextLine,
    Style? prettyFileHeader,
    Style? prettyAddedLineNumber,
    Style? prettyRemovedLineNumber,
    Style? prettyContextLineNumber,
    Style? sideBySideSeparator,
    Style? sideBySideAddedLine,
    Style? sideBySideRemovedLine,
    Style? sideBySideContextLine,
    Style? sideBySideLineNumber,
    Style? sideBySideEmptyCell,
    Style? sideBySideAddedMarker,
    Style? sideBySideRemovedMarker,
    Style? sideBySideContextMarker,
    Style? inlineAddedHighlight,
    Style? inlineRemovedHighlight,
    Style? selectedCommentLine,
    Style? selectedCommentGutter,
    Style? commentRangeLine,
    Style? commentRangeGutter,
    Style? commentThreadLine,
    Style? commentThreadGutter,
  }) : addedLine = addedLine ?? Style().foreground(const BasicColor('#22c55e')),
       removedLine =
           removedLine ?? Style().foreground(const BasicColor('#ef4444')),
       contextLine = contextLine ?? Style(),
       fileHeader =
           fileHeader ?? Style().bold().foreground(const BasicColor('#ffffff')),
       hunkHeader =
           hunkHeader ?? Style().foreground(const BasicColor('#06b6d4')),
       addedGutter =
           addedGutter ??
           Style().foreground(const BasicColor('#22c55e')).bold(),
       removedGutter =
           removedGutter ??
           Style().foreground(const BasicColor('#ef4444')).bold(),
       contextGutter =
           contextGutter ?? Style().foreground(const BasicColor('#6b7280')),
       lineNumber =
           lineNumber ?? Style().foreground(const BasicColor('#6b7280')),
       prettyAddedLine =
           prettyAddedLine ??
           Style()
               .foreground(const BasicColor('#22c55e'))
               .background(const BasicColor('#1a2e1a')),
       prettyRemovedLine =
           prettyRemovedLine ??
           Style()
               .foreground(const BasicColor('#ef4444'))
               .background(const BasicColor('#2e1a1a')),
       prettyContextLine = prettyContextLine ?? Style(),
       prettyFileHeader =
           prettyFileHeader ?? Style().foreground(const BasicColor('#6b7280')),
       prettyAddedLineNumber =
           prettyAddedLineNumber ??
           Style()
               .foreground(const BasicColor('#22c55e'))
               .background(const BasicColor('#1a2e1a')),
       prettyRemovedLineNumber =
           prettyRemovedLineNumber ??
           Style()
               .foreground(const BasicColor('#ef4444'))
               .background(const BasicColor('#2e1a1a')),
       prettyContextLineNumber =
           prettyContextLineNumber ??
           Style().foreground(const BasicColor('#6b7280')),
       sideBySideSeparator =
           sideBySideSeparator ??
           Style().foreground(const BasicColor('#6b7280')),
       sideBySideAddedLine =
           sideBySideAddedLine ??
           Style()
               .foreground(const BasicColor('#22c55e'))
               .background(const BasicColor('#1a2e1a')),
       sideBySideRemovedLine =
           sideBySideRemovedLine ??
           Style()
               .foreground(const BasicColor('#ef4444'))
               .background(const BasicColor('#2e1a1a')),
       sideBySideContextLine = sideBySideContextLine ?? Style(),
       sideBySideLineNumber =
           sideBySideLineNumber ??
           Style().foreground(const BasicColor('#6b7280')),
       sideBySideEmptyCell =
           sideBySideEmptyCell ??
           Style().foreground(const BasicColor('#3a3a3a')),
       sideBySideAddedMarker =
           sideBySideAddedMarker ??
           Style().foreground(const BasicColor('#22c55e')),
       sideBySideRemovedMarker =
           sideBySideRemovedMarker ??
           Style().foreground(const BasicColor('#ef4444')),
       sideBySideContextMarker =
           sideBySideContextMarker ??
           Style().foreground(const BasicColor('#6b7280')),
       inlineAddedHighlight =
           inlineAddedHighlight ??
           Style().background(const BasicColor('#2a4a2a')),
       inlineRemovedHighlight =
           inlineRemovedHighlight ??
           Style().background(const BasicColor('#4a2a2a')),
       selectedCommentLine =
           selectedCommentLine ??
           Style().background(const BasicColor('#2f3f5f')),
       selectedCommentGutter =
           selectedCommentGutter ??
           Style().background(const BasicColor('#50668f')),
       commentRangeLine =
           commentRangeLine ?? Style().background(const BasicColor('#263847')),
       commentRangeGutter =
           commentRangeGutter ??
           Style().background(const BasicColor('#3f6374')),
       commentThreadLine =
           commentThreadLine ?? Style().background(const BasicColor('#5d4037')),
       commentThreadGutter =
           commentThreadGutter ??
           Style().background(const BasicColor('#8d6e63'));

  /// Creates a dark-theme diff style preset (identical to the defaults).
  ///
  /// Provided for symmetry with [DiffStyles.light].
  factory DiffStyles.dark() => DiffStyles();

  /// Creates a light-theme diff style preset.
  ///
  /// Uses a warm cream background with pastel green/pink highlights for
  /// added/removed lines. Code text is dark; only `+`/`-` markers use
  /// colored foregrounds. Suitable for terminals with a light background
  /// or when explicitly filling the screen with a light color scheme.
  factory DiffStyles.light() {
    // ── Palette ──────────────────────────────────────────────────────────────
    const cream = BasicColor('#faf6f1'); // overall warm cream background
    const darkText = BasicColor('#24292f'); // near-black code text
    const mutedText = BasicColor('#6e7781'); // muted gray for line numbers
    const fileHeaderText = BasicColor('#57606a'); // slightly darker muted
    const greenMarker = BasicColor('#1a7f37'); // deep green for + markers
    const redMarker = BasicColor('#cf222e'); // deep red for - markers
    const hunkText = BasicColor('#8b949e'); // subtle gray for hunk headers

    const addedBg = BasicColor('#dafbe1'); // pastel green background
    const removedBg = BasicColor('#ffebe9'); // pastel pink background
    const inlineAddedBg = BasicColor('#abf2bc'); // stronger green highlight
    const inlineRemovedBg = BasicColor('#ffc1ba'); // stronger pink highlight
    const emptyCellBg = BasicColor('#f0ebe6'); // slightly darker cream

    return DiffStyles(
      // ── Unified mode ────────────────────────────────────────────────────
      addedLine: Style().foreground(darkText).background(addedBg),
      removedLine: Style().foreground(darkText).background(removedBg),
      contextLine: Style().foreground(darkText).background(cream),
      fileHeader: Style().bold().foreground(fileHeaderText).background(cream),
      hunkHeader: Style().foreground(hunkText).background(cream),
      addedGutter: Style().foreground(greenMarker).background(addedBg).bold(),
      removedGutter: Style().foreground(redMarker).background(removedBg).bold(),
      contextGutter: Style().foreground(mutedText).background(cream),
      lineNumber: Style().foreground(mutedText).background(cream),
      // ── Pretty mode ─────────────────────────────────────────────────────
      prettyAddedLine: Style().foreground(darkText).background(addedBg),
      prettyRemovedLine: Style().foreground(darkText).background(removedBg),
      prettyContextLine: Style().foreground(darkText).background(cream),
      prettyFileHeader: Style().foreground(fileHeaderText).background(cream),
      prettyAddedLineNumber: Style()
          .foreground(greenMarker)
          .background(addedBg),
      prettyRemovedLineNumber: Style()
          .foreground(redMarker)
          .background(removedBg),
      prettyContextLineNumber: Style().foreground(mutedText).background(cream),
      // ── Side-by-side mode ───────────────────────────────────────────────
      sideBySideSeparator: Style().foreground(mutedText).background(cream),
      sideBySideAddedLine: Style().foreground(darkText).background(addedBg),
      sideBySideRemovedLine: Style().foreground(darkText).background(removedBg),
      sideBySideContextLine: Style().foreground(darkText).background(cream),
      sideBySideLineNumber: Style().foreground(mutedText).background(cream),
      sideBySideEmptyCell: Style()
          .foreground(mutedText)
          .background(emptyCellBg),
      sideBySideAddedMarker: Style()
          .foreground(greenMarker)
          .background(addedBg),
      sideBySideRemovedMarker: Style()
          .foreground(redMarker)
          .background(removedBg),
      sideBySideContextMarker: Style().foreground(mutedText).background(cream),
      // ── Inline diff highlighting ────────────────────────────────────────
      inlineAddedHighlight: Style()
          .foreground(darkText)
          .background(inlineAddedBg),
      inlineRemovedHighlight: Style()
          .foreground(darkText)
          .background(inlineRemovedBg),
      selectedCommentLine: Style()
          .foreground(darkText)
          .background(const BasicColor('#bfd7ff')),
      selectedCommentGutter: Style()
          .foreground(darkText)
          .background(const BasicColor('#9dbcf8')),
      commentRangeLine: Style()
          .foreground(darkText)
          .background(const BasicColor('#d6e8ff')),
      commentRangeGutter: Style()
          .foreground(darkText)
          .background(const BasicColor('#b8d7ff')),
      commentThreadLine: Style()
          .foreground(darkText)
          .background(const BasicColor('#ffeb3b')),
      commentThreadGutter: Style()
          .foreground(darkText)
          .background(const BasicColor('#fbc02d')),
    );
  }

  /// Creates diff styles from semantic colors.
  ///
  /// Maps semantic color slots (success/error/muted/surface/onSurface/border)
  /// to the appropriate diff styles. This enables theme-driven styling
  /// without coupling to a specific theme class.
  ///
  /// - [success] — color for added lines (foreground).
  /// - [error] — color for removed lines (foreground).
  /// - [muted] — color for line numbers, context gutter, separators.
  /// - [surface] — background for panels (used for empty cells in
  ///   side-by-side mode).
  /// - [onSurface] — text color on surface backgrounds (file headers).
  /// - [onBackground] — text color on main background (context lines).
  /// - [border] — border/separator color.
  /// - [successBg] — subtle background for added lines (optional).
  /// - [errorBg] — subtle background for removed lines (optional).
  factory DiffStyles.fromColors({
    required Color success,
    required Color error,
    required Color muted,
    required Color surface,
    required Color onSurface,
    required Color onBackground,
    required Color border,
    bool hasDarkBackground = true,
    Color? successBg,
    Color? errorBg,
    Color? inlineAddedBg,
    Color? inlineRemovedBg,
  }) {
    final addedBg = successBg ?? const BasicColor('#1a2e1a');
    final removedBg = errorBg ?? const BasicColor('#2e1a1a');

    return DiffStyles(
      // Unified mode
      addedLine: _bgAware(Style().foreground(success), hasDarkBackground),
      removedLine: _bgAware(Style().foreground(error), hasDarkBackground),
      contextLine: _bgAware(Style().foreground(onBackground), hasDarkBackground),
      fileHeader: _bgAware(
        Style().bold().foreground(onSurface),
        hasDarkBackground,
      ),
      hunkHeader: _bgAware(Style().foreground(muted), hasDarkBackground),
      addedGutter: _bgAware(Style().foreground(success).bold(), hasDarkBackground),
      removedGutter: _bgAware(Style().foreground(error).bold(), hasDarkBackground),
      contextGutter: _bgAware(Style().foreground(muted), hasDarkBackground),
      lineNumber: _bgAware(Style().foreground(muted), hasDarkBackground),
      // Pretty mode
      prettyAddedLine: _bgAware(
        Style().foreground(success).background(addedBg),
        hasDarkBackground,
      ),
      prettyRemovedLine: _bgAware(
        Style().foreground(error).background(removedBg),
        hasDarkBackground,
      ),
      prettyContextLine: _bgAware(
        Style().foreground(onBackground),
        hasDarkBackground,
      ),
      prettyFileHeader: _bgAware(Style().foreground(muted), hasDarkBackground),
      prettyAddedLineNumber: _bgAware(
        Style().foreground(success).background(addedBg),
        hasDarkBackground,
      ),
      prettyRemovedLineNumber: _bgAware(
        Style().foreground(error).background(removedBg),
        hasDarkBackground,
      ),
      prettyContextLineNumber: _bgAware(
        Style().foreground(muted),
        hasDarkBackground,
      ),
      // Side-by-side mode
      sideBySideSeparator: _bgAware(Style().foreground(border), hasDarkBackground),
      sideBySideAddedLine: _bgAware(
        Style().foreground(success).background(addedBg),
        hasDarkBackground,
      ),
      sideBySideRemovedLine: _bgAware(
        Style().foreground(error).background(removedBg),
        hasDarkBackground,
      ),
      sideBySideContextLine: _bgAware(
        Style().foreground(onBackground),
        hasDarkBackground,
      ),
      sideBySideLineNumber: _bgAware(Style().foreground(muted), hasDarkBackground),
      sideBySideEmptyCell: _bgAware(Style().foreground(surface), hasDarkBackground),
      sideBySideAddedMarker: _bgAware(Style().foreground(success), hasDarkBackground),
      sideBySideRemovedMarker: _bgAware(Style().foreground(error), hasDarkBackground),
      sideBySideContextMarker: _bgAware(Style().foreground(muted), hasDarkBackground),
      // Inline diff highlighting
      inlineAddedHighlight: _bgAware(
        Style().background(
        inlineAddedBg ?? const BasicColor('#2a4a2a'),
      ),
        hasDarkBackground,
      ),
      inlineRemovedHighlight: _bgAware(
        Style().background(
        inlineRemovedBg ?? const BasicColor('#4a2a2a'),
      ),
        hasDarkBackground,
      ),
      selectedCommentLine: _bgAware(
        Style().background(
          AdaptiveColor(
            dark: const BasicColor('#2f3f5f'),
            light: const BasicColor('#bfd7ff'),
          ),
        ),
        hasDarkBackground,
      ),
      selectedCommentGutter: _bgAware(
        Style().background(
          AdaptiveColor(
            dark: const BasicColor('#50668f'),
            light: const BasicColor('#9dbcf8'),
          ),
        ),
        hasDarkBackground,
      ),
      commentRangeLine: _bgAware(
        Style().background(
          AdaptiveColor(
            dark: const BasicColor('#263847'),
            light: const BasicColor('#d6e8ff'),
          ),
        ),
        hasDarkBackground,
      ),
      commentRangeGutter: _bgAware(
        Style().background(
          AdaptiveColor(
            dark: const BasicColor('#3f6374'),
            light: const BasicColor('#b8d7ff'),
          ),
        ),
        hasDarkBackground,
      ),
      commentThreadLine: _bgAware(
        Style().background(
          AdaptiveColor(
            dark: const BasicColor('#5d4037'),
            light: const BasicColor('#ffeb3b'),
          ),
        ),
        hasDarkBackground,
      ),
      commentThreadGutter: _bgAware(
        Style().background(
          AdaptiveColor(
            dark: const BasicColor('#8d6e63'),
            light: const BasicColor('#fbc02d'),
          ),
        ),
        hasDarkBackground,
      ),
    );
  }

  static Style _bgAware(Style style, bool hasDarkBackground) {
    final copy = style.copy();
    copy.hasDarkBackground = hasDarkBackground;
    return copy;
  }

  /// Style for added (+) lines.
  final Style addedLine;

  /// Style for removed (-) lines.
  final Style removedLine;

  /// Style for context (unchanged) lines.
  final Style contextLine;

  /// Style for file header lines (diff --git, ---/+++ lines).
  final Style fileHeader;

  /// Style for hunk headers (@@ ... @@).
  final Style hunkHeader;

  /// Style for the gutter indicator on added lines.
  final Style addedGutter;

  /// Style for the gutter indicator on removed lines.
  final Style removedGutter;

  /// Style for the gutter indicator on context lines.
  final Style contextGutter;

  /// Style for line numbers.
  final Style lineNumber;

  // ── Pretty mode styles ──────────────────────────────────────────────────

  /// Pretty mode: style for added lines (foreground + background).
  final Style prettyAddedLine;

  /// Pretty mode: style for removed lines (foreground + background).
  final Style prettyRemovedLine;

  /// Pretty mode: style for context lines.
  final Style prettyContextLine;

  /// Pretty mode: style for file header lines.
  final Style prettyFileHeader;

  /// Pretty mode: style for line numbers on added lines.
  final Style prettyAddedLineNumber;

  /// Pretty mode: style for line numbers on removed lines.
  final Style prettyRemovedLineNumber;

  /// Pretty mode: style for line numbers on context lines.
  final Style prettyContextLineNumber;

  // ── Side-by-side mode styles ────────────────────────────────────────────

  /// Side-by-side mode: style for the center separator column (│).
  final Style sideBySideSeparator;

  /// Side-by-side mode: style for added lines (right panel).
  final Style sideBySideAddedLine;

  /// Side-by-side mode: style for removed lines (left panel).
  final Style sideBySideRemovedLine;

  /// Side-by-side mode: style for context lines (both panels).
  final Style sideBySideContextLine;

  /// Side-by-side mode: style for line numbers.
  final Style sideBySideLineNumber;

  /// Side-by-side mode: style for empty cells (no content on that side).
  final Style sideBySideEmptyCell;

  /// Side-by-side mode: style for the `+` marker on added lines.
  final Style sideBySideAddedMarker;

  /// Side-by-side mode: style for the `-` marker on removed lines.
  final Style sideBySideRemovedMarker;

  /// Side-by-side mode: style for the space marker on context lines.
  final Style sideBySideContextMarker;

  // ── Inline diff highlighting ─────────────────────────────────────────────

  /// Inline diff: stronger highlight for added (new) tokens within a
  /// changed line. Applied on top of the line's base style.
  final Style inlineAddedHighlight;

  /// Inline diff: stronger highlight for removed (old) tokens within a
  /// changed line. Applied on top of the line's base style.
  final Style inlineRemovedHighlight;

  /// Full-line style layered onto the selected diff comment line.
  final Style selectedCommentLine;

  /// Gutter style layered onto the selected diff comment line.
  final Style selectedCommentGutter;

  /// Full-line style layered onto lines in the selected comment range.
  final Style commentRangeLine;

  /// Gutter style layered onto lines in the selected comment range.
  final Style commentRangeGutter;

  /// Full-line style layered onto lines that already have review threads.
  final Style commentThreadLine;

  /// Gutter style layered onto lines that already have review threads.
  final Style commentThreadGutter;

  /// Creates a copy with the given fields replaced.
  DiffStyles copyWith({
    Style? addedLine,
    Style? removedLine,
    Style? contextLine,
    Style? fileHeader,
    Style? hunkHeader,
    Style? addedGutter,
    Style? removedGutter,
    Style? contextGutter,
    Style? lineNumber,
    Style? prettyAddedLine,
    Style? prettyRemovedLine,
    Style? prettyContextLine,
    Style? prettyFileHeader,
    Style? prettyAddedLineNumber,
    Style? prettyRemovedLineNumber,
    Style? prettyContextLineNumber,
    Style? sideBySideSeparator,
    Style? sideBySideAddedLine,
    Style? sideBySideRemovedLine,
    Style? sideBySideContextLine,
    Style? sideBySideLineNumber,
    Style? sideBySideEmptyCell,
    Style? sideBySideAddedMarker,
    Style? sideBySideRemovedMarker,
    Style? sideBySideContextMarker,
    Style? inlineAddedHighlight,
    Style? inlineRemovedHighlight,
    Style? selectedCommentLine,
    Style? selectedCommentGutter,
    Style? commentRangeLine,
    Style? commentRangeGutter,
    Style? commentThreadLine,
    Style? commentThreadGutter,
  }) {
    return DiffStyles(
      addedLine: addedLine ?? this.addedLine,
      removedLine: removedLine ?? this.removedLine,
      contextLine: contextLine ?? this.contextLine,
      fileHeader: fileHeader ?? this.fileHeader,
      hunkHeader: hunkHeader ?? this.hunkHeader,
      addedGutter: addedGutter ?? this.addedGutter,
      removedGutter: removedGutter ?? this.removedGutter,
      contextGutter: contextGutter ?? this.contextGutter,
      lineNumber: lineNumber ?? this.lineNumber,
      prettyAddedLine: prettyAddedLine ?? this.prettyAddedLine,
      prettyRemovedLine: prettyRemovedLine ?? this.prettyRemovedLine,
      prettyContextLine: prettyContextLine ?? this.prettyContextLine,
      prettyFileHeader: prettyFileHeader ?? this.prettyFileHeader,
      prettyAddedLineNumber:
          prettyAddedLineNumber ?? this.prettyAddedLineNumber,
      prettyRemovedLineNumber:
          prettyRemovedLineNumber ?? this.prettyRemovedLineNumber,
      prettyContextLineNumber:
          prettyContextLineNumber ?? this.prettyContextLineNumber,
      sideBySideSeparator: sideBySideSeparator ?? this.sideBySideSeparator,
      sideBySideAddedLine: sideBySideAddedLine ?? this.sideBySideAddedLine,
      sideBySideRemovedLine:
          sideBySideRemovedLine ?? this.sideBySideRemovedLine,
      sideBySideContextLine:
          sideBySideContextLine ?? this.sideBySideContextLine,
      sideBySideLineNumber: sideBySideLineNumber ?? this.sideBySideLineNumber,
      sideBySideEmptyCell: sideBySideEmptyCell ?? this.sideBySideEmptyCell,
      sideBySideAddedMarker:
          sideBySideAddedMarker ?? this.sideBySideAddedMarker,
      sideBySideRemovedMarker:
          sideBySideRemovedMarker ?? this.sideBySideRemovedMarker,
      sideBySideContextMarker:
          sideBySideContextMarker ?? this.sideBySideContextMarker,
      inlineAddedHighlight: inlineAddedHighlight ?? this.inlineAddedHighlight,
      inlineRemovedHighlight:
          inlineRemovedHighlight ?? this.inlineRemovedHighlight,
      selectedCommentLine: selectedCommentLine ?? this.selectedCommentLine,
      selectedCommentGutter:
          selectedCommentGutter ?? this.selectedCommentGutter,
      commentRangeLine: commentRangeLine ?? this.commentRangeLine,
      commentRangeGutter: commentRangeGutter ?? this.commentRangeGutter,
      commentThreadLine: commentThreadLine ?? this.commentThreadLine,
      commentThreadGutter: commentThreadGutter ?? this.commentThreadGutter,
    );
  }

  /// Returns a copy whose adaptive colors resolve against [hasDarkBackground].
  DiffStyles withHasDarkBackground(bool hasDarkBackground) {
    Style bgAware(Style style) {
      final copy = style.copy();
      copy.hasDarkBackground = hasDarkBackground;
      return copy;
    }

    return DiffStyles(
      addedLine: bgAware(addedLine),
      removedLine: bgAware(removedLine),
      contextLine: bgAware(contextLine),
      fileHeader: bgAware(fileHeader),
      hunkHeader: bgAware(hunkHeader),
      addedGutter: bgAware(addedGutter),
      removedGutter: bgAware(removedGutter),
      contextGutter: bgAware(contextGutter),
      lineNumber: bgAware(lineNumber),
      prettyAddedLine: bgAware(prettyAddedLine),
      prettyRemovedLine: bgAware(prettyRemovedLine),
      prettyContextLine: bgAware(prettyContextLine),
      prettyFileHeader: bgAware(prettyFileHeader),
      prettyAddedLineNumber: bgAware(prettyAddedLineNumber),
      prettyRemovedLineNumber: bgAware(prettyRemovedLineNumber),
      prettyContextLineNumber: bgAware(prettyContextLineNumber),
      sideBySideSeparator: bgAware(sideBySideSeparator),
      sideBySideAddedLine: bgAware(sideBySideAddedLine),
      sideBySideRemovedLine: bgAware(sideBySideRemovedLine),
      sideBySideContextLine: bgAware(sideBySideContextLine),
      sideBySideLineNumber: bgAware(sideBySideLineNumber),
      sideBySideEmptyCell: bgAware(sideBySideEmptyCell),
      sideBySideAddedMarker: bgAware(sideBySideAddedMarker),
      sideBySideRemovedMarker: bgAware(sideBySideRemovedMarker),
      sideBySideContextMarker: bgAware(sideBySideContextMarker),
      inlineAddedHighlight: bgAware(inlineAddedHighlight),
      inlineRemovedHighlight: bgAware(inlineRemovedHighlight),
      selectedCommentLine: bgAware(selectedCommentLine),
      selectedCommentGutter: bgAware(selectedCommentGutter),
      commentRangeLine: bgAware(commentRangeLine),
      commentRangeGutter: bgAware(commentRangeGutter),
      commentThreadLine: bgAware(commentThreadLine),
      commentThreadGutter: bgAware(commentThreadGutter),
    );
  }
}

/// The type of a parsed diff line.
enum DiffLineType {
  /// File header line (diff --git, index, ---/+++).
  fileHeader,

  /// Hunk header line (@@ ... @@).
  hunkHeader,

  /// Added line (+).
  added,

  /// Removed line (-).
  removed,

  /// Context (unchanged) line.
  context,

  /// Empty/separator line.
  empty,
}

/// Which side of a pull-request diff a commentable line belongs to.
enum DiffCommentSide {
  /// The old/deleted side of the diff.
  left,

  /// The new/added side of the diff.
  right;

  /// GitHub's review-comment API literal for this side.
  String get githubApiValue => switch (this) {
    DiffCommentSide.left => 'LEFT',
    DiffCommentSide.right => 'RIGHT',
  };
}

/// The kind of diff line represented by a [DiffCommentAnchor].
enum DiffCommentKind {
  /// Added line on the new side.
  addition,

  /// Deleted line on the old side.
  deletion,

  /// Unchanged context line, commentable on the new side.
  context,
}

/// The visual role of a commentable diff line.
enum DiffCommentLineHighlightKind {
  /// A line with an existing review thread.
  thread,

  /// A line inside the currently selected multi-line comment range.
  range,

  /// The active keyboard/mouse-selected line.
  selected,
}

/// Stable identity for a commentable line in a pull-request diff.
class DiffCommentLineKey {
  /// Creates a stable diff comment line key.
  const DiffCommentLineKey({
    required this.path,
    required this.line,
    required this.side,
  });

  /// Creates a key from a rendered comment anchor.
  factory DiffCommentLineKey.fromAnchor(DiffCommentAnchor anchor) {
    return DiffCommentLineKey(
      path: anchor.path,
      line: anchor.line,
      side: anchor.side,
    );
  }

  /// File path in the pull request diff.
  final String path;

  /// Blob line number on [side].
  final int line;

  /// Diff side for [line].
  final DiffCommentSide side;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DiffCommentLineKey &&
            path == other.path &&
            line == other.line &&
            side == other.side;
  }

  @override
  int get hashCode => Object.hash(path, line, side);
}

/// A visual highlight request for a commentable diff line.
class DiffCommentLineHighlight {
  /// Creates a diff comment line highlight.
  const DiffCommentLineHighlight({required this.key, required this.kind});

  /// Creates a selected-line highlight from [anchor].
  factory DiffCommentLineHighlight.selected(DiffCommentAnchor anchor) {
    return DiffCommentLineHighlight(
      key: anchor.key,
      kind: DiffCommentLineHighlightKind.selected,
    );
  }

  /// Creates a selected-range highlight from [anchor].
  factory DiffCommentLineHighlight.range(DiffCommentAnchor anchor) {
    return DiffCommentLineHighlight(
      key: anchor.key,
      kind: DiffCommentLineHighlightKind.range,
    );
  }

  /// Creates an existing-thread highlight from [anchor].
  factory DiffCommentLineHighlight.thread(DiffCommentAnchor anchor) {
    return DiffCommentLineHighlight(
      key: anchor.key,
      kind: DiffCommentLineHighlightKind.thread,
    );
  }

  /// Comment line identity.
  final DiffCommentLineKey key;

  /// Highlight role.
  final DiffCommentLineHighlightKind kind;
}

/// A commentable position in the rendered diff.
class DiffCommentAnchor {
  /// Creates a diff comment anchor.
  const DiffCommentAnchor({
    required this.path,
    required this.line,
    required this.side,
    required this.kind,
    required this.renderLine,
    required this.content,
    int? renderLineEnd,
  }) : renderLineEnd = renderLineEnd ?? renderLine + 1;

  /// File path for GitHub's review-comment API.
  final String path;

  /// Blob line number on [side].
  final int line;

  /// Diff side for [line].
  final DiffCommentSide side;

  /// Type of source diff line.
  final DiffCommentKind kind;

  /// First rendered row occupied by this source line.
  final int renderLine;

  /// First rendered row after this source line.
  final int renderLineEnd;

  /// Source line content without the diff marker.
  final String content;

  /// Stable identity for this anchor.
  DiffCommentLineKey get key => DiffCommentLineKey.fromAnchor(this);

  /// Compact label for UI hints.
  String get label {
    final marker = side == DiffCommentSide.right ? '+' : '-';
    return '$path:$marker$line';
  }
}

/// A single parsed line from a unified diff.
class DiffLine {
  /// Creates a new diff line.
  const DiffLine({
    required this.type,
    required this.content,
    this.oldLineNumber,
    this.newLineNumber,
  });

  /// The type of this diff line.
  final DiffLineType type;

  /// The raw content of this line.
  final String content;

  /// The line number in the old file (null for added lines / headers).
  final int? oldLineNumber;

  /// The line number in the new file (null for removed lines / headers).
  final int? newLineNumber;
}

/// A file entry in a parsed diff.
class DiffFile {
  /// Creates a new diff file entry.
  DiffFile({required this.oldPath, required this.newPath, required this.lines});

  /// Path of the old file (before changes).
  final String oldPath;

  /// Path of the new file (after changes).
  final String newPath;

  /// All parsed diff lines for this file.
  final List<DiffLine> lines;

  /// Number of added lines.
  late final int additions = lines
      .where((l) => l.type == DiffLineType.added)
      .length;

  /// Number of removed lines.
  late final int deletions = lines
      .where((l) => l.type == DiffLineType.removed)
      .length;
}

/// A git diff viewer bubble.
///
/// Parses unified diff text and renders it with syntax highlighting, line
/// numbers, and scrollable navigation via an embedded [ViewportModel].
///
/// ## Example
///
/// ```dart
/// final diff = GitDiffModel(width: 80, height: 24);
/// final loaded = diff.setDiff(rawDiffString);
///
/// // In update:
/// final (newDiff, cmd) = loaded.update(msg);
///
/// // In view:
/// print(loaded.view());
/// ```
class GitDiffModel extends ViewComponent {
  /// Creates a new git diff model.
  GitDiffModel({
    this.width = 80,
    this.height = 24,
    this.showLineNumbers = true,
    this.wrapLines = true,
    this.zeroPadLineNumbers = false,
    this.viewMode = DiffViewMode.unified,
    this.horizontalOffset = 0,
    DiffStyles? styles,
    GitDiffKeyMap? keyMap,
    ViewportModel? viewport,
    List<DiffFile>? files,
    List<String>? renderedLines,
    List<DiffCommentLineHighlight>? commentHighlights,
  }) : styles = styles ?? DiffStyles(),
       keyMap = keyMap ?? GitDiffKeyMap(),
       _files = files ?? const [],
       _renderedLines = renderedLines ?? const [],
       commentHighlights = commentHighlights ?? const [],
       _viewport = viewport ?? ViewportModel(width: width, height: height);

  /// Width of the diff viewer in columns.
  final int width;

  /// Height of the diff viewer in rows.
  final int height;

  /// Whether to display line numbers in the gutter.
  final bool showLineNumbers;

  /// Whether to wrap long lines that exceed the viewport width.
  ///
  /// When enabled, lines that are wider than the available content area are
  /// split into multiple display lines. Continuation lines are indented to
  /// align past the gutter (line number + marker columns).
  final bool wrapLines;

  /// Whether to zero-pad line numbers (e.g. `0001`) instead of space-padding
  /// (e.g. `   1`).
  ///
  /// Defaults to `false` (space-padded, right-aligned).
  final bool zeroPadLineNumbers;

  /// Unified or side-by-side display mode.
  final DiffViewMode viewMode;

  /// Horizontal scroll offset for side-by-side mode content.
  ///
  /// When [wrapLines] is false and [viewMode] is [DiffViewMode.sideBySide],
  /// this offset shifts the visible content window within each panel. For
  /// unified and pretty modes, the viewport's own xOffset handles horizontal
  /// scrolling instead.
  final int horizontalOffset;

  /// The styles used for rendering.
  final DiffStyles styles;

  /// Visual highlights applied to commentable diff lines.
  final List<DiffCommentLineHighlight> commentHighlights;

  /// Key bindings for diff viewer actions.
  final GitDiffKeyMap keyMap;

  /// The parsed file entries.
  final List<DiffFile> _files;

  /// Pre-rendered styled lines fed into the viewport.
  final List<String> _renderedLines;

  /// The underlying viewport for scrolling.
  final ViewportModel _viewport;

  /// The parsed diff files.
  List<DiffFile> get files => _files;

  /// The embedded viewport model (exposed for widget wrapping).
  ViewportModel get viewport => _viewport;

  /// Total number of additions across all files.
  late final int totalAdditions = _files.fold(0, (sum, f) => sum + f.additions);

  /// Total number of deletions across all files.
  late final int totalDeletions = _files.fold(0, (sum, f) => sum + f.deletions);

  /// Commentable anchors in the current rendered diff.
  ///
  /// The [DiffCommentAnchor.renderLine] values match the model's current
  /// [viewMode], [wrapLines], [width], and line-number settings.
  late final List<DiffCommentAnchor> commentAnchors = List.unmodifiable(
    _computeCommentAnchors(_files),
  );

  late final Map<DiffCommentLineKey, DiffCommentLineHighlightKind>
  _commentHighlightByKey = _buildCommentHighlightMap(commentHighlights);

  /// Returns the nearest comment anchor at or after [renderLine].
  DiffCommentAnchor? nearestCommentAnchor(int renderLine) {
    if (commentAnchors.isEmpty) return null;
    final index = nearestCommentAnchorIndex(renderLine);
    return commentAnchors[index];
  }

  /// Returns the nearest comment-anchor index at or after [renderLine].
  int nearestCommentAnchorIndex(int renderLine) {
    if (commentAnchors.isEmpty) return 0;
    final index = commentAnchors.indexWhere(
      (anchor) => anchor.renderLine >= renderLine,
    );
    return index >= 0 ? index : commentAnchors.length - 1;
  }

  /// Returns the comment anchor occupying [renderLine], optionally preferring
  /// the requested [side] when multiple anchors share the same rendered row.
  DiffCommentAnchor? commentAnchorAt(int renderLine, {DiffCommentSide? side}) {
    if (commentAnchors.isEmpty) return null;
    DiffCommentAnchor? fallback;
    for (final anchor in commentAnchors) {
      if (renderLine < anchor.renderLine) break;
      if (renderLine >= anchor.renderLineEnd) continue;
      fallback ??= anchor;
      if (side == null || anchor.side == side) return anchor;
    }
    return fallback;
  }

  /// Returns the index of the comment anchor occupying [renderLine].
  int? commentAnchorIndexAt(int renderLine, {DiffCommentSide? side}) {
    if (commentAnchors.isEmpty) return null;
    int? fallback;
    for (var index = 0; index < commentAnchors.length; index++) {
      final anchor = commentAnchors[index];
      if (renderLine < anchor.renderLine) break;
      if (renderLine >= anchor.renderLineEnd) continue;
      fallback ??= index;
      if (side == null || anchor.side == side) return index;
    }
    return fallback;
  }

  /// Creates a copy with the given fields replaced.
  GitDiffModel copyWith({
    int? width,
    int? height,
    bool? showLineNumbers,
    bool? wrapLines,
    bool? zeroPadLineNumbers,
    DiffViewMode? viewMode,
    int? horizontalOffset,
    DiffStyles? styles,
    GitDiffKeyMap? keyMap,
    ViewportModel? viewport,
    List<DiffFile>? files,
    List<String>? renderedLines,
    List<DiffCommentLineHighlight>? commentHighlights,
  }) {
    return GitDiffModel(
      width: width ?? this.width,
      height: height ?? this.height,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wrapLines: wrapLines ?? this.wrapLines,
      zeroPadLineNumbers: zeroPadLineNumbers ?? this.zeroPadLineNumbers,
      viewMode: viewMode ?? this.viewMode,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
      styles: styles ?? this.styles,
      keyMap: keyMap ?? this.keyMap,
      viewport: viewport ?? _viewport,
      files: files ?? _files,
      renderedLines: renderedLines ?? _renderedLines,
      commentHighlights: commentHighlights ?? this.commentHighlights,
    );
  }

  /// Sets the raw unified diff content and parses it.
  ///
  /// Returns a new model with parsed and rendered diff content loaded into
  /// the viewport.
  GitDiffModel setDiff(String rawDiff) {
    final parsedFiles = _parseDiff(rawDiff);
    final rendered = _renderLines(parsedFiles);
    final newViewport = _viewport.copyWith(
      width: width,
      height: height,
      lines: rendered,
    );
    return copyWith(
      files: parsedFiles,
      horizontalOffset: 0,
      renderedLines: rendered,
      viewport: newViewport,
    );
  }

  /// Re-renders the existing parsed files with the current configuration.
  ///
  /// Use this after changing display options (viewMode, showLineNumbers,
  /// wrapLines, styles) via [copyWith] to rebuild the rendered lines and
  /// viewport without re-parsing the diff.
  GitDiffModel rerender() {
    if (_files.isEmpty) return this;
    final rendered = _renderLines(_files);
    final newViewport = _viewport.copyWith(
      width: width,
      height: height,
      lines: rendered,
    );
    return copyWith(renderedLines: rendered, viewport: newViewport);
  }

  @override
  Cmd? init() => null;

  @override
  (GitDiffModel, Cmd?) update(Msg msg) {
    // Intercept view-mode cycling key before delegating to the viewport.
    if (msg is KeyMsg && keyMatches(msg.key, [keyMap.cycleViewMode])) {
      final modes = DiffViewMode.values;
      final nextMode = modes[(viewMode.index + 1) % modes.length];
      // Reset horizontal offset when switching view modes.
      final rendered = _renderLines(_files, overrideViewMode: nextMode);
      final newViewport = _viewport.copyWith(
        width: width,
        height: height,
        lines: rendered,
      );
      return (
        copyWith(
          viewMode: nextMode,
          horizontalOffset: 0,
          renderedLines: rendered,
          viewport: newViewport,
        ),
        null,
      );
    }

    // In side-by-side mode with wrapping disabled, intercept left/right keys
    // to apply horizontal scrolling within each panel.  The viewport's own
    // xOffset can't help here because each composed line contains two fixed-
    // width panels separated by │ — scrolling the whole line would eat into
    // the gutter rather than scrolling panel content.
    if (!wrapLines && viewMode == DiffViewMode.sideBySide && msg is KeyMsg) {
      final vkm = _viewport.keyMap;
      final step = _viewport.horizontalStep;
      if (step > 0) {
        int? newOffset;
        if (keyMatches(msg.key, [vkm.left])) {
          newOffset = (horizontalOffset - step).clamp(0, horizontalOffset);
        } else if (keyMatches(msg.key, [vkm.right])) {
          newOffset = horizontalOffset + step;
        }
        if (newOffset != null && newOffset != horizontalOffset) {
          // Create model with new offset so _renderLines reads the right value.
          final updated = copyWith(horizontalOffset: newOffset);
          final rendered = updated._renderLines(_files);
          final newViewport = _viewport.copyWith(
            width: width,
            height: height,
            lines: rendered,
          );
          return (
            updated.copyWith(renderedLines: rendered, viewport: newViewport),
            null,
          );
        }
        // If we matched left/right but offset didn't change (clamped at 0),
        // consume the key to avoid the viewport scrolling the whole line.
        if (newOffset != null) return (this, null);
      }
    }

    final (newViewport, cmd) = _viewport.update(msg);
    if (identical(newViewport, _viewport)) {
      return (this, cmd);
    }
    return (copyWith(viewport: newViewport), cmd);
  }

  @override
  String view() => _viewport.view();

  // ───────────────────────────────────────────────────────────────────────────
  // Parsing
  // ───────────────────────────────────────────────────────────────────────────

  /// Parses a unified diff string into a list of [DiffFile] entries.
  List<DiffFile> _parseDiff(String raw) {
    if (raw.trim().isEmpty) return [];

    final lines = raw.split('\n');
    final files = <DiffFile>[];

    var currentOldPath = '';
    var currentNewPath = '';
    var currentLines = <DiffLine>[];
    var inFile = false;

    var oldLineNum = 0;
    var newLineNum = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // New file header
      if (line.startsWith('diff --git')) {
        // Save previous file if any
        if (inFile && currentLines.isNotEmpty) {
          files.add(
            DiffFile(
              oldPath: currentOldPath,
              newPath: currentNewPath,
              lines: List.unmodifiable(currentLines),
            ),
          );
        }
        currentLines = [];
        inFile = true;

        // Extract paths from "diff --git a/path b/path"
        final parts = line.split(' ');
        if (parts.length >= 4) {
          currentOldPath = parts[2].startsWith('a/')
              ? parts[2].substring(2)
              : parts[2];
          currentNewPath = parts[3].startsWith('b/')
              ? parts[3].substring(2)
              : parts[3];
        }
        currentLines.add(
          DiffLine(type: DiffLineType.fileHeader, content: line),
        );
        continue;
      }

      // File metadata lines (index, mode, etc.)
      if (inFile &&
          (line.startsWith('index ') ||
              line.startsWith('old mode') ||
              line.startsWith('new mode') ||
              line.startsWith('new file mode') ||
              line.startsWith('deleted file mode') ||
              line.startsWith('similarity index') ||
              line.startsWith('rename from') ||
              line.startsWith('rename to') ||
              line.startsWith('copy from') ||
              line.startsWith('copy to') ||
              line.startsWith('Binary files'))) {
        currentLines.add(
          DiffLine(type: DiffLineType.fileHeader, content: line),
        );
        continue;
      }

      // Old file path
      if (line.startsWith('--- ')) {
        currentLines.add(
          DiffLine(type: DiffLineType.fileHeader, content: line),
        );
        continue;
      }

      // New file path
      if (line.startsWith('+++ ')) {
        currentLines.add(
          DiffLine(type: DiffLineType.fileHeader, content: line),
        );
        continue;
      }

      // Hunk header
      if (line.startsWith('@@ ')) {
        final hunkMatch = RegExp(
          r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@(.*)$',
        ).firstMatch(line);
        if (hunkMatch != null) {
          oldLineNum = int.tryParse(hunkMatch.group(1) ?? '') ?? 0;
          newLineNum = int.tryParse(hunkMatch.group(2) ?? '') ?? 0;
        }
        currentLines.add(
          DiffLine(type: DiffLineType.hunkHeader, content: line),
        );
        continue;
      }

      // Diff content lines
      if (inFile) {
        if (line.startsWith('+')) {
          currentLines.add(
            DiffLine(
              type: DiffLineType.added,
              content: line.length > 1 ? line.substring(1) : '',
              newLineNumber: newLineNum,
            ),
          );
          newLineNum++;
        } else if (line.startsWith('-')) {
          currentLines.add(
            DiffLine(
              type: DiffLineType.removed,
              content: line.length > 1 ? line.substring(1) : '',
              oldLineNumber: oldLineNum,
            ),
          );
          oldLineNum++;
        } else if (line.startsWith(' ')) {
          currentLines.add(
            DiffLine(
              type: DiffLineType.context,
              content: line.length > 1 ? line.substring(1) : '',
              oldLineNumber: oldLineNum,
              newLineNumber: newLineNum,
            ),
          );
          oldLineNum++;
          newLineNum++;
        } else if (line.startsWith('\\')) {
          // "\ No newline at end of file" — treat as context
          currentLines.add(DiffLine(type: DiffLineType.context, content: line));
        } else if (line.isEmpty) {
          currentLines.add(
            const DiffLine(type: DiffLineType.empty, content: ''),
          );
        }
      }
    }

    // Save last file
    if (inFile && currentLines.isNotEmpty) {
      files.add(
        DiffFile(
          oldPath: currentOldPath,
          newPath: currentNewPath,
          lines: List.unmodifiable(currentLines),
        ),
      );
    }

    return files;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Rendering
  // ───────────────────────────────────────────────────────────────────────────

  /// Computes the maximum line number across all files for consistent padding.
  int _computeMaxLineNumber(List<DiffFile> files) {
    var max = 0;
    for (final file in files) {
      for (final line in file.lines) {
        if (line.oldLineNumber != null && line.oldLineNumber! > max) {
          max = line.oldLineNumber!;
        }
        if (line.newLineNumber != null && line.newLineNumber! > max) {
          max = line.newLineNumber!;
        }
      }
    }
    return max;
  }

  List<DiffCommentAnchor> _computeCommentAnchors(List<DiffFile> files) {
    if (files.isEmpty) return const <DiffCommentAnchor>[];
    return switch (viewMode) {
      DiffViewMode.sideBySide => _computeSideBySideCommentAnchors(files),
      DiffViewMode.pretty => _computePrettyCommentAnchors(files),
      DiffViewMode.unified => _computeUnifiedCommentAnchors(files),
    };
  }

  List<DiffCommentAnchor> _computeUnifiedCommentAnchors(List<DiffFile> files) {
    final maxLineNum = _computeMaxLineNumber(files);
    final numWidth = '$maxLineNum'.length < 4 ? 4 : '$maxLineNum'.length;
    final contentWidth = _unifiedContentWidth(numWidth);
    final anchors = <DiffCommentAnchor>[];
    var renderLine = 0;

    for (var fileIndex = 0; fileIndex < files.length; fileIndex++) {
      final file = files[fileIndex];
      if (fileIndex > 0) renderLine++;
      for (final line in file.lines) {
        final height = _renderedUnifiedLineHeight(line, contentWidth);
        final anchor = _anchorForLine(
          file,
          line,
          renderLine,
          renderLineEnd: renderLine + height,
        );
        if (anchor != null) anchors.add(anchor);
        renderLine += height;
      }
    }

    return anchors;
  }

  List<DiffCommentAnchor> _computePrettyCommentAnchors(List<DiffFile> files) {
    final maxLineNum = _computeMaxLineNumber(files);
    final numWidth = '$maxLineNum'.length < 4 ? 4 : '$maxLineNum'.length;
    final contentWidth = _prettyContentWidth(numWidth);
    final anchors = <DiffCommentAnchor>[];
    var renderLine = 0;

    for (var fileIndex = 0; fileIndex < files.length; fileIndex++) {
      final file = files[fileIndex];
      if (fileIndex > 0) renderLine++;
      renderLine++; // Pretty file header.

      var previousWasHunk = false;
      for (final line in file.lines) {
        if (line.type == DiffLineType.fileHeader) continue;
        if (line.type == DiffLineType.hunkHeader) {
          if (!previousWasHunk) renderLine++;
          previousWasHunk = true;
          continue;
        }
        previousWasHunk = false;
        if (line.type == DiffLineType.empty) {
          renderLine++;
          continue;
        }

        final height = _renderedLineHeight(line.content, contentWidth);
        final anchor = _anchorForLine(
          file,
          line,
          renderLine,
          renderLineEnd: renderLine + height,
        );
        if (anchor != null) anchors.add(anchor);
        renderLine += height;
      }
    }

    return anchors;
  }

  List<DiffCommentAnchor> _computeSideBySideCommentAnchors(
    List<DiffFile> files,
  ) {
    final maxLineNum = _computeMaxLineNumber(files);
    final numWidth = '$maxLineNum'.length < 4 ? 4 : '$maxLineNum'.length;
    const separatorWidth = 1;
    const markerWidth = 2;
    final lineNumWidth = showLineNumbers ? numWidth + 1 : 0;
    final gutterWidth = lineNumWidth + markerWidth;
    final availableWidth = width - separatorWidth;
    final leftPanelWidth = availableWidth ~/ 2;
    final rightPanelWidth = availableWidth - leftPanelWidth;
    final leftContentWidth = leftPanelWidth - gutterWidth;
    final rightContentWidth = rightPanelWidth - gutterWidth;

    if (leftContentWidth <= 0 || rightContentWidth <= 0) {
      return _computeUnifiedCommentAnchors(files);
    }

    final anchors = <DiffCommentAnchor>[];
    var renderLine = 0;

    for (var fileIndex = 0; fileIndex < files.length; fileIndex++) {
      final file = files[fileIndex];
      if (fileIndex > 0) renderLine++;
      renderLine++; // Side-by-side file header.

      final lines = file.lines;
      var index = 0;
      while (index < lines.length) {
        final line = lines[index];
        if (line.type == DiffLineType.fileHeader) {
          index++;
          continue;
        }
        if (line.type == DiffLineType.hunkHeader ||
            line.type == DiffLineType.empty) {
          renderLine++;
          index++;
          continue;
        }
        if (line.type == DiffLineType.context) {
          final height = _renderedLineHeight(line.content, rightContentWidth);
          final leftAnchor = _anchorForLine(
            file,
            line,
            renderLine,
            side: DiffCommentSide.left,
            renderLineEnd: renderLine + height,
          );
          if (leftAnchor != null) anchors.add(leftAnchor);
          final rightAnchor = _anchorForLine(
            file,
            line,
            renderLine,
            side: DiffCommentSide.right,
            renderLineEnd: renderLine + height,
          );
          if (rightAnchor != null) anchors.add(rightAnchor);
          renderLine += height;
          index++;
          continue;
        }

        final removedLines = <DiffLine>[];
        final addedLines = <DiffLine>[];
        while (index < lines.length &&
            lines[index].type == DiffLineType.removed) {
          removedLines.add(lines[index]);
          index++;
        }
        while (index < lines.length &&
            lines[index].type == DiffLineType.added) {
          addedLines.add(lines[index]);
          index++;
        }

        final pairCount = removedLines.length > addedLines.length
            ? removedLines.length
            : addedLines.length;
        for (var pairIndex = 0; pairIndex < pairCount; pairIndex++) {
          final removed = pairIndex < removedLines.length
              ? removedLines[pairIndex]
              : null;
          final added = pairIndex < addedLines.length
              ? addedLines[pairIndex]
              : null;
          final leftHeight = removed == null
              ? 1
              : _renderedLineHeight(removed.content, leftContentWidth);
          final rightHeight = added == null
              ? 1
              : _renderedLineHeight(added.content, rightContentWidth);
          if (removed != null) {
            final anchor = _anchorForLine(
              file,
              removed,
              renderLine,
              renderLineEnd: renderLine + leftHeight,
            );
            if (anchor != null) anchors.add(anchor);
          }
          if (added != null) {
            final anchor = _anchorForLine(
              file,
              added,
              renderLine,
              renderLineEnd: renderLine + rightHeight,
            );
            if (anchor != null) anchors.add(anchor);
          }
          renderLine += leftHeight > rightHeight ? leftHeight : rightHeight;
        }
      }
    }

    return anchors;
  }

  DiffCommentAnchor? _anchorForLine(
    DiffFile file,
    DiffLine line,
    int renderLine, {
    DiffCommentSide? side,
    required int renderLineEnd,
  }) {
    return switch (line.type) {
      DiffLineType.added when line.newLineNumber != null => DiffCommentAnchor(
        path: _commentPath(file, DiffCommentSide.right),
        line: line.newLineNumber!,
        side: DiffCommentSide.right,
        kind: DiffCommentKind.addition,
        renderLine: renderLine,
        renderLineEnd: renderLineEnd,
        content: line.content,
      ),
      DiffLineType.removed when line.oldLineNumber != null => DiffCommentAnchor(
        path: _commentPath(file, DiffCommentSide.left),
        line: line.oldLineNumber!,
        side: DiffCommentSide.left,
        kind: DiffCommentKind.deletion,
        renderLine: renderLine,
        renderLineEnd: renderLineEnd,
        content: line.content,
      ),
      DiffLineType.context
          when (side == DiffCommentSide.left && line.oldLineNumber != null) =>
        DiffCommentAnchor(
          path: _commentPath(file, DiffCommentSide.left),
          line: line.oldLineNumber!,
          side: DiffCommentSide.left,
          kind: DiffCommentKind.context,
          renderLine: renderLine,
          renderLineEnd: renderLineEnd,
          content: line.content,
        ),
      DiffLineType.context when line.newLineNumber != null => DiffCommentAnchor(
        path: _commentPath(file, DiffCommentSide.right),
        line: line.newLineNumber!,
        side: DiffCommentSide.right,
        kind: DiffCommentKind.context,
        renderLine: renderLine,
        renderLineEnd: renderLineEnd,
        content: line.content,
      ),
      _ => null,
    };
  }

  Map<DiffCommentLineKey, DiffCommentLineHighlightKind>
  _buildCommentHighlightMap(List<DiffCommentLineHighlight> highlights) {
    if (highlights.isEmpty) {
      return const <DiffCommentLineKey, DiffCommentLineHighlightKind>{};
    }
    final result = <DiffCommentLineKey, DiffCommentLineHighlightKind>{};
    for (final highlight in highlights) {
      final current = result[highlight.key];
      if (current == null || highlight.kind.index >= current.index) {
        result[highlight.key] = highlight.kind;
      }
    }
    return result;
  }

  DiffCommentLineKey? _lineKeyForLine(
    DiffFile file,
    DiffLine line, {
    DiffCommentSide? side,
  }) {
    return switch (line.type) {
      DiffLineType.added when line.newLineNumber != null => DiffCommentLineKey(
        path: _commentPath(file, DiffCommentSide.right),
        line: line.newLineNumber!,
        side: DiffCommentSide.right,
      ),
      DiffLineType.removed when line.oldLineNumber != null =>
        DiffCommentLineKey(
          path: _commentPath(file, DiffCommentSide.left),
          line: line.oldLineNumber!,
          side: DiffCommentSide.left,
        ),
      DiffLineType.context
          when side == DiffCommentSide.left && line.oldLineNumber != null =>
        DiffCommentLineKey(
          path: _commentPath(file, DiffCommentSide.left),
          line: line.oldLineNumber!,
          side: DiffCommentSide.left,
        ),
      DiffLineType.context when line.newLineNumber != null =>
        DiffCommentLineKey(
          path: _commentPath(file, DiffCommentSide.right),
          line: line.newLineNumber!,
          side: DiffCommentSide.right,
        ),
      _ => null,
    };
  }

  DiffCommentLineHighlightKind? _highlightForLine(
    DiffFile file,
    DiffLine line, {
    DiffCommentSide? side,
  }) {
    final key = _lineKeyForLine(file, line, side: side);
    return key == null ? null : _commentHighlightByKey[key];
  }

  Style _contentStyleWithHighlight(
    Style base,
    DiffCommentLineHighlightKind? highlight,
  ) {
    final overlay = switch (highlight) {
      DiffCommentLineHighlightKind.selected => styles.selectedCommentLine,
      DiffCommentLineHighlightKind.range => styles.commentRangeLine,
      DiffCommentLineHighlightKind.thread => styles.commentThreadLine,
      null => null,
    };
    if (overlay == null) return base;
    return base.copy()..inherit(overlay);
  }

  Style _gutterStyleWithHighlight(
    Style base,
    DiffCommentLineHighlightKind? highlight,
  ) {
    final overlay = switch (highlight) {
      DiffCommentLineHighlightKind.selected => styles.selectedCommentGutter,
      DiffCommentLineHighlightKind.range => styles.commentRangeGutter,
      DiffCommentLineHighlightKind.thread => styles.commentThreadGutter,
      null => null,
    };
    if (overlay == null) return base;
    return base.copy()..inherit(overlay);
  }

  String _commentPath(DiffFile file, DiffCommentSide side) {
    final path = side == DiffCommentSide.left ? file.oldPath : file.newPath;
    if (path.isNotEmpty && path != '/dev/null') return path;
    return side == DiffCommentSide.left ? file.newPath : file.oldPath;
  }

  int _unifiedContentWidth(int numWidth) {
    final lineNumWidth = showLineNumbers ? numWidth + 1 : 0;
    const gutterCharWidth = 2;
    return width - lineNumWidth - gutterCharWidth;
  }

  int _prettyContentWidth(int numWidth) {
    final lineNumWidth = showLineNumbers ? numWidth + 1 : 0;
    const markerWidth = 3;
    return width - lineNumWidth - markerWidth;
  }

  int _renderedLineHeight(String text, int contentWidth) {
    if (!wrapLines || contentWidth <= 0 || text.length <= contentWidth) {
      return 1;
    }
    return (text.length / contentWidth).ceil();
  }

  int _renderedUnifiedLineHeight(DiffLine line, int contentWidth) {
    if (line.type == DiffLineType.fileHeader ||
        line.type == DiffLineType.hunkHeader ||
        line.type == DiffLineType.empty ||
        line.content.startsWith('\\')) {
      return 1;
    }
    return _renderedLineHeight(line.content, contentWidth);
  }

  /// Renders all parsed diff files into styled string lines.
  List<String> _renderLines(
    List<DiffFile> files, {
    DiffViewMode? overrideViewMode,
  }) {
    final mode = overrideViewMode ?? viewMode;
    if (mode == DiffViewMode.pretty) {
      return _renderLinesPretty(files);
    }
    if (mode == DiffViewMode.sideBySide) {
      return _renderLinesSideBySide(files);
    }

    final numWidth = '${_computeMaxLineNumber(files)}'.length;
    final effectiveNumWidth = numWidth < 4 ? 4 : numWidth;
    final result = <String>[];

    for (var fi = 0; fi < files.length; fi++) {
      final file = files[fi];

      // Separator between files
      if (fi > 0) {
        result.add('');
      }

      for (final line in file.lines) {
        result.addAll(_renderLine(file, line, effectiveNumWidth));
      }
    }

    return result;
  }

  /// Renders a single diff line with appropriate styling and gutter.
  ///
  /// Returns a list of rendered strings. When [wrapLines] is enabled and the
  /// content exceeds the available width, continuation lines are generated
  /// with blank padding in the gutter area.
  List<String> _renderLine(DiffFile file, DiffLine line, int numWidth) {
    switch (line.type) {
      case DiffLineType.fileHeader:
        return [styles.fileHeader.render(line.content)];

      case DiffLineType.hunkHeader:
        return [styles.hunkHeader.render(line.content)];

      case DiffLineType.added:
        final highlight = _highlightForLine(file, line);
        final gutter = _gutterStyleWithHighlight(
          styles.addedGutter,
          highlight,
        ).render('+');
        final lineNums = _formatLineNumbers(null, line.newLineNumber, numWidth);
        return _wrapUnifiedLine(
          line.content,
          lineNums,
          gutter,
          _contentStyleWithHighlight(styles.addedLine, highlight),
          numWidth,
        );

      case DiffLineType.removed:
        final highlight = _highlightForLine(file, line);
        final gutter = _gutterStyleWithHighlight(
          styles.removedGutter,
          highlight,
        ).render('-');
        final lineNums = _formatLineNumbers(line.oldLineNumber, null, numWidth);
        return _wrapUnifiedLine(
          line.content,
          lineNums,
          gutter,
          _contentStyleWithHighlight(styles.removedLine, highlight),
          numWidth,
        );

      case DiffLineType.context:
        if (line.content.startsWith('\\')) {
          return [styles.contextLine.render(line.content)];
        }
        final highlight = _highlightForLine(file, line);
        final gutter = _gutterStyleWithHighlight(
          styles.contextGutter,
          highlight,
        ).render(' ');
        final lineNums = _formatLineNumbers(
          line.oldLineNumber,
          line.newLineNumber,
          numWidth,
        );
        return _wrapUnifiedLine(
          line.content,
          lineNums,
          gutter,
          _contentStyleWithHighlight(styles.contextLine, highlight),
          numWidth,
        );

      case DiffLineType.empty:
        return [''];
    }
  }

  /// Wraps a unified-mode line, producing continuation lines if needed.
  List<String> _wrapUnifiedLine(
    String text,
    String lineNums,
    String gutter,
    Style contentStyle,
    int numWidth,
  ) {
    // Compute prefix width:
    // line numbers = (numWidth + space) when shown, else 0
    // gutter = marker + space = 2
    final lineNumWidth = showLineNumbers ? numWidth + 1 : 0;
    const gutterCharWidth = 2; // marker char + trailing space
    final prefixWidth = lineNumWidth + gutterCharWidth;
    final contentWidth = width - prefixWidth;

    if (!wrapLines || contentWidth <= 0 || text.length <= contentWidth) {
      final content = contentStyle.render(text);
      return ['$lineNums$gutter $content'];
    }

    final result = <String>[];
    var offset = 0;

    while (offset < text.length) {
      final end = (offset + contentWidth).clamp(0, text.length);
      final chunk = text.substring(offset, end);

      if (offset == 0) {
        result.add('$lineNums$gutter ${contentStyle.render(chunk)}');
      } else {
        // Blank line number area + blank gutter
        final blankNums = showLineNumbers
            ? styles.lineNumber.render('${' ' * numWidth} ')
            : '';
        final blankGutter = '  '; // 2 spaces matching "marker + space"
        result.add('$blankNums$blankGutter${contentStyle.render(chunk)}');
      }

      offset = end;
    }

    return result;
  }

  /// Formats the line number for the gutter (single column).
  ///
  /// Shows one line number per row: for added lines the new number, for
  /// removed lines the old number, and for context lines whichever is
  /// available (preferring new). Uses [numWidth] for consistent
  /// right-aligned layout based on the maximum line number across all files.
  /// Padding uses '0' when [zeroPadLineNumbers] is true, spaces otherwise.
  String _formatLineNumbers(int? oldNum, int? newNum, int numWidth) {
    if (!showLineNumbers) return '';

    final num = newNum ?? oldNum;
    final padChar = zeroPadLineNumbers ? '0' : ' ';
    final formatted = num != null
        ? '$num'.padLeft(numWidth, padChar)
        : ' ' * numWidth;

    return styles.lineNumber.render('$formatted ');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Pretty mode rendering
  // ───────────────────────────────────────────────────────────────────────────

  /// Renders all parsed diff files in pretty mode.
  ///
  /// Pretty mode shows clean file headers (← Edit path), hides raw diff
  /// metadata and hunk headers, uses single-column line numbers, and applies
  /// full-width background highlighting.
  List<String> _renderLinesPretty(List<DiffFile> files) {
    final maxLineNum = _computeMaxLineNumber(files);
    final numWidth = '$maxLineNum'.length;
    final effectiveNumWidth = numWidth < 4 ? 4 : numWidth;
    final result = <String>[];

    for (var fi = 0; fi < files.length; fi++) {
      final file = files[fi];

      // Separator between files
      if (fi > 0) {
        result.add('');
      }

      // Pretty file header: "← Edit path/to/file.dart"
      final displayPath = file.newPath.isNotEmpty ? file.newPath : file.oldPath;
      result.add(styles.prettyFileHeader.render('\u2190 Edit $displayPath'));

      var previousWasHunk = false;
      for (final line in file.lines) {
        // Skip raw file headers — we already rendered a pretty header.
        if (line.type == DiffLineType.fileHeader) continue;

        // Replace hunk headers with blank separator lines.
        if (line.type == DiffLineType.hunkHeader) {
          // Only add separator if there's content before this hunk
          // (i.e. not the very first hunk).
          if (result.isNotEmpty && !previousWasHunk) {
            result.add('');
          }
          previousWasHunk = true;
          continue;
        }
        previousWasHunk = false;

        if (line.type == DiffLineType.empty) {
          result.add('');
          continue;
        }

        result.addAll(_renderLinePretty(file, line, effectiveNumWidth));
      }
    }

    return result;
  }

  /// Renders a single diff line in pretty mode.
  ///
  /// Uses a single line-number column, +/- gutter markers, and full-width
  /// background highlighting for added and removed lines.
  ///
  /// Returns a list of rendered strings. When [wrapLines] is enabled and the
  /// content exceeds the available width, continuation lines are generated
  /// with blank padding in the gutter area.
  List<String> _renderLinePretty(DiffFile file, DiffLine line, int numWidth) {
    // Determine the line number to show (single column).
    final int? lineNum;
    final Style lineNumStyle;
    final Style lineStyle;
    final String marker;

    switch (line.type) {
      case DiffLineType.added:
        lineNum = line.newLineNumber;
        lineNumStyle = styles.prettyAddedLineNumber;
        lineStyle = styles.prettyAddedLine;
        marker = '+';
      case DiffLineType.removed:
        lineNum = line.oldLineNumber;
        lineNumStyle = styles.prettyRemovedLineNumber;
        lineStyle = styles.prettyRemovedLine;
        marker = '-';
      case DiffLineType.context:
        if (line.content.startsWith('\\')) {
          return [styles.prettyContextLine.render(line.content)];
        }
        lineNum = line.newLineNumber ?? line.oldLineNumber;
        lineNumStyle = styles.prettyContextLineNumber;
        lineStyle = styles.prettyContextLine;
        marker = ' ';
      default:
        return [''];
    }
    final highlight = _highlightForLine(file, line);
    final effectiveLineNumStyle = _gutterStyleWithHighlight(
      lineNumStyle,
      highlight,
    );
    final effectiveLineStyle = _contentStyleWithHighlight(lineStyle, highlight);

    // Format single-column line number, zero-padded or space-padded.
    final padChar = zeroPadLineNumbers ? '0' : ' ';
    final numStr = showLineNumbers
        ? effectiveLineNumStyle.render(
            '${lineNum != null ? '$lineNum'.padLeft(numWidth, padChar) : ' ' * numWidth} ',
          )
        : '';

    // Gutter marker.
    final gutter = effectiveLineStyle.render(' $marker ');

    // Content padded to fill available width for full-width background.
    // Account for line number width + gutter width (3 chars: space+marker+space).
    final gutterWidth = showLineNumbers ? numWidth + 1 : 0; // numWidth + space
    final markerWidth = 3; // space + marker + space
    final contentWidth = width - gutterWidth - markerWidth;

    if (!wrapLines ||
        contentWidth <= 0 ||
        line.content.length <= contentWidth) {
      // No wrapping needed — single line.
      final paddedContent = contentWidth > 0
          ? line.content.padRight(contentWidth)
          : line.content;
      final content = effectiveLineStyle.render(paddedContent);
      return ['$numStr$gutter$content'];
    }

    // Wrap the content into chunks of contentWidth characters.
    final result = <String>[];
    final text = line.content;
    var offset = 0;

    while (offset < text.length) {
      final end = (offset + contentWidth).clamp(0, text.length);
      final chunk = text.substring(offset, end);

      if (offset == 0) {
        // First line: line number + gutter + content.
        final paddedChunk = chunk.padRight(contentWidth);
        result.add('$numStr$gutter${effectiveLineStyle.render(paddedChunk)}');
      } else {
        // Continuation line: blank padding for line number + blank gutter.
        final blankNum = showLineNumbers
            ? effectiveLineNumStyle.render('${' ' * numWidth} ')
            : '';
        final blankGutter = effectiveLineStyle.render(
          '   ',
        ); // 3 spaces matching marker
        final paddedChunk = chunk.padRight(contentWidth);
        result.add(
          '$blankNum$blankGutter${effectiveLineStyle.render(paddedChunk)}',
        );
      }

      offset = end;
    }

    return result;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Side-by-side mode rendering
  // ───────────────────────────────────────────────────────────────────────────

  /// Renders all parsed diff files in side-by-side mode.
  ///
  /// Splits the viewport into two panels: old file on the left, new file on
  /// the right, separated by a thin gap. Added/removed lines are paired
  /// so that a removed line on the left appears next to the corresponding
  /// added line on the right. Each line shows a colored `+`/`-` marker.
  List<String> _renderLinesSideBySide(List<DiffFile> files) {
    final maxLineNum = _computeMaxLineNumber(files);
    final numWidth = '$maxLineNum'.length;
    final effectiveNumWidth = numWidth < 4 ? 4 : numWidth;
    final result = <String>[];

    // Layout: [lineNum space] [marker space] content │ [lineNum space] [marker space] content
    // separator = 1 char: " " (thin gap, no box-drawing character)
    const separatorWidth = 1;
    // marker = 2 chars: marker + space
    const markerWidth = 2;
    final lineNumWidth = showLineNumbers ? effectiveNumWidth + 1 : 0;
    final gutterWidth = lineNumWidth + markerWidth;
    final availableWidth = width - separatorWidth;
    final leftPanelWidth = availableWidth ~/ 2;
    final rightPanelWidth = availableWidth - leftPanelWidth;
    final leftContentWidth = leftPanelWidth - gutterWidth;
    final rightContentWidth = rightPanelWidth - gutterWidth;

    if (leftContentWidth <= 0 || rightContentWidth <= 0) {
      // Too narrow for side-by-side — fall back to unified.
      return _renderLines(files, overrideViewMode: DiffViewMode.unified);
    }

    final separator = styles.sideBySideSeparator.render(' ');

    for (var fi = 0; fi < files.length; fi++) {
      final file = files[fi];

      if (fi > 0) {
        result.add('');
      }

      // File header — use pretty-style "← Edit path" spanning full width.
      final displayPath = file.newPath.isNotEmpty ? file.newPath : file.oldPath;
      result.add(styles.prettyFileHeader.render('\u2190 Edit $displayPath'));

      // Process hunks — pair removed and added lines.
      final lines = file.lines;
      var i = 0;

      while (i < lines.length) {
        final line = lines[i];

        // Skip file headers — we already rendered one.
        if (line.type == DiffLineType.fileHeader) {
          i++;
          continue;
        }

        // Hunk header — render split across both panels.
        if (line.type == DiffLineType.hunkHeader) {
          final hunkMatch = RegExp(
            r'^@@ -(\d+(?:,\d+)?) \+(\d+(?:,\d+)?) @@(.*)$',
          ).firstMatch(line.content);
          if (hunkMatch != null) {
            final oldRange = '-${hunkMatch.group(1)!}';
            final newRange = '+${hunkMatch.group(2)!}';
            final ctx = hunkMatch.group(3)!.trim();
            final leftHunk = ctx.isEmpty ? '@@ $oldRange' : '@@ $oldRange $ctx';
            final rightHunk = '@@ $newRange';
            final leftCell = styles.hunkHeader.render(
              leftHunk.padRight(leftPanelWidth),
            );
            final rightCell = styles.hunkHeader.render(
              rightHunk.padRight(rightPanelWidth),
            );
            result.add('$leftCell$separator$rightCell');
          } else {
            // Fallback: raw hunk header spanning full width.
            result.add(styles.hunkHeader.render(line.content.padRight(width)));
          }
          i++;
          continue;
        }

        // Empty line.
        if (line.type == DiffLineType.empty) {
          result.add('');
          i++;
          continue;
        }

        // Context line — same content on both sides.
        if (line.type == DiffLineType.context) {
          final leftHighlight = _highlightForLine(
            file,
            line,
            side: DiffCommentSide.left,
          );
          final rightHighlight = _highlightForLine(
            file,
            line,
            side: DiffCommentSide.right,
          );
          final leftRows = _sbsCell(
            lineNum: line.oldLineNumber,
            content: line.content,
            style: styles.sideBySideContextLine,
            numStyle: styles.sideBySideLineNumber,
            markerStyle: styles.sideBySideContextMarker,
            marker: ' ',
            numWidth: effectiveNumWidth,
            cellWidth: leftPanelWidth,
            contentWidth: leftContentWidth,
            highlight: leftHighlight,
          );
          final rightRows = _sbsCell(
            lineNum: line.newLineNumber,
            content: line.content,
            style: styles.sideBySideContextLine,
            numStyle: styles.sideBySideLineNumber,
            markerStyle: styles.sideBySideContextMarker,
            marker: ' ',
            numWidth: effectiveNumWidth,
            cellWidth: rightPanelWidth,
            contentWidth: rightContentWidth,
            highlight: rightHighlight,
          );
          _sbsJoinRows(
            result,
            leftRows,
            rightRows,
            separator,
            leftPanelWidth,
            rightPanelWidth,
          );
          i++;
          continue;
        }

        // Collect consecutive removed and added lines for pairing.
        final removedLines = <DiffLine>[];
        final addedLines = <DiffLine>[];

        // Gather removed lines.
        while (i < lines.length && lines[i].type == DiffLineType.removed) {
          removedLines.add(lines[i]);
          i++;
        }
        // Gather added lines immediately after.
        while (i < lines.length && lines[i].type == DiffLineType.added) {
          addedLines.add(lines[i]);
          i++;
        }

        // Compute inline diffs for paired removed/added lines.
        final pairCount = removedLines.length > addedLines.length
            ? removedLines.length
            : addedLines.length;
        final inlinePairs = <(List<_InlineSpan>, List<_InlineSpan>)>[];
        for (var p = 0; p < pairCount; p++) {
          if (p < removedLines.length && p < addedLines.length) {
            inlinePairs.add(
              _computeInlineDiff(
                removedLines[p].content,
                addedLines[p].content,
              ),
            );
          } else {
            inlinePairs.add((const [], const []));
          }
        }

        // Pair them: zip removed with added, then fill remainder.
        for (var p = 0; p < pairCount; p++) {
          final hasLeft = p < removedLines.length;
          final hasRight = p < addedLines.length;

          final leftRows = hasLeft
              ? _sbsCell(
                  lineNum: removedLines[p].oldLineNumber,
                  content: removedLines[p].content,
                  style: styles.sideBySideRemovedLine,
                  numStyle: styles.sideBySideLineNumber,
                  markerStyle: styles.sideBySideRemovedMarker,
                  marker: '-',
                  numWidth: effectiveNumWidth,
                  cellWidth: leftPanelWidth,
                  contentWidth: leftContentWidth,
                  inlineSpans: inlinePairs[p].$1,
                  inlineHighlight: styles.inlineRemovedHighlight,
                  highlight: _highlightForLine(file, removedLines[p]),
                )
              : [_sbsEmptyCell(leftPanelWidth)];

          final rightRows = hasRight
              ? _sbsCell(
                  lineNum: addedLines[p].newLineNumber,
                  content: addedLines[p].content,
                  style: styles.sideBySideAddedLine,
                  numStyle: styles.sideBySideLineNumber,
                  markerStyle: styles.sideBySideAddedMarker,
                  marker: '+',
                  numWidth: effectiveNumWidth,
                  cellWidth: rightPanelWidth,
                  contentWidth: rightContentWidth,
                  inlineSpans: inlinePairs[p].$2,
                  inlineHighlight: styles.inlineAddedHighlight,
                  highlight: _highlightForLine(file, addedLines[p]),
                )
              : [_sbsEmptyCell(rightPanelWidth)];

          _sbsJoinRows(
            result,
            leftRows,
            rightRows,
            separator,
            leftPanelWidth,
            rightPanelWidth,
          );
        }
      }
    }

    return result;
  }

  /// Renders a single cell for side-by-side mode.
  ///
  /// Each cell contains an optional line number, a colored marker (`+`, `-`,
  /// or space), and content, padded to [cellWidth] visible characters. When
  /// [wrapLines] is enabled and the content exceeds [contentWidth],
  /// continuation rows are produced with blank line-number gutters.
  ///
  /// If [inlineSpans] is non-empty, word-level diff highlighting is applied
  /// to the content using [inlineHighlight].
  List<String> _sbsCell({
    required int? lineNum,
    required String content,
    required Style style,
    required Style numStyle,
    required Style markerStyle,
    required String marker,
    required int numWidth,
    required int cellWidth,
    required int contentWidth,
    List<_InlineSpan> inlineSpans = const [],
    Style? inlineHighlight,
    DiffCommentLineHighlightKind? highlight,
  }) {
    final effectiveStyle = _contentStyleWithHighlight(style, highlight);
    final effectiveNumStyle = _gutterStyleWithHighlight(numStyle, highlight);
    final effectiveMarkerStyle = _gutterStyleWithHighlight(
      markerStyle,
      highlight,
    );
    final padChar = zeroPadLineNumbers ? '0' : ' ';
    final numStr = showLineNumbers
        ? effectiveNumStyle.render(
            '${lineNum != null ? '$lineNum'.padLeft(numWidth, padChar) : ' ' * numWidth} ',
          )
        : '';

    // Render the marker with its dedicated style.
    final markerStr = effectiveMarkerStyle.render('$marker ');

    if (!wrapLines || contentWidth <= 0 || content.length <= contentWidth) {
      // Side-by-side cells must have fixed width to maintain panel alignment.
      // When horizontalOffset > 0, shift the visible content window so that
      // left/right scrolling reveals content that would otherwise be truncated.
      final String displayContent;
      int displayOffset = 0;
      if (content.length <= contentWidth) {
        displayContent = content.padRight(contentWidth);
      } else {
        displayOffset = horizontalOffset.clamp(0, content.length);
        final end = (displayOffset + contentWidth).clamp(
          displayOffset,
          content.length,
        );
        displayContent = content
            .substring(displayOffset, end)
            .padRight(contentWidth);
      }

      // Apply inline highlighting if spans are provided.
      final styledContent = _renderInlineContent(
        displayContent,
        displayOffset,
        contentWidth,
        effectiveStyle,
        inlineSpans,
        inlineHighlight,
      );
      return ['$numStr$markerStr$styledContent'];
    }

    // Wrap: split content into chunks of contentWidth.
    final rows = <String>[];
    var offset = 0;
    while (offset < content.length) {
      final end = (offset + contentWidth).clamp(0, content.length);
      final chunk = content.substring(offset, end).padRight(contentWidth);
      final styledChunk = _renderInlineContent(
        chunk,
        offset,
        contentWidth,
        effectiveStyle,
        inlineSpans,
        inlineHighlight,
      );
      if (offset == 0) {
        rows.add('$numStr$markerStr$styledChunk');
      } else {
        final blankNum = showLineNumbers
            ? effectiveNumStyle.render('${' ' * numWidth} ')
            : '';
        final blankMarker = effectiveMarkerStyle.render(
          '  ',
        ); // 2 spaces matching marker
        rows.add('$blankNum$blankMarker$styledChunk');
      }
      offset = end;
    }
    return rows;
  }

  /// Renders an empty cell for side-by-side mode.
  String _sbsEmptyCell(int cellWidth) {
    return styles.sideBySideEmptyCell.render(' ' * cellWidth);
  }

  /// Joins left and right cell row lists into combined side-by-side rows.
  ///
  /// If one side has more rows than the other, the shorter side is padded
  /// with empty cells.
  void _sbsJoinRows(
    List<String> result,
    List<String> leftRows,
    List<String> rightRows,
    String separator,
    int leftPanelWidth,
    int rightPanelWidth,
  ) {
    final rowCount = leftRows.length > rightRows.length
        ? leftRows.length
        : rightRows.length;
    for (var r = 0; r < rowCount; r++) {
      final left = r < leftRows.length
          ? leftRows[r]
          : _sbsEmptyCell(leftPanelWidth);
      final right = r < rightRows.length
          ? rightRows[r]
          : _sbsEmptyCell(rightPanelWidth);
      result.add('$left$separator$right');
    }
  }

  /// Computes word-level inline diff between [oldContent] and [newContent].
  ///
  /// Returns a pair of span lists: the first for the old (removed) line and the
  /// second for the new (added) line. Highlighted spans mark tokens that differ
  /// between the two lines.
  (List<_InlineSpan>, List<_InlineSpan>) _computeInlineDiff(
    String oldContent,
    String newContent,
  ) {
    if (oldContent.isEmpty && newContent.isEmpty) {
      return (const [], const []);
    }
    if (oldContent.isEmpty) {
      return (const [], [_InlineSpan(0, newContent.length, true)]);
    }
    if (newContent.isEmpty) {
      return ([_InlineSpan(0, oldContent.length, true)], const []);
    }

    // Tokenize into words, preserving exact character positions.
    final oldTokens = _tokenize(oldContent);
    final newTokens = _tokenize(newContent);

    // Compute LCS of token strings.
    final lcs = _lcsTokens(oldTokens, newTokens);

    // Mark tokens not in LCS as highlighted.
    final oldSpans = <_InlineSpan>[];
    final newSpans = <_InlineSpan>[];

    var li = 0; // index into lcs
    for (final t in oldTokens) {
      if (li < lcs.length && t.text == lcs[li]) {
        // Token matches LCS — not highlighted, advance LCS pointer.
        li++;
      } else {
        // Token differs — mark as highlighted (skip whitespace-only tokens).
        if (t.text.trim().isNotEmpty) {
          oldSpans.add(_InlineSpan(t.start, t.end, true));
        }
      }
    }

    li = 0;
    for (final t in newTokens) {
      if (li < lcs.length && t.text == lcs[li]) {
        li++;
      } else {
        if (t.text.trim().isNotEmpty) {
          newSpans.add(_InlineSpan(t.start, t.end, true));
        }
      }
    }

    // Merge adjacent highlighted spans.
    return (_mergeSpans(oldSpans), _mergeSpans(newSpans));
  }

  /// Tokenizes [input] into a list of tokens split at word boundaries.
  ///
  /// Each token preserves its start/end character position. Whitespace runs and
  /// punctuation characters are individual tokens.
  static List<_Token> _tokenize(String input) {
    final tokens = <_Token>[];
    final len = input.length;
    var i = 0;
    while (i < len) {
      final ch = input[i];
      if (ch == ' ' || ch == '\t') {
        // Whitespace run.
        final start = i;
        while (i < len && (input[i] == ' ' || input[i] == '\t')) {
          i++;
        }
        tokens.add(_Token(start, i, input.substring(start, i)));
      } else if (_isPunctuation(ch)) {
        tokens.add(_Token(i, i + 1, ch));
        i++;
      } else {
        // Word characters.
        final start = i;
        while (i < len &&
            input[i] != ' ' &&
            input[i] != '\t' &&
            !_isPunctuation(input[i])) {
          i++;
        }
        tokens.add(_Token(start, i, input.substring(start, i)));
      }
    }
    return tokens;
  }

  static bool _isPunctuation(String ch) {
    const puncts = '(){}[]<>.,;:!?@#\$%^&*+-=/\\|~`\'"';
    return puncts.contains(ch);
  }

  /// Computes the longest common subsequence of token strings.
  static List<String> _lcsTokens(List<_Token> a, List<_Token> b) {
    final m = a.length;
    final n = b.length;

    // For very long token lists, fall back to highlighting everything
    // to avoid O(m*n) memory/time.
    if (m * n > 100000) {
      return const [];
    }

    // Build DP table.
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (a[i - 1].text == b[j - 1].text) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }

    // Backtrack to find LCS.
    final lcs = <String>[];
    var i = m;
    var j = n;
    while (i > 0 && j > 0) {
      if (a[i - 1].text == b[j - 1].text) {
        lcs.add(a[i - 1].text);
        i--;
        j--;
      } else if (dp[i - 1][j] > dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }
    return lcs.reversed.toList();
  }

  /// Merges adjacent highlighted spans into single spans.
  static List<_InlineSpan> _mergeSpans(List<_InlineSpan> spans) {
    if (spans.length <= 1) return spans;
    final merged = <_InlineSpan>[spans.first];
    for (var i = 1; i < spans.length; i++) {
      final prev = merged.last;
      final curr = spans[i];
      if (prev.end == curr.start) {
        merged[merged.length - 1] = _InlineSpan(prev.start, curr.end, true);
      } else {
        merged.add(curr);
      }
    }
    return merged;
  }

  /// Renders [displayContent] with optional inline highlighting.
  ///
  /// When [inlineSpans] is empty or [inlineHighlight] is null, applies
  /// [baseStyle] to the entire string. Otherwise, segments that overlap with
  /// highlighted spans get [inlineHighlight] and the rest get [baseStyle].
  ///
  /// [displayOffset] is the character offset into the original content (for
  /// horizontal scrolling), used to map spans to display coordinates.
  String _renderInlineContent(
    String displayContent,
    int displayOffset,
    int contentWidth,
    Style baseStyle,
    List<_InlineSpan> inlineSpans,
    Style? inlineHighlight,
  ) {
    if (inlineSpans.isEmpty || inlineHighlight == null) {
      return baseStyle.render(displayContent);
    }

    // Map spans from original content coordinates to display coordinates.
    // Display window: [displayOffset, displayOffset + contentWidth)
    final displayEnd = displayOffset + contentWidth;
    final buf = StringBuffer();
    var pos = 0; // position in displayContent

    for (final span in inlineSpans) {
      // Clip span to display window.
      final spanStart = span.start < displayOffset ? displayOffset : span.start;
      final spanEnd = span.end > displayEnd ? displayEnd : span.end;
      if (spanStart >= spanEnd) continue;

      // Convert to display-local coordinates.
      final localStart = spanStart - displayOffset;
      final localEnd = spanEnd - displayOffset;

      // Render non-highlighted segment before this span.
      if (localStart > pos) {
        buf.write(baseStyle.render(displayContent.substring(pos, localStart)));
      }

      // Render highlighted segment.
      buf.write(
        inlineHighlight.render(displayContent.substring(localStart, localEnd)),
      );
      pos = localEnd;
    }

    // Render remaining non-highlighted content.
    if (pos < displayContent.length) {
      buf.write(baseStyle.render(displayContent.substring(pos)));
    }

    return buf.toString();
  }
}

/// A span within a diff line marking a character range.
class _InlineSpan {
  const _InlineSpan(this.start, this.end, this.highlighted);

  /// Start character index (inclusive).
  final int start;

  /// End character index (exclusive).
  final int end;

  /// Whether this span represents a changed (highlighted) region.
  final bool highlighted;
}

/// A token with its position in the original string.
class _Token {
  const _Token(this.start, this.end, this.text);
  final int start;
  final int end;
  final String text;
}
