import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/widgets.dart'
    show WidgetApp, StatelessWidget, BuildContext, Widget, Text;

class Hello extends StatelessWidget {
  Hello({super.key});
  @override
  Widget build(BuildContext context) => Text('Hello!');
}

void main() async {
  await runWidgetApp(WidgetApp(Hello()));
}
