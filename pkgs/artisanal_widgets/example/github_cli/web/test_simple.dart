import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';

class Hello extends StatelessWidget {
  Hello({super.key});

  @override
  Widget build(BuildContext context) => Text('Hello WASM!');
}

void main() async {
  await runWidgetApp(WidgetApp(Hello()));
}
