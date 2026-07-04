// Focused OpenCode diff-scroll repro.
//
// Minimal chat layout that isolates diff-heavy messages inside a single
// variable-height scroll area.

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../opencode/models/message.dart';
import '../opencode/theme.dart';
import '../opencode/widgets/chat_body.dart';

void main() async {
  final app = tui.WidgetApp(_DiffScrollReproApp());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class _DiffScrollReproApp extends w.StatefulWidget {
  _DiffScrollReproApp();

  @override
  w.State createState() => _DiffScrollReproAppState();
}

class _DiffScrollReproAppState extends w.State<_DiffScrollReproApp> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.char == 'q' ||
          key == tui.Keys.escape ||
          key == tui.Keys.ctrlC ||
          key.type == tui.KeyType.escape) {
        return tui.Cmd.quit();
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Container(
      color: OC.background,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Text('Focused OpenCode scroll repro'),
          w.SizedBox(height: 1),
          w.Expanded(
            child: ChatBody(
              scrollController: _scrollController,
              showDiffs: true,
              messages: _messages,
            ),
          ),
        ],
      ),
    );
  }
}

final List<ChatMessage> _messages = [
  ChatMessage.user(
    'Please inspect the scroll behavior for the full OpenCode message set.',
    id: 'user-1',
  ),
  ChatMessage.assistant([
    TextPart(
      'This repro includes every widget type we currently render: text, '
      'reasoning, inline tools, block tools, diffs, todos, questions, and '
      'skills.',
    ),
    ReasoningPart(
      'Keep the example compact enough to debug, but varied enough to hit '
      'the full scroll and layout surface area.',
    ),
    ToolPart(
      toolName: 'bash',
      title: 'bash',
      input: 'dart test test/scroll/scroll_test.dart',
      status: ToolStatus.completed,
    ),
    ToolPart(
      toolName: 'edit',
      title: 'edit',
      isBlock: true,
      filePath: 'lib/src/widgets/scroll/scroll_widgets.dart',
      diff: _sampleDiff1,
      output: 'Adjusted drag release behavior and metrics commit logic.',
    ),
    ToolPart(
      toolName: 'write',
      title: 'write',
      isBlock: true,
      filePath: 'lib/src/widgets/components/opencode_focus.dart',
      output: 'Added focus repro sample data and mixed card coverage.',
    ),
    ToolPart(
      toolName: 'apply_patch',
      title: 'apply_patch',
      isBlock: true,
      filePath: 'lib/src/widgets/scroll/scroll_widgets.dart',
      diff: _sampleDiff2,
      output: 'Patched deferred content extent commit on thumb release.',
    ),
    ToolPart(
      toolName: 'todowrite',
      title: 'Todos',
      isBlock: true,
      output:
          '- [x] Add split-border cards\n- [x] Add tool card variants\n- [ ] Match every OpenCode nuance',
    ),
    ToolPart(
      toolName: 'question',
      title: 'Question',
      isBlock: true,
      input: 'Should the diff preview scroll independently?',
      output: 'No. Keep the outer timeline in charge.',
    ),
    ToolPart(
      toolName: 'skill',
      title: 'Skill',
      isBlock: true,
      output: 'Border splitting and timeline row projection.',
    ),
  ], id: 'asst-1'),
  ChatMessage.assistant([
    DiffPart(
      filePath: 'lib/src/widgets/perf/sample_1.dart',
      diff: _sampleDiff1,
      additions: 26,
      deletions: 8,
    ),
  ], id: 'asst-2'),
  ChatMessage.assistant([
    TextPart(
      'Validated scroll interactions, collected hit-test timings, and '
      'compared layout counters across runs.',
    ),
  ], id: 'asst-3'),
  ChatMessage.assistant([
    DiffPart(
      filePath: 'lib/src/widgets/perf/sample_2.dart',
      diff: _sampleDiff2,
      additions: 32,
      deletions: 6,
    ),
  ], id: 'asst-4'),
  ChatMessage.user(
    'Scrolling up a bit should make the thumb react to the changing height.',
    id: 'user-2',
  ),
];

