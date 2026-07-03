import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

final class GithubRepositoryPrompt extends w.StatefulWidget {
  GithubRepositoryPrompt({
    required this.initialValue,
    required this.currentRepository,
    required this.error,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  final String initialValue;
  final String? currentRepository;
  final String? error;
  final tui.Cmd? Function(String value) onSubmit;
  final tui.Cmd? Function() onCancel;

  @override
  w.State<GithubRepositoryPrompt> createState() =>
      _GithubRepositoryPromptState();
}

final class _GithubRepositoryPromptState
    extends w.State<GithubRepositoryPrompt> {
  late final w.TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = w.TextEditingController(text: widget.initialValue);
  }

  @override
  tui.Cmd? didUpdateWidget(covariant GithubRepositoryPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text.isEmpty) {
      _controller.text = widget.initialValue;
    }
    return null;
  }

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
    final errorStyle = theme.bodySmall.copy()..foreground(theme.error);

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
                w.Text('Switch target', style: theme.titleMedium),
                w.Text('esc', style: hint),
              ],
            ),
            w.Text(
              'Enter @me, owner/org, owner/repo, or a github.com URL. Blank opens current gh repo.',
              style: hint,
            ),
            if (widget.currentRepository != null)
              w.Text('Current: ${widget.currentRepository}', style: hint),
            w.Frame(
              background: theme.resolvedSurfaceVariant,
              padding: const w.EdgeInsets.symmetric(horizontal: 1),
              child: w.TextField(
                controller: _controller,
                prompt: 'target> ',
                placeholder: '@me',
                autofocus: true,
                maxLines: 1,
              ),
            ),
            if (widget.error != null) w.Text(widget.error!, style: errorStyle),
            w.Text('enter load | esc cancel', style: hint),
          ],
        ),
      ),
    );
  }
}
