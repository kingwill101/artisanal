import 'dart:async';

import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('SettingsListItem', () {
    test('searches all terms across labels, category, reason and keywords', () {
      const item = SettingsListItem<String>(
        id: 'scroll',
        label: 'Scroll speed',
        category: 'Input',
        disabledReason: 'Needs terminal support',
        searchTerms: ['wheel', 'pointer'],
      );

      expect(item.matchesQuery('input wheel'), isTrue);
      expect(item.matchesQuery('support pointer'), isTrue);
      expect(item.matchesQuery('wheel volume'), isFalse);
    });
  });

  group('SettingsList', () {
    test('shows grouped values and explicit unavailable reasons', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: SettingsList<String>(
            items: const [
              SettingsListItem(
                id: 'mode',
                label: 'Color mode',
                category: 'Appearance',
                value: 'dark',
              ),
              SettingsListItem(
                id: 'notifications',
                label: 'Notifications',
                category: 'Alerts',
                disabledReason: 'No notification host is available.',
              ),
            ],
          ),
        ),
      );

      expect(tester.find.text('Appearance'), isTrue);
      expect(tester.find.text('dark'), isTrue);
      expect(tester.find.text('Alerts'), isTrue);
      expect(tester.find.text('No notification host is available.'), isTrue);
    });

    test(
      'retains selection by stable ID when the host replaces rows',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        String? activated;

        SettingsList<String> build(List<SettingsListItem<String>> items) =>
            SettingsList<String>(
              key: const ValueKey('settings'),
              items: items,
              onActivate: (id) {
                activated = id;
                return const SettingsListResult.accepted();
              },
              initialSelection: 'second',
            );

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: build(const [
              SettingsListItem(
                id: 'first',
                label: 'First',
                activation: SettingsListActivation.action,
              ),
              SettingsListItem(
                id: 'second',
                label: 'Second',
                activation: SettingsListActivation.action,
              ),
            ]),
          ),
        );
        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: build(const [
              SettingsListItem(
                id: 'third',
                label: 'Third',
                activation: SettingsListActivation.action,
              ),
              SettingsListItem(
                id: 'second',
                label: 'Second',
                activation: SettingsListActivation.action,
              ),
              SettingsListItem(
                id: 'first',
                label: 'First',
                activation: SettingsListActivation.action,
              ),
            ]),
          ),
        );

        tester.sendSpecialKey(KeyType.enter);
        expect(activated, 'second');
      },
    );

    test(
      'pointer activation targets and runs the row under the pointer',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        final adjustments = <String>[];
        String? activated;

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: SettingsList<String>(
              items: const [
                SettingsListItem(id: 'speed', label: 'Scroll speed'),
                SettingsListItem(
                  id: 'theme',
                  label: 'Theme',
                  activation: SettingsListActivation.action,
                ),
              ],
              onAdjust: (id, direction) {
                adjustments.add('$id:$direction');
                return const SettingsListResult.accepted();
              },
              onActivate: (id) {
                activated = id;
                return const SettingsListResult.accepted();
              },
            ),
          ),
        );

        tester.tap(tester.find.textLocation('Scroll speed'));
        await Future<void>.delayed(Duration.zero);
        tester.pump();
        expect(adjustments, ['speed:1']);
        expect(activated, isNull);

        tester.tap(tester.find.textLocation('Theme'));
        await Future<void>.delayed(Duration.zero);
        tester.pump();
        expect(adjustments, ['speed:1']);
        expect(activated, 'theme');
      },
    );

    test('shows an empty state when search filters every row', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: SettingsList<String>(
            items: const [
              SettingsListItem(
                id: 'color',
                label: 'Color mode',
                category: 'Appearance',
              ),
            ],
          ),
        ),
      );

      tester.typeText('no matching setting');
      expect(tester.find.text('No matches for "no matching setting"'), isTrue);
      expect(tester.find.text('Color mode'), isFalse);
      tester.sendSpecialKey(KeyType.enter);
      expect(tester.find.text('No matches for "no matching setting"'), isTrue);
    });

    test('renders controls in a compact settings viewport', () async {
      final tester = WidgetTester(screenWidth: 36, screenHeight: 12);
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: SettingsList<String>(
            title: 'Settings',
            width: 32,
            height: 10,
            items: const [
              SettingsListItem(
                id: 'color',
                label: 'Color mode',
                category: 'Appearance',
                value: 'dark',
              ),
            ],
          ),
        ),
      );

      expect(tester.find.text('Settings'), isTrue);
      expect(tester.find.text('Color mode'), isTrue);
      expect(tester.find.text('dark'), isTrue);
    });

    test('reveals the initial selection in a compact viewport', () async {
      final tester = WidgetTester(screenWidth: 36, screenHeight: 12);
      addTearDown(tester.dispose);

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: SettingsList<String>(
            width: 32,
            height: 10,
            initialSelection: 'option-6',
            items: [
              for (var index = 0; index < 7; index++)
                SettingsListItem(
                  id: 'option-$index',
                  label: 'Option $index',
                  category: 'Group $index',
                ),
            ],
          ),
        ),
      );

      expect(tester.view, contains('Option 6'));
    });

    test(
      'filters by multiple terms and preserves selected row identity',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        String? adjusted;

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: SettingsList<String>(
              items: const [
                SettingsListItem(
                  id: 'color',
                  label: 'Color mode',
                  category: 'Appearance',
                ),
                SettingsListItem(
                  id: 'scroll',
                  label: 'Scroll speed',
                  category: 'Input',
                  searchTerms: ['wheel', 'pointer'],
                ),
              ],
              onAdjust: (id, direction) {
                adjusted = '$id:$direction';
                return const SettingsListResult.accepted();
              },
            ),
          ),
        );

        tester.typeText('wheel pointer');
        expect(tester.find.text('Scroll speed'), isTrue);
        expect(tester.find.text('Color mode'), isFalse);
        tester.sendSpecialKey(KeyType.tab);
        tester.sendSpecialKey(KeyType.right);
        expect(adjusted, 'scroll:1');
      },
    );

    test('can route adjustments while search keeps focus', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final directions = <int>[];

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: SettingsList<String>(
            adjustWhileSearching: true,
            items: const [
              SettingsListItem(id: 'scroll', label: 'Scroll speed'),
            ],
            onAdjust: (id, direction) {
              directions.add(direction);
              return const SettingsListResult.accepted();
            },
          ),
        ),
      );

      tester.sendSpecialKey(KeyType.right);
      expect(directions, [1]);
    });

    test(
      'preserves search-caret arrows by default until rows get focus',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        final directions = <int>[];

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: SettingsList<String>(
              items: const [
                SettingsListItem(id: 'scroll', label: 'Scroll speed'),
              ],
              onAdjust: (id, direction) {
                directions.add(direction);
                return const SettingsListResult.accepted();
              },
            ),
          ),
        );

        tester.sendSpecialKey(KeyType.right);
        expect(directions, isEmpty);
        tester.sendSpecialKey(KeyType.tab);
        tester.sendSpecialKey(KeyType.right);
        expect(directions, [1]);
      },
    );

    test(
      'obeys directional bounds and keeps accepted values host-owned',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        final directions = <int>[];

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: SettingsList<String>(
              items: const [
                SettingsListItem(
                  id: 'volume',
                  label: 'Volume',
                  value: '0%',
                  canDecrease: false,
                ),
              ],
              onAdjust: (id, direction) {
                directions.add(direction);
                return const SettingsListResult.accepted();
              },
            ),
          ),
        );

        tester.sendSpecialKey(KeyType.left);
        expect(directions, isEmpty);
        tester.sendSpecialKey(KeyType.tab);
        tester.sendSpecialKey(KeyType.left);
        expect(tester.find.text('0%'), isTrue);
        tester.sendSpecialKey(KeyType.right);
        await Future<void>.delayed(Duration.zero);
        tester.pump();
        expect(directions, [1]);
        expect(tester.find.text('0%'), isTrue);
      },
    );

    test('serializes async edits and reports host rejection', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final completion = Completer<SettingsListResult>();
      var calls = 0;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: SettingsList<String>(
            items: const [
              SettingsListItem(id: 'tabs', label: 'Tabs', value: 'auto'),
            ],
            onAdjust: (id, direction) {
              calls++;
              return completion.future;
            },
          ),
        ),
      );

      tester.sendSpecialKey(KeyType.tab);
      tester.sendSpecialKey(KeyType.right);
      tester.sendSpecialKey(KeyType.right);
      expect(calls, 1);
      expect(tester.find.text('Saving…'), isTrue);
      completion.complete(
        const SettingsListResult.rejected('Settings write was rejected.'),
      );
      await Future<void>.delayed(Duration.zero);
      tester.pump();
      expect(tester.find.text('Settings write was rejected.'), isTrue);
      expect(tester.find.text('auto'), isTrue);
    });

    test(
      'keeps the saving indicator on its row while selection moves',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        final completion = Completer<SettingsListResult>();

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: SettingsList<String>(
              items: const [
                SettingsListItem(
                  id: 'first',
                  label: 'First option',
                  value: 'old value',
                ),
                SettingsListItem(
                  id: 'second',
                  label: 'Second option',
                  value: 'accepted value',
                ),
              ],
              onAdjust: (id, direction) => completion.future,
            ),
          ),
        );

        tester.sendSpecialKey(KeyType.tab);
        tester.sendSpecialKey(KeyType.right);
        tester.sendSpecialKey(KeyType.down);
        tester.pump();

        final rendered = tester.view;
        final firstRow = rendered.indexOf('First option');
        final savingIndicator = rendered.indexOf('Saving…');
        final secondRow = rendered.indexOf('Second option');
        expect(firstRow, greaterThanOrEqualTo(0));
        expect(savingIndicator, greaterThan(firstRow));
        expect(savingIndicator, lessThan(secondRow));
        expect(rendered, contains('accepted value'));

        completion.complete(const SettingsListResult.accepted());
        await Future<void>.delayed(Duration.zero);
        tester.pump();
        expect(tester.view, isNot(contains('Saving…')));
      },
    );

    test(
      'action rows activate only with Enter and ignore adjustments',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        var activations = 0;
        final directions = <int>[];

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: SettingsList<String>(
              items: const [
                SettingsListItem(
                  id: 'theme',
                  label: 'Theme',
                  activation: SettingsListActivation.action,
                ),
              ],
              onActivate: (id) {
                activations++;
                return const SettingsListResult.accepted();
              },
              onAdjust: (id, direction) {
                directions.add(direction);
                return const SettingsListResult.accepted();
              },
            ),
          ),
        );

        tester.sendSpecialKey(KeyType.left);
        tester.sendSpecialKey(KeyType.enter);
        await Future<void>.delayed(Duration.zero);
        tester.pump();
        expect(activations, 1);
        expect(directions, isEmpty);
      },
    );
  });
}
