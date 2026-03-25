import '../style/color.dart';
import '../style/style.dart';

/// Theme configuration for [Console] output styles.
///
/// Provides customizable colors for different message types:
/// - info, warning, error, success, comment, question, muted
///
/// Uses [AdaptiveColor] so colors automatically adapt to:
/// - Terminal color capabilities (ANSI vs truecolor)
/// - Light/dark terminal backgrounds
///
/// {@category Core}
///
/// ## Usage
///
/// ```dart
/// // Use a preset
/// final console = Console(outputTheme: OutputTheme.dark());
///
/// // Or customize
/// final console = Console(
///   outputTheme: OutputTheme(
///     info: AdaptiveColor(light: AnsiColor(33), dark: AnsiColor(39)),
///     error: AdaptiveColor(light: AnsiColor(196), dark: AnsiColor(203)),
///   ),
/// );
/// ```
class OutputTheme {
  /// Creates an output theme with the given colors.
  ///
  /// All colors default to adaptive variants that work well on both
  /// light and dark terminals.
  const OutputTheme({
    this.info,
    this.warning,
    this.error,
    this.success,
    this.comment,
    this.question,
    this.muted,
    this.alert,
  });

  /// Info message color (green by default).
  final Color? info;

  /// Warning message color (yellow by default).
  final Color? warning;

  /// Error message color (red by default).
  final Color? error;

  /// Success message color (green by default).
  final Color? success;

  /// Comment message color (yellow by default).
  final Color? comment;

  /// Question message color (cyan on black by default).
  final Color? question;

  /// Muted/dimmed text color (gray by default).
  final Color? muted;

  /// Alert box color (yellow/orange by default).
  final Color? alert;

  /// Default color theme (matches original behavior).
  static const OutputTheme default_ = OutputTheme();

  /// Dark terminal optimized theme.
  ///
  /// Uses brighter variants of the default colors for dark backgrounds.
  static OutputTheme dark() => const OutputTheme(
    info: AdaptiveColor(
      light: BasicColor('#22c55e'),
      dark: BasicColor('#4ade80'),
    ),
    warning: AdaptiveColor(
      light: BasicColor('#f59e0b'),
      dark: BasicColor('#fbbf24'),
    ),
    error: AdaptiveColor(
      light: BasicColor('#ef4444'),
      dark: BasicColor('#f87171'),
    ),
    success: AdaptiveColor(
      light: BasicColor('#22c55e'),
      dark: BasicColor('#4ade80'),
    ),
    comment: AdaptiveColor(
      light: BasicColor('#f59e0b'),
      dark: BasicColor('#fbbf24'),
    ),
    question: AdaptiveColor(
      light: BasicColor('#06b6d4'),
      dark: BasicColor('#22d3ee'),
    ),
    muted: AdaptiveColor(
      light: BasicColor('#6b7280'),
      dark: BasicColor('#9ca3af'),
    ),
  );

  /// Light terminal optimized theme.
  ///
  /// Uses darker variants of the default colors for light backgrounds.
  static OutputTheme light() => const OutputTheme(
    info: AdaptiveColor(
      light: BasicColor('#16a34a'),
      dark: BasicColor('#22c55e'),
    ),
    warning: AdaptiveColor(
      light: BasicColor('#d97706'),
      dark: BasicColor('#f59e0b'),
    ),
    error: AdaptiveColor(
      light: BasicColor('#dc2626'),
      dark: BasicColor('#ef4444'),
    ),
    success: AdaptiveColor(
      light: BasicColor('#16a34a'),
      dark: BasicColor('#22c55e'),
    ),
    comment: AdaptiveColor(
      light: BasicColor('#d97706'),
      dark: BasicColor('#f59e0b'),
    ),
    question: AdaptiveColor(
      light: BasicColor('#0891b2'),
      dark: BasicColor('#06b6d4'),
    ),
    muted: AdaptiveColor(
      light: BasicColor('#6b7280'),
      dark: BasicColor('#9ca3af'),
    ),
  );

  /// Minimal theme using a single foreground color.
  ///
  /// Uses [foregroundColor] for all styled elements. Useful when you want
  /// a unified look or minimal color usage.
  static OutputTheme minimal(Color foregroundColor) => OutputTheme(
    info: foregroundColor,
    warning: foregroundColor,
    error: foregroundColor,
    success: foregroundColor,
    comment: foregroundColor,
    question: foregroundColor,
    muted: foregroundColor,
  );

  /// Creates a copy of this theme with the given fields replaced.
  OutputTheme copyWith({
    Color? info,
    Color? warning,
    Color? error,
    Color? success,
    Color? comment,
    Color? question,
    Color? muted,
  }) {
    return OutputTheme(
      info: info ?? this.info,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      success: success ?? this.success,
      comment: comment ?? this.comment,
      question: question ?? this.question,
      muted: muted ?? this.muted,
    );
  }

  /// Creates Style objects from this theme's colors.
  ///
  /// Returns a map of style names to their corresponding Style objects.
  /// Each Style is created fresh to avoid shared state issues.
  Map<String, Style> toStyles() {
    final styles = <String, Style>{};
    if (info case final c?) styles['info'] = Style()..foreground(c);
    if (warning case final c?) styles['warning'] = Style()..foreground(c);
    if (error case final c?) styles['error'] = Style()..foreground(c);
    if (success case final c?) styles['success'] = Style()..foreground(c);
    if (comment case final c?) styles['comment'] = Style()..foreground(c);
    if (question case final c?) styles['question'] = Style()..foreground(c);
    if (muted case final c?) styles['muted'] = Style()..foreground(c);
    if (alert case final c?) styles['alert'] = Style()..foreground(c);
    return styles;
  }
}
