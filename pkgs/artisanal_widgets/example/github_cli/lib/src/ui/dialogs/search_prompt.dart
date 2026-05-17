import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

final class GithubSearchPrompt extends w.StatefulWidget {
  GithubSearchPrompt({
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  final tui.Cmd? Function(String value) onSubmit;
  final tui.Cmd? Function() onCancel;

  @override
  w.State<GithubSearchPrompt> createState() => _GithubSearchPromptState();
}

final class _GithubSearchPromptState extends w.State<GithubSearchPrompt> {
  final _controller = w.TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    if (msg.key.type == tui.KeyType.escape) return widget.onCancel();
    if (msg.key.type == tui.KeyType.enter) {
      return widget.onSubmit(_controller.text);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final hint = theme.bodySmall.copy()..foreground(theme.muted);

    return w.SizedBox(
      width: 70,
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
                w.Text('Search PRs & Issues', style: theme.titleMedium),
                w.Text('esc', style: hint),
              ],
            ),
            w.Text(
              'Enter a search query. Results appear in the work queue.',
              style: hint,
            ),
            w.Frame(
              background: theme.background,
              padding: const w.EdgeInsets.symmetric(horizontal: 1),
              child: w.TextField(
                controller: _controller,
                prompt: 'search> ',
                placeholder: 'is:open is:issue label:bug',
                autofocus: true,
                maxLines: 1,
              ),
            ),
            w.Text('enter search | esc cancel', style: hint),
          ],
        ),
      ),
    );
  }
}
