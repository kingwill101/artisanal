import '../widgets/footer_bar.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/chat_model.dart';
import '../widgets/chat_body.dart';
import '../widgets/prompt_input.dart';
import '../widgets/session_header.dart';
import 'session/sidebar.dart';

class SessionShell extends w.StatelessWidget {
  SessionShell({
    required this.model,
    required this.scrollController,
    required this.promptController,
    required this.statusHint,
    required this.replayEvents,
    required this.replayHistory,
    this.onReplayHistoryModeSelected,
    this.onReplayHistoryExpandedChanged,
    super.key,
  });

  final ChatModel model;
  final w.WidgetScrollController scrollController;
  final w.TextFieldController promptController;
  final String statusHint;
  final List<tui.ReplayEventPresentation> replayEvents;
  final w.ReplayEventHistoryState replayHistory;
  final w.ValueCmdCallback<w.ReplayEventHistoryMode>?
  onReplayHistoryModeSelected;
  final w.ValueCmdCallback<bool>? onReplayHistoryExpandedChanged;

  @override
  w.Widget build(w.BuildContext context) {
    final content = SessionContentPane(
      model: model,
      scrollController: scrollController,
      promptController: promptController,
      statusHint: statusHint,
      replayEvents: replayEvents,
      replayHistory: replayHistory,
      onReplayHistoryModeSelected: onReplayHistoryModeSelected,
      onReplayHistoryExpandedChanged: onReplayHistoryExpandedChanged,
    );
    if (!model.sidebarOpen) return content;
    return w.Row(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Expanded(child: content),
        SessionSidebarPane(model: model),
      ],
    );
  }
}

class SessionContentPane extends w.StatelessWidget {
  SessionContentPane({
    required this.model,
    required this.scrollController,
    required this.promptController,
    required this.statusHint,
    required this.replayEvents,
    required this.replayHistory,
    this.onReplayHistoryModeSelected,
    this.onReplayHistoryExpandedChanged,
    super.key,
  });

  final ChatModel model;
  final w.WidgetScrollController scrollController;
  final w.TextFieldController promptController;
  final String statusHint;
  final List<tui.ReplayEventPresentation> replayEvents;
  final w.ReplayEventHistoryState replayHistory;
  final w.ValueCmdCallback<w.ReplayEventHistoryMode>?
  onReplayHistoryModeSelected;
  final w.ValueCmdCallback<bool>? onReplayHistoryExpandedChanged;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Expanded(
          child: w.Padding(
            padding: const w.EdgeInsets.only(
              left: 2,
              right: 2,
              top: 1,
              bottom: 1,
            ),
            child: w.Column(
              crossAxisAlignment: w.CrossAxisAlignment.stretch,
              children: [
                SessionHeader(
                  title: model.sessionTitle.isNotEmpty
                      ? model.sessionTitle
                      : 'New Session',
                  contextTokens: model.contextTokens,
                  contextPercentage: model.contextPercentage,
                  cost: model.cost,
                ),
                w.SizedBox(height: 1),
                w.Expanded(
                  child: ChatBody(
                    messages: model.messages,
                    scrollController: scrollController,
                    showDiffs: true,
                  ),
                ),
                w.SizedBox(height: 1),
                PromptInput(
                  controller: promptController,
                  agentName: model.agentName,
                  modelName: model.modelName,
                  providerName: model.providerName,
                ),
                if (replayEvents.isNotEmpty) ...[
                  w.SizedBox(height: 1),
                  w.ReplayEventHistoryBrowser.renderCaptures(
                    title: 'Replay History',
                    events: replayEvents,
                    state: replayHistory,
                    onStateChanged: (state) {
                      if (state.mode != replayHistory.mode) {
                        return onReplayHistoryModeSelected?.call(state.mode);
                      }
                      if (state.expanded != replayHistory.expanded) {
                        return onReplayHistoryExpandedChanged?.call(
                          state.expanded,
                        );
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        FooterBar(
          workingDirectory: model.workingDirectory,
          lspCount: model.lspServers.length,
          mcpCount: model.mcpServers.length,
          statusHint: statusHint,
        ),
      ],
    );
  }
}
