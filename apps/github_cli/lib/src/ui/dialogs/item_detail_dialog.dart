import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/display_item.dart';
import '../markdown/body.dart';
import '../../utils/text_format.dart';

final class GithubItemDetailDialog extends w.StatefulWidget {
  GithubItemDetailDialog({
    required this.item,
    required this.onClose,
    super.key,
  });

  final GithubDisplayItem item;
  final tui.Cmd? Function() onClose;

  @override
  w.State<GithubItemDetailDialog> createState() =>
      _GithubItemDetailDialogState();
}

final class _GithubItemDetailDialogState
    extends w.State<GithubItemDetailDialog> {
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
    final body = githubDisplayMarkdown(widget.item.body).trim();

    return w.SizedBox(
      width: 88,
      child: w.Frame(
        background: theme.surface,
        padding: const w.EdgeInsets.only(left: 2, right: 2, top: 1, bottom: 1),
        child: w.Column(
          gap: 1,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Row(
              mainAxisAlignment: w.MainAxisAlignment.spaceBetween,
              children: [
                w.Text(
                  '${widget.item.kind.toUpperCase()} #${widget.item.number}',
                  style: theme.titleMedium,
                ),
                w.Text('esc', style: hint),
              ],
            ),
            w.Text(widget.item.title, style: theme.titleLarge),
            w.Text(
              '${widget.item.author} / ${widget.item.status} / ${widget.item.footer}',
              style: hint,
            ),
            w.ScrollArea(
              height: 14,
              showScrollbar: true,
              child: GithubMarkdownBody(
                data: widget.item.body,
                fallbackMarkdown: body.isEmpty
                    ? '_No description provided._'
                    : body,
                maxWidth: 80,
                textStyle: theme.bodyMedium,
              ),
            ),
            w.Text(widget.item.url, style: hint),
            w.Text(
              'esc/enter close | o opens the browser from the list',
              style: hint,
            ),
          ],
        ),
      ),
    );
  }
}
