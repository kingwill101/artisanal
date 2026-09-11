import 'package:artisanal/style.dart' show Colors, Style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/dashboard_data.dart';
import '../../models/display_item.dart';
import '../../utils/time.dart';

final class GithubRunDetailDialog extends w.StatefulWidget {
  GithubRunDetailDialog({
    required this.item,
    required this.detail,
    required this.loading,
    required this.error,
    required this.onClose,
    super.key,
  });

  final GithubDisplayItem item;
  final GithubWorkflowRunDetail? detail;
  final bool loading;
  final String? error;
  final tui.Cmd? Function() onClose;

  @override
  w.State<GithubRunDetailDialog> createState() => _GithubRunDetailDialogState();
}

final class _GithubRunDetailDialogState extends w.State<GithubRunDetailDialog> {
  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg &&
        (msg.key.type == tui.KeyType.escape ||
            msg.key.type == tui.KeyType.enter)) {
      return widget.onClose();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final size = w.MediaQuery.maybeOf(context)?.size ?? const w.Size(100, 30);
    final width = size.width.toInt().clamp(74, 150) - 8;
    final height = size.height.toInt().clamp(20, 60) - 9;
    final hint = theme.bodySmall.copy()..foreground(theme.muted);
    final errorStyle = theme.bodyMedium.copy()..foreground(theme.error);

    return w.SizedBox(
      width: width + 4,
      child: w.Frame(
        background: theme.surface,
        padding: const w.EdgeInsets.only(left: 2, right: 2, top: 1, bottom: 1),
        child: w.Column(
          gap: 1,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Row(
              children: [
                w.Text('Run #${widget.item.number}', style: theme.titleMedium),
                w.Spacer(),
                if (widget.loading) w.SpinnerIndicator(),
                if (widget.loading) w.Spacer(size: 1),
                w.Text('esc', style: hint),
              ],
            ),
            w.Text(widget.item.title, style: theme.titleLarge),
            if (widget.error != null) w.Text(widget.error!, style: errorStyle),
            w.ScrollArea(
              height: height,
              showScrollbar: true,
              child: _body(theme, hint),
            ),
            w.Text(
              'esc/enter close | o opens the run URL from the list',
              style: hint,
            ),
          ],
        ),
      ),
    );
  }

  w.Widget _body(w.Theme theme, Style hint) {
    if (widget.loading && widget.detail == null) {
      return w.Text('Loading run details from gh...', style: hint);
    }
    final detail = widget.detail;
    if (detail == null) {
      return w.Text('No run details loaded.', style: hint);
    }

    final run = detail.run;
    final statusColor = run.hasFailures ? Colors.red : Colors.green;
    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      gap: 1,
      children: [
        w.Row(
          gap: 1,
          children: [
            w.Badge(
              run.statusLabel,
              background: statusColor,
              foreground: Colors.black,
            ),
            w.Badge(
              run.workflowName,
              background: theme.background,
              foreground: theme.onSurface,
            ),
            w.Badge(
              run.event,
              background: theme.background,
              foreground: theme.muted,
            ),
          ],
        ),
        w.Text(
          '${run.headBranch} / ${relativeGithubTime(run.updatedAt ?? run.createdAt)}',
          style: hint,
        ),
        if (detail.headSha.isNotEmpty)
          w.Text('sha ${_shortSha(detail.headSha)}', style: hint),
        w.Text(
          'jobs ${detail.successfulJobCount}/${detail.jobs.length} passing',
          style: theme.bodyMedium,
        ),
        for (final job in detail.jobs) _job(theme, hint, job),
      ],
    );
  }

  w.Widget _job(w.Theme theme, Style hint, GithubWorkflowJobItem job) {
    final color = job.hasFailures ? Colors.red : Colors.green;
    return w.Frame(
      background: theme.background,
      padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Row(
            children: [
              w.Text(
                job.statusLabel,
                style: theme.bodyMedium.copy()..foreground(color),
              ),
              w.Spacer(size: 1),
              w.Text(job.name, style: theme.bodyMedium),
              w.Spacer(),
              w.Text(_duration(job.startedAt, job.completedAt), style: hint),
            ],
          ),
          for (final step in job.steps.take(12))
            w.Text(
              '${step.hasFailures ? 'x' : 'v'} ${step.number}. ${step.name} (${step.statusLabel})',
              style: theme.bodySmall.copy()
                ..foreground(step.hasFailures ? Colors.red : theme.muted),
              overflow: w.TextOverflow.ellipsis,
              maxWidth: 120,
            ),
          if (job.steps.length > 12)
            w.Text('+${job.steps.length - 12} more steps', style: hint),
        ],
      ),
    );
  }
}

String _shortSha(String value) {
  if (value.length <= 12) return value;
  return value.substring(0, 12);
}

String _duration(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '';
  final duration = end.difference(start);
  if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }
  return '${duration.inSeconds}s';
}
