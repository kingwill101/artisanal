/// Home view — the landing screen shown before a session is active.
///
/// Matches the real OpenCode home layout:
/// - Centered ASCII logo
/// - Centered prompt (max-width ~75)
/// - Random tip below
/// - MCP status in footer area
/// - Footer bar at bottom
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui show Cmd, KeyMsg, Keys, Msg;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../models/chat_model.dart';
import '../theme.dart';
import 'footer_bar.dart';
import 'logo_widget.dart';
import 'prompt_input.dart';
import 'tips_widget.dart';

/// The home / landing view before a chat session starts.
class HomeView extends w.StatefulWidget {
  HomeView({required this.model, this.onSubmit, super.key});

  final ChatModel model;

  /// Called when the user submits text from the prompt.
  final void Function(String text)? onSubmit;

  @override
  w.State createState() => _HomeViewState();
}

class _HomeViewState extends w.State<HomeView> {
  @override
  w.Widget build(w.BuildContext context) {
    final model = widget.model;

    return w.Column(
      mainAxisSize: w.MainAxisSize.max,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Expanded(
          child: w.Container(
            color: OC.background,
            child: w.Padding(
              padding: const w.EdgeInsets.only(left: 2, right: 2),
              child: w.Column(
                mainAxisSize: w.MainAxisSize.max,
                children: [
                  w.Spacer(flex: 5),
                  w.Center(
                    child: w.ConstrainedBox(
                      constraints: w.BoxConstraints(maxWidth: 75),
                      child: w.Column(
                        mainAxisSize: w.MainAxisSize.min,
                        crossAxisAlignment: w.CrossAxisAlignment.stretch,
                        children: [
                          w.Center(child: LogoWidget()),
                          w.SizedBox(height: 1),
                          PromptInput(
                            agentName: model.agentName,
                            modelName: model.modelName,
                            providerName: model.providerName,
                          ),
                          w.SizedBox(height: 1),
                          _buildPromptHints(),
                          w.SizedBox(height: 2),
                          w.Center(child: TipsWidget()),
                        ],
                      ),
                    ),
                  ),
                  w.Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
        FooterBar(
          workingDirectory: model.workingDirectory,
          lspCount: model.lspServers.length,
          mcpCount: model.mcpServers.length,
        ),
      ],
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      // Enter key navigates to session
      if (msg.key == tui.Keys.enter) {
        widget.onSubmit?.call('');
        return tui.Cmd.none();
      }
    }
    return null;
  }

  w.Widget _buildPromptHints() {
    return w.Row(
      mainAxisAlignment: w.MainAxisAlignment.end,
      children: [
        w.Text(
          'ctrl+t',
          style: style.Style()
            ..foreground(OC.text)
            ..dim(),
        ),
        w.SizedBox(width: 1),
        w.Text(
          'variants',
          style: style.Style()
            ..foreground(OC.textMuted)
            ..dim(),
        ),
        w.SizedBox(width: 2),
        w.Text(
          'tab',
          style: style.Style()
            ..foreground(OC.text)
            ..dim(),
        ),
        w.SizedBox(width: 1),
        w.Text(
          'agents',
          style: style.Style()
            ..foreground(OC.textMuted)
            ..dim(),
        ),
        w.SizedBox(width: 2),
        w.Text(
          'ctrl+p',
          style: style.Style()
            ..foreground(OC.text)
            ..dim(),
        ),
        w.SizedBox(width: 1),
        w.Text('commands', style: style.Style()..foreground(OC.textMuted)),
      ],
    );
  }
}
