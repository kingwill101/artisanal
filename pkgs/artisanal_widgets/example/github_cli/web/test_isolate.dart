// Test 1: runWidgetApp with a simple WidgetApp shell
import 'package:artisanal_widgets/artisanal_widgets.dart';

class Hello extends StatelessWidget {
  Hello({super.key});

  @override
  Widget build(BuildContext context) => Text('Greetings from WASM!');
}

void main() async {
  await runWidgetApp(WidgetApp(Hello()));
}
