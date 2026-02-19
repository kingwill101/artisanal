import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/models/message.dart';
import '../../example/opencode/widgets/chat_body.dart';

void main() {
  test('user message renders file chips and compaction marker', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Container(
        child: ChatBody(
          messages: [
            ChatMessage.user(
              'Please review attached files.',
              files: const [
                UserFilePart(mime: 'text/plain', filename: 'notes.txt'),
                UserFilePart(mime: 'application/pdf', filename: 'spec.pdf'),
              ],
              showCompaction: true,
              timestamp: DateTime(2026, 2, 11, 10, 5),
            ),
          ],
        ),
      ),
    );

    expect(tester.locateText('notes.txt'), isNotNull);
    expect(tester.locateText('spec.pdf'), isNotNull);
    expect(tester.locateText('Compaction'), isNotNull);
  });

  test('system message renders in chat body', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Container(
        child: ChatBody(
          messages: [
            ChatMessage.system(
              'System: context compacted to reduce token usage.',
            ),
          ],
        ),
      ),
    );

    expect(
      tester.locateText('System: context compacted to reduce token usage.'),
      isNotNull,
    );
  });

  test('assistant message shows top-level error panel', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Container(
        child: ChatBody(
          messages: [
            ChatMessage.assistant(
              const [TextPart('The request failed while generating output.')],
              errorMessage: 'Provider rate limit exceeded',
              isLast: true,
            ),
          ],
        ),
      ),
    );

    expect(tester.locateText('Provider rate limit exceeded'), isNotNull);
  });

  test('assistant interrupted footer includes interrupted label', () async {
    final tester = WidgetTester(screenWidth: 110, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Container(
        child: ChatBody(
          messages: [
            ChatMessage.assistant(
              const [TextPart('Stopping now.')],
              interrupted: true,
              modelId: 'claude-opus-4-20250514',
              isLast: true,
            ),
          ],
        ),
      ),
    );

    expect(tester.locateText('interrupted'), isNotNull);
  });

  test('diff viewers render without clickable toggle wrappers', () async {
    final tester = WidgetTester(screenWidth: 120, screenHeight: 30);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Container(
        child: ChatBody(
          messages: [
            ChatMessage.assistant([
              const TextPart('Applying edits now.'),
              ToolPart(
                toolName: 'edit',
                title: '# Edited lib/src/app.dart',
                isBlock: true,
                filePath: 'lib/src/app.dart',
                diff: _sampleDiff,
              ),
              const DiffPart(
                filePath: 'lib/src/utils.dart',
                diff: _sampleDiff,
                additions: 2,
                deletions: 1,
                expanded: true,
              ),
            ], isLast: true),
          ],
        ),
      ),
    );

    final viewers = tester.find.byType<w.GitDiffViewer>();
    expect(viewers.length, greaterThanOrEqualTo(2));

    var hasToggleWrapper = false;
    for (final element in tester.find.byType<w.GestureDetector>()) {
      final key = element.widget.key;
      if (key is w.ValueKey<String> && key.value.startsWith('diff-toggle-')) {
        hasToggleWrapper = true;
      }
    }
    expect(hasToggleWrapper, isFalse);
  });
}

const _sampleDiff = '''
diff --git a/lib/src/app.dart b/lib/src/app.dart
index 1111111..2222222 100644
--- a/lib/src/app.dart
+++ b/lib/src/app.dart
@@ -1,3 +1,4 @@
-final enabled = false;
+final enabled = true;
+final retries = 3;
 void run() {}
''';
