import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/action_prompt.dart';

final class GithubActionPromptDialog extends w.StatefulWidget {
  GithubActionPromptDialog({
    required this.prompt,
    required this.error,
    required this.running,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  final GithubActionPrompt prompt;
  final String? error;
  final bool running;
  final Cmd? Function(String value) onSubmit;
  final Cmd? Function() onCancel;

  @override
  w.State<GithubActionPromptDialog> createState() =>
      _GithubActionPromptDialogState();
}

final class _GithubActionPromptDialogState
    extends w.State<GithubActionPromptDialog> {
  late final w.TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = w.TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is! KeyMsg) return null;
    if (widget.running) return null;
    if (msg.key.type == KeyType.escape) return widget.onCancel();
    if (msg.key.type == KeyType.enter) {
      return widget.onSubmit(_controller.text);
    }
    return null;
  }

  final FocusController _editorFocus = FocusController();
  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final hint = theme.bodySmall.copy()..foreground(theme.muted);
    final errorStyle = theme.bodySmall.copy()..foreground(theme.error);

    return w.SizedBox(
      width: 78,
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
                w.Text(widget.prompt.title, style: theme.titleMedium),
                if (widget.running)
                  w.SpinnerIndicator()
                else
                  w.Text('esc', style: hint),
              ],
            ),
            w.Text(widget.prompt.description, style: hint),
            w.Frame(
              background: theme.resolvedSurfaceVariant,
              padding: const w.EdgeInsets.symmetric(horizontal: 1),
              child: w.TextField(
                controller: _controller,
                focusController: _editorFocus,
                prompt: '> ',
                placeholder: widget.prompt.placeholder,
                autofocus: true,
                maxLines: widget.prompt.maxLines,
              ),
            ),
            if (widget.error != null) w.Text(widget.error!, style: errorStyle),
            w.Text('enter submit | esc cancel', style: hint),
          ],
        ),
      ),
    );
  }
}
