part of 'components_widgets.dart';

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
