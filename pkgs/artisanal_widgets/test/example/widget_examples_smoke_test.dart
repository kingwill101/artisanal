import 'package:artisanal/style.dart' show Layout;
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:test/test.dart';

import '../../example/builder/main.dart' as builder;
import '../../example/buttons/main.dart' as buttons;
import '../../example/card_panel_frame/main.dart' as cards;
import '../../example/chip/main.dart' as chip;
import '../../example/choice_chip/main.dart' as choice;
import '../../example/clip_rect/main.dart' as clip;
import '../../example/colored_box/main.dart' as colored;
import '../../example/data_table/main.dart' as table;
import '../../example/dataviz/main.dart' as dataviz;
import '../../example/decorated_box/main.dart' as decorated;
import '../../example/decoration/main.dart' as decoration;
import '../../example/dropdown_button/main.dart' as dropdown;
import '../../example/flex_layout/main.dart' as flex;
import '../../example/focus/main.dart' as focus;
import '../../example/gesture/main.dart' as gesture;
import '../../example/history_panel/main.dart' as history;
import '../../example/hyperlink_text/main.dart' as hyperlink;
import '../../example/inputs/main.dart' as inputs;
import '../../example/list_accordion/main.dart' as accordion;
import '../../example/metric_display/main.dart' as metrics;
import '../../example/navigator/main.dart' as navigator;
import '../../example/progress_styles/main.dart' as progress;
import '../../example/range_slider/main.dart' as range;
import '../../example/rich_text/main.dart' as rich;
import '../../example/row_column/main.dart' as row_column;
import '../../example/scroll/main.dart' as scroll;
import '../../example/scroll_area/main.dart' as scroll_area;
import '../../example/scrollbar/main.dart' as scrollbar;
import '../../example/slider/main.dart' as slider;
import '../../example/splitview_sidebar/main.dart' as split;
import '../../example/stack/main.dart' as stack;
import '../../example/status_line/main.dart' as status;
import '../../example/step_indicator/main.dart' as steps;
import '../../example/tabs_nav/main.dart' as tabs;
import '../../example/text/main.dart' as text;
import '../../example/theme/main.dart' as theme;
import '../../example/tint/main.dart' as tint;
import '../../example/transform/main.dart' as transform;
import '../../example/tree_view/main.dart' as tree;
import '../../example/vertical_divider/main.dart' as vertical;
import '../../example/wrap_divider/main.dart' as wrap;

