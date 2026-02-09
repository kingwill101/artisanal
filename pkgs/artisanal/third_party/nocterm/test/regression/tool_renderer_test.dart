import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// Test that mimics vide_cli's DefaultRenderer structure
/// to reproduce issues with BoxConstraints equality
void main() {
  group('Tool Renderer Layout', () {
    test('row with flexible text and fixed suffix renders correctly', () async {
      await testNocterm(
        'row with flexible text',
        (tester) async {
          await tester.pumpComponent(
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status indicator
                      Text('●', style: TextStyle(color: Colors.green)),
                      SizedBox(width: 1),
                      // Tool name
                      Text('Read'),
                      // Parameters with flexible + fixed suffix
                      Flexible(
                        child: Text(
                          '(file_path: /some/very/long/path/to/file.dart',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(')'),
                    ],
                  ),
                ],
              ),
            ),
          );

          // Verify the row renders correctly
          expect(tester.terminalState, containsText('●'));
          expect(tester.terminalState, containsText('Read'));
          expect(tester.terminalState, containsText(')'));
        },
        size: Size(60, 10),
        debugPrintAfterPump: true,
      );
    });

    test('nested row with expanded text renders correctly', () async {
      await testNocterm(
        'nested row with expanded',
        (tester) async {
          await tester.pumpComponent(
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Text('●'),
                      SizedBox(width: 1),
                      Text('Read'),
                      Flexible(
                        child: Text(
                          '(file_path: test.dart',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(')'),
                    ],
                  ),
                  // Result row with Expanded
                  Container(
                    padding: EdgeInsets.only(left: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⎿  '),
                        Expanded(
                          child: Text(
                            'File content preview here',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          expect(tester.terminalState, containsText('●'));
          expect(tester.terminalState, containsText('Read'));
          expect(tester.terminalState, containsText('⎿'));
          expect(tester.terminalState, containsText('File content'));
        },
        size: Size(60, 10),
        debugPrintAfterPump: true,
      );
    });

    test('multiple updates with same constraints should work', () async {
      await testNocterm(
        'multiple updates same constraints',
        (tester) async {
          // First render
          await tester.pumpComponent(
            _TestToolRenderer(filePath: '/path/to/file1.dart'),
          );

          print('\n--- First render ---');
          expect(tester.terminalState, containsText('file1.dart'));

          // Update with different content but same layout structure
          await tester.pumpComponent(
            _TestToolRenderer(filePath: '/path/to/file2.dart'),
          );

          print('\n--- Second render ---');
          expect(tester.terminalState, containsText('file2.dart'));

          // Third update
          await tester.pumpComponent(
            _TestToolRenderer(filePath: '/path/to/file3.dart'),
          );

          print('\n--- Third render ---');
          expect(tester.terminalState, containsText('file3.dart'));
        },
        size: Size(60, 10),
        debugPrintAfterPump: true,
      );
    });

    test('text length changes within Flexible should not leave gaps', () async {
      await testNocterm(
        'flexible text length changes',
        (tester) async {
          // First render with LONG path
          await tester.pumpComponent(
            _TestToolRenderer(filePath: '/some/very/long/path/to/file.dart'),
          );

          print('\n--- Long path ---');
          // The `)` should be right after the text

          // Update with SHORT path - this is where the bug might appear
          await tester.pumpComponent(
            _TestToolRenderer(filePath: 'short.dart'),
          );

          print('\n--- Short path ---');
          // If there's a bug, we might see: "(file_path: short.dart      )"
          // Instead of: "(file_path: short.dart)"
          // Check that there's no gap before the closing paren
          expect(
            tester.terminalState,
            containsText('short.dart)'),
            reason: 'Closing paren should be immediately after the text',
          );
        },
        size: Size(60, 10),
        debugPrintAfterPump: true,
      );
    });

    test('text length changes with styled text', () async {
      await testNocterm(
        'styled flexible text length changes',
        (tester) async {
          // Mimic vide_cli's exact structure with styled text
          final textColor = Colors.white;
          final dimColor = textColor.withOpacity(0.6);

          // First render with LONG path
          await tester.pumpComponent(
            Row(
              children: [
                Text('●', style: TextStyle(color: Colors.yellow)),
                SizedBox(width: 1),
                Text('Read', style: TextStyle(color: textColor)),
                Flexible(
                  child: Text(
                    '(file_path: /some/very/long/path/to/file.dart',
                    style: TextStyle(color: dimColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(')', style: TextStyle(color: dimColor)),
              ],
            ),
          );

          print('\n--- Long path (styled) ---');

          // Update with SHORT path
          await tester.pumpComponent(
            Row(
              children: [
                Text('●', style: TextStyle(color: Colors.green)),
                SizedBox(width: 1),
                Text('Read', style: TextStyle(color: textColor)),
                Flexible(
                  child: Text(
                    '(file_path: short.dart',
                    style: TextStyle(color: dimColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(')', style: TextStyle(color: dimColor)),
              ],
            ),
          );

          print('\n--- Short path (styled) ---');
          expect(
            tester.terminalState,
            containsText('short.dart)'),
            reason: 'Closing paren should be immediately after the text',
          );
        },
        size: Size(60, 10),
        debugPrintAfterPump: true,
      );
    });

    test('SizedBox width changes trigger relayout', () async {
      await testNocterm(
        'SizedBox width changes',
        (tester) async {
          // Render with SizedBox(width: 1)
          await tester.pumpComponent(
            Row(
              children: [
                Text('A'),
                SizedBox(width: 1),
                Text('B'),
              ],
            ),
          );

          print('\n--- Width 1 ---');
          // A and B should be separated by 1 space
          expect(tester.terminalState, containsText('A B'));

          // Update with SizedBox(width: 3)
          await tester.pumpComponent(
            Row(
              children: [
                Text('A'),
                SizedBox(width: 3),
                Text('B'),
              ],
            ),
          );

          print('\n--- Width 3 ---');
          // A and B should be separated by 3 spaces
          expect(tester.terminalState, containsText('A   B'));
        },
        size: Size(20, 5),
        debugPrintAfterPump: true,
      );
    });
    test('stateful component with dynamic content updates correctly', () async {
      await testNocterm(
        'stateful dynamic content',
        (tester) async {
          // First render with pending state
          await tester.pumpComponent(
            _StatefulToolRenderer(
              toolName: 'Read',
              filePath: '/path/to/file.dart',
              hasResult: false,
            ),
          );

          print('\n--- Pending state ---');
          expect(tester.terminalState, containsText('●'));
          expect(tester.terminalState, containsText('Read'));
          expect(tester.terminalState, containsText('file.dart'));

          // Update to completed state
          await tester.pumpComponent(
            _StatefulToolRenderer(
              toolName: 'Read',
              filePath: '/path/to/file.dart',
              hasResult: true,
            ),
          );

          print('\n--- Completed state ---');
          expect(tester.terminalState, containsText('●'));
          expect(tester.terminalState, containsText('Read'));
          expect(tester.terminalState, containsText('file.dart'));
        },
        size: Size(60, 10),
        debugPrintAfterPump: true,
      );
    });

    test('row layout with conditional children', () async {
      await testNocterm(
        'conditional children',
        (tester) async {
          // First render without result
          await tester.pumpComponent(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('●'),
                    SizedBox(width: 1),
                    Text('Read'),
                    Flexible(
                      child: Text(
                        '(file: test.dart',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(')'),
                  ],
                ),
                // No result row
              ],
            ),
          );

          print('\n--- Without result ---');
          expect(tester.terminalState, containsText('Read'));

          // Update WITH result
          await tester.pumpComponent(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('●'),
                    SizedBox(width: 1),
                    Text('Read'),
                    Flexible(
                      child: Text(
                        '(file: test.dart',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(')'),
                  ],
                ),
                // Result row added
                Container(
                  padding: EdgeInsets.only(left: 2),
                  child: Row(
                    children: [
                      Text('⎿  '),
                      Expanded(child: Text('Result content')),
                    ],
                  ),
                ),
              ],
            ),
          );

          print('\n--- With result ---');
          expect(tester.terminalState, containsText('Read'));
          expect(tester.terminalState, containsText('⎿'));
          expect(tester.terminalState, containsText('Result'));
        },
        size: Size(60, 10),
        debugPrintAfterPump: true,
      );
    });
  });
}

/// Test component mimicking DefaultRenderer structure (Stateless)
class _TestToolRenderer extends StatelessComponent {
  final String filePath;

  const _TestToolRenderer({required this.filePath});

  @override
  Component build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('●', style: TextStyle(color: Colors.green)),
              SizedBox(width: 1),
              Text('Read'),
              Flexible(
                child: Text(
                  '(file_path: $filePath',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Text(')'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stateful version mimicking vide_cli's DefaultRenderer
class _StatefulToolRenderer extends StatefulComponent {
  final String toolName;
  final String filePath;
  final bool hasResult;

  const _StatefulToolRenderer({
    required this.toolName,
    required this.filePath,
    required this.hasResult,
  });

  @override
  State<_StatefulToolRenderer> createState() => _StatefulToolRendererState();
}

class _StatefulToolRendererState extends State<_StatefulToolRenderer> {
  @override
  Component build(BuildContext context) {
    final statusColor = component.hasResult ? Colors.green : Colors.yellow;

    return Container(
      padding: EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('●', style: TextStyle(color: statusColor)),
              SizedBox(width: 1),
              Text(component.toolName),
              if (component.filePath.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    '(file_path: ${component.filePath}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(')'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
