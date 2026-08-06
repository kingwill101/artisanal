/// Diff review showcase (OpenCode multi-file review surface).
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../theme.dart';
import '../widgets/footer_bar.dart';

/// Sample multi-file review using [w.DiffReviewPane].
class ReviewScreen extends w.StatelessWidget {
  ReviewScreen({
    this.workingDirectory = '~/code/artisanal',
    super.key,
  });

  final String workingDirectory;

  static final sampleFiles = <w.DiffReviewFile>[
    w.DiffReviewFile(
      path: 'lib/src/widgets/composer/frecency_store.dart',
      additions: 40,
      deletions: 0,
      diff: r'''diff --git a/lib/src/widgets/composer/frecency_store.dart b/lib/src/widgets/composer/frecency_store.dart
new file mode 100644
--- /dev/null
+++ b/lib/src/widgets/composer/frecency_store.dart
@@ -0,0 +1,12 @@
+class FrecencyStore {
+  void touch(String key) {}
+  double score(String key) => 0;
+}
''',
    ),
    w.DiffReviewFile(
      path: 'lib/src/widgets/components/status_section.dart',
      additions: 8,
      deletions: 3,
      diff: r'''diff --git a/lib/src/widgets/components/status_section.dart b/lib/src/widgets/components/status_section.dart
--- a/lib/src/widgets/components/status_section.dart
+++ b/lib/src/widgets/components/status_section.dart
@@ -10,7 +10,12 @@
 class StatusSection extends StatelessWidget {
-  StatusSection({required this.title, required this.children});
+  StatusSection({
+    required this.title,
+    required this.items,
+    this.expanded = true,
+  });
   final String title;
-  final List<Widget> children;
+  final List<Widget> items;
+  final bool expanded;
 }
''',
    ),
    w.DiffReviewFile(
      path: 'README.md',
      additions: 2,
      deletions: 1,
      diff: r'''diff --git a/README.md b/README.md
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
 # artisanal
-
-TUI toolkit for Dart.
+OpenTUI-class terminal UI toolkit for Dart.
+Includes composer autocomplete and diff review.
''',
    ),
  ];

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Expanded(
          child: w.Padding(
            padding: const w.EdgeInsets.all(1),
            child: w.Column(
              crossAxisAlignment: w.CrossAxisAlignment.stretch,
              gap: 1,
              children: [
                w.Text(
                  'Diff review',
                  style: style.Style()
                    ..foreground(OC.text)
                    ..bold(),
                ),
                w.Text(
                  '↑↓ files · v cycles patch view · ctrl+p commands · esc back',
                  style: style.Style()..foreground(OC.textMuted),
                ),
                w.Expanded(
                  child: w.DiffReviewPane(files: sampleFiles),
                ),
              ],
            ),
          ),
        ),
        FooterBar(
          workingDirectory: workingDirectory,
          statusHint: 'ctrl+x d · review',
        ),
      ],
    );
  }
}
