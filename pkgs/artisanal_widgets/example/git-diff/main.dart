// Git Diff Viewer — Widget Example
//
// Demonstrates GitDiffViewer widget with a hardcoded sample diff.
// Scroll with j/k or pgup/pgdn. Press q to quit.
//
// Run with: dart run example/git-diff/main.dart

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

/// Light-theme diff styles.
final _lightStyles = tui.DiffStyles.light();

/// Status bar style matching the light theme.
final _statusBarStyle = style.Style()
    .foreground(const style.BasicColor('#57606a'))
    .background(const style.BasicColor('#ece7e1'));

/// Title style matching the light theme.
final _titleStyle = style.Style()
    .bold()
    .foreground(const style.BasicColor('#24292f'))
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

void main() async {
  final app = tui.WidgetApp(DiffShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class DiffShowcase extends w.StatefulWidget {
  DiffShowcase({super.key});

  @override
  w.State createState() => _DiffShowcaseState();
}

class _DiffShowcaseState extends w.State<DiffShowcase> {
  final _controller = w.GitDiffController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round().clamp(1, 9999);
    final height = media.size.height.round();

    final adds = _controller.totalAdditions;
    final dels = _controller.totalDeletions;
    final fileCount = _controller.files.length;
    final pct = (_controller.scrollPercent * 100).toStringAsFixed(0);
    final modeName = switch (_controller.model.viewMode) {
      tui.DiffViewMode.unified => 'unified',
      tui.DiffViewMode.sideBySide => 'side-by-side',
      tui.DiffViewMode.pretty => 'pretty',
    };

    // Title + status take 2 rows; use the rest for the diff viewer
    final diffHeight = height > 2 ? height - 2 : 1;

    final titleText = ' Git Diff Viewer'.padRight(width);
    final statusText =
        ' $fileCount file(s)  +$adds  -$dels  |  $pct%  |  $modeName (v)  j/k scroll  q quit'
            .padRight(width);

    return w.Column(
      children: [
        w.Text(_titleStyle.render(titleText), softWrap: false),
        w.GitDiffViewer(
          diff: _sampleDiff,
          width: width,
          height: diffHeight,
          styles: _lightStyles,
          controller: _controller,
        ),
        w.Text(_statusBarStyle.render(statusText), softWrap: false),
      ],
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
