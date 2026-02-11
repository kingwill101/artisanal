part of 'layout_widgets.dart';

class Divider extends StatelessWidget {
  Divider({this.width = 40, this.char = '─', this.style, super.key});

  final int width;
  final String char;
  final Style? style;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ?? Style().foreground(ThemeScope.of(context).border);
    return Text(char * width, style: resolvedStyle);
  }
}
