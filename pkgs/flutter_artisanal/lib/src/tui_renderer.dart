import 'package:artisanal/tui.dart' show UltravioletTuiRenderer;
import 'package:ultraviolet/ultraviolet.dart' as uv;

class FlutterTerminalRenderer extends UltravioletTuiRenderer {
  FlutterTerminalRenderer({
    required super.terminal,
    super.options,
    required this.onFlush,
  });

  final void Function(uv.Buffer buffer) onFlush;

  @override
  Future<void> flush() async {
    await super.flush();
    final screen = screenBuffer;
    if (screen != null) {
      onFlush(screen.buffer);
    }
  }
}
