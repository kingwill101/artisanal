import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A simple text component.
class Text extends DisplayComponent {
  const Text(this.text, {this.style});

  final String text;
  final String Function(String)? style;

  @override
  String render() => style != null ? style!(text) : text;
}

/// A styled text component using the context's style.
class StyledText extends DisplayComponent {
  const StyledText.info(this.text, {this.renderConfig = const RenderConfig()})
    : _type = _StyleType.info;
  const StyledText.success(
    this.text, {
    this.renderConfig = const RenderConfig(),
  }) : _type = _StyleType.success;
  const StyledText.warning(
    this.text, {
    this.renderConfig = const RenderConfig(),
  }) : _type = _StyleType.warning;
  const StyledText.error(this.text, {this.renderConfig = const RenderConfig()})
    : _type = _StyleType.error;
  const StyledText.muted(this.text, {this.renderConfig = const RenderConfig()})
    : _type = _StyleType.muted;
  const StyledText.emphasize(
    this.text, {
    this.renderConfig = const RenderConfig(),
  }) : _type = _StyleType.emphasize;
  const StyledText.heading(
    this.text, {
    this.renderConfig = const RenderConfig(),
  }) : _type = _StyleType.heading;

  final String text;
  final _StyleType _type;
  final RenderConfig renderConfig;

  @override
  String render() {
    final style = renderConfig.configureStyle(Style());
    final output = switch (_type) {
      _StyleType.info => style.foreground(Colors.info).render(text),
      _StyleType.success => style.foreground(Colors.success).render(text),
      _StyleType.warning =>
        style.foreground(Colors.warning).bold().render(text),
      _StyleType.error => style.foreground(Colors.error).render(text),
      _StyleType.muted => style.dim().render(text),
      _StyleType.emphasize =>
        style.foreground(Colors.warning).bold().render(text),
      _StyleType.heading => style.bold().render(text),
    };
    return output;
  }
}

enum _StyleType { info, success, warning, error, muted, emphasize, heading }

/// A horizontal rule/separator component.
class Rule extends DisplayComponent {
  const Rule({
    this.text,
    this.char = '─',
    this.renderConfig = const RenderConfig(),
  });

  final String? text;
  final String char;
  final RenderConfig renderConfig;

  @override
  String render() {
    final width = renderConfig.terminalWidth;

    if (text == null) {
      return char * width;
    }

    final label = ' $text ';
    final remaining = width - Style.visibleLength(label);
    final safeRemaining = remaining > 0 ? remaining : 0;
    final left = safeRemaining ~/ 2;
    final right = safeRemaining - left;

    return '${char * left}$label${char * right}';
  }
}
