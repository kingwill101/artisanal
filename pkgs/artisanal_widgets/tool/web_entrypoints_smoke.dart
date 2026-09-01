import 'package:artisanal_widgets/app.dart' as app;
import 'package:artisanal_widgets/widgets.dart' as widgets;

void main() {
  final entrypointTypes = <Type>[app.WidgetApp, widgets.Text];
  if (entrypointTypes.isEmpty) {
    throw StateError('Artisanal Widgets web entrypoints were not loaded.');
  }
}
