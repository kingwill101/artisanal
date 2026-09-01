import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout/_layout_core.dart';

/// A two-pane view that arranges children along an axis.
///
/// The [SplitView] widget displays [first] and [second] children with optional
/// [separator] and [gap]. Use [firstFlex] and [secondFlex] to control the
/// relative sizes of the panes.
///
/// By default, axes are horizontal (side-by-side). Set [axis] to
/// [Axis.vertical] for top-to-bottom arrangement.
///
/// Example:
/// ```dart
/// SplitView(
///   first: ListView(children: [Text('Pane 1')]),
///   second: EditorArea(),
///   gap: 1,
///   separator: VerticalDivider(),
/// )
/// ```
class SplitView extends StatelessWidget {
  SplitView({
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.firstFlex = 1,
    this.secondFlex = 1,
    this.gap = 1,
    this.separator,
    super.key,
  });

  final Widget first;
  final Widget second;
  final Axis axis;
  final int firstFlex;
  final int secondFlex;
  final int gap;
  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    final sep = separator ?? _defaultSeparator();
    if (axis == Axis.horizontal) {
      return Row(
        gap: 0,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: firstFlex, child: first),
          if (gap > 0 || separator != null) sep,
          Expanded(flex: secondFlex, child: second),
        ],
      );
    }

    return Column(
      gap: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: firstFlex, child: first),
        if (gap > 0 || separator != null) sep,
        Expanded(flex: secondFlex, child: second),
      ],
    );
  }

  Widget _defaultSeparator() {
    return axis == Axis.horizontal
        ? SizedBox(width: gap)
        : SizedBox(height: gap);
  }
}
