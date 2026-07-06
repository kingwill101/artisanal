import 'package:artisanal_widgets/widgets.dart' as w;

import 'models/chat_model.dart';
import 'models/message.dart';

ChatModel initialModel() {
  return ChatModel(
    route: AppRoute.home,
    sessionTitle: 'Build OpenCode TUI example',
    modelName: 'gpt-5.3-codex',
    providerName: 'OpenAI',
    agentName: 'build',
    contextTokens: 84231,
    contextPercentage: 42,
    cost: 1.87,
    workingDirectory: '~/code/artisanal',
    sidebarOpen: true,
    mcpServers: const [
      McpServer('filesystem', status: 'connected'),
      McpServer('git', status: 'connected'),
      McpServer('postgres', status: 'disabled'),
    ],
    lspServers: const [
      LspServer('dart', status: 'connected'),
      LspServer('typescript', status: 'connected'),
    ],
    todos: const [
      TodoItem('Add theme system extensions', done: true),
      TodoItem('Build KeyHint and StatusBar widgets', done: true),
      TodoItem('Create AccentPanel component', done: true),
      TodoItem('Implement CommandPalette', done: true),
      TodoItem('Build OpenCode example app', inProgress: true),
      TodoItem('Write tests for new widgets'),
    ],
    modifiedFiles: const [
      ModifiedFile(
        'lib/src/widgets/theme/theme.dart',
        additions: 142,
        deletions: 8,
      ),
      ModifiedFile(
        'lib/src/widgets/components/key_hint.dart',
        additions: 68,
        deletions: 0,
      ),
      ModifiedFile(
        'lib/src/widgets/components/status_bar.dart',
        additions: 74,
        deletions: 0,
      ),
      ModifiedFile('example/opencode/main.dart', additions: 210, deletions: 0),
    ],
    messages: [
      ChatMessage.user(
        'I want to build an OpenCode-style chat UI as an example app '
        'using the artisanal widget system. Can you help me plan this out?',
      ),
      ChatMessage.assistant(
        [
          TextPart(
            "I'd be happy to help! Let me break down the OpenCode UI into "
            'components we can build:\n\n'
            '1. **Two-column split layout** \u2014 main chat area and sidebar\n'
            '2. **Chat body** \u2014 scrollable message list with '
            'user/assistant message parts\n'
            '3. **Prompt input** \u2014 input box with agent/model labels\n'
            '4. **Sidebar** \u2014 context info, collapsible MCP/LSP/todo '
            'sections\n'
            '5. **Footer** \u2014 directory, LSP/MCP counts, status hint\n'
            '6. **Command palette** \u2014 searchable modal overlay (ctrl+p)',
          ),
        ],
        modelId: 'claude-opus-4-20250514',
        agent: 'code',
        duration: const Duration(seconds: 3),
      ),
      ChatMessage.user(
        "Great, let's start by extending the theme system to support "
        'the extra semantic colors and component themes we need.',
      ),
      ChatMessage.assistant(
        [
          ReasoningPart(
            'The user wants theme extensions. I need to add colors for '
            'panels, borders, diffs, and component-level theming.',
          ),
          ToolPart(
            toolName: 'Read',
            icon: '\u{1F4C4}',
            title: 'Read',
            filePath: 'lib/src/widgets/theme/theme.dart',
            status: ToolStatus.completed,
          ),
          ToolPart(
            toolName: 'Edit',
            icon: '\u270F',
            title: 'Edit',
            filePath: 'lib/src/widgets/theme/theme.dart',
            status: ToolStatus.completed,
            isBlock: true,
            diff: _sampleDiff,
            output:
                'Added 10 extended semantic colors:\n'
                '  surfaceVariant / onSurfaceVariant\n'
                '  outline, info / onInfo\n'
                '  onSuccess / onWarning\n'
                '  highlight / onHighlight, shadow\n\n'
                'Added 3 component themes:\n'
                '  StatusBarThemeData\n'
                '  AccentPanelThemeData\n'
                '  CommandPaletteThemeData',
          ),
          TextPart(
            "I've added 10 new extended semantic colors and 3 component "
            'theme data classes. All factory constructors and `copyWith()` '
            'have been updated. The analysis is clean \u2014 '
            '0 errors, 0 warnings.',
          ),
        ],
        modelId: 'claude-opus-4-20250514',
        agent: 'code',
        duration: const Duration(seconds: 8),
      ),
      ChatMessage.user(
        'Now build the 4 new reusable widgets: KeyHint, StatusBar, '
        'AccentPanel, and CommandPalette.',
      ),
      ChatMessage.assistant(
        [
          ToolPart(
            toolName: 'Write',
            icon: '\u{1F4DD}',
            title: 'Write',
            filePath: 'lib/src/widgets/components/key_hint.dart',
            status: ToolStatus.completed,
          ),
          ToolPart(
            toolName: 'Write',
            icon: '\u{1F4DD}',
            title: 'Write',
            filePath: 'lib/src/widgets/components/status_bar.dart',
            status: ToolStatus.completed,
          ),
          ToolPart(
            toolName: 'Write',
            icon: '\u{1F4DD}',
            title: 'Write',
            filePath: 'lib/src/widgets/components/accent_panel.dart',
            status: ToolStatus.completed,
          ),
          ToolPart(
            toolName: 'Write',
            icon: '\u{1F4DD}',
            title: 'Write',
            filePath: 'lib/src/widgets/components/command_palette.dart',
            status: ToolStatus.completed,
          ),
          ToolPart(
            toolName: 'Bash',
            icon: '\u2699',
            title: 'dart test',
            isBlock: true,
            status: ToolStatus.completed,
            output: '37 passed, 0 failures',
          ),
          TextPart(
            'Done! All 4 widgets are added to `components/`:\n\n'
            '- **KeyHint** \u2014 keyboard shortcut badge + description\n'
            '- **StatusBar** \u2014 horizontal bar of KeyHint items\n'
            '- **AccentPanel** \u2014 colored vertical accent stripe panel\n'
            '- **CommandPalette** \u2014 searchable grouped list modal\n\n'
            'All are fully themeable via ThemeScope.',
          ),
        ],
        modelId: 'claude-opus-4-20250514',
        agent: 'code',
        duration: const Duration(seconds: 14),
      ),
      ChatMessage.user(
        'Can you also add a proper VerticalDivider and fix the Container '
        'constraint transparency?',
      ),
      ChatMessage.assistant(
        [
          TextPart(
            "Sure! I'll fix the Container constraint handling and update "
            'the VerticalDivider. Here are the changes:',
          ),
          DiffPart(
            filePath: 'lib/src/widgets/layout/container.dart',
            diff: _containerDiff,
            additions: 18,
            deletions: 4,
            expanded: true,
          ),
          DiffPart(
            filePath: 'lib/src/widgets/layout/vertical_divider.dart',
            diff: _dividerDiff,
            additions: 12,
            deletions: 3,
          ),
          DiffPart(
            filePath: 'lib/src/widgets/rendering/render_layout.dart',
            diff: _renderLayoutDiff,
            additions: 24,
            deletions: 0,
          ),
          TextPart(
            'All three files have been updated. The Container is now '
            'constraint-transparent when no explicit size or alignment is '
            'set, and the 3-pass stretch layout properly handles childless '
            'containers. Tests pass: **1704 passed**, 0 failures.',
          ),
        ],
        modelId: 'claude-opus-4-20250514',
        agent: 'code',
        duration: const Duration(seconds: 11),
      ),
      // -- Currently in-progress message with running tools --
      ChatMessage.user(
        'Great! Now add test coverage for the new widgets and make sure '
        'the existing tests still pass.',
      ),
      ChatMessage.assistant(
        [
          ReasoningPart(
            'The user wants tests. Let me read the existing test files first '
            'to understand the patterns, then write new tests.',
          ),
          ToolPart(
            toolName: 'Read',
            icon: '\u{1F4C4}',
            title: 'Read',
            filePath: 'test/components/key_hint_status_bar_test.dart',
            status: ToolStatus.completed,
          ),
          ToolPart(
            toolName: 'Read',
            icon: '\u{1F4C4}',
            title: 'Read',
            filePath: 'test/components/accent_panel_test.dart',
            status: ToolStatus.completed,
          ),
          ToolPart(
            toolName: 'Write',
            icon: '\u{1F4DD}',
            title: 'Write',
            filePath: 'test/components/command_palette_test.dart',
            status: ToolStatus.running,
          ),
          ToolPart(
            toolName: 'Bash',
            icon: '\u2699',
            title: 'dart test',
            isBlock: true,
            status: ToolStatus.pending,
          ),
        ],
        modelId: 'claude-opus-4-20250514',
        agent: 'code',
        isLast: false,
      ),
      ..._loadTestMessages(),
    ],
    enterBehavior: .send,
  );
}

