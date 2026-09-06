import 'package:artisanal_widgets/widgets.dart';

/// Placeholder on platforms where `dart:io` PTYs are unavailable.
class PseudoTerminalView extends StatelessWidget {
  PseudoTerminalView({required Object pty, super.key});

  @override
  Widget build(BuildContext context) =>
      Text('Pseudo terminals are unavailable on this platform.');
}
