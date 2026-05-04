import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/comment.dart';
import '../../models/display_item.dart';
import '../../utils/time.dart';
import '../markdown/body.dart';

final class GithubCommentsDialog extends w.StatefulWidget {
  GithubCommentsDialog({
    required this.item,
    required this.comments,
    required this.loading,
    required this.error,
    required this.onClose,
    super.key,
  });

  final GithubDisplayItem item;
  final List<GithubCommentItem> comments;
  final bool loading;
  final String? error;
  final tui.Cmd? Function() onClose;

  @override
  w.State<GithubCommentsDialog> createState() => _GithubCommentsDialogState();
}

final class _GithubCommentsDialogState extends w.State<GithubCommentsDialog> {
  final _scrollController = w.WidgetScrollController();

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
    final hint = theme.bodySmall.copy()..foreground(theme.muted);
    final errorStyle = theme.bodyMedium.copy()..foreground(theme.error);

    return w.SizedBox(
      width: 92,
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
                  'All comments ${widget.item.kind.toUpperCase()} #${widget.item.number}',
                  style: theme.titleMedium,
                ),
                w.Spacer(),
                if (widget.loading) w.SpinnerIndicator(),
                if (widget.loading) w.Spacer(size: 1),
                w.Text('esc', style: hint),
              ],
            ),
            w.Text(widget.item.title, style: hint),
            if (widget.error != null) w.Text(widget.error!, style: errorStyle),
            w.SizedBox(height: 18, child: _commentBody(theme)),
            w.Text(
              'esc/enter close | a adds a comment from the list',
              style: hint,
            ),
          ],
        ),
      ),
    );
  }

  w.Widget _commentBody(w.Theme theme) {
    final hint = theme.bodySmall.copy()..foreground(theme.muted);
    if (widget.loading && widget.comments.isEmpty) {
      return w.Text('Loading comments from gh...', style: hint);
    }
    if (widget.comments.isEmpty) {
      return w.Text('No comments returned by gh.', style: hint);
    }
    return w.Scrollbar(
      controller: _scrollController,
      child: w.VirtualListView.builder(
        controller: _scrollController,
        width: 86,
        height: 18,
        variableHeight: true,
        estimatedItemExtent: 6,
        separator: '\n',
        itemCount: widget.comments.length,
        itemBuilder: (context, index) {
          final comment = widget.comments[index];
          return w.Frame(
            background: theme.background,
            padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            child: w.Column(
              crossAxisAlignment: w.CrossAxisAlignment.stretch,
              children: [
                w.Text(
                  '${comment.author} / ${relativeGithubTime(comment.createdAt)}',
                  style: hint,
                ),
                GithubMarkdownBody(
                  data: comment.body,
                  fallbackMarkdown: '_Empty comment._',
                  maxWidth: 82,
                  textStyle: theme.bodyMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
