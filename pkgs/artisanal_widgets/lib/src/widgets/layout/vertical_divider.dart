import 'package:artisanal/style.dart' show Style;
import '../core/widget.dart';
import '../framework.dart';
import '../theme/theme_scope.dart' show ThemeScope;
import 'text.dart';


/// A vertical line divider.
///
/// Renders a vertical line using the specified character, repeated for
/// the given [height]. Useful as a separator between horizontally
/// arranged elements.
///
/// ```dart
/// Row(
///   children: [
///     Text('Left'),
///     VerticalDivider(height: 5),
///     Text('Right'),
///   ],
/// )
/// ```
class VerticalDivider extends StatelessWidget {
  VerticalDivider({this.height = 3, this.char = '│', this.style, super.key});

  /// Height in rows.
  final int height;

  /// Character used for the divider line.
  final String char;

  /// Optional style override. Defaults to theme border color.
  final Style? style;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ?? Style().foreground(ThemeScope.of(context).border);
    final line = List.generate(height, (_) => char).join('\n');
    return Text(line, style: resolvedStyle);
  }
}
