import '../core/widget.dart';
import '../framework.dart';
import '../theme/theme_scope.dart' show ThemeScope;
import '../style.dart';
import 'text.dart';

class Divider extends StatelessWidget {
  Divider({this.width = 40, this.char = '─', this.style, super.key});

  final int width;
  final String char;
  final Style? style;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ?? Style().foreground(ThemeScope.of(context).border);
    // A divider is preformatted structure, not prose. When its requested
    // width exceeds the available columns it should clip to one row rather
    // than wrap into a stack of divider lines.
    return Text(char * width, style: resolvedStyle, softWrap: false);
  }
}
