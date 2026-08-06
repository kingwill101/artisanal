/// OpenCode example-local tool cards (not a framework API).
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

/// Lifecycle status for a [ToolCard] / [ToolCardInline].
enum ToolCardStatus {
  pending,
  running,
  completed,
  error,
}

/// Compact one-line tool invocation (OpenCode-style inline tool).
class ToolCardInline extends w.StatelessWidget {
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
  final style.Color? accentColor;
  final style.Color? mutedColor;
  final style.Color? errorColor;
  final style.Color? runningColor;
  final bool showSpinner;

  String get _label {
    final head = title.isNotEmpty ? title : toolName;
    if (filePath != null && filePath!.isNotEmpty) return '$head $filePath';
    if (input.isNotEmpty) return '$head $input';
    return head;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
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

    return w.Column(
      gap: 0,
      crossAxisAlignment: w.CrossAxisAlignment.start,
      children: [
        w.Row(
          gap: 1,
          children: [
            if (isRunning && showSpinner)
              w.SpinnerIndicator(
                color: run,
                interval: const Duration(milliseconds: 80),
              )
            else if (status == ToolCardStatus.pending)
              w.Text(
                pendingGlyph,
                style: theme.bodySmall.copy()..foreground(muted),
              )
            else if (isError)
              w.Text(
                errorGlyph,
                style: theme.bodySmall.copy()..foreground(err),
              )
            else
              w.Text(icon, style: theme.bodySmall.copy()..foreground(fg)),
            w.Text(
              _label,
              style: theme.bodySmall.copy()..foreground(fg),
              softWrap: false,
            ),
          ],
        ),
        if (error != null && error!.isNotEmpty)
          w.Padding(
            padding: const w.EdgeInsets.only(left: 2),
            child: w.Text(
              error!,
              style: theme.bodySmall.copy()..foreground(err),
            ),
          ),
      ],
    );
  }
}

/// Bordered tool card for block tools (OpenCode session-ui style).
class ToolCard extends w.StatelessWidget {
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
  final w.Widget? body;
  final style.Color? accentColor;
  final style.Color? background;
  final style.Color? borderColor;
  final style.Color? mutedColor;
  final style.Color? errorColor;
  final style.Color? runningColor;
  final bool showSpinner;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final muted = mutedColor ?? theme.muted;
    final err = errorColor ?? theme.error;
    final run = runningColor ?? theme.primary;
    final bg = background ?? theme.surface;
    final accent =
        accentColor ??
        (status == ToolCardStatus.running
            ? run
            : status == ToolCardStatus.error
            ? err
            : (borderColor ?? theme.border));

    final isRunning = status == ToolCardStatus.running;
    final isPending = status == ToolCardStatus.pending;
    final heading = title.isNotEmpty ? title : '# $toolName';
    final headingFg = isRunning || isPending ? theme.onSurface : muted;

    return w.Frame(
      background: bg,
      border: style.Border.rounded,
      borderColor: accent,
      padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Row(
            gap: 1,
            children: [
              if (isRunning && showSpinner)
                w.SpinnerIndicator(
                  color: run,
                  interval: const Duration(milliseconds: 80),
                )
              else if (isPending)
                w.Text('⋯', style: theme.bodySmall.copy()..foreground(muted)),
              w.Expanded(
                child: w.Text(
                  heading,
                  style: theme.labelLarge.copy()..foreground(headingFg),
                  softWrap: false,
                ),
              ),
              if (filePath != null && filePath!.isNotEmpty)
                w.Text(
                  filePath!,
                  style: theme.bodySmall.copy()..foreground(muted),
                  softWrap: false,
                ),
            ],
          ),
          if (error != null && error!.isNotEmpty)
            w.Text(error!, style: theme.bodySmall.copy()..foreground(err)),
          ?body,
        ],
      ),
    );
  }
}
