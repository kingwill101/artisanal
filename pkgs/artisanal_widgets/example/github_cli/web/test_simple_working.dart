import 'package:artisanal_widgets/widgets.dart'
import 'package:artisanal_widgets/artisanal_widgets.dart';
    show WidgetApp, StatelessWidget, BuildContext, Widget, Text;
import 'package:artisanal/artisanal.dart' show runWidgetAppInBrowser;

class Hello extends StatelessWidget {
  Hello({super.key});

  @override
  Widget build(BuildContext context) => Text('Hello WASM!');
}

void main() async {
  await runWidgetAppInBrowser(WidgetApp(Hello()));
}
