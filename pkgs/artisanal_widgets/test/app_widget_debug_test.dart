/// Regression tests for AppWidget tab-switching via click.
///
/// These tests verify that clicking tab labels in the real example AppWidget
/// switches the displayed body content. They cover:
/// - Full tap lifecycle on the real AppWidget
/// - GestureDetector + Container with vertical padding
/// - GestureDetector + Container without vertical padding
/// - GestureDetector + Container with background color
///
/// The root cause was that [WidgetElement.update] did not call
/// [markNeedsBuild], so plain [Widget] subclasses (like [Frame]) whose
/// children changed across rebuilds never reconciled their element children,
/// leaving stale render objects in the tree.
library;

import 'package:artisanal/testing.dart';
import 'package:artisanal/style.dart' show BasicColor;
import 'package:artisanal/widgets.dart' as w;
import 'package:test/test.dart';

// Import the actual example app widget.
import '../example/main.dart' show AppWidget;

void main() {
  group('AppWidget tab click regression', () {
    test('clicking Theme tab shows theme content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      // Initial state: tab 0 (Layout) is selected.
      expect(
        tester.find.text('Row + Column'),
        isTrue,
        reason: 'Layout demo should be visible initially',
      );

      // Click the "Theme" tab label.
      tester.tap(tester.find.textLocation('Theme'));

      // _themeDemo() produces "Theme Colors" as its title.
      expect(
        tester.find.text('Theme Colors'),
        isTrue,
        reason: 'After clicking "Theme" tab, "Theme Colors" should be visible',
      );
      expect(
        tester.find.text('Row + Column'),
        isFalse,
        reason: 'After clicking "Theme" tab, Layout content should be gone',
      );
    });

    test('clicking Stack tab shows stack content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      tester.tap(tester.find.textLocation('Stack'));

      expect(
        tester.find.text('Stack + Positioned'),
        isTrue,
        reason: 'Stack demo should appear after clicking Stack tab',
      );
      expect(
        tester.find.text('Row + Column'),
        isFalse,
        reason: 'Layout content should be gone',
      );
    });

    test('clicking multiple tabs in sequence works', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      // Switch to Theme
      tester.tap(tester.find.textLocation('Theme'));
      expect(tester.find.text('Theme Colors'), isTrue);

      // Switch to Stack
      tester.tap(tester.find.textLocation('Stack'));
      expect(tester.find.text('Stack + Positioned'), isTrue);
      expect(tester.find.text('Theme Colors'), isFalse);

      // Switch back to Layout
      tester.tap(tester.find.textLocation('Layout'));
      expect(tester.find.text('Row + Column'), isTrue);
      expect(tester.find.text('Stack + Positioned'), isFalse);
    });

    test('tab state survives resize', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      tester.tap(tester.find.textLocation('Theme'));
      expect(tester.find.text('Theme Colors'), isTrue);

      tester.resize(100, 30);
      expect(
        tester.find.text('Theme Colors'),
        isTrue,
        reason: 'Tab selection should survive resize',
      );
    });

    test('root showcase theme controls switch the active preset', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      expect(tester.view, contains('Preset: Adaptive core'));

      tester.tap(tester.find.textLocation('Palette next'));

      expect(tester.view, contains('Preset: Dark core'));
    });

    test('components forms section shows text editors panel', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AppWidget(), width: 120, height: 40);

      tester.tap(tester.find.textLocation('Components'));
      expect(tester.find.text('Buttons + Badges'), isTrue);

      tester.tap(tester.find.textLocation('Forms'));

      expect(tester.find.text('Text Editors'), isTrue);
      expect(tester.find.text('Build the widget showcase'), isTrue);
      expect(tester.find.text('Refine hosted runners'), isTrue);
      expect(tester.view, contains('host_runner.dart'));
      expect(tester.view, contains('bootHostedApp'));
      expect(tester.view, contains('release_notes.md'));
      expect(tester.view, contains('Preview · markdown'));
      expect(tester.view, contains('3~'));
      expect(tester.view, contains('5!'));
      expect(tester.view, contains('7i'));
    });

    test(
      'components forms section routes shared diagnostics through embedded editors',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(AppWidget(), width: 120, height: 40);

        tester.tap(tester.find.textLocation('Components'));
        tester.tap(tester.find.textLocation('Forms'));

        final codeEditor = tester
            .elementsWhere((element) => element.widget is w.CodeEditor)
            .map((element) => element.widget as w.CodeEditor)
            .single;
        expect(codeEditor.controller, isNotNull);
        expect(codeEditor.controller!.diagnostics, isNotEmpty);

        codeEditor.controller!.selectDiagnosticAtLine(4);
        tester.pump();

        expect(tester.view, contains('error [showcase/FIX001]'));
        expect(tester.view, contains('Replace'));
        expect(tester.view, contains('real hosted'));
        expect(tester.view, contains('bootstrap flow.'));
      },
    );

    test(
      'overlays panel modal does not shift panel content vertically',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(AppWidget(), width: 120, height: 40);

        tester.tap(tester.find.textLocation('Components'));
        tester.tap(tester.find.textLocation('Overlays'));

        final before = tester.locateText('Drawer preview');
        expect(before, isNotNull);

        tester.tap(tester.find.textLocation('Open'));

        expect(tester.find.text('Modal Dialog'), isTrue);

        final after = tester.locateText('Drawer preview');
        expect(after, isNotNull);
        expect(after!.y, equals(before!.y));
      },
    );
  });

  group('GestureDetector + Container tab switching variants', () {
    test('Container with vertical padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_PaddedTabWidget(), width: 80, height: 20);

      expect(tester.find.text('Content: Tab 0'), isTrue);

      tester.tap(tester.find.textLocation('Tab 1'));

      expect(
        tester.find.text('Content: Tab 1'),
        isTrue,
        reason: 'Tab 1 content should appear after clicking Tab 1',
      );
    });

    test('Container without vertical padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_NoPaddingTabWidget(), width: 80, height: 20);

      expect(tester.find.text('Content: Tab 0'), isTrue);

      tester.tap(tester.find.textLocation('Tab 1'));

      expect(
        tester.find.text('Content: Tab 1'),
        isTrue,
        reason: 'Tab 1 content should appear after clicking Tab 1',
      );
    });

    test('Container with color and horizontal padding', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ColoredTabWidget(), width: 80, height: 20);

      expect(tester.find.text('Content: Tab 0'), isTrue);

      tester.tap(tester.find.textLocation('Tab 1'));

      expect(
        tester.find.text('Content: Tab 1'),
        isTrue,
        reason: 'Tab 1 content should appear after clicking Tab 1',
      );
    });
  });
}

