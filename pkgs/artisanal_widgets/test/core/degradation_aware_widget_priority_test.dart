import 'package:artisanal/tui.dart'
    show DegradationLevel, RenderBudgetMsg, RenderBudgetState;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  group('Widget degradation policies', () {
    test('Widget.shouldRenderAt follows priority rules by level', () {
      final essential = w.Budgeted(
        priority: w.WidgetDegradationPriority.essential,
        child: w.Text('essential'),
      );
      final standard = w.Budgeted(
        priority: w.WidgetDegradationPriority.standard,
        child: w.Text('standard'),
      );
      final low = w.Budgeted(
        priority: w.WidgetDegradationPriority.low,
        child: w.Text('low'),
      );
      final decorative = w.Budgeted(
        priority: w.WidgetDegradationPriority.decorative,
        child: w.Text('decorative'),
      );
      final staleStandard = w.Budgeted(
        priority: w.WidgetDegradationPriority.standard,
        stale: true,
        child: w.Text('stale-standard'),
      );

      expect(
        essential.shouldRenderAt(
          DegradationLevel.skeleton,
          subtreeHasFocusedWidget: false,
        ),
        isTrue,
      );
      expect(
        standard.shouldRenderAt(
          DegradationLevel.noStyling,
          subtreeHasFocusedWidget: false,
        ),
        isTrue,
      );
      expect(
        standard.shouldRenderAt(
          DegradationLevel.essentialOnly,
          subtreeHasFocusedWidget: false,
        ),
        isFalse,
      );
      expect(
        low.shouldRenderAt(
          DegradationLevel.noStyling,
          subtreeHasFocusedWidget: false,
        ),
        isFalse,
      );
      expect(
        decorative.shouldRenderAt(
          DegradationLevel.full,
          subtreeHasFocusedWidget: false,
        ),
        isTrue,
      );
      expect(
        staleStandard.shouldRenderAt(
          DegradationLevel.noStyling,
          subtreeHasFocusedWidget: false,
        ),
        isFalse,
      );
      expect(
        staleStandard.shouldRenderAt(
          DegradationLevel.simpleBorders,
          subtreeHasFocusedWidget: false,
        ),
        isTrue,
      );
    });

    test(
      'focus boosts visibility while standard-priority subtree is focused',
      () {
        final focused = _FocusableText('focused');
        final tree = w.ElementTree(
          w.Budgeted(
            priority: w.WidgetDegradationPriority.standard,
            focusBoost: true,
            child: focused,
          ),
        );
        addTearDown(tree.unmount);

        expect(
          tree.root.render(degradationLevel: DegradationLevel.skeleton),
          equals(''),
        );

        focused.onFocus();
        expect(
          tree.root.render(degradationLevel: DegradationLevel.essentialOnly),
          contains('focused'),
        );
        expect(
          tree.root.render(degradationLevel: DegradationLevel.skeleton),
          equals(''),
        );
      },
    );
  });

  group('WidgetApp budget-aware rendering', () {
    test('RenderBudgetMsg updates tree degradation level without restart', () {
      final app = w.WidgetApp(
        w.Column(
          children: [
            w.Budgeted(
              priority: w.WidgetDegradationPriority.decorative,
              child: w.Text('decorative'),
            ),
            w.Budgeted(
              priority: w.WidgetDegradationPriority.standard,
              child: w.Text('standard'),
            ),
            w.Budgeted(
              priority: w.WidgetDegradationPriority.low,
              child: w.Text('low'),
            ),
            w.Budgeted(
              priority: w.WidgetDegradationPriority.essential,
              child: w.Text('essential'),
            ),
            w.Budgeted(
              priority: w.WidgetDegradationPriority.standard,
              stale: true,
              child: w.Text('stale-standard'),
            ),
          ],
        ),
      );

      String renderAt(DegradationLevel level) {
        app.update(RenderBudgetMsg(_budgetState(level)));
        final view = app.view();
        expect(
          view,
          isA<String>(),
          reason: 'WidgetApp without background uses String view',
        );
        return view as String;
      }

      expect(
        renderAt(DegradationLevel.full),
        allOf(
          contains('decorative'),
          contains('standard'),
          contains('low'),
          contains('essential'),
          contains('stale-standard'),
        ),
      );

      expect(
        renderAt(DegradationLevel.noStyling),
        allOf(
          isNot(contains('decorative')),
          contains('standard'),
          isNot(contains('low')),
          contains('essential'),
          isNot(contains('stale-standard')),
        ),
      );

      expect(
        renderAt(DegradationLevel.essentialOnly),
        allOf(
          isNot(contains('decorative')),
          isNot(contains('standard')),
          isNot(contains('low')),
          contains('essential'),
          isNot(contains('stale-standard')),
        ),
      );
    });
  });
}

class _FocusableText extends w.StatelessWidget with w.FocusableWidget {
  _FocusableText(this.text);

  final String text;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(text);
  }
}

RenderBudgetState _budgetState(DegradationLevel level) {
  return RenderBudgetState(
    level: level,
    frameBudget: const Duration(milliseconds: 16),
    lastRenderDuration: Duration.zero,
    overBudgetStreak: 0,
    recoveryStreak: 0,
  );
}
