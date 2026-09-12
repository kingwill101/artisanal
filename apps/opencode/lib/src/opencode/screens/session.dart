import '../widgets/footer_bar.dart';
import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/chat_model.dart';
import '../theme.dart';
import '../widgets/agent/permission_dock.dart';
import '../widgets/agent/question_dock.dart';
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
    this.agentDock = SessionAgentDock.none,
    this.onAgentDockDismiss,
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

  /// Inline agent chrome above the prompt (OpenCode session dock slot).
  final SessionAgentDock agentDock;
  final void Function()? onAgentDockDismiss;
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
      agentDock: widget.agentDock,
      onAgentDockDismiss: widget.onAgentDockDismiss,
      scannerFrame: widget.scannerFrame,
      scanner: widget.scanner,
      onSubmit: widget.onSubmit,
      onReplayHistoryModeSelected: widget.onReplayHistoryModeSelected,
      onReplayHistoryExpandedChanged: widget.onReplayHistoryExpandedChanged,
    );

    // OpenCode: auto-hide sidebar when width ≤ 120 unless force-opened.
    return w.LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : (w.MediaQuery.maybeOf(context)?.size.width.toInt() ?? 80);
        final showSidebar = widget.model.isSidebarVisible(width);

        return w.Row(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Expanded(child: content),
            if (showSidebar) SessionSidebarPane(model: widget.model),
          ],
        );
      },
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
    this.agentDock = SessionAgentDock.none,
    this.onAgentDockDismiss,
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
  final SessionAgentDock agentDock;
  final void Function()? onAgentDockDismiss;
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
  final _textController = w.TextEditingController();

  @override
  w.Widget build(w.BuildContext context) {
    // Live sequence state from KeymapHub — same catalog as the interceptor.
    final hub = w.KeymapHubScope.maybeOf(context);
    final chordActive = hub?.isSequencePending ?? false;
    final scannerRunning = widget.scanner?.isRunning ?? false;
    final dimmed = chordActive || scannerRunning;
    final statusHint =
        chordActive ? (hub?.pendingStatusHint ?? '') : widget.statusHint;

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
                  dimmed: dimmed,
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
                // OpenCode places permission/question docks above the prompt.
                if (widget.agentDock == SessionAgentDock.permission) ...[
                  PermissionDock(
                    title: 'Run bash',
                    detail: 'dart test',
                    selectedAction: PermissionAction.allow,
                    onAction: (_) => widget.onAgentDockDismiss?.call(),
                    body: w.Text(
                      'Agent wants to execute a shell command.',
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                  ),
                  w.SizedBox(height: 1),
                ],
                if (widget.agentDock == SessionAgentDock.question) ...[
                  QuestionDock(
                    questions: const [
                      AgentQuestion(
                        id: 'scope',
                        prompt: 'Ship scope for this PR?',
                        options: [
                          QuestionOption(
                            id: 'min',
                            label: 'Minimal',
                            description: 'docs only',
                          ),
                          QuestionOption(
                            id: 'full',
                            label: 'Full',
                            description: 'code + tests',
                          ),
                        ],
                      ),
                    ],
                    onSubmit: (_) => widget.onAgentDockDismiss?.call(),
                    onReject: () => widget.onAgentDockDismiss?.call(),
                  ),
                  w.SizedBox(height: 1),
                ],
                PromptInput(
                  controller: _textController,
                  agentName: widget.model.agentName,
                  modelName: widget.model.modelName,
                  providerName: widget.model.providerName,
                  enterBehavior: widget.model.enterBehavior,
                  dimmed: dimmed,
                  onSubmit: (text) {
                    _textController.clear();
                    widget.onSubmit?.call(text);
                  },
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
        // Which-key: auto from KeymapHub pending continuations.
        w.WhichKeySlot(
          bannerColor: OC.primary,
          bannerForeground: OC.background,
          background: OC.backgroundPanel,
          borderColor: OC.primary,
          keyBackground: OC.backgroundElement,
          keyForeground: OC.text,
          descriptionForeground: OC.text,
          mutedForeground: OC.textMuted,
          accentForeground: OC.primary,
        ),
        FooterBar(
          workingDirectory: widget.model.workingDirectory,
          lspCount: widget.model.lspServers.length,
          mcpCount: widget.model.mcpServers.length,
          statusHint: statusHint,
          scanner: widget.scanner,
          tokenCount: widget.model.contextTokens,
          mode: widget.model.mode,
        ),
      ],
    );
  }
}
