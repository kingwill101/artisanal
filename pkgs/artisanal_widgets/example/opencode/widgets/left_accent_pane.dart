library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

class LeftAccentPane extends w.StatelessWidget {
  LeftAccentPane({
    required this.accentColor,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.dimmed = false,
    super.key,
  });

  final style.Color accentColor;
  final style.Color? backgroundColor;
  final w.EdgeInsets? padding;
  final w.Widget child;
  final bool dimmed;

  @override
  w.Widget build(w.BuildContext context) {
    final resolvedAccent = dimmed ? style.BasicColor('#808080') : accentColor;
    return w.Row(
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Container(color: resolvedAccent, width: 1),
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
