import 'renderer.dart' show Renderer;
import 'renderer_impl.dart' show TerminalRenderer;

Renderer createDefaultRenderer() => TerminalRenderer();
