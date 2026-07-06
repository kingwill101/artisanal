
import 'package:artisanal/widgets.dart';

import 'package:artisanal/style.dart' show Color, Border, Style, Colors;


class Toast extends StatelessWidget {
  Toast({
    this.title,
    this.message,
    this.child,
    this.variant = AlertVariant.info,
    this.actions = const [],
    this.padding,
    this.margin,
    super.key,
  });

  final String? title;
  final String? message;
  final Widget? child;
  final AlertVariant variant;
  final List<Widget> actions;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return AlertBox(
      title: title,
      message: message,
      child: child,
      variant: variant,
      actions: actions,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      margin: margin,
      border: Border.rounded,
    );
  }
}
