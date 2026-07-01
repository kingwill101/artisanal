import 'package:artisanal/web.dart' show runWidgetAppInBrowser;
import 'package:artisanal_widgets/widgets.dart'
    show WidgetApp, StatelessWidget, BuildContext, Widget, Text;

class Hello extends StatelessWidget {
  Hello({super.key});
  @override
  Widget build(BuildContext context) => Text('Hello!');
}

void main() async {
  await runWidgetAppInBrowser(WidgetApp(Hello()));
}
