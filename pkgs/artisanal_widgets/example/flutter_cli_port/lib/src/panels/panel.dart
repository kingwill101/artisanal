import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../theme.dart';

class FlutterCliPanel extends w.StatelessWidget {
  FlutterCliPanel({
    required this.title,
    required this.flTheme,
    required this.child,
    super.key,
  });

  final String title;
  final FlutterCliTheme flTheme;
  final w.Widget child;

  @override
  w.Widget build(w.BuildContext context) {
    return w.PanelBox(
      title: title,
      padding: const w.EdgeInsets.all(1),
      background: flTheme.bg,
      foreground: flTheme.fg,
      border: style.Border.normal,
      borderColor: flTheme.dim,
      titleStyle: flTheme.bold(flTheme.accent),
      bodyStyle: flTheme.base,
      child: child,
    );
  }
}
