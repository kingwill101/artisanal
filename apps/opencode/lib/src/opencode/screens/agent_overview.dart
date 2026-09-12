/// Agent chrome showcase — laid out like an OpenCode session surface.
///
/// OpenCode does not use a separate "agent overview" route; permission /
/// question docks and tool cards appear *in* the session. This screen
/// stages those widgets with the same header / body / dock / footer chrome
/// (and the same responsive sidebar policy) so we can iterate visual parity.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/chat_model.dart';
import '../theme.dart';
import '../widgets/agent/permission_dock.dart';
import '../widgets/agent/question_dock.dart';
import '../widgets/agent/tool_card.dart';
import '../widgets/footer_bar.dart';
import '../widgets/session_header.dart';
import 'session/sidebar.dart';

/// Demo surface for OpenCode-style agent chrome (example-local widgets).
class AgentOverview extends w.StatelessWidget {
  AgentOverview({required this.model, super.key});

  final ChatModel model;

  @override
  w.Widget build(w.BuildContext context) {
    // Same shell as session: main lane + optional auto sidebar.
    return w.LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : (w.MediaQuery.maybeOf(context)?.size.width.toInt() ?? 80);
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight.toInt()
            : (w.MediaQuery.maybeOf(context)?.size.height.toInt() ?? 40);
        final showSidebar = model.isSidebarVisible(width);
        // Pin docks only when there is room; otherwise scroll with content.
        final pinDocks = height >= 36 && width >= 60;

        final main = _AgentMainLane(
          model: model,
          pinDocks: pinDocks,
        );

        return w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Expanded(
              child: w.Row(
                crossAxisAlignment: w.CrossAxisAlignment.stretch,
                children: [
                  w.Expanded(child: main),
                  if (showSidebar) SessionSidebarPane(model: model),
                ],
              ),
            ),
            FooterBar(
              workingDirectory: model.workingDirectory,
              lspCount: model.lspServers.length,
              mcpCount: model.mcpServers.length,
              statusHint: 'ctrl+x a · agent',
              mode: model.mode,
            ),
          ],
        );
      },
    );
  }
}

class _AgentMainLane extends w.StatelessWidget {
  _AgentMainLane({required this.model, required this.pinDocks});

  final ChatModel model;
  final bool pinDocks;

  @override
  w.Widget build(w.BuildContext context) {
    final stream = <w.Widget>[
      w.Text(
        'Agent loop surfaces (demo)',
        style: style.Style()
          ..foreground(OC.textMuted)
          ..bold(),
      ),
      w.Text(
        'ctrl+x a here · ctrl+x b sidebar · ctrl+p commands · docks match session',
        style: style.Style()..foreground(OC.textMuted),
      ),
      w.SizedBox(height: 1),
      ToolCardInline(
        toolName: 'read',
        title: 'Read',
        status: ToolCardStatus.completed,
        filePath: 'lib/main.dart',
      ),
      ToolCardInline(
        toolName: 'bash',
        title: 'Bash',
        status: ToolCardStatus.running,
        input: 'dart analyze',
      ),
      ToolCard(
        toolName: 'edit',
        title: '# Edit',
        status: ToolCardStatus.completed,
        filePath: 'pubspec.yaml',
        body: w.Text(
          '  name: demo',
          style: style.Style()..foreground(OC.textMuted),
        ),
      ),
      ToolCard(
        toolName: 'bash',
        title: '# Bash',
        status: ToolCardStatus.error,
        error: 'exit 1: command not found',
      ),
      w.SizedBox(height: 1),
      _metaRow('Agent', model.agentName),
      _metaRow('Model', model.modelName),
      _metaRow('Provider', model.providerName),
      w.SizedBox(height: 1),
      w.Text(
        'Subagents',
        style: style.Style()
          ..foreground(OC.textMuted)
          ..bold(),
      ),
      w.SubagentRow(
        title: 'Explore codebase layout',
        agentLabel: 'Explore',
        status: w.SubagentStatus.completed,
        index: 1,
        total: 3,
        detail: '12s · 4.2k tokens',
      ),
      w.SubagentRow(
        title: 'Draft StatusSection API',
        agentLabel: 'Code',
        status: w.SubagentStatus.running,
        index: 2,
        total: 3,
        detail: 'running…',
      ),
      w.SubagentRow(
        title: 'Write widget tests',
        agentLabel: 'Code',
        status: w.SubagentStatus.pending,
        index: 3,
        total: 3,
      ),
    ];

    final docks = <w.Widget>[
      PermissionDock(
        title: 'Run bash',
        detail: 'dart test',
        selectedAction: PermissionAction.allow,
        body: w.Text(
          'Agent wants to execute a shell command.',
          style: style.Style()..foreground(OC.textMuted),
        ),
      ),
      w.SizedBox(height: 1),
      QuestionDock(
        questions: const [
          AgentQuestion(
            id: 'package',
            prompt: 'Which package manager?',
            options: [
              QuestionOption(
                id: 'pub',
                label: 'pub',
                description: 'Dart default',
              ),
              QuestionOption(
                id: 'melos',
                label: 'melos',
                description: 'Monorepo tooling',
              ),
            ],
          ),
          AgentQuestion(
            id: 'targets',
            prompt: 'What should we ship first?',
            multiple: true,
            options: [
              QuestionOption(id: 'cli', label: 'CLI'),
              QuestionOption(id: 'tui', label: 'TUI widgets'),
              QuestionOption(id: 'docs', label: 'Docs'),
            ],
          ),
        ],
      ),
    ];

    return w.Padding(
      padding: const w.EdgeInsets.only(left: 2, right: 2, top: 1, bottom: 1),
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          SessionHeader(
            title: model.sessionTitle.isNotEmpty
                ? model.sessionTitle
                : 'Agent chrome',
            contextTokens: model.contextTokens,
            contextPercentage: model.contextPercentage,
            cost: model.cost,
            mode: model.mode,
          ),
          w.SizedBox(height: 1),
          if (pinDocks) ...[
            w.Expanded(
              child: w.SingleChildScrollView(
                child: w.Column(
                  crossAxisAlignment: w.CrossAxisAlignment.stretch,
                  gap: 1,
                  children: stream,
                ),
              ),
            ),
            w.SizedBox(height: 1),
            ...docks,
          ] else
            w.Expanded(
              child: w.SingleChildScrollView(
                child: w.Column(
                  crossAxisAlignment: w.CrossAxisAlignment.stretch,
                  gap: 1,
                  children: [
                    ...stream,
                    w.SizedBox(height: 1),
                    ...docks,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  w.Widget _metaRow(String label, String value) {
    return w.Row(
      children: [
        w.Text('$label:', style: style.Style()..foreground(OC.textMuted)),
        w.SizedBox(width: 2),
        w.Text(value, style: style.Style()..foreground(OC.text)),
      ],
    );
  }
}
