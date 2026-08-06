import 'package:artisanal/style.dart' show Color, Border;
import 'package:artisanal/widgets.dart';

/// Lifecycle status for a [ToolCard] / [ToolCardInline].
enum ToolCardStatus {
  pending,
  running,
  completed,
  error,
}

/// Compact one-line tool invocation (OpenCode-style inline tool).
///
/// ```dart
/// ToolCardInline(
///   toolName: 'Read',
///   status: ToolCardStatus.completed,
///   filePath: 'lib/main.dart',
/// )
/// ```
class ToolCardInline extends StatelessWidget {
  ToolCardInline({
    required this.toolName,
    this.title = '',
    this.status = ToolCardStatus.completed,
    this.icon = '⚙',
    this.input = '',
    this.filePath,
    this.error,
    this.pendingGlyph = '⋯',
    this.errorGlyph = '✗',
    this.accentColor,
    this.mutedColor,
    this.errorColor,
    this.runningColor,
    this.showSpinner = true,
    super.key,
  });

  final String toolName;
  final String title;
  final ToolCardStatus status;
  final String icon;
  final String input;
  final String? filePath;
  final String? error;
  final String pendingGlyph;
  final String errorGlyph;
  final Color? accentColor;
  final Color? mutedColor;
  final Color? errorColor;
  final Color? runningColor;
  final bool showSpinner;

  String get _label {
    final head = title.isNotEmpty ? title : toolName;
    if (filePath != null && filePath!.isNotEmpty) return '$head $filePath';
    if (input.isNotEmpty) return '$head $input';
    return head;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final muted = mutedColor ?? theme.muted;
    final err = errorColor ?? theme.error;
    final run = runningColor ?? theme.primary;
    final onSurface = theme.onSurface;

    final isRunning = status == ToolCardStatus.running;
    final isPending =
        status == ToolCardStatus.pending || status == ToolCardStatus.running;
    final isError = status == ToolCardStatus.error;

    final fg = isPending
        ? onSurface
        : isError
        ? err
        : muted;

    return Column(
      gap: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          gap: 1,
          children: [
            if (isRunning && showSpinner)
              SpinnerIndicator(
                color: run,
                interval: const Duration(milliseconds: 80),
              )
            else if (status == ToolCardStatus.pending)
              Text(pendingGlyph, style: theme.bodySmall.copy()..foreground(muted))
            else if (isError)
              Text(errorGlyph, style: theme.bodySmall.copy()..foreground(err))
            else
              Text(icon, style: theme.bodySmall.copy()..foreground(fg)),
            Text(
              _label,
              style: theme.bodySmall.copy()..foreground(fg),
              softWrap: false,
            ),
          ],
        ),
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              error!,
              style: theme.bodySmall.copy()..foreground(err),
            ),
          ),
      ],
    );
  }
}

/// Bordered tool card for block tools (OpenCode session-ui basic-tool style).
///
/// Optional [body] can hold expanded output, markdown, or a [GitDiffViewer].
class ToolCard extends StatelessWidget {
  ToolCard({
    required this.toolName,
    this.title = '',
    this.status = ToolCardStatus.completed,
    this.filePath,
    this.error,
    this.body,
    this.accentColor,
    this.background,
    this.borderColor,
    this.mutedColor,
    this.errorColor,
    this.runningColor,
    this.showSpinner = true,
    super.key,
  });

  final String toolName;
  final String title;
  final ToolCardStatus status;
  final String? filePath;
  final String? error;
  final Widget? body;
  final Color? accentColor;
  final Color? background;
  final Color? borderColor;
  final Color? mutedColor;
  final Color? errorColor;
  final Color? runningColor;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final muted = mutedColor ?? theme.muted;
    final err = errorColor ?? theme.error;
    final run = runningColor ?? theme.primary;
    final bg = background ?? theme.surface;
    final accent = accentColor ??
        (status == ToolCardStatus.running
            ? run
            : status == ToolCardStatus.error
            ? err
            : (borderColor ?? theme.border));

    final isRunning = status == ToolCardStatus.running;
    final isPending = status == ToolCardStatus.pending;
    final heading = title.isNotEmpty ? title : '# $toolName';
    final headingFg =
        isRunning || isPending ? theme.onSurface : muted;

    return Frame(
      background: bg,
      border: Border.rounded,
      borderColor: accent,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: Column(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            gap: 1,
            children: [
              if (isRunning && showSpinner)
                SpinnerIndicator(
                  color: run,
                  interval: const Duration(milliseconds: 80),
                )
              else if (isPending)
                Text('⋯', style: theme.bodySmall.copy()..foreground(muted)),
              Expanded(
                child: Text(
                  heading,
                  style: theme.labelLarge.copy()..foreground(headingFg),
                  softWrap: false,
                ),
              ),
              if (filePath != null && filePath!.isNotEmpty)
                Text(
                  filePath!,
                  style: theme.bodySmall.copy()..foreground(muted),
                  softWrap: false,
                ),
            ],
          ),
          if (error != null && error!.isNotEmpty)
            Text(error!, style: theme.bodySmall.copy()..foreground(err)),
          ?body,
        ],
      ),
    );
  }
}