// =============================================================================
// Minimal reproduction widgets
// =============================================================================

/// Tabs using GestureDetector > Container(horizontal+vertical padding) > Text.
/// Mirrors the real AppWidget's _tab() structure.
class _PaddedTabWidget extends w.StatefulWidget {
  @override
  w.State createState() => _PaddedTabWidgetState();
}

class _PaddedTabWidgetState extends w.State<_PaddedTabWidget> {
  int _selectedTab = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Row(
          gap: 2,
          children: [
            for (var i = 0; i < 3; i++)
              w.GestureDetector(
                key: w.ValueKey<int>(i),
                onTap: () {
                  setState(() => _selectedTab = i);
                  return null;
                },
                child: w.Container(
                  padding: const w.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 0.5,
                  ),
                  color: const BasicColor('#333333'),
                  child: w.Text('Tab $i'),
                ),
              ),
          ],
        ),
        w.Text('Content: Tab $_selectedTab'),
      ],
    );
  }
}

/// Same but WITHOUT vertical padding — control case.
class _NoPaddingTabWidget extends w.StatefulWidget {
  @override
  w.State createState() => _NoPaddingTabWidgetState();
}

class _NoPaddingTabWidgetState extends w.State<_NoPaddingTabWidget> {
  int _selectedTab = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Row(
          gap: 2,
          children: [
            for (var i = 0; i < 3; i++)
              w.GestureDetector(
                key: w.ValueKey<int>(i),
                onTap: () {
                  setState(() => _selectedTab = i);
                  return null;
                },
                child: w.Container(
                  padding: const w.EdgeInsets.symmetric(horizontal: 2),
                  child: w.Text('Tab $i'),
                ),
              ),
          ],
        ),
        w.Text('Content: Tab $_selectedTab'),
      ],
    );
  }
}

/// Container with color but no vertical padding.
class _ColoredTabWidget extends w.StatefulWidget {
  @override
  w.State createState() => _ColoredTabWidgetState();
}

class _ColoredTabWidgetState extends w.State<_ColoredTabWidget> {
  int _selectedTab = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.Row(
          gap: 2,
          children: [
            for (var i = 0; i < 3; i++)
              w.GestureDetector(
                key: w.ValueKey<int>(i),
                onTap: () {
                  setState(() => _selectedTab = i);
                  return null;
                },
                child: w.Container(
                  padding: const w.EdgeInsets.symmetric(horizontal: 2),
                  color: const BasicColor('#333333'),
                  child: w.Text('Tab $i'),
                ),
              ),
          ],
        ),
        w.Text('Content: Tab $_selectedTab'),
      ],
    );
  }
}
