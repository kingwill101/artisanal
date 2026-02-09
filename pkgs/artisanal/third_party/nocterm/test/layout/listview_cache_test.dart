import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('ListView cache optimization', () {
    test('itemBuilder is only called once per unique index during layout',
        () async {
      await testNocterm(
        'cache optimization test',
        (tester) async {
          final scrollController = ScrollController();
          int buildCount = 0;
          final builtIndices = <int>{};

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 100,
                itemBuilder: (context, index) {
                  buildCount++;
                  builtIndices.add(index);
                  return Text('Item $index');
                },
              ),
            ),
          );

          final initialBuildCount = buildCount;
          final initialUniqueCount = builtIndices.length;

          // Build count should equal unique items (no redundant calls)
          expect(initialBuildCount, equals(initialUniqueCount),
              reason:
                  'Each item should only be built once during initial layout');

          // Scroll down
          scrollController.scrollDown(3.0);
          await tester.pump();

          // After scrolling, new items may be built but existing ones shouldn't rebuild
          final newUniqueItems = builtIndices.length - initialUniqueCount;
          final newBuildCalls = buildCount - initialBuildCount;

          expect(newBuildCalls, equals(newUniqueItems),
              reason:
                  'Only newly visible items should trigger builder calls after scroll');
        },
        size: Size(35, 10),
      );
    });

    test('non-lazy mode also benefits from cache optimization', () async {
      await testNocterm(
        'non-lazy cache test',
        (tester) async {
          final scrollController = ScrollController();
          int buildCount = 0;

          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: false, // Non-lazy builds all items
                itemCount: 50,
                itemBuilder: (context, index) {
                  buildCount++;
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Non-lazy mode should build all 50 items exactly once
          expect(buildCount, equals(50),
              reason: 'Non-lazy mode should build each item exactly once');

          // Scroll and verify no redundant rebuilds
          final buildCountBeforeScroll = buildCount;
          scrollController.scrollDown(10.0);
          await tester.pump();

          // Scrolling should NOT trigger additional itemBuilder calls
          // because all items are already cached
          expect(buildCount, equals(buildCountBeforeScroll),
              reason:
                  'Scrolling should not rebuild already cached items in non-lazy mode');
        },
        size: Size(35, 10),
      );
    });
  });

  group('ListView rebuild on state change', () {
    test('items rebuild when parent state changes (selection)', () async {
      await testNocterm(
        'selection rebuild test',
        (tester) async {
          // Test widget that tracks selection state
          int selectedIndex = 0;

          Component buildList(int selected) {
            return Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                lazy: true,
                itemCount: 5,
                itemBuilder: (context, index) {
                  final isSelected = index == selected;
                  return Text(
                    '${isSelected ? ">" : " "} Item $index',
                  );
                },
              ),
            );
          }

          // Initial render with item 0 selected
          await tester.pumpComponent(buildList(selectedIndex));

          expect(tester.terminalState.containsText('> Item 0'), isTrue,
              reason: 'Item 0 should be selected initially');
          expect(tester.terminalState.containsText('> Item 1'), isFalse,
              reason: 'Item 1 should not be selected initially');

          // Change selection to item 1
          selectedIndex = 1;
          await tester.pumpComponent(buildList(selectedIndex));

          expect(tester.terminalState.containsText('> Item 0'), isFalse,
              reason: 'Item 0 should no longer be selected');
          expect(tester.terminalState.containsText('> Item 1'), isTrue,
              reason: 'Item 1 should now be selected');

          // Change selection to item 2
          selectedIndex = 2;
          await tester.pumpComponent(buildList(selectedIndex));

          expect(tester.terminalState.containsText('> Item 1'), isFalse,
              reason: 'Item 1 should no longer be selected');
          expect(tester.terminalState.containsText('> Item 2'), isTrue,
              reason: 'Item 2 should now be selected');
        },
        size: Size(35, 10),
      );
    });

    test('items rebuild when itemCount changes', () async {
      await testNocterm(
        'item count change test',
        (tester) async {
          final scrollController = ScrollController();

          // Start with 3 items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          expect(tester.terminalState.containsText('Item 0'), isTrue);
          expect(tester.terminalState.containsText('Item 2'), isTrue);
          expect(tester.terminalState.containsText('Item 5'), isFalse,
              reason: 'Item 5 should not exist yet');

          // Increase to 10 items
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Scroll to see new items
          scrollController.scrollDown(5.0);
          await tester.pump();

          expect(tester.terminalState.containsText('Item 5'), isTrue,
              reason: 'New items should be visible after count increase');
        },
        size: Size(35, 10),
      );
    });

    test('cache is cleared when widget updates', () async {
      await testNocterm(
        'cache clear on update test',
        (tester) async {
          int buildCount = 0;

          // First render
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 3,
              child: ListView.builder(
                lazy: true,
                itemCount: 5,
                itemBuilder: (context, index) {
                  buildCount++;
                  return Text('Version 1 - Item $index');
                },
              ),
            ),
          );

          final firstRenderCount = buildCount;
          expect(tester.terminalState.containsText('Version 1'), isTrue);

          // Second render with different content
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 3,
              child: ListView.builder(
                lazy: true,
                itemCount: 5,
                itemBuilder: (context, index) {
                  buildCount++;
                  return Text('Version 2 - Item $index');
                },
              ),
            ),
          );

          // Items should have been rebuilt with new version
          expect(tester.terminalState.containsText('Version 2'), isTrue,
              reason: 'Items should show updated content after rebuild');
          expect(tester.terminalState.containsText('Version 1'), isFalse,
              reason: 'Old content should be replaced');

          // Build count should have increased (items were rebuilt)
          expect(buildCount, greaterThan(firstRenderCount),
              reason: 'Items should rebuild when widget updates');
        },
        size: Size(40, 8),
      );
    });
  });

  group('ListView performance with large lists', () {
    test('lazy mode handles large item counts efficiently', () async {
      await testNocterm(
        'large list performance test',
        (tester) async {
          final scrollController = ScrollController();
          int buildCount = 0;

          // Create a list with 10,000 items and fixed itemExtent for O(1) jumping
          await tester.pumpComponent(
            Container(
              width: 30,
              height: 5,
              child: ListView.builder(
                controller: scrollController,
                lazy: true,
                itemCount: 10000,
                itemExtent: 1, // Fixed extent enables efficient jumping
                itemBuilder: (context, index) {
                  buildCount++;
                  return Text('Item $index');
                },
              ),
            ),
          );

          // Only visible items should be built (roughly viewport height)
          expect(buildCount, lessThan(20),
              reason:
                  'Lazy mode should only build visible items, not all 10,000');

          final buildCountBeforeJump = buildCount;

          // Jump to middle of list - with fixed itemExtent this is O(1)
          scrollController.jumpTo(5000.0);
          await tester.pump();

          // With fixed itemExtent, jumping should only build visible items at new position
          final newBuilds = buildCount - buildCountBeforeJump;
          expect(newBuilds, lessThanOrEqualTo(20),
              reason:
                  'With fixed itemExtent, jumping should only build newly visible items');
        },
        size: Size(35, 10),
      );
    });

    test('scrolling through list only builds new items', () async {
      await testNocterm(
        'scroll efficiency test',
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
                itemBuilder: (context, index) {
                  builtIndices.add(index);
                  return Text('Item $index');
                },
              ),
            ),
          );

          final initialCount = builtIndices.length;

          // Scroll down multiple times
          for (int i = 0; i < 5; i++) {
            scrollController.scrollDown(2.0);
            await tester.pump();
          }

          // Should have built some new items but not rebuilt old ones
          // Total unique items built should be initial + new items scrolled into view
          expect(builtIndices.length, greaterThan(initialCount),
              reason: 'Scrolling should build new items');
          expect(builtIndices.length, lessThan(30),
              reason:
                  'Should not build excessive items - only what becomes visible');
        },
        size: Size(35, 10),
      );
    });
  });
}
