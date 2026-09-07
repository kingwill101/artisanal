import '../style/style.dart';
import '../tui/bubbles/components/base.dart';

/// Resolves a component's themed style with an optional semantic override.
///
/// The component theme remains responsible for component-specific attributes;
/// a registered semantic style overrides the attributes it defines.
Style resolveConsoleComponentStyle(Style themed, Style? semanticOverride) {
  if (semanticOverride == null) return themed;
  return themed.copy()..inherit(semanticOverride);
}

/// Renders [component] and emits each resulting line through [writeLine].
void writeConsoleComponent(
  DisplayComponent component,
  void Function(String line) writeLine,
) {
  final output = component.render();
  if (output.isEmpty) return;
  for (final line in output.split('\n')) {
    writeLine(line);
  }
}
