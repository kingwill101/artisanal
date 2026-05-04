import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/display_item.dart';

final class GithubDiffDialog extends w.StatefulWidget {
  GithubDiffDialog({
    required this.item,
    required this.diff,
    required this.loading,
    required this.error,
    required this.onClose,
    super.key,
  });

  final GithubDisplayItem item;
  final String diff;
  final bool loading;
  final String? error;
  final tui.Cmd? Function() onClose;

  @override
  w.State<GithubDiffDialog> createState() => _GithubDiffDialogState();
}

final class _GithubDiffDialogState extends w.State<GithubDiffDialog> {
  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == tui.KeyType.escape) {
      return widget.onClose();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final size = w.MediaQuery.maybeOf(context)?.size ?? const w.Size(100, 30);
    final width = size.width.toInt().clamp(72, 160) - 8;
    final height = size.height.toInt().clamp(20, 60) - 8;
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
                w.Text(
                  'Diff PR #${widget.item.number}',
                  style: theme.titleMedium,
                ),
                w.Spacer(),
                if (widget.loading) w.SpinnerIndicator(),
                if (widget.loading) w.Spacer(size: 1),
                w.Text('esc', style: hint),
              ],
            ),
            w.Text(
              widget.item.title,
              style: hint,
              overflow: w.TextOverflow.ellipsis,
            ),
            if (widget.error != null) w.Text(widget.error!, style: errorStyle),
            if (widget.loading && widget.diff.isEmpty)
              w.SizedBox(
                height: height,
                child: w.Text('Loading PR files from GitHub...', style: hint),
              )
            else if (widget.diff.trim().isEmpty)
              w.SizedBox(
                height: height,
                child: w.Text('No diff returned by gh.', style: hint),
              )
            else
              w.GitDiffViewer(
                diff: widget.diff,
                width: width,
                height: height,
                wrapLines: true,
              ),
            w.Text(
              'j/k or pgup/pgdn scroll | v changes diff view | esc close',
              style: hint,
            ),
          ],
        ),
      ),
    );
  }
}
