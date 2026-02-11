library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

class LeftAccentPane extends w.StatelessWidget {
  LeftAccentPane({
    required this.accentColor,
    required this.child,
    this.backgroundColor,
    this.padding,
    super.key,
  });

  final style.Color accentColor;
  final style.Color? backgroundColor;
  final w.EdgeInsets? padding;
  final w.Widget child;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Row(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Container(color: accentColor, width: 1),
        w.Expanded(
          child: w.Container(
            color: backgroundColor,
            padding: padding,
            child: child,
          ),
        ),
      ],
    );
  }
}
