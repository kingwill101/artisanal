import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  test('ReplayEventHistoryPanel renders empty state', () async {
    final tester = WidgetTester(screenWidth: 70, screenHeight: 16);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(events: const []),
      ),
    );

    expect(tester.view, contains('Replay History'));
    expect(tester.view, contains('No replay events yet.'));
  });

  test('ReplayEventHistoryPanel renders recent event summaries', () async {
    final tester = WidgetTester(screenWidth: 70, screenHeight: 20);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(
          maxItems: 2,
          events: const [
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'replay event -> ui.sidebar.toggle',
              statusHint: '/replay ui.sidebar.toggle',
              fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
            ),
            ReplayEventPresentation(
              summary: 'render capture g3 120x40 cells 2 spans 1',
              statusHint: '/replay g3 120x40 c2 s1',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('Replay History'));
    expect(tester.view, contains('render capture g2 100x32 cells 4 spans 2'));
    expect(tester.view, contains('/replay g2 100x32 c4 s2'));
    expect(tester.view, contains('replay event -> ui.sidebar.toggle'));
    expect(tester.view, contains('/replay ui.sidebar.toggle'));
    expect(
      tester.view,
      isNot(contains('render capture g3 120x40 cells 2 spans 1')),
    );
  });

  test('ReplayEventHistoryPanel can filter to render-capture events', () async {
    final tester = WidgetTester(screenWidth: 70, screenHeight: 20);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(
          filter: ReplayEventHistoryFilter.renderCaptures,
          events: const [
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'replay event -> ui.sidebar.toggle',
              statusHint: '/replay ui.sidebar.toggle',
              fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('filter: render captures'));
    expect(tester.view, contains('render capture g2 100x32 cells 4 spans 2'));
    expect(tester.view, isNot(contains('replay event -> ui.sidebar.toggle')));
  });

  test('ReplayEventHistoryPanel shows empty filtered state', () async {
    final tester = WidgetTester(screenWidth: 70, screenHeight: 16);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(
          filter: ReplayEventHistoryFilter.renderCaptures,
          events: const [
            ReplayEventPresentation(
              summary: 'replay event -> ui.sidebar.toggle',
              statusHint: '/replay ui.sidebar.toggle',
              fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('filter: render captures'));
    expect(tester.view, contains('No matching replay events.'));
  });

  test('ReplayEventHistoryPanel can group repeated event summaries', () async {
    final tester = WidgetTester(screenWidth: 70, screenHeight: 20);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(
          mode: ReplayEventHistoryMode.grouped,
          events: const [
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'replay event -> ui.sidebar.toggle',
              statusHint: '/replay ui.sidebar.toggle',
              fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('mode: grouped'));
    expect(
      tester.view,
      contains('2x render capture g2 100x32 cells 4 spans 2'),
    );
    expect(tester.view, contains('/replay g2 100x32 c4 s2'));
    expect(tester.view, contains('1x replay event -> ui.sidebar.toggle'));
    expect(tester.view, contains('/replay ui.sidebar.toggle'));
  });

  test('ReplayEventHistoryPanel can show event-type chips', () async {
    final tester = WidgetTester(screenWidth: 80, screenHeight: 20);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(
          showTypeChips: true,
          events: const [
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'render capture g3 120x40 cells 2 spans 1',
              statusHint: '/replay g3 120x40 c2 s1',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'replay event -> ui.sidebar.toggle',
              statusHint: '/replay ui.sidebar.toggle',
              fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('render 2'));
    expect(tester.view, contains('ui.sidebar.toggle 1'));
  });

  test(
    'ReplayEventHistoryPanel type chips become grouped-row-aware in grouped mode',
    () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ReplayEventHistoryPanel(
            mode: ReplayEventHistoryMode.grouped,
            showTypeChips: true,
            events: const [
              ReplayEventPresentation(
                summary: 'render capture g2 100x32 cells 4 spans 2',
                statusHint: '/replay g2 100x32 c4 s2',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
              ReplayEventPresentation(
                summary: 'render capture g2 100x32 cells 4 spans 2',
                statusHint: '/replay g2 100x32 c4 s2',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
              ReplayEventPresentation(
                summary: 'render capture g3 120x40 cells 2 spans 1',
                statusHint: '/replay g3 120x40 c2 s1',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
              ReplayEventPresentation(
                summary: 'replay event -> ui.sidebar.toggle',
                statusHint: '/replay ui.sidebar.toggle',
                fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
              ),
              ReplayEventPresentation(
                summary: 'replay event -> ui.sidebar.toggle',
                statusHint: '/replay ui.sidebar.toggle',
                fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
              ),
            ],
          ),
        ),
      );

      expect(tester.view, contains('render 2'));
      expect(tester.view, contains('ui.sidebar.toggle 1'));
      expect(tester.view, isNot(contains('render 3')));
      expect(tester.view, isNot(contains('ui.sidebar.toggle 2')));
    },
  );

  test('ReplayEventHistoryPanel can expose interactive filter chips', () async {
    final tester = WidgetTester(screenWidth: 90, screenHeight: 20);
    addTearDown(() => tester.dispose());
    ReplayEventHistoryFilter? selectedFilter;

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(
          showFilterChips: true,
          onFilterSelected: (value) {
            selectedFilter = value;
            return null;
          },
          events: const [
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'replay event -> ui.sidebar.toggle',
              statusHint: '/replay ui.sidebar.toggle',
              fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('all'));
    expect(tester.view, contains('render'));
    expect(tester.view, contains('captures'));
    expect(tester.view, contains('custom'));
    expect(tester.view, contains('events'));

    tester.tap(
      tester.find.byKeyLocation(ValueKey('replay-history-filter-custom')),
    );
    expect(selectedFilter, ReplayEventHistoryFilter.custom);
  });

  test('ReplayEventHistoryBrowser forwards state changes', () async {
    final tester = WidgetTester(screenWidth: 90, screenHeight: 24);
    addTearDown(() => tester.dispose());
    ReplayEventHistoryState? nextState;

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryBrowser(
          events: const [
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'replay event -> ui.sidebar.toggle',
              statusHint: '/replay ui.sidebar.toggle',
              fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
            ),
            ReplayEventPresentation(
              summary: 'render capture g3 120x40 cells 2 spans 1',
              statusHint: '/replay g3 120x40 c2 s1',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
          ],
          state: const ReplayEventHistoryState(
            filter: ReplayEventHistoryFilter.all,
            mode: ReplayEventHistoryMode.grouped,
          ),
          maxItems: 1,
          showExpandToggle: true,
          onStateChanged: (state) {
            nextState = state;
            return null;
          },
        ),
      ),
    );

    tester.tap(
      tester.find.byKeyLocation(ValueKey('replay-history-expand-toggle')),
    );
    expect(nextState?.expanded, isTrue);
    expect(nextState?.mode, ReplayEventHistoryMode.grouped);
    expect(nextState?.filter, ReplayEventHistoryFilter.all);
  });

  test(
    'ReplayEventHistoryBrowser render-capture preset hides filter chips',
    () async {
      final tester = WidgetTester(screenWidth: 90, screenHeight: 20);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ReplayEventHistoryBrowser.renderCaptures(
            events: const [
              ReplayEventPresentation(
                summary: 'render capture g2 100x32 cells 4 spans 2',
                statusHint: '/replay g2 100x32 c4 s2',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
              ReplayEventPresentation(
                summary: 'render capture g2 100x32 cells 4 spans 2',
                statusHint: '/replay g2 100x32 c4 s2',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
              ReplayEventPresentation(
                summary: 'render capture g3 120x40 cells 2 spans 1',
                statusHint: '/replay g3 120x40 c2 s1',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
              ReplayEventPresentation(
                summary: 'render capture g4 120x40 cells 1 spans 1',
                statusHint: '/replay g4 120x40 c1 s1',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
            ],
            state: const ReplayEventHistoryState(
              filter: ReplayEventHistoryFilter.renderCaptures,
              mode: ReplayEventHistoryMode.grouped,
            ),
            onStateChanged: (_) => null,
          ),
        ),
      );

      expect(tester.view, contains('Replay History'));
      expect(tester.view, contains('mode: grouped'));
      expect(tester.view, contains('render 3'));
      expect(tester.view, contains('show'));
      expect(tester.view, contains('all'));
      expect(tester.view, contains('groups'));
      expect(tester.view, isNot(contains('filter: render captures')));
      expect(tester.view, isNot(contains('custom')));
    },
  );

  test('ReplayEventHistoryPanel can render mode chips', () async {
    final tester = WidgetTester(screenWidth: 90, screenHeight: 20);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(
          mode: ReplayEventHistoryMode.grouped,
          showModeChips: true,
          onModeSelected: (_) => null,
          events: const [
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('flat'));
    expect(tester.view, contains('grouped'));
  });

  test('ReplayEventHistoryPanel can expose expand toggle', () async {
    final tester = WidgetTester(screenWidth: 90, screenHeight: 24);
    addTearDown(() => tester.dispose());
    bool? expandedValue;

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: ReplayEventHistoryPanel(
          maxItems: 2,
          showExpandToggle: true,
          onExpandedChanged: (value) {
            expandedValue = value;
            return null;
          },
          events: const [
            ReplayEventPresentation(
              summary: 'render capture g2 100x32 cells 4 spans 2',
              statusHint: '/replay g2 100x32 c4 s2',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
            ReplayEventPresentation(
              summary: 'replay event -> ui.sidebar.toggle',
              statusHint: '/replay ui.sidebar.toggle',
              fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
            ),
            ReplayEventPresentation(
              summary: 'render capture g3 120x40 cells 2 spans 1',
              statusHint: '/replay g3 120x40 c2 s1',
              fields: <String, Object?>{'type': 'runtime.render_capture'},
            ),
          ],
        ),
      ),
    );

    expect(tester.view, contains('show all 3'));
    expect(tester.view, contains('1 hidden'));
    expect(
      tester.view,
      isNot(contains('render capture g3 120x40 cells 2 spans 1')),
    );

    tester.tap(
      tester.find.byKeyLocation(ValueKey('replay-history-expand-toggle')),
    );
    expect(expandedValue, isTrue);
  });

  test(
    'ReplayEventHistoryPanel reports hidden grouped rows in grouped mode',
    () async {
      final tester = WidgetTester(screenWidth: 90, screenHeight: 24);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: ReplayEventHistoryPanel(
            maxItems: 2,
            mode: ReplayEventHistoryMode.grouped,
            showExpandToggle: true,
            onExpandedChanged: (_) => null,
            events: const [
              ReplayEventPresentation(
                summary: 'render capture g2 100x32 cells 4 spans 2',
                statusHint: '/replay g2 100x32 c4 s2',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
              ReplayEventPresentation(
                summary: 'render capture g2 100x32 cells 4 spans 2',
                statusHint: '/replay g2 100x32 c4 s2',
                fields: <String, Object?>{'type': 'runtime.render_capture'},
              ),
              ReplayEventPresentation(
                summary: 'replay event -> ui.sidebar.toggle',
                statusHint: '/replay ui.sidebar.toggle',
                fields: <String, Object?>{'type': 'ui.sidebar.toggle'},
              ),
              ReplayEventPresentation(
                summary: 'replay event -> ui.panel.resize',
                statusHint: '/replay ui.panel.resize',
                fields: <String, Object?>{'type': 'ui.panel.resize'},
              ),
            ],
          ),
        ),
      );

      expect(tester.view, contains('show all 3 groups'));
      expect(tester.view, contains('2 groups hidden'));
      expect(
        tester.view,
        contains('2x render capture g2 100x32 cells 4 spans 2'),
      );
      expect(tester.view, isNot(contains('ui.sidebar.toggle')));
    },
  );
}
