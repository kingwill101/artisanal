// Test 1: runWidgetAppInBrowser with a simple Model (no WidgetApp)
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal/tui.dart' show Model, Cmd, View, Msg;
import 'package:artisanal/artisanal.dart' show runWidgetAppInBrowser;

class SimpleModel implements Model {
  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  Object view() => View(content: 'Hello!');
}

void main() async {
  await runWidgetAppInBrowser(SimpleModel());
}
