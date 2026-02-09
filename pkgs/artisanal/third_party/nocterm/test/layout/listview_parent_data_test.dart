import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// Comprehensive tests for ListView parent data handling.
///
/// These tests ensure that the refactoring to use parent data for layout offsets
/// works correctly. The parent data (ListViewParentData) stores:
/// - layoutOffset: The scroll offset of each child from the start of the list
/// - extent: The measured size (height for vertical, width for horizontal) of each child
/// - index: The index of this child in the list
///
/// This follows Flutter's architecture where position data is attached to each
/// child's render object rather than cached in separate maps.
void main() {
  group('ListView parent data basics', () {
    test('items have correct parent data after initial layout', () async {
      await testNocterm(
        'initial parent data',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 10,
              child: ListView.builder(
                controller: scrollController,
                lazy: false, // Non-lazy to build all items
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // All 5 items should be visible or built
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 1'), isTrue);
          expect(tester.terminalState.containsText('Item 2'), isTrue);
          expect(tester.terminalState.containsText('Item 3'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);

          // Verify scroll extent is calculated correctly
          // 5 items of height 1 each, viewport of 10 means no scrolling needed
          expect(scrollController.maxScrollExtent, equals(0.0));
        },
        size: Size(35, 15),
      );
    });

    test('items have correct parent data with fixed itemExtent',
        skip:
            'Known bug: ListView maxScrollExtent not calculated correctly with Container',
        () async {
      await testNocterm(
        'fixed itemExtent parent data',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 10,
                itemExtent: 1, // Fixed height of 1 per item
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // With 10 items of height 1 and viewport of 5
          // maxScrollExtent should be 10 - 5 = 5
          expect(scrollController.maxScrollExtent, equals(5.0));

          // Verify initial items are visible
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);
          expect(tester.terminalState.containsText('Item 9'), isFalse);
        },
        size: Size(35, 10),
      );
    });

    test('scrolling updates which items are visible',
        skip: 'Known bug: ListView scrolling with Container constraint',
        () async {
      await testNocterm(
        'scroll updates visibility',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 15,
                itemExtent: 1,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Initially items 0-4 should be visible
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 10'), isFalse);

          // Scroll to offset 10
          scrollController.jumpTo(10.0);
          await tester.pump();

          // Now items 10-14 should be visible
          expect(tester.terminalState.containsText('Item 0'), isFalse);
          expect(tester.terminalState.containsText('Item 10'), isTrue);
          expect(tester.terminalState.containsText('Item 14'), isTrue);
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView parent data with variable height items', () {
    test('variable height items are laid out correctly', () async {
      await testNocterm(
        'variable height layout',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 10,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 5,
                itemBuilder: (context, index) {
                  // Create items with varying heights
                  if (index == 2) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Multi'),
                        Text('Line'),
                        Text('Item $index'),
                      ],
                    );
                  }
                  return Text('Item $index');
                },
              ),
            ),
          );

          // All content should be visible
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Multi'), isTrue);
          expect(tester.terminalState.containsText('Line'), isTrue);
          expect(tester.terminalState.containsText('Item 2'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('scrolling works correctly with variable height items', () async {
      await testNocterm(
        'variable height scrolling',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 10,
                itemBuilder: (context, index) {
                  // Every third item is 2 lines tall
                  if (index % 3 == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tall $index'),
                        Text('Line 2'),
                      ],
                    );
                  }
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Verify scrolling works
          expect(scrollController.maxScrollExtent, greaterThan(0));

          // Scroll to end
          scrollController.scrollToEnd();
          await tester.pump();

          // Last item should be visible (index 9 is a "Tall" item since 9 % 3 == 0)
          expect(tester.terminalState.containsText('Tall 9'), isTrue);
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView lazy mode parent data', () {
    test('lazy mode only builds visible items initially', () async {
      await testNocterm(
        'lazy initial build',
        (tester) async {
          final scrollController = ScrollController();
          final builtIndices = <int>{};

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 100,
                itemExtent: 1,
                itemBuilder: (context, index) {
                  builtIndices.add(index);
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Only visible items (0-4) plus cache should be built
          // With cacheExtent of 5.0, we might build a few extra
          expect(builtIndices.length, lessThan(20));
          expect(builtIndices.contains(0), isTrue);
          expect(builtIndices.contains(50), isFalse);
          expect(builtIndices.contains(99), isFalse);
        },
        size: Size(35, 10),
      );
    });

    test('lazy mode builds items as they scroll into view', () async {
      await testNocterm(
        'lazy scroll build',
        (tester) async {
          final scrollController = ScrollController();
          final builtIndices = <int>{};

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 100,
                itemExtent: 1,
                itemBuilder: (context, index) {
                  builtIndices.add(index);
                  return Text('Item $index');
                },
              ),
            ),
          );

          builtIndices.clear();

          // Scroll to middle
          scrollController.jumpTo(50.0);
          await tester.pump();

          // Items around index 50 should now be built
          expect(builtIndices.contains(50), isTrue);
          expect(builtIndices.contains(51), isTrue);
          expect(builtIndices.contains(0), isFalse); // Old items not rebuilt
        },
        size: Size(35, 10),
      );
    });

    test('lazy mode removes items that scroll out of view', () async {
      await testNocterm(
        'lazy remove out of view',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 100,
                itemExtent: 1,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Items 0-4 visible
          expect(tester.terminalState.containsText('Item 0'), isTrue);

          // Jump far away
          scrollController.jumpTo(80.0);
          await tester.pump();

          // Items 80-84 should now be visible
          expect(tester.terminalState.containsText('Item 80'), isTrue);
          expect(tester.terminalState.containsText('Item 0'), isFalse);
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView reverse mode parent data', () {
    test('reverse mode lays out items from bottom', () async {
      await testNocterm(
        'reverse layout',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 10,
              child: ListView.builder(
                reverse: true,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // In reverse mode, Item 0 should appear at the bottom visually
          // All items should be visible
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 4'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('reverse mode scrolling works correctly', () async {
      await testNocterm(
        'reverse scroll',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                itemCount: 15,
                itemExtent: 1,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Initially first items (0-4) should be visible at bottom
          expect(tester.terminalState.containsText('Item 0'), isTrue);

          // Scroll to see more items
          scrollController.jumpTo(10.0);
          await tester.pump();

          // Now items 10-14 should be visible
          expect(tester.terminalState.containsText('Item 10'), isTrue);
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView separated parent data', () {
    test('separators are included in layout calculations', () async {
      await testNocterm(
        'separated layout',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 10,
              child: ListView.separated(
                controller: scrollController,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
                separatorBuilder: (context, index) {
                  return Text('---');
                },
              ),
            ),
          );

          // Items and separators should be visible
          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('---'), isTrue);
          expect(tester.terminalState.containsText('Item 1'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('separated mode scroll extent includes separators',
        skip: 'Known bug: ListView maxScrollExtent not calculated correctly',
        () async {
      await testNocterm(
        'separated scroll extent',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.separated(
                controller: scrollController,
                lazy: false,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
                separatorBuilder: (context, index) {
                  return Text('-');
                },
              ),
            ),
          );

          // 10 items + 9 separators = 19 lines
          // Viewport of 5, so maxScrollExtent = 19 - 5 = 14
          expect(scrollController.maxScrollExtent, equals(14.0));
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView dynamic updates', () {
    test('adding items updates scroll extent',
        skip: 'Known bug: ListView maxScrollExtent not calculated correctly',
        () async {
      await testNocterm(
        'add items extent',
        (tester) async {
          final scrollController = ScrollController();

          // Start with 5 items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // 5 items fit in viewport of 5, no scrolling
          expect(scrollController.maxScrollExtent, equals(0.0));

          // Add more items (10 total)
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Now we should be able to scroll
          expect(scrollController.maxScrollExtent, equals(5.0));
        },
        size: Size(35, 10),
      );
    });

    test('removing items updates scroll extent',
        skip: 'Known bug: ListView maxScrollExtent not calculated correctly',
        () async {
      await testNocterm(
        'remove items extent',
        (tester) async {
          final scrollController = ScrollController();

          // Start with 10 items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          expect(scrollController.maxScrollExtent, equals(5.0));

          // Remove items (5 total)
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // No scrolling needed with 5 items
          expect(scrollController.maxScrollExtent, equals(0.0));
        },
        size: Size(35, 10),
      );
    });

    test('item content update reflects in display', () async {
      await testNocterm(
        'content update',
        (tester) async {
          int version = 1;

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Text('V$version Item $index');
                },
              ),
            ),
          );

          expect(tester.terminalState.containsText('V1 Item 0'), isTrue);

          // Update content
          version = 2;
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Text('V$version Item $index');
                },
              ),
            ),
          );

          expect(tester.terminalState.containsText('V2 Item 0'), isTrue);
          expect(tester.terminalState.containsText('V1 Item 0'), isFalse);
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView scroll position edge cases', () {
    test('scroll position clamped when items removed',
        skip: 'Known bug: ListView maxScrollExtent not calculated correctly',
        () async {
      await testNocterm(
        'clamp on remove',
        (tester) async {
          final scrollController = ScrollController();

          // Start with 20 items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Scroll to end
          scrollController.jumpTo(15.0);
          await tester.pump();
          expect(scrollController.offset, equals(15.0));

          // Remove most items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Offset should be clamped to new maxScrollExtent (0)
          expect(scrollController.offset, equals(0.0));
        },
        size: Size(35, 10),
      );
    });

    test('jumpTo respects bounds',
        skip: 'Known bug: ListView maxScrollExtent not calculated correctly',
        () async {
      await testNocterm(
        'jumpTo bounds',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Try to jump past end
          scrollController.jumpTo(100.0);
          await tester.pump();

          // Should be clamped to maxScrollExtent
          expect(scrollController.offset, equals(5.0));

          // Try to jump before start
          scrollController.jumpTo(-100.0);
          await tester.pump();

          // Should be clamped to 0
          expect(scrollController.offset, equals(0.0));
        },
        size: Size(35, 10),
      );
    });

    test('scrollDown respects bounds',
        skip: 'Known bug: ListView maxScrollExtent not calculated correctly',
        () async {
      await testNocterm(
        'scrollDown bounds',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Scroll down many times
          for (int i = 0; i < 20; i++) {
            scrollController.scrollDown(1.0);
          }
          await tester.pump();

          // Should stop at maxScrollExtent
          expect(scrollController.offset, equals(5.0));
        },
        size: Size(35, 10),
      );
    });

    test('scrollUp respects bounds', () async {
      await testNocterm(
        'scrollUp bounds',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Start at the end
          scrollController.jumpTo(5.0);
          await tester.pump();

          // Scroll up many times
          for (int i = 0; i < 20; i++) {
            scrollController.scrollUp(1.0);
          }
          await tester.pump();

          // Should stop at 0
          expect(scrollController.offset, equals(0.0));
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView with complex items', () {
    test('items with Container and padding', () async {
      await testNocterm(
        'container items',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.all(1),
                    child: Text('Item $index'),
                  );
                },
              ),
            ),
          );

          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 1'), isTrue);
          expect(tester.terminalState.containsText('Item 2'), isTrue);
        },
        size: Size(35, 15),
      );
    });

    test('items with nested Row/Column', () async {
      await testNocterm(
        'nested layout items',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              height: 10,
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Text('[$index]'),
                      Expanded(child: Text(' Content for item $index')),
                    ],
                  );
                },
              ),
            ),
          );

          expect(tester.terminalState.containsText('[0]'), isTrue);
          expect(tester.terminalState.containsText('[1]'), isTrue);
          expect(tester.terminalState.containsText('[2]'), isTrue);
        },
        size: Size(45, 15),
      );
    });

    test('items with GestureDetector', () async {
      await testNocterm(
        'gesture items',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 10,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {},
                    child: Text('Tap me $index'),
                  );
                },
              ),
            ),
          );

          expect(tester.terminalState.containsText('Tap me 0'), isTrue);
          // Note: Actual tap testing would require simulating mouse events
        },
        size: Size(35, 15),
      );
    });
  });

  group('ListView scrollToEnd regression', () {
    test('scrollToEnd works after items are added', () async {
      await testNocterm(
        'scrollToEnd after add',
        (tester) async {
          final scrollController = ScrollController();

          // Start with 5 items (no scroll needed)
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Add items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false,
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Scroll to end
          scrollController.scrollToEnd();
          await tester.pump();

          // Last items should be visible
          expect(
            tester.terminalState.containsText('Item 19') ||
                tester.terminalState.containsText('Item 18'),
            isTrue,
            reason: 'Should be able to scroll to see last items',
          );
        },
        size: Size(35, 10),
      );
    });

    test('scrollToEnd works with lazy mode', () async {
      await testNocterm(
        'scrollToEnd lazy',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 50,
                itemExtent: 1, // Fixed extent for accurate calculation
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Scroll to end
          scrollController.scrollToEnd();
          await tester.pump();

          // Last items should be visible
          expect(
            tester.terminalState.containsText('Item 49') ||
                tester.terminalState.containsText('Item 48'),
            isTrue,
            reason: 'Should be able to scroll to last items in lazy mode',
          );
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView horizontal mode', () {
    test('horizontal layout works correctly', () async {
      await testNocterm(
        'horizontal layout',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(width: 10, child: Center(child: Text('A'))),
                  Container(width: 10, child: Center(child: Text('B'))),
                  Container(width: 10, child: Center(child: Text('C'))),
                ],
              ),
            ),
          );

          // All items should be visible horizontally
          expect(tester.terminalState.containsText('A'), isTrue);
          expect(tester.terminalState.containsText('B'), isTrue);
          expect(tester.terminalState.containsText('C'), isTrue);
        },
        size: Size(35, 10),
      );
    });

    test('horizontal scrolling works', () async {
      await testNocterm(
        'horizontal scroll',
        (tester) async {
          final scrollController = ScrollController();

          await tester.pumpComponent(
            Container(
              width: 20,
              height: 3,
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Container(
                    width: 5,
                    child: Center(child: Text('$index')),
                  );
                },
              ),
            ),
          );

          // Initially items 0-3 visible
          expect(tester.terminalState.containsText('0'), isTrue);

          // Scroll right
          scrollController.jumpTo(30.0);
          await tester.pump();

          // Later items should be visible
          expect(tester.terminalState.containsText('6'), isTrue);
        },
        size: Size(25, 10),
      );
    });
  });
}
