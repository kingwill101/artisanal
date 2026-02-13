// OpenCode Chat UI — Widget Example
//
// Demonstrates an OpenCode-style chat interface built with
// artisanal_widgets: session header, scrollable message body with
// text/tool/reasoning parts, prompt input, sidebar with collapsible
// sections, footer status bar, and a command palette overlay.
//
// Run with: dart run example/opencode/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'dart:io';

import 'models/chat_model.dart';
import 'models/message.dart';
import 'theme.dart';
import 'widgets/chat_body.dart';
import 'widgets/copy_toast.dart';
import 'widgets/footer_bar.dart';
import 'widgets/home_view.dart';
import 'widgets/prompt_input.dart';
import 'widgets/session_header.dart';
import 'widgets/session_list_dialog.dart';
import 'widgets/sidebar_widget.dart';
import 'widgets/theme_list_dialog.dart';
import 'replay_driver.dart';

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

ChatModel _initialModel() {
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

List<w.CommandPaletteItem> _sampleCommands() {
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

List<SessionSummary> _sampleSessions() {
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

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

String? _themeOverrideFromArgs(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--theme=')) {
      final value = arg.substring('--theme='.length).trim();
      if (value.isNotEmpty) return value;
    }
    if (arg == '--theme' && i + 1 < args.length) {
      final value = args[i + 1].trim();
      if (value.isNotEmpty) return value;
    }
  }
  return null;
}

bool _hasArg(List<String> args, String flag) {
  return args.any((arg) => arg == flag);
}

void _printUsage() {
  stderr.writeln('OpenCode example usage:');
  stderr.writeln('  --theme <name>');
  stderr.writeln('  --replay-scenario <name|path>');
  stderr.writeln('  --replay-speed <factor>     (default: 1.0)');
  stderr.writeln('  --replay-loop               (repeat forever)');
  stderr.writeln(
    '  --replay-keep-open          (do not auto-quit after replay)',
  );
  stderr.writeln(
    '  --replay-block-input        (ignore manual terminal input during replay)',
  );
  stderr.writeln('  --help');
}

void main(List<String> args) async {
  if (_hasArg(args, '--help')) {
    _printUsage();
    return;
  }

  final themeOverride = _themeOverrideFromArgs(args);
  OpenCodeReplayPlan? replayPlan;
  try {
    replayPlan = await loadOpenCodeReplayPlanFromArgs(args);
  } on FormatException catch (error) {
    stderr.writeln('[opencode] $error');
    _printUsage();
    exitCode = 64;
    return;
  } on FileSystemException catch (error) {
    stderr.writeln('[opencode] ${error.message}: ${error.path ?? ''}');
    _printUsage();
    exitCode = 66;
    return;
  }

  if (themeOverride != null) {
    await loadOpenCodeThemeAtLaunch(themeName: themeOverride);
  }

  if (replayPlan != null) {
    stdout.writeln(
      '[opencode] replay=${replayPlan.name} '
      'actions=${replayPlan.actionCount} '
      'loop=${replayPlan.loop} '
      'keepOpen=${replayPlan.keepOpen} '
      'blockInput=${replayPlan.blockInput} '
      'speed=${replayPlan.speed.toStringAsFixed(2)} '
      'path=${replayPlan.path}',
    );
  }

  final app = w.WidgetApp(
    OpenCodeApp(),
    backgroundColorBuilder: currentOpenCodeRouteBackground,
  );

  try {
    await tui.runProgram(
      app,
      options: tui.ProgramOptions(
        altScreen: true,
        mouse: true,
        mouseMode: tui.MouseMode.allMotion,
        replay: replayPlan?.replay,
        interceptor: replayPlan?.interceptor,
        blockInputWhileReplay: replayPlan?.blockInput ?? false,
      ),
    );
  } catch (error, stackTrace) {
    _restoreTerminalBestEffort();
    final logPath = await _writeCrashLog(error, stackTrace);
    stderr.writeln('[opencode] Crash log written to $logPath');
    rethrow;
  }
}

void _restoreTerminalBestEffort() {
  // Reset styles, show cursor, and leave alt-screen if still active.
  stdout.write('\x1b[0m\x1b[?25h\x1b[?1049l');
}

Future<String> _writeCrashLog(Object error, StackTrace stackTrace) async {
  final now = DateTime.now().toIso8601String().replaceAll(':', '-');
  final logDir = Directory('pkgs/artisanal_widgets/example/opencode/traces');
  if (!await logDir.exists()) {
    await logDir.create(recursive: true);
  }
  final file = File('${logDir.path}/opencode-crash-$now.log');
  final lines = [
    'OpenCode example crash',
    'time: ${DateTime.now().toIso8601String()}',
    'cwd: ${Directory.current.path}',
    '',
    'error:',
    '$error',
    '',
    'stackTrace:',
    '$stackTrace',
  ];
  await file.writeAsString('${lines.join('\n')}\n');
  return file.path;
}

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

class OpenCodeApp extends w.StatefulWidget {
  OpenCodeApp({super.key});

  @override
  w.State createState() => _OpenCodeAppState();
}

class _HideCopyToastMsg extends tui.Msg {
  const _HideCopyToastMsg(this.token);
  final int token;
}

class _OpenCodeAppState extends w.State<OpenCodeApp> {
  late ChatModel _model;
  final _scrollController = w.WidgetScrollController();
  final _promptController = w.TextFieldController();
  bool _commandPaletteOpen = false;
  bool _sessionListOpen = false;
  bool _themeListOpen = false;
  String _currentThemeName = openCodeDefaultThemeName;
  List<String> _themeOptions = const [openCodeDefaultThemeName];
  String? _copyToastMessage;
  int _copyToastToken = 0;

  @override
  void initState() {
    super.initState();
    _model = _initialModel();
    if (_model.inputText.isNotEmpty) {
      _promptController.text = _model.inputText;
    }
    _currentThemeName = currentOpenCodeThemeName();
    _loadThemeOptions();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadThemeOptions() async {
    final options = await discoverOpenCodeThemeNames();
    if (!mounted) return;
    setState(() {
      _themeOptions = options;
    });
  }

  Future<void> _applyTheme(String themeName) async {
    final ok = await applyOpenCodeThemeOverride(themeName);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _themeListOpen = false;
      });
      return;
    }
    setState(() {
      _currentThemeName = currentOpenCodeThemeName();
      _themeListOpen = false;
    });
  }

  bool _isCtrlCShortcut(tui.Key key) {
    if (!key.ctrl || key.alt || key.meta || key.hyper || key.superKey) {
      return false;
    }
    if (key.runes.isEmpty) return false;
    if (key.runes.length == 1 && key.runes.first == 0x03) {
      return true;
    }
    final char = key.char;
    return char != null && char.toLowerCase() == 'c';
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.InterruptMsg) {
      return tui.Cmd.quit();
    }
    if (msg is tui.KeyMsg && _isCtrlCShortcut(msg.key)) {
      return tui.Cmd.quit();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = openCodeTheme();
    setOpenCodeRouteBackground(
      _model.route == AppRoute.home ? OC.background : OC.background,
    );

    // Helper to wrap content with theme list + session list + command palette
    w.Widget wrapWithOverlays(w.Widget content) {
      final overlays = ThemeListDialog(
        open: _themeListOpen,
        themes: _themeOptions,
        currentTheme: _currentThemeName,
        onDismiss: () {
          setState(() => _themeListOpen = false);
          return null;
        },
        onSelect: (themeName) {
          _applyTheme(themeName);
        },
        child: SessionListDialog(
          open: _sessionListOpen,
          sessions: _sampleSessions(),
          onDismiss: () {
            setState(() => _sessionListOpen = false);
            return null;
          },
          onSelect: (session) {
            setState(() {
              _sessionListOpen = false;
              // Navigate to the selected session (or stay on current)
              if (!session.isCurrent) {
                _model = ChatModel(
                  route: AppRoute.session,
                  messages: _model.messages,
                  inputText: _promptController.text,
                  modelName: _model.modelName,
                  providerName: _model.providerName,
                  agentName: _model.agentName,
                  sessionTitle: session.title,
                  contextTokens: _model.contextTokens,
                  contextPercentage: _model.contextPercentage,
                  cost: _model.cost,
                  sidebar: _model.sidebar,
                  sidebarOpen: _model.sidebarOpen,
                  todos: _model.todos,
                  modifiedFiles: _model.modifiedFiles,
                  mcpServers: _model.mcpServers,
                  lspServers: _model.lspServers,
                  workingDirectory: _model.workingDirectory,
                );
              } else {
                _model = ChatModel(
                  route: AppRoute.session,
                  messages: _model.messages,
                  inputText: _promptController.text,
                  modelName: _model.modelName,
                  providerName: _model.providerName,
                  agentName: _model.agentName,
                  sessionTitle: _model.sessionTitle,
                  contextTokens: _model.contextTokens,
                  contextPercentage: _model.contextPercentage,
                  cost: _model.cost,
                  sidebar: _model.sidebar,
                  sidebarOpen: _model.sidebarOpen,
                  todos: _model.todos,
                  modifiedFiles: _model.modifiedFiles,
                  mcpServers: _model.mcpServers,
                  lspServers: _model.lspServers,
                  workingDirectory: _model.workingDirectory,
                );
              }
            });
          },
          child: w.CommandPalette(
            open: _commandPaletteOpen,
            title: 'Commands',
            hint: 'Search',
            backdropOpacity: 0.7,
            items: _sampleCommands(),
            onDismiss: () {
              setState(() => _commandPaletteOpen = false);
              return null;
            },
            onSelect: (item) {
              if (item.label == 'Exit') {
                setState(() {
                  _commandPaletteOpen = false;
                });
                return tui.Cmd.quit();
              }
              setState(() {
                _commandPaletteOpen = false;
                if (item.label == 'Session List') {
                  _sessionListOpen = true;
                }
                if (item.label == 'Toggle Theme') {
                  _themeListOpen = true;
                }
              });
              return null;
            },
            child: content,
          ),
        ),
      );

      return w.Stack(
        fit: w.StackFit.expand,
        children: [
          overlays,
          if (_copyToastMessage != null)
            w.Positioned(
              top: 1,
              left: 0,
              right: 0,
              child: w.IgnorePointer(
                child: w.Center(
                  child: w.ConstrainedBox(
                    constraints: w.BoxConstraints(maxWidth: 38),
                    child: CopyToast(message: _copyToastMessage!),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Home view — landing screen
    if (_model.route == AppRoute.home) {
      return w.ThemeScope(
        theme: theme,
        child: wrapWithOverlays(
          HomeView(
            model: _model,
            promptController: _promptController,
            onSubmit: (text) {
              setState(() {
                _model = ChatModel(
                  route: AppRoute.session,
                  messages: _model.messages,
                  inputText: text,
                  modelName: _model.modelName,
                  providerName: _model.providerName,
                  agentName: _model.agentName,
                  sessionTitle: _model.sessionTitle,
                  contextTokens: _model.contextTokens,
                  contextPercentage: _model.contextPercentage,
                  cost: _model.cost,
                  sidebar: _model.sidebar,
                  sidebarOpen: _model.sidebarOpen,
                  todos: _model.todos,
                  modifiedFiles: _model.modifiedFiles,
                  mcpServers: _model.mcpServers,
                  lspServers: _model.lspServers,
                  workingDirectory: _model.workingDirectory,
                );
              });
            },
          ),
        ),
      );
    }

    final mainLayout = SessionShell(
      model: _model,
      scrollController: _scrollController,
      promptController: _promptController,
    );

    // Wrap with theme + session list + command palette
    return w.ThemeScope(theme: theme, child: wrapWithOverlays(mainLayout));
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.ClipboardSetMsg) {
      final token = ++_copyToastToken;
      setState(() {
        _copyToastMessage = 'Copied to clipboard';
      });
      return tui.Cmd.delayed(
        const Duration(milliseconds: 1600),
        () => _HideCopyToastMsg(token),
      );
    }

    if (msg is _HideCopyToastMsg) {
      if (msg.token == _copyToastToken && _copyToastMessage != null) {
        setState(() {
          _copyToastMessage = null;
        });
      }
      return null;
    }

    if (msg is tui.KeyMsg) {
      final key = msg.key;

      // ctrl+p to toggle command palette
      if (key == tui.Keys.ctrl('p')) {
        setState(() => _commandPaletteOpen = !_commandPaletteOpen);
        return tui.Cmd.none();
      }

      // ctrl+l to toggle session list dialog
      if (key == tui.Keys.ctrl('l')) {
        setState(() => _sessionListOpen = !_sessionListOpen);
        return tui.Cmd.none();
      }

      // ctrl+t to toggle theme list dialog
      if (key == tui.Keys.ctrl('t')) {
        setState(() => _themeListOpen = !_themeListOpen);
        return tui.Cmd.none();
      }

      // ctrl+b to toggle sidebar
      if (key == tui.Keys.ctrl('b')) {
        setState(() {
          _model = ChatModel(
            route: _model.route,
            messages: _model.messages,
            inputText: _promptController.text,
            modelName: _model.modelName,
            providerName: _model.providerName,
            agentName: _model.agentName,
            sessionTitle: _model.sessionTitle,
            contextTokens: _model.contextTokens,
            contextPercentage: _model.contextPercentage,
            cost: _model.cost,
            sidebar: _model.sidebar,
            sidebarOpen: !_model.sidebarOpen,
            todos: _model.todos,
            modifiedFiles: _model.modifiedFiles,
            mcpServers: _model.mcpServers,
            lspServers: _model.lspServers,
            workingDirectory: _model.workingDirectory,
          );
        });
        return tui.Cmd.none();
      }
    }
    return null;
  }
}

class SessionShell extends w.StatelessWidget {
  SessionShell({
    required this.model,
    required this.scrollController,
    required this.promptController,
    super.key,
  });

  final ChatModel model;
  final w.WidgetScrollController scrollController;
  final w.TextFieldController promptController;

  @override
  w.Widget build(w.BuildContext context) {
    final content = SessionContentPane(
      model: model,
      scrollController: scrollController,
      promptController: promptController,
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
    super.key,
  });

  final ChatModel model;
  final w.WidgetScrollController scrollController;
  final w.TextFieldController promptController;

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
                  ),
                ),
                w.SizedBox(height: 1),
                PromptInput(
                  controller: promptController,
                  agentName: model.agentName,
                  modelName: model.modelName,
                  providerName: model.providerName,
                ),
              ],
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
}

class SessionSidebarPane extends w.StatefulWidget {
  SessionSidebarPane({required this.model, super.key});

  final ChatModel model;

  @override
  w.State createState() => _SessionSidebarPaneState();
}

class _SessionSidebarPaneState extends w.State<SessionSidebarPane> {
  late SidebarState _state;

  @override
  void initState() {
    super.initState();
    _state = _copySidebarState(widget.model.sidebar);
  }

  @override
  tui.Cmd? didUpdateWidget(covariant SessionSidebarPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      _state = _copySidebarState(widget.model.sidebar);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return SidebarWidget(
      model: widget.model,
      sidebarState: _state,
      onToggleMcp: () {
        setState(() => _state.mcpExpanded = !_state.mcpExpanded);
      },
      onToggleLsp: () {
        setState(() => _state.lspExpanded = !_state.lspExpanded);
      },
      onToggleTodo: () {
        setState(() => _state.todoExpanded = !_state.todoExpanded);
      },
      onToggleFiles: () {
        setState(() => _state.filesExpanded = !_state.filesExpanded);
      },
    );
  }
}

SidebarState _copySidebarState(SidebarState source) {
  final state = SidebarState();
  state.mcpExpanded = source.mcpExpanded;
  state.lspExpanded = source.lspExpanded;
  state.todoExpanded = source.todoExpanded;
  state.filesExpanded = source.filesExpanded;
  return state;
}