List<ChatMessage> _loadTestMessages() {
  final messages = <ChatMessage>[];
  for (var i = 0; i < 14; i++) {
    messages.add(
      ChatMessage.user(
        'Follow-up $i: please profile scrolling and rendering again after '
        'recent refactors. Include a larger dataset so we can expose hotspots.',
      ),
    );

    final longText = StringBuffer()
      ..writeln('Profile iteration $i complete. Key findings:')
      ..writeln(
        '- Layout dominates paint time when many message cards are visible.',
      )
      ..writeln(
        '- Width calculations are repeated across markdown and diff rows.',
      )
      ..writeln('- Expanding diffs can trigger expensive relayouts.')
      ..writeln('')
      ..writeln('### Suggested follow-ups')
      ..writeln('1. Keep virtualization enabled for variable-height rows.')
      ..writeln('2. Cache expensive text wrapping and width calculations.')
      ..writeln('3. Defer heavy sections until expanded by the user.')
      ..writeln('')
      ..writeln(
        'This synthetic message is intentionally verbose to stress markdown and '
        'layout paths while scrolling through long sessions.',
      );

    messages.add(
      ChatMessage.assistant(
        [
          TextPart(longText.toString()),
          ToolPart(
            toolName: 'Edit',
            icon: '\u270F',
            title: 'apply virtual list optimizations',
            isBlock: true,
            status: ToolStatus.completed,
            filePath: 'lib/src/widgets/scroll/scroll_widgets.dart',
            diff: _largeSyntheticDiff(100 + i),
            output:
                'Processed 8 traces, compared p95 layout durations, and '
                'extracted top RenderContainer/RenderColumn spans.',
          ),
          ToolPart(
            toolName: 'Bash',
            icon: '\u2699',
            title: 'analyze trace batch',
            isBlock: true,
            status: ToolStatus.completed,
            output:
                'Validated scroll interactions, collected hit-test timings, '
                'and compared layout counters across runs.',
          ),
          DiffPart(
            filePath: 'lib/src/widgets/scroll/virtual_list_view_$i.dart',
            diff: _largeSyntheticDiff(i),
            additions: 96 + i,
            deletions: 22 + (i % 7),
            expanded: i % 3 == 0,
          ),
        ],
        modelId: 'claude-opus-4-20250514',
        agent: 'code',
        isLast: i == 13,
      ),
    );
  }
  return messages;
}

