/// Prompt input widget — matches the real OpenCode prompt.
///
/// Left ┃ border colored by agent, backgroundElement bg,
/// textarea, agent/model/provider labels below input.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import 'left_accent_pane.dart';
import 'state/open_code_ui_state.dart';
import '../theme.dart';

/// Agent color lookup (matches OpenCode agent system).
style.Color agentColor(String agent) {
  return switch (agent) {
    'build' => OC.secondary,
    'code' => OC.secondary,
    'task' => OC.accent,
    'plan' => OC.success,
    _ => OC.secondary,
  };
}

class PromptInput extends w.StatelessWidget {
  PromptInput({
    this.controller,
    this.agentName = 'build',
    this.modelName = 'gpt-5.3-codex',
    this.providerName = 'OpenAI',
    this.showPlaceholder = true,
    this.onChanged,
    this.enterBehavior = EnterBehavior.send,
    this.onSubmit,
    this.dimmed = false,
    super.key,
  });

  final w.TextEditingController? controller;
  final String agentName;
  final String modelName;
  final String providerName;
  final bool showPlaceholder;
  final w.TextChangedCallback? onChanged;
  final EnterBehavior enterBehavior;
  final void Function(String text)? onSubmit;
  final bool dimmed;

  @override
  w.Widget build(w.BuildContext context) {
    final color = agentColor(agentName);
    final agentLabel = '${agentName[0].toUpperCase()}${agentName.substring(1)}';

    final modelParts = modelName.split('-');
    final modelDisplay = modelParts.length > 3
        ? modelParts.take(3).join('-')
        : modelName;

    final submitHelper = enterBehavior == EnterBehavior.send
        ? 'Enter'
        : 'Ctrl+Enter';

    return w.Row(
      children: [
        w.Expanded(
          child: LeftAccentPane(
            accentColor: color,
            backgroundColor: OC.backgroundElement,
            dimmed: dimmed,
            padding: const w.EdgeInsets.only(
              left: 2,
              right: 2,
              top: 1,
              bottom: 1,
            ),
            child: w.Column(
              children: [
                w.TextField(
                  controller: controller,
                  focusId: 'home-prompt',
                  prompt: ' ',
                  placeholder: showPlaceholder ? 'Ask anything...' : '',
                  onChanged: onChanged,
                  autofocus: true,
                  multiline: true,
                  maxLines: 6,
                  charLimit: 4000,
                  collapseLargePaste: true,
                  collapsedPasteMinChars: 1200,
                  collapsedPasteMinLines: 20,
                ),
                w.SizedBox(height: 1),
                w.Row(
                  gap: 1,
                  children: [
                    w.Text(agentLabel, style: style.Style()..foreground(color)),
                    w.Text(
                      modelDisplay,
                      style: style.Style()..foreground(OC.text),
                      softWrap: false,
                    ),
                    w.Text(
                      providerName,
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                    w.Spacer(),
                    w.Text(
                      submitHelper,
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
