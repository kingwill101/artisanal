import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A simple titled block used by the artisanal-style I/O facade.
///
/// Renders a styled title line, then indented message lines:
///
/// ```text
///   TITLE
///   line 1
///   line 2
/// ```
class TitledBlockComponent extends DisplayComponent {
  const TitledBlockComponent({
    required this.title,
    required this.message,
    required this.titleStyle,
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  });

  TitledBlockComponent.info({
    required this.title,
    required this.message,
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  }) : titleStyle = Style().foreground(Colors.info);

  TitledBlockComponent.success({
    required this.title,
    required this.message,
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  }) : titleStyle = Style().foreground(Colors.success);

  TitledBlockComponent.warning({
    required this.title,
    required this.message,
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  }) : titleStyle = Style().foreground(Colors.warning);

  TitledBlockComponent.error({
    required this.title,
    required this.message,
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  }) : titleStyle = Style().foreground(Colors.error);

  final String title;
  final Object message;
  final Style titleStyle;
  final int indent;
  final RenderConfig renderConfig;

  @override
  String render() {
    final titleStyle = renderConfig.configureStyle(this.titleStyle);
    final lines = _normalizeLines(message);
    final prefix = ' ' * indent;

    final buffer = StringBuffer();
    buffer.writeln(titleStyle.render('$prefix$title'));
    for (final line in lines) {
      buffer.writeln('$prefix$line');
    }
    return buffer.toString().trimRight();
  }

  List<String> _normalizeLines(Object message) {
    if (message is Iterable) {
      return message.map((e) => e.toString()).toList();
    }
    return message.toString().split('\n');
  }
}
