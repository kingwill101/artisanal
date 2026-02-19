/// Sidebar widget — matches the real OpenCode sidebar.
///
/// Fixed 42-column width, backgroundPanel bg, scrollable content area
/// with Title, Context, MCP, LSP, Todo, Modified Files sections.
/// Bottom pinned: directory path + version.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../models/chat_model.dart';
import '../theme.dart';

class SidebarWidget extends w.StatelessWidget {
  SidebarWidget({
    required this.model,
    this.sidebarState,
    this.onToggleMcp,
    this.onToggleLsp,
    this.onToggleTodo,
    this.onToggleFiles,
    super.key,
  });

  final ChatModel model;
  final SidebarState? sidebarState;
  final w.VoidCallback? onToggleMcp;
  final w.VoidCallback? onToggleLsp;
  final w.VoidCallback? onToggleTodo;
  final w.VoidCallback? onToggleFiles;

  SidebarState get _sidebar => sidebarState ?? model.sidebar;

  @override
  w.Widget build(w.BuildContext context) {
    return w.SizedBox(
      width: 42,
      child: w.Container(
        color: OC.backgroundPanel,
        padding: const w.EdgeInsets.only(top: 1, bottom: 1, left: 2, right: 2),
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            // Scrollable content
            w.Expanded(
              child: w.SingleChildScrollView(
                child: w.Column(
                  gap: 1,
                  children: [
                    _buildTitle(),
                    _buildContext(),
                    if (model.mcpServers.isNotEmpty) _buildMcpSection(),
                    _buildLspSection(),
                    if (_hasActiveTodos()) _buildTodoSection(),
                    if (model.modifiedFiles.isNotEmpty) _buildFilesSection(),
                  ],
                ),
              ),
            ),
            // Bottom pinned: directory + version
            w.SizedBox(height: 1),
            _buildBottomInfo(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Title
  // ─────────────────────────────────────────────────────────────────────────

  w.Widget _buildTitle() {
    final title = model.sessionTitle.isNotEmpty
        ? model.sessionTitle
        : 'New Session';
    return w.Padding(
      padding: const w.EdgeInsets.only(right: 1),
      child: w.Text(
        title,
        style: style.Style()
          ..foreground(OC.text)
          ..bold(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Context section
  // ─────────────────────────────────────────────────────────────────────────

  w.Widget _buildContext() {
    final pct = '${model.contextPercentage}%';
    final cost = '\$${model.cost.toStringAsFixed(2)}';

    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      gap: 0,
      children: [
        w.Text(
          'Context',
          style: style.Style()
            ..foreground(OC.text)
            ..bold(),
        ),
        _infoLine('${model.contextTokens} tokens'),
        _infoLine('$pct used'),
        _infoLine('$cost spent'),
      ],
    );
  }

  w.Widget _infoLine(String text) {
    return w.Text(text, style: style.Style()..foreground(OC.textMuted));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MCP section
  // ─────────────────────────────────────────────────────────────────────────

  w.Widget _buildMcpSection() {
    final expanded = _sidebar.mcpExpanded;
    final servers = model.mcpServers;

    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      gap: 0,
      children: [
        w.GestureDetector(
          onTap: () {
            onToggleMcp?.call();
            return null;
          },
          child: w.Row(
            gap: 1,
            children: [
              if (servers.length > 2)
                w.Text(
                  expanded ? '\u25bc' : '\u25b6',
                  style: style.Style()..foreground(OC.text),
                ),
              w.Text(
                'MCP',
                style: style.Style()
                  ..foreground(OC.text)
                  ..bold(),
              ),
            ],
          ),
        ),
        if (expanded || servers.length <= 2) ...servers.map((s) => _mcpItem(s)),
      ],
    );
  }

  w.Widget _mcpItem(McpServer server) {
    final color = switch (server.status) {
      'connected' => OC.success,
      'failed' => OC.error,
      'disabled' => OC.textMuted,
      _ => OC.textMuted,
    };
    final statusText = switch (server.status) {
      'connected' => 'Connected',
      'failed' => 'Failed',
      'disabled' => 'Disabled',
      _ => server.status,
    };

    return w.Row(
      gap: 1,
      children: [
        w.Text('\u2022', style: style.Style()..foreground(color)),
        w.Text(
          server.name,
          style: style.Style()..foreground(OC.text),
          softWrap: false,
        ),
        w.Text(statusText, style: style.Style()..foreground(OC.textMuted)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LSP section
  // ─────────────────────────────────────────────────────────────────────────

  w.Widget _buildLspSection() {
    final expanded = _sidebar.lspExpanded;
    final servers = model.lspServers;

    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      gap: 0,
      children: [
        w.GestureDetector(
          onTap: () {
            onToggleLsp?.call();
            return null;
          },
          child: w.Row(
            gap: 1,
            children: [
              if (servers.length > 2)
                w.Text(
                  expanded ? '\u25bc' : '\u25b6',
                  style: style.Style()..foreground(OC.text),
                ),
              w.Text(
                'LSP',
                style: style.Style()
                  ..foreground(OC.text)
                  ..bold(),
              ),
            ],
          ),
        ),
        if (expanded || servers.length <= 2) ...[
          if (servers.isEmpty)
            w.Text(
              'LSPs will activate as files are read',
              style: style.Style()..foreground(OC.textMuted),
            )
          else
            ...servers.map((s) => _lspItem(s)),
        ],
      ],
    );
  }

  w.Widget _lspItem(LspServer server) {
    final color = server.status == 'connected' ? OC.success : OC.error;
    return w.Row(
      gap: 1,
      children: [
        w.Text('\u2022', style: style.Style()..foreground(color)),
        w.Text(
          server.name,
          style: style.Style()..foreground(OC.text),
          softWrap: false,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Todo section
  // ─────────────────────────────────────────────────────────────────────────

  bool _hasActiveTodos() {
    return model.todos.any((t) => !t.done);
  }

  w.Widget _buildTodoSection() {
    final expanded = _sidebar.todoExpanded;
    final todos = model.todos;

    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      gap: 0,
      children: [
        w.GestureDetector(
          onTap: () {
            onToggleTodo?.call();
            return null;
          },
          child: w.Row(
            gap: 1,
            children: [
              if (todos.length > 2)
                w.Text(
                  expanded ? '\u25bc' : '\u25b6',
                  style: style.Style()..foreground(OC.text),
                ),
              w.Text(
                'Todo',
                style: style.Style()
                  ..foreground(OC.text)
                  ..bold(),
              ),
            ],
          ),
        ),
        if (expanded || todos.length <= 2) ...todos.map((t) => _todoItem(t)),
      ],
    );
  }

  w.Widget _todoItem(TodoItem todo) {
    final mark = todo.done
        ? 'x'
        : todo.inProgress
        ? '~'
        : ' ';
    final color = todo.done
        ? OC.success
        : todo.inProgress
        ? OC.warning
        : OC.textMuted;

    return w.Row(
      gap: 1,
      children: [
        w.Text('[$mark]', style: style.Style()..foreground(color)),
        w.Text(
          todo.label,
          style: todo.done
              ? (style.Style()
                  ..foreground(OC.textMuted)
                  ..dim())
              : (style.Style()..foreground(OC.text)),
          softWrap: false,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Modified files section
  // ─────────────────────────────────────────────────────────────────────────

  w.Widget _buildFilesSection() {
    final expanded = _sidebar.filesExpanded;
    final files = model.modifiedFiles;

    return w.Column(
      gap: 0,
      children: [
        w.GestureDetector(
          onTap: () {
            onToggleFiles?.call();
            return null;
          },
          child: w.Row(
            gap: 1,
            children: [
              if (files.length > 2)
                w.Text(
                  expanded ? '\u25bc' : '\u25b6',
                  style: style.Style()..foreground(OC.text),
                ),
              w.Text(
                'Modified Files',
                style: style.Style()
                  ..foreground(OC.text)
                  ..bold(),
              ),
            ],
          ),
        ),
        if (expanded || files.length <= 2) ...files.map((f) => _fileItem(f)),
      ],
    );
  }

  w.Widget _fileItem(ModifiedFile file) {
    // Show just the filename for brevity.
    final shortPath = file.path.split('/').last;
    return w.Row(
      children: [
        w.Expanded(
          child: w.Text(
            shortPath,
            style: style.Style()..foreground(OC.textMuted),
            softWrap: false,
          ),
        ),
        w.Row(
          gap: 1,
          children: [
            w.Text(
              '+${file.additions}',
              style: style.Style()..foreground(OC.diffAdded),
            ),
            w.Text(
              '-${file.deletions}',
              style: style.Style()..foreground(OC.diffRemoved),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom pinned section
  // ─────────────────────────────────────────────────────────────────────────

  w.Widget _buildBottomInfo() {
    // Split directory: parent/ in muted, last segment in text
    final parts = model.workingDirectory.split('/');
    final last = parts.isNotEmpty ? parts.last : '';
    final parent = parts.length > 1
        ? '${parts.sublist(0, parts.length - 1).join('/')}/'
        : '';

    return w.Column(
      gap: 0,
      children: [
        w.Row(
          children: [
            w.Text(parent, style: style.Style()..foreground(OC.textMuted)),
            w.Text(last, style: style.Style()..foreground(OC.text)),
          ],
        ),
        w.Row(
          gap: 0,
          children: [
            w.Text('\u2022 ', style: style.Style()..foreground(OC.success)),
            w.Text(
              'Open',
              style: style.Style()
                ..foreground(OC.textMuted)
                ..bold(),
            ),
            w.Text(
              'Code ',
              style: style.Style()
                ..foreground(OC.text)
                ..bold(),
            ),
            w.Text('0.1.0', style: style.Style()..foreground(OC.textMuted)),
          ],
        ),
      ],
    );
  }
}