const _sampleDiff1 = '''
diff --git a/lib/src/widgets/perf/sample_1.dart b/lib/src/widgets/perf/sample_1.dart
index 0000000..1111111 100644
--- a/lib/src/widgets/perf/sample_1.dart
+++ b/lib/src/widgets/perf/sample_1.dart
@@ -1,8 +1,34 @@
-final oldLine0_0 = calculateOldValue(0);
-final oldLine0_1 = calculateOldValue(1);
-final oldLine0_2 = calculateOldValue(2);
-final oldLine0_3 = calculateOldValue(3);
-final oldLine0_4 = calculateOldValue(4);
-final oldLine0_5 = calculateOldValue(5);
+final newLine0_0 = calculateNewValue(2 + 0);
+final newLine0_1 = calculateNewValue(2 + 1);
+final newLine0_2 = calculateNewValue(2 + 2);
+final newLine0_3 = calculateNewValue(2 + 3);
+final newLine0_4 = calculateNewValue(2 + 4);
+final newLine0_5 = calculateNewValue(2 + 5);
+final newLine0_6 = calculateNewValue(2 + 6);
+final newLine0_7 = calculateNewValue(2 + 7);
+final newLine0_8 = calculateNewValue(2 + 8);
+final newLine0_9 = calculateNewValue(2 + 9);
+final newLine0_10 = calculateNewValue(2 + 10);
+final newLine0_11 = calculateNewValue(2 + 11);
+final newLine0_12 = calculateNewValue(2 + 12);
+final newLine0_13 = calculateNewValue(2 + 13);
+final newLine0_14 = calculateNewValue(2 + 14);
+final newLine0_15 = calculateNewValue(2 + 15);
+final newLine0_16 = calculateNewValue(2 + 16);
+final newLine0_17 = calculateNewValue(2 + 17);
+final newLine0_18 = calculateNewValue(2 + 18);
+final newLine0_19 = calculateNewValue(2 + 19);
+final newLine0_20 = calculateNewValue(2 + 20);
+final newLine0_21 = calculateNewValue(2 + 21);
+final newLine0_22 = calculateNewValue(2 + 22);
+final newLine0_23 = calculateNewValue(2 + 23);
+final newLine0_24 = calculateNewValue(2 + 24);
+final newLine0_25 = calculateNewValue(2 + 25);
 ''';

const _sampleDiff2 = '''
diff --git a/lib/src/widgets/perf/sample_2.dart b/lib/src/widgets/perf/sample_2.dart
index 2222222..3333333 100644
--- a/lib/src/widgets/perf/sample_2.dart
+++ b/lib/src/widgets/perf/sample_2.dart
@@ -12,6 +12,38 @@
-final oldLine1_0 = calculateOldValue(0);
-final oldLine1_1 = calculateOldValue(1);
-final oldLine1_2 = calculateOldValue(2);
-final oldLine1_3 = calculateOldValue(3);
-final oldLine1_4 = calculateOldValue(4);
-final oldLine1_5 = calculateOldValue(5);
+final newLine1_0 = calculateNewValue(3 + 0);
+final newLine1_1 = calculateNewValue(3 + 1);
+final newLine1_2 = calculateNewValue(3 + 2);
+final newLine1_3 = calculateNewValue(3 + 3);
+final newLine1_4 = calculateNewValue(3 + 4);
+final newLine1_5 = calculateNewValue(3 + 5);
+final newLine1_6 = calculateNewValue(3 + 6);
+final newLine1_7 = calculateNewValue(3 + 7);
+final newLine1_8 = calculateNewValue(3 + 8);
+final newLine1_9 = calculateNewValue(3 + 9);
+final newLine1_10 = calculateNewValue(3 + 10);
+final newLine1_11 = calculateNewValue(3 + 11);
+final newLine1_12 = calculateNewValue(3 + 12);
+final newLine1_13 = calculateNewValue(3 + 13);
+final newLine1_14 = calculateNewValue(3 + 14);
+final newLine1_15 = calculateNewValue(3 + 15);
+final newLine1_16 = calculateNewValue(3 + 16);
+final newLine1_17 = calculateNewValue(3 + 17);
+final newLine1_18 = calculateNewValue(3 + 18);
+final newLine1_19 = calculateNewValue(3 + 19);
+final newLine1_20 = calculateNewValue(3 + 20);
+final newLine1_21 = calculateNewValue(3 + 21);
+final newLine1_22 = calculateNewValue(3 + 22);
+final newLine1_23 = calculateNewValue(3 + 23);
+final newLine1_24 = calculateNewValue(3 + 24);
+final newLine1_25 = calculateNewValue(3 + 25);
+final newLine1_26 = calculateNewValue(3 + 26);
+final newLine1_27 = calculateNewValue(3 + 27);
+final newLine1_28 = calculateNewValue(3 + 28);
+final newLine1_29 = calculateNewValue(3 + 29);
+final newLine1_30 = calculateNewValue(3 + 30);
+final newLine1_31 = calculateNewValue(3 + 31);
 ''';