// Exercise real widget roots without starting their interactive main() entry
// points. These checks cover startup, safe navigation keys, and resizing;
// feature-specific example tests cover deeper interactions.
final _examples = <({String name, w.Widget Function() create})>[
  (name: 'builder', create: builder.BuilderExample.new),
  (name: 'buttons', create: buttons.ButtonShowcase.new),
  (name: 'card_panel_frame', create: cards.CardPanelShowcase.new),
  (name: 'chip', create: chip.ChipShowcase.new),
  (name: 'choice_chip', create: choice.ChoiceChipShowcase.new),
  (name: 'clip_rect', create: clip.ClipRectExample.new),
  (name: 'colored_box', create: colored.ColoredBoxExample.new),
  (name: 'data_table', create: table.DataTableShowcase.new),
  (name: 'dataviz', create: dataviz.DataVizDemo.new),
  (name: 'decorated_box', create: decorated.DecoratedBoxExample.new),
  (name: 'decoration', create: decoration.DecorationShowcase.new),
  (name: 'dropdown_button', create: dropdown.DropdownButtonShowcase.new),
  (name: 'flex_layout', create: flex.FlexShowcase.new),
  (name: 'focus', create: focus.FocusDemo.new),
  (name: 'gesture', create: gesture.GestureShowcase.new),
  (name: 'history_panel', create: history.HistoryPanelShowcase.new),
  (name: 'hyperlink_text', create: hyperlink.HyperlinkTextShowcase.new),
  (name: 'inputs', create: inputs.InputShowcase.new),
  (name: 'list_accordion', create: accordion.ListAccordionShowcase.new),
  (name: 'metric_display', create: metrics.MetricDisplayShowcase.new),
  (name: 'navigator', create: navigator.NavigatorDemo.new),
  (name: 'progress_styles', create: progress.ProgressStylesExample.new),
  (name: 'range_slider', create: range.RangeSliderShowcase.new),
  (name: 'rich_text', create: rich.RichTextDemo.new),
  (name: 'row_column', create: row_column.RowColumnShowcase.new),
  (name: 'scroll', create: scroll.ScrollDemo.new),
  (name: 'scroll_area', create: scroll_area.ScrollAreaShowcase.new),
  (name: 'scrollbar', create: scrollbar.ScrollbarDemo.new),
  (name: 'slider', create: slider.SliderShowcase.new),
  (name: 'splitview_sidebar', create: split.SplitViewShowcase.new),
  (name: 'stack', create: stack.StackShowcase.new),
  (name: 'status_line', create: status.StatusLineShowcase.new),
  (name: 'step_indicator', create: steps.StepIndicatorShowcase.new),
  (name: 'tabs_nav', create: tabs.TabsNavShowcase.new),
  (name: 'text', create: text.TextShowcase.new),
  (name: 'theme', create: theme.ThemeShowcase.new),
  (name: 'tint', create: tint.TintDemo.new),
  (name: 'transform', create: transform.TransformDemo.new),
  (name: 'tree_view', create: tree.TreeViewShowcase.new),
  (name: 'vertical_divider', create: vertical.VerticalDividerExample.new),
  (name: 'wrap_divider', create: wrap.WrapDividerShowcase.new),
];

void _expectHealthy(WidgetTester tester, String context) {
  final view = Layout.stripAnsi(tester.view);
  expect(view.trim(), isNotEmpty, reason: context);
  expect(view, isNot(contains('Build failed in ')), reason: context);
  expect(view, isNot(contains('Unhandled exception')), reason: context);
  expect(tester.find.byType<w.TUIErrorWidget>(), isEmpty, reason: context);
}

void main() {
  test(
    'split-view showcase bounds its vertical panes and scrolls to the end',
    () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      await tester.pumpWidget(split.SplitViewShowcase());
      final vertical = tester.find
          .byType<w.SplitView>()
          .singleWhere(
            (element) =>
                (element.widget as w.SplitView).axis == w.Axis.vertical,
          )
          .children
          .single
          .renderObject!;
      expect(vertical.size.height, 5);
      expect(vertical.children.map((child) => child.size.height), [2, 1, 2]);
      expect(vertical.children.map((child) => child.offset.dy), [0, 2, 3]);
      tester.sendSpecialKey(KeyType.end);
      _expectHealthy(tester, 'splitview_sidebar: scroll to end');
      expect(tester.find.text('Sidebar (right)'), isTrue);
    },
  );

  for (final example in _examples) {
    for (final size in [
      (width: 80, height: 24),
      (width: 40, height: 12),
      (width: 120, height: 40),
    ]) {
      test(
        '${example.name} renders and resizes from ${size.width}x${size.height}',
        () async {
          final tester = WidgetTester(
            screenWidth: size.width,
            screenHeight: size.height,
          );
          addTearDown(tester.dispose);
          await tester.pumpWidget(example.create());
          _expectHealthy(tester, '${example.name}: initial $size');
          tester.sendSpecialKey(KeyType.tab);
          tester.sendSpecialKey(KeyType.down);
          _expectHealthy(tester, '${example.name}: keyboard $size');
          tester.resize(48, 16);
          _expectHealthy(tester, '${example.name}: resized to 48x16');
          tester.resize(size.width, size.height);
          _expectHealthy(tester, '${example.name}: restored $size');
        },
      );
    }
  }
}
