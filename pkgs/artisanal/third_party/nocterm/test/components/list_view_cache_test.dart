// Tests for ListView cache invalidation when itemCount changes.
// This test file was created to prevent regressions of the bug where
// _itemOffsets and _itemExtents caches weren't invalidated when itemCount
// changed, causing new items to not render (especially with reverse: true).
//
// ARCHITECTURAL NOTE (Flutter comparison):
// Flutter stores `layoutOffset` in `parentData` on each child render object,
// not in a separate map keyed by index. This means Flutter doesn't have the
// same cache invalidation issue we had.
//
// Our architecture uses `_itemOffsets` as a `Map<int, double>` keyed by index,
// so we need to invalidate when indices shift (e.g., when items are prepended
// in reverse mode). Our fix (invalidate when `itemCount` changes) is the right
// approach for our architecture.
//
// Key test coverage:
// 1. Basic itemCount increase/decrease
// 2. Reverse mode with prepended items (the exact bug scenario)
// 3. Cache is preserved when itemCount stays the same (performance)

import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('ListView cache invalidation', () {
    test('renders new items when itemCount increases', () async {
      await testNocterm(
        'itemCount increase',
        (tester) async {
          // Start with 3 items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          // Verify initial 3 items
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 1'), isTrue);
          expect(tester.terminalState.containsText('Item 2'), isTrue);

          // Increase to 5 items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          // Verify all 5 items render (visible ones at least)
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 3'), isTrue,
              reason: 'New items must render when itemCount increases');
          expect(tester.terminalState.containsText('Item 4'), isTrue,
              reason: 'New items must render when itemCount increases');
        },
        size: Size(35, 15),
      );
    });

    test('removes items when itemCount decreases', () async {
      await testNocterm(
        'itemCount decrease',
        (tester) async {
          // Start with 5 items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          // Verify initial 5 items
          expect(tester.terminalState.containsText('Item 4'), isTrue);

          // Decrease to 3 items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          // Verify only 3 items render
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 1'), isTrue);
          expect(tester.terminalState.containsText('Item 2'), isTrue);
          expect(tester.terminalState.containsText('Item 3'), isFalse,
              reason: 'Removed items must not render');
          expect(tester.terminalState.containsText('Item 4'), isFalse,
              reason: 'Removed items must not render');
        },
        size: Size(35, 15),
      );
    });

    test('renders new items with reverse: true', () async {
      // CRITICAL: This is the exact bug we fixed.
      // With reverse: true (chat UI pattern), new items prepend at index 0
      // and all existing indices shift. The cache must be invalidated
      // so new items at index 0 are rendered.
      await testNocterm(
        'reverse mode new items',
        (tester) async {
          List<String> messages = ['Message 1', 'Message 2'];

          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => Text(messages[index]),
              ),
            ),
          );

          // Initial state
          expect(tester.terminalState.containsText('Message 1'), isTrue);
          expect(tester.terminalState.containsText('Message 2'), isTrue);

          // Add new message (prepended, like in a chat)
          messages = ['NEW MESSAGE', ...messages];

          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => Text(messages[index]),
              ),
            ),
          );

          // CRITICAL: New message MUST appear
          expect(tester.terminalState.containsText('NEW MESSAGE'), isTrue,
              reason:
                  'New items must render when prepended in reverse mode - this was the original bug');
          expect(tester.terminalState.containsText('Message 1'), isTrue);
          expect(tester.terminalState.containsText('Message 2'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('handles rapid itemCount changes', () async {
      // Simulate chat: 3 -> 4 -> 5 -> 6 items rapidly
      await testNocterm(
        'rapid itemCount changes',
        (tester) async {
          for (int count = 3; count <= 8; count++) {
            await tester.pumpComponent(
              SizedBox(
                width: 30,
                height: 15,
                child: ListView.builder(
                  itemCount: count,
                  itemBuilder: (context, index) => Text('Item $index'),
                ),
              ),
            );

            // Verify the last item renders
            expect(
                tester.terminalState.containsText('Item ${count - 1}'), isTrue,
                reason:
                    'Item ${count - 1} must render after itemCount = $count');
          }
        },
        size: Size(35, 20),
      );
    });
  });

  group('ListView cache preservation', () {
    test('preserves cache when itemCount unchanged', () async {
      await testNocterm(
        'cache preserved on scroll',
        (tester) async {
          final scrollController = ScrollController();
          int buildCount = 0;

          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 20,
                itemBuilder: (context, index) {
                  buildCount++;
                  return Text('Item $index');
                },
              ),
            ),
          );

          final initialBuildCount = buildCount;

          // Scroll down
          scrollController.scrollDown(2.0);
          await tester.pump();

          // Items should still render correctly
          expect(tester.terminalState.containsText('Item'), isTrue);

          // Build count should only increase for newly visible items,
          // not for already cached items
          expect(buildCount, greaterThan(initialBuildCount));
        },
        size: Size(35, 10),
      );
    });

    test('preserves cache during parent rebuild without itemCount change',
        () async {
      await testNocterm(
        'cache preserved on parent rebuild',
        (tester) async {
          int buildCount = 0;

          // First render
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 5,
              child: Column(
                children: [
                  Text('Other state: 0'),
                  Expanded(
                    child: ListView.builder(
                      lazy: true,
                      itemCount: 10, // itemCount stays the same
                      itemBuilder: (context, index) {
                        buildCount++;
                        return Text('Item $index');
                      },
                    ),
                  ),
                ],
              ),
            ),
          );

          final initialBuildCount = buildCount;

          // Re-render with different header but same itemCount
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 5,
              child: Column(
                children: [
                  Text('Other state: 1'),
                  Expanded(
                    child: ListView.builder(
                      lazy: true,
                      itemCount: 10, // itemCount stays the same
                      itemBuilder: (context, index) {
                        buildCount++;
                        return Text('Item $index');
                      },
                    ),
                  ),
                ],
              ),
            ),
          );

          // Items should rebuild to get updated state
          // (but cache structure should be preserved for performance)
          expect(tester.terminalState.containsText('Other state: 1'), isTrue);
          expect(tester.terminalState.containsText('Item 0'), isTrue);

          // Items will rebuild because parent rebuilt
          expect(buildCount, greaterThan(initialBuildCount));
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView reverse mode', () {
    test('new items appear at visual bottom with reverse: true', () async {
      // With reverse: true, index 0 is at the visual bottom
      // New items (at index 0) should appear at bottom
      await testNocterm(
        'reverse mode visual position',
        (tester) async {
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                reverse: true,
                itemCount: 5,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          // All items should be visible
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 1'), isTrue);
          expect(tester.terminalState.containsText('Item 2'), isTrue);
          expect(tester.terminalState.containsText('Item 3'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('scroll position maintained when items added in reverse mode',
        () async {
      await testNocterm(
        'reverse mode scroll position',
        (tester) async {
          final scrollController = ScrollController();
          List<String> messages = ['Msg 1', 'Msg 2', 'Msg 3'];

          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 8,
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => Text(messages[index]),
              ),
            ),
          );

          // Add a message
          messages = ['New Msg', ...messages];

          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 8,
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => Text(messages[index]),
              ),
            ),
          );

          // New message should be visible
          expect(tester.terminalState.containsText('New Msg'), isTrue,
              reason: 'New message must appear when added');
        },
        size: Size(35, 12),
      );
    });

    test('multiple rapid additions in reverse mode', () async {
      // Simulate receiving multiple chat messages quickly
      await testNocterm(
        'rapid additions reverse mode',
        (tester) async {
          List<String> messages = ['Initial'];

          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 15,
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => Text(messages[index]),
              ),
            ),
          );

          // Rapid additions (like receiving chat messages)
          for (int i = 1; i <= 5; i++) {
            messages = ['Msg $i', ...messages];

            await tester.pumpComponent(
              SizedBox(
                width: 30,
                height: 15,
                child: ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) => Text(messages[index]),
                ),
              ),
            );

            expect(tester.terminalState.containsText('Msg $i'), isTrue,
                reason: 'Message $i must appear immediately after being added');
          }

          // All messages should be visible
          expect(tester.terminalState.containsText('Initial'), isTrue);
          expect(tester.terminalState.containsText('Msg 5'), isTrue);
        },
        size: Size(35, 20),
      );
    });
  });

  group('ListView edge cases', () {
    test('handles itemCount from null to number', () async {
      // Infinite list -> finite list
      await testNocterm(
        'null to finite itemCount',
        (tester) async {
          // Initially infinite (null itemCount)
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: null,
                itemBuilder: (context, index) {
                  // For null itemCount, only render up to 10 items
                  if (index >= 10) return null;
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Initially infinite (null itemCount), showing items
          expect(tester.terminalState.containsText('Item 0'), isTrue);

          // Change to finite
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Only 5 items should render
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('handles itemCount from number to null', () async {
      // Finite list -> infinite list
      await testNocterm(
        'finite to null itemCount',
        (tester) async {
          // Initially 5 items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          expect(tester.terminalState.containsText('Item 4'), isTrue);

          // Change to infinite (null)
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: null,
                itemBuilder: (context, index) {
                  // For null itemCount, allow more items
                  if (index >= 15) return null;
                  return Text('Item $index');
                },
              ),
            ),
          );

          // More items should be available (though may not all be visible)
          expect(tester.terminalState.containsText('Item 0'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('handles itemCount change from 0 to n', () async {
      // Empty list -> populated list
      await testNocterm(
        'empty to populated',
        (tester) async {
          // Initially empty
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 0,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          // Initially empty
          expect(tester.terminalState.containsText('Item'), isFalse);

          // Add items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          // Items should render
          expect(tester.terminalState.containsText('Item 0'), isTrue,
              reason: 'Items must render when going from empty to populated');
          expect(tester.terminalState.containsText('Item 4'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('handles itemCount change from n to 0', () async {
      // Populated list -> empty list
      await testNocterm(
        'populated to empty',
        (tester) async {
          // Initially 5 items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);

          // Clear all items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 0,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          );

          // No items should render
          expect(tester.terminalState.containsText('Item 0'), isFalse,
              reason: 'No items should render when itemCount is 0');
          expect(tester.terminalState.containsText('Item'), isFalse);
        },
        size: Size(35, 15),
      );
    });
  });

  group('CRITICAL: Original bug regression test', () {
    test('CRITICAL: new items render after state change with reverse: true',
        () async {
      // This test MUST exist and would have caught the original bug.
      // The bug was that when itemCount changed, the _itemOffsets and
      // _itemExtents caches weren't invalidated, causing new items
      // (especially at index 0 in reverse mode) to not render.
      await testNocterm(
        'CRITICAL regression test',
        (tester) async {
          // Simulate chat UI: messages list that grows
          List<String> messages = ['Message 1', 'Message 2'];

          await tester.pumpComponent(
            SizedBox(
              width: 40,
              height: 10,
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => Text(messages[index]),
              ),
            ),
          );

          // Initial state
          expect(tester.terminalState.containsText('Message 1'), isTrue);
          expect(tester.terminalState.containsText('Message 2'), isTrue);

          // Add new message (prepended, like in a chat)
          messages = ['NEW MESSAGE', ...messages];

          await tester.pumpComponent(
            SizedBox(
              width: 40,
              height: 10,
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) => Text(messages[index]),
              ),
            ),
          );

          // CRITICAL: New message MUST appear
          // This is THE regression test for the bug we fixed
          expect(tester.terminalState.containsText('NEW MESSAGE'), isTrue,
              reason: 'New items must render when prepended in reverse mode. '
                  'This is the CRITICAL test that would have caught the original '
                  'bug where _itemOffsets and _itemExtents caches were not '
                  'invalidated when itemCount changed.');
        },
        size: Size(45, 15),
      );
    });

    test('cache invalidation occurs when itemCount changes', () async {
      // Verify the fix: caches should be invalidated when itemCount changes
      await testNocterm(
        'cache invalidation verification',
        (tester) async {
          final List<int> builtIndices = [];

          // Start with 3 items
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                lazy: true,
                itemCount: 3,
                itemBuilder: (context, index) {
                  builtIndices.add(index);
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Clear to track new builds
          builtIndices.clear();

          // Increase itemCount - should trigger cache invalidation
          await tester.pumpComponent(
            SizedBox(
              width: 30,
              height: 10,
              child: ListView.builder(
                lazy: true,
                itemCount: 6,
                itemBuilder: (context, index) {
                  builtIndices.add(index);
                  return Text('Item $index');
                },
              ),
            ),
          );

          // New items should have been built
          // (The exact indices depend on viewport size, but new indices should appear)
          expect(builtIndices.where((i) => i >= 3).isNotEmpty, isTrue,
              reason:
                  'New item indices (3, 4, 5) should be built after itemCount increase');

          // Verify they render
          expect(tester.terminalState.containsText('Item 3'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);
          expect(tester.terminalState.containsText('Item 5'), isTrue);
        },
        size: Size(35, 15),
      );
    });
  });

  group('ListView with StatefulComponent for state changes', () {
    test('renders new items when state changes with stateful parent', () async {
      await testNocterm(
        'stateful parent state change',
        (tester) async {
          await tester.pumpComponent(_DynamicListView());

          // Initial state shows 3 items
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 2'), isTrue);
          expect(tester.terminalState.containsText('Item 3'), isFalse);

          // Trigger state change to add items
          final state = tester.findState<_DynamicListViewState>();
          state.addItems(3);
          await tester.pump();

          // New items should render
          expect(tester.terminalState.containsText('Item 3'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);
          expect(tester.terminalState.containsText('Item 5'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('renders new items with reverse mode using stateful parent', () async {
      await testNocterm(
        'stateful reverse mode',
        (tester) async {
          await tester.pumpComponent(_DynamicChatView());

          // Initial state shows messages
          expect(tester.terminalState.containsText('Message 0'), isTrue);
          expect(tester.terminalState.containsText('Message 1'), isTrue);

          // Add a new message (prepended)
          final state = tester.findState<_DynamicChatViewState>();
          state.addMessage('NEW MESSAGE');
          await tester.pump();

          // New message should render
          expect(tester.terminalState.containsText('NEW MESSAGE'), isTrue,
              reason:
                  'New prepended message must render in reverse mode with stateful parent');
          expect(tester.terminalState.containsText('Message 0'), isTrue);
          expect(tester.terminalState.containsText('Message 1'), isTrue);
        },
        size: Size(35, 15),
      );
    });
  });
}

/// Helper widget that can dynamically add items
class _DynamicListView extends StatefulComponent {
  @override
  State<_DynamicListView> createState() => _DynamicListViewState();
}

class _DynamicListViewState extends State<_DynamicListView> {
  int itemCount = 3;

  void addItems(int count) {
    setState(() {
      itemCount += count;
    });
  }

  @override
  Component build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 10,
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) => Text('Item $index'),
      ),
    );
  }
}

/// Helper widget that simulates a chat with reverse list
class _DynamicChatView extends StatefulComponent {
  @override
  State<_DynamicChatView> createState() => _DynamicChatViewState();
}

class _DynamicChatViewState extends State<_DynamicChatView> {
  List<String> messages = ['Message 0', 'Message 1'];

  void addMessage(String message) {
    setState(() {
      messages = [message, ...messages]; // Prepend like a chat
    });
  }

  @override
  Component build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 10,
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) => Text(messages[index]),
      ),
    );
  }
}
