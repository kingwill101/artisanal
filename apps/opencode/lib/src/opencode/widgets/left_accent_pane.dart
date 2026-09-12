library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../theme.dart';

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
    final resolvedAccent = dimmed ? OC.borderSubtle : accentColor;

    return w.Frame(
      border: style.Border.split.copyWith(right: ''),
      borderColor: resolvedAccent,
      background: backgroundColor,
      padding: padding ?? w.EdgeInsets.zero,
      child: child,
    );
  }
}