String _largeSyntheticDiff(int seed) {
  final path = 'lib/src/widgets/perf/sample_$seed.dart';
  final b = StringBuffer()
    ..writeln('diff --git a/$path b/$path')
    ..writeln('index 1111111..2222222 100644')
    ..writeln('--- a/$path')
    ..writeln('+++ b/$path');

  for (var hunk = 0; hunk < 4; hunk++) {
    final start = 20 + hunk * 24;
    b.writeln('@@ -$start,12 +$start,20 @@ void renderBlock$hunk() {');
    for (var j = 0; j < 6; j++) {
      b.writeln('-  final oldLine${hunk}_$j = calculateOldValue($j);');
    }
    for (var j = 0; j < 12; j++) {
      b.writeln('+  final newLine${hunk}_$j = calculateNewValue($seed + $j);');
    }
    b.writeln(' }');
  }
  return b.toString();
}

List<w.CommandPaletteItem> sampleCommands() {
  return const [
    w.CommandPaletteItem(
      label: 'New Session',
      shortcut: 'ctrl+n',
      group: 'Session',
    ),
    w.CommandPaletteItem(
      label: 'Session List',
      shortcut: 'ctrl+l',
      group: 'Session',
    ),
    w.CommandPaletteItem(label: 'Clear Messages', group: 'Session'),
    w.CommandPaletteItem(label: 'Exit', shortcut: 'ctrl+c', group: 'Session'),
    w.CommandPaletteItem(
      label: 'Toggle Sidebar',
      shortcut: 'ctrl+b',
      group: 'View',
    ),
    w.CommandPaletteItem(label: 'Toggle Theme', group: 'View'),
    w.CommandPaletteItem(
      label: 'Go to Home',
      shortcut: 'ctrl+h',
      group: 'Navigate',
    ),
    w.CommandPaletteItem(
      label: 'Go to Session',
      shortcut: 'ctrl+s',
      group: 'Navigate',
    ),
    w.CommandPaletteItem(
      label: 'Go to Agent Overview',
      shortcut: 'ctrl+shift+a',
      group: 'Navigate',
    ),
    w.CommandPaletteItem(
      label: 'Switch Model',
      shortcut: 'ctrl+k',
      group: 'Model',
    ),
    w.CommandPaletteItem(
      label: 'Switch Agent',
      shortcut: 'tab',
      group: 'Model',
    ),
    w.CommandPaletteItem(label: 'Open File', shortcut: 'ctrl+o', group: 'File'),
    w.CommandPaletteItem(
      label: 'Save Session',
      shortcut: 'ctrl+s',
      group: 'File',
    ),
    w.CommandPaletteItem(
      label: 'Settings',
      shortcut: 'ctrl+,',
      group: 'Preferences',
    ),
    w.CommandPaletteItem(
      label: 'Keyboard Shortcuts',
      shortcut: 'ctrl+k ctrl+s',
      group: 'Preferences',
    ),
  ];
}

