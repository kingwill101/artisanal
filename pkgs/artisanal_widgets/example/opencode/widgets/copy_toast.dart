library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../theme.dart';

class CopyToast extends w.StatelessWidget {
  CopyToast({required this.message, super.key});

  final String message;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Container(
      color: OC.backgroundElement,
      padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: w.Row(
        children: [
          w.Text('│', style: style.Style()..foreground(OC.accent)),
          w.SizedBox(width: 2),
          w.Text(message, style: style.Style()..foreground(OC.text)),
          w.SizedBox(width: 2),
          w.Text('│', style: style.Style()..foreground(OC.accent)),
        ],
      ),
    );
  }
}
