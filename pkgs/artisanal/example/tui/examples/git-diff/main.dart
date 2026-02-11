/// Git diff viewer example — TUI bubble.
///
/// Displays a hardcoded sample diff with syntax-highlighted additions,
/// deletions, file headers, and hunk headers. Scroll with j/k, pgup/pgdn.
///
/// Run with: dart run example/tui/examples/git-diff/main.dart
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;

/// Status bar style matching the light theme.
final _statusBarStyle = style.Style()
    .foreground(const style.BasicColor('#57606a'))
    .background(const style.BasicColor('#ece7e1'));

/// Sample unified diff for demonstration.
const _sampleDiff = '''
diff --git a/lib/config.dart b/lib/config.dart
index a1b2c3d..e4f5g6h 100644
--- a/lib/config.dart
+++ b/lib/config.dart
@@ -1,8 +1,10 @@
+import 'dart:convert';
 import 'dart:io';
 
 class Config {
-  final String name;
-  Config(this.name);
+  final String name;
+  final int version;
+  Config({required this.name, this.version = 1});
 
-  void save() => File('config.json').writeAsStringSync(name);
+  void save() => File('config.json').writeAsStringSync(
+        jsonEncode({'name': name, 'version': version}),
+      );
 }
diff --git a/test/config_test.dart b/test/config_test.dart
new file mode 100644
index 0000000..1234567
--- /dev/null
+++ b/test/config_test.dart
@@ -0,0 +1,12 @@
+import 'package:test/test.dart';
+import '../lib/config.dart';
+
+void main() {
+  test('Config defaults', () {
+    final config = Config(name: 'app');
+    expect(config.name, 'app');
+    expect(config.version, 1);
+  });
+}
diff --git a/README.md b/README.md
index abcdef0..1234567 100644
--- a/README.md
+++ b/README.md
@@ -1,3 +1,5 @@
 # My Project
 
-A simple project.
+A simple project with versioned configuration.
+
+Run tests: `dart test`
''';

class DiffViewerModel implements tui.Model {
  DiffViewerModel({
    tui.GitDiffModel? diff,
    this.quitting = false,
    this.ready = false,
  }) : diff =
           diff ??
           tui.GitDiffModel(
             viewMode: tui.DiffViewMode.pretty,
             styles: tui.DiffStyles.light(),
           );

  final tui.GitDiffModel diff;
  final bool quitting;
  final bool ready;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.WindowSizeMsg(width: final w, height: final h):
        // Use full terminal width, reserve 1 row for status bar
        final updated = diff.copyWith(width: w, height: h - 1);
        // First time: parse the diff; subsequent resizes: just re-render
        final resized = diff.files.isEmpty
            ? updated.setDiff(_sampleDiff)
            : updated.rerender();
        return (DiffViewerModel(diff: resized, ready: true), null);

      case tui.KeyMsg(key: final key):
        if (key.char == 'q' ||
            key.type == tui.KeyType.escape ||
            key == tui.Keys.ctrlC) {
          return (
            DiffViewerModel(diff: diff, quitting: true, ready: ready),
            tui.Cmd.quit(),
          );
        }
    }

    // Delegate scrolling keys to the diff model
    final (newDiff, cmd) = diff.update(msg);
    return (DiffViewerModel(diff: newDiff, ready: ready), cmd);
  }

  DiffViewerModel copyWith({
    tui.GitDiffModel? diff,
    bool? quitting,
    bool? ready,
  }) {
    return DiffViewerModel(
      diff: diff ?? this.diff,
      quitting: quitting ?? this.quitting,
      ready: ready ?? this.ready,
    );
  }

  @override
  String view() {
    if (quitting) return 'Bye!\n';
    if (!ready) return '\n  Loading diff...';

    final pct = (diff.viewport.scrollPercent * 100).toStringAsFixed(0);
    final adds = diff.totalAdditions;
    final dels = diff.totalDeletions;
    final fileCount = diff.files.length;
    final modeName = switch (diff.viewMode) {
      tui.DiffViewMode.unified => 'unified',
      tui.DiffViewMode.sideBySide => 'side-by-side',
      tui.DiffViewMode.pretty => 'pretty',
    };
    final status =
        ' $fileCount file(s)  +$adds  -$dels  |  $pct%  |  $modeName (v)  j/k scroll  q quit';
    final styledStatus = _statusBarStyle.render(status.padRight(diff.width));

    return '${diff.view()}\n$styledStatus';
  }
}

Future<void> main() async {
  await tui.runProgram(
    DiffViewerModel(),
    options: const tui.ProgramOptions(altScreen: true, mouse: true),
  );
}