// ---------------------------------------------------------------------------
// Sample sessions (for session list dialog)
// ---------------------------------------------------------------------------

List<SessionSummary> sampleSessions() {
  final now = DateTime.now();
  return [
    SessionSummary(
      id: 'current',
      title: 'Build OpenCode TUI example',
      lastUpdated: now.subtract(const Duration(minutes: 5)),
      isCurrent: true,
      isBusy: true,
      messageCount: 10,
    ),
    SessionSummary(
      id: 's2',
      title: 'Fix text wrapping in RenderText',
      lastUpdated: now.subtract(const Duration(hours: 2)),
      messageCount: 6,
    ),
    SessionSummary(
      id: 's3',
      title: 'Add GitDiffViewer widget',
      lastUpdated: now.subtract(const Duration(hours: 5)),
      messageCount: 14,
    ),
    SessionSummary(
      id: 's4',
      title: 'Implement ScrollArea with scrollbar',
      lastUpdated: now.subtract(const Duration(days: 1, hours: 3)),
      messageCount: 8,
    ),
    SessionSummary(
      id: 's5',
      title: 'Debug background color reset on exit',
      lastUpdated: now.subtract(const Duration(days: 1, hours: 8)),
      messageCount: 22,
    ),
    SessionSummary(
      id: 's6',
      title: 'Design theme system with semantic colors',
      lastUpdated: now.subtract(const Duration(days: 3)),
      messageCount: 16,
    ),
    SessionSummary(
      id: 's7',
      title: 'Initial project setup and architecture',
      lastUpdated: now.subtract(const Duration(days: 7)),
      messageCount: 4,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Sample models (for model list dialog)
// ---------------------------------------------------------------------------

List<ModelOption> sampleModels() {
  return const [
    ModelOption(modelName: 'claude-opus-4-20250514', providerName: 'Anthropic'),
    ModelOption(
      modelName: 'claude-sonnet-4-20250514',
      providerName: 'Anthropic',
    ),
    ModelOption(
      modelName: 'claude-3-5-haiku-20241022',
      providerName: 'Anthropic',
    ),
    ModelOption(modelName: 'gpt-5.3-codex', providerName: 'OpenAI'),
    ModelOption(modelName: 'gpt-4o', providerName: 'OpenAI'),
    ModelOption(modelName: 'gpt-4o-mini', providerName: 'OpenAI'),
    ModelOption(modelName: 'gemini-2.5-pro-0325', providerName: 'Google'),
    ModelOption(modelName: 'gemini-2.5-flash-0325', providerName: 'Google'),
    ModelOption(modelName: 'deepseek-claude', providerName: 'DeepSeek'),
  ];
}

// ---------------------------------------------------------------------------
// Sample diff (unified format)
// ---------------------------------------------------------------------------

const _sampleDiff =
    '''diff --git a/lib/src/widgets/theme/theme.dart b/lib/src/widgets/theme/theme.dart
index 9a3f1c2..4e7b8d1 100644
--- a/lib/src/widgets/theme/theme.dart
+++ b/lib/src/widgets/theme/theme.dart
@@ -42,6 +42,16 @@ class Theme {
   final Color onError;
   final Color muted;
   final Color border;
+  final Color surfaceVariant;
+  final Color onSurfaceVariant;
+  final Color outline;
+  final Color info;
+  final Color onInfo;
+  final Color onSuccess;
+  final Color onWarning;
+  final Color highlight;
+  final Color onHighlight;
+  final Color shadow;
 
   /// Text styles for different type scales.
   final Style titleLarge;
@@ -52,6 +62,9 @@ class Theme {
   final Style labelLarge;
   final Style labelMedium;
   final Style labelSmall;
+  final StatusBarThemeData? statusBarTheme;
+  final AccentPanelThemeData? accentPanelTheme;
+  final CommandPaletteThemeData? commandPaletteTheme;
 }
''';

const _containerDiff =
    '''diff --git a/lib/src/widgets/layout/container.dart b/lib/src/widgets/layout/container.dart
index a1b2c3d..e4f5678 100644
--- a/lib/src/widgets/layout/container.dart
+++ b/lib/src/widgets/layout/container.dart
@@ -113,10 +113,28 @@ class RenderContainer extends RenderBox {
     var childConstraints = constraints;
     if (width != null || height != null) {
       childConstraints = BoxConstraints(
-        minWidth: width?.toDouble() ?? 0,
-        maxWidth: width?.toDouble() ?? constraints.maxWidth,
-        minHeight: height?.toDouble() ?? 0,
-        maxHeight: height?.toDouble() ?? constraints.maxHeight,
+        minWidth: width?.toDouble() ?? constraints.minWidth,
+        maxWidth: width?.toDouble() ?? constraints.maxWidth,
+        minHeight: height?.toDouble() ?? constraints.minHeight,
+        maxHeight: height?.toDouble() ?? constraints.maxHeight,
+      );
+    } else if (alignment != null) {
+      // Alignment is set — loosen min constraints so the child can size
+      // naturally and then be positioned within the container.
+      childConstraints = BoxConstraints(
+        minWidth: 0,
+        maxWidth: math.max(0, constraints.maxWidth - overheadH),
+        minHeight: 0,
+        maxHeight: math.max(0, constraints.maxHeight - overheadV),
+      );
+    } else {
+      // No explicit size, no alignment — propagate parent constraints
+      // through (deflated by padding/border/margin overhead).
+      childConstraints = BoxConstraints(
+        minWidth: math.max(0, constraints.minWidth - overheadH),
+        maxWidth: math.max(0, constraints.maxWidth - overheadH),
+        minHeight: math.max(0, constraints.minHeight - overheadV),
+        maxHeight: math.max(0, constraints.maxHeight - overheadV),
       );
     }
     _child?.layout(childConstraints);
''';

const _dividerDiff =
    '''diff --git a/lib/src/widgets/layout/vertical_divider.dart b/lib/src/widgets/layout/vertical_divider.dart
index 1234567..abcdef0 100644
--- a/lib/src/widgets/layout/vertical_divider.dart
+++ b/lib/src/widgets/layout/vertical_divider.dart
@@ -18,9 +18,18 @@ class VerticalDivider extends StatelessWidget {
-  VerticalDivider({this.height = 3, this.char = '│', this.style, super.key});
+  VerticalDivider({this.height, this.char = '│', this.style, super.key});
 
-  /// Height in rows.
-  final int height;
+  /// Height in rows. When null, fills available space from constraints.
+  final int? height;
 
   /// Character used for the divider line.
   final String char;
+
+  @override
+  Widget build(BuildContext context) {
+    final resolvedStyle =
+        style ?? Style().foreground(ThemeScope.of(context).border);
+    final h = height ?? 1; // fallback; stretch constraints provide real height
+    final line = List.generate(h, (_) => char).join('\\n');
+    return Text(line, style: resolvedStyle);
+  }
''';

const _renderLayoutDiff =
    '''diff --git a/lib/src/widgets/rendering/render_layout.dart b/lib/src/widgets/rendering/render_layout.dart
index 7890abc..def1234 100644
--- a/lib/src/widgets/rendering/render_layout.dart
+++ b/lib/src/widgets/rendering/render_layout.dart
@@ -170,6 +170,30 @@ class RenderRow extends RenderBox {
     }
 
+    // Resolve cross size: max(constraints.minHeight, maxChildHeight).
+    // This matches Flutter's RenderFlex cross-axis resolution.
+    final crossSize = math.max(constraints.minHeight, height);
+
+    // Pass 3 (stretch only): Re-layout children that need to match the
+    // resolved cross size.  This is necessary because the initial passes
+    // used loose cross constraints to discover the natural cross extent.
+    if (isStretch) {
+      for (var i = 0; i < children.length; i++) {
+        final child = children[i];
+        if (child.size.height == crossSize) continue;
+        final prevConstraints = child.constraints;
+        final stretchConstraints = BoxConstraints(
+          minWidth: prevConstraints.minWidth,
+          maxWidth: prevConstraints.maxWidth,
+          minHeight: crossSize,
+          maxHeight: crossSize,
+        );
+        child.layout(stretchConstraints);
+      }
+    }
+
+    width = children.fold<double>(0, (sum, c) => sum + c.size.width) + gapTotal;
+
     final contentWidth = width;
-    final contentHeight = height;
+    final contentHeight = isStretch ? crossSize : height;
''';
