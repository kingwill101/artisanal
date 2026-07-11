import '../widgets/footer_bar.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/chat_model.dart';
import '../widgets/chat_body.dart';
import '../widgets/prompt_input.dart';
import '../widgets/session_header.dart';
import 'session/sidebar.dart';

class SessionShell extends w.StatefulWidget {
  SessionShell({
    required this.model,
    required this.scrollController,
    required this.promptController,
    required this.statusHint,
    required this.replayEvents,
    required this.replayHistory,
    this.chordActive = false,
    this.scannerFrame,
    this.scanner,
    this.onSubmit,
    this.onReplayHistoryModeSelected,
    this.onReplayHistoryExpandedChanged,
    super.key,
  });

  final ChatModel model;
  final w.WidgetScrollController scrollController;
  final w.TextFieldController promptController;
  final String statusHint;
  final bool chordActive;
  final String? scannerFrame;
  final w.SpinnerController? scanner;
  final void Function(String text)? onSubmit;
  final List<tui.ReplayEventPresentation> replayEvents;
  final w.ReplayEventHistoryState replayHistory;
  final w.ValueCmdCallback<w.ReplayEventHistoryMode>?
  onReplayHistoryModeSelected;
  final w.ValueCmdCallback<bool>? onReplayHistoryExpandedChanged;

  @override
  w.State<SessionShell> createState() => _SessionShellState();
}

class _SessionShellState extends w.State<SessionShell> {
  @override
  w.Widget build(w.BuildContext context) {
    final content = SessionContentPane(
      model: widget.model,
      scrollController: widget.scrollController,
      promptController: widget.promptController,
      statusHint: widget.statusHint,
      replayEvents: widget.replayEvents,
      replayHistory: widget.replayHistory,
      chordActive: widget.chordActive,
      scannerFrame: widget.scannerFrame,
      scanner: widget.scanner,
      onSubmit: widget.onSubmit,
      onReplayHistoryModeSelected: widget.onReplayHistoryModeSelected,
      onReplayHistoryExpandedChanged: widget.onReplayHistoryExpandedChanged,
    );

    return w.Row(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Expanded(child: content),
        if (widget.model.sidebarOpen) SessionSidebarPane(model: widget.model),
      ],
    );
  }
}

class SessionContentPane extends w.StatefulWidget {
  SessionContentPane({
    required this.model,
    required this.scrollController,
    required this.promptController,
    required this.statusHint,
    required this.replayEvents,
    required this.replayHistory,
    this.chordActive = false,
    this.scannerFrame,
    this.scanner,
    this.onSubmit,
    this.onReplayHistoryModeSelected,
    this.onReplayHistoryExpandedChanged,
    super.key,
  });

  final ChatModel model;
  final w.WidgetScrollController scrollController;
  final w.TextFieldController promptController;
  final String statusHint;
  final bool chordActive;
  final String? scannerFrame;
  final w.SpinnerController? scanner;
  final List<tui.ReplayEventPresentation> replayEvents;
  final w.ReplayEventHistoryState replayHistory;
  final void Function(String text)? onSubmit;
  final w.ValueCmdCallback<w.ReplayEventHistoryMode>?
  onReplayHistoryModeSelected;
  final w.ValueCmdCallback<bool>? onReplayHistoryExpandedChanged;

  @override
  w.State<SessionContentPane> createState() => _SessionContentPaneState();
}

class _SessionContentPaneState extends w.State<SessionContentPane> {
  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(:final key) when key.isEnterLike:
        final text = _textController.value.text;
        if (widget.model.enterBehavior == .send) {
          _textController.clear();
          widget.onSubmit?.call(text);
          return null;
        } else {
          if (key.shift) {
            _textController.clear();
            widget.onSubmit?.call(text);
            return null;
          }
        }
        break;
    }

    return null;
  }

  final _textController = w.TextEditingController();

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
                  title: widget.model.sessionTitle.isNotEmpty
                      ? widget.model.sessionTitle
                      : 'New Session',
                  contextTokens: widget.model.contextTokens,
                  contextPercentage: widget.model.contextPercentage,
                  cost: widget.model.cost,
                  mode: widget.model.mode,
                  dimmed: widget.chordActive,
                ),
                w.SizedBox(height: 1),
                w.Expanded(
                  child: ChatBody(
                    messages: widget.model.messages,
                    scrollController: widget.scrollController,
                    showDiffs: true,
                  ),
                ),
                w.SizedBox(height: 1),
                PromptInput(
                  controller: _textController,
                  agentName: widget.model.agentName,
                  modelName: widget.model.modelName,
                  providerName: widget.model.providerName,
                  enterBehavior: widget.model.enterBehavior,
                  dimmed: widget.chordActive,
                ),
                if (widget.replayEvents.isNotEmpty) ...[
                  w.SizedBox(height: 1),
                  w.ReplayEventHistoryBrowser.renderCaptures(
                    title: 'Replay History',
                    events: widget.replayEvents,
                    state: widget.replayHistory,
                    onStateChanged: (state) {
                      if (state.mode != widget.replayHistory.mode) {
                        return widget.onReplayHistoryModeSelected?.call(
                          state.mode,
                        );
                      }
                      if (state.expanded != widget.replayHistory.expanded) {
                        return widget.onReplayHistoryExpandedChanged?.call(
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
          workingDirectory: widget.model.workingDirectory,
          lspCount: widget.model.lspServers.length,
          mcpCount: widget.model.mcpServers.length,
          statusHint: widget.statusHint,
          scanner: widget.scanner,
          tokenCount: widget.model.contextTokens,
          mode: widget.model.mode,
        ),
      ],
    );
  }
}
