import '../buffer.dart';
import '../../colorprofile/profile.dart' as cp;

/// Abstract base class for UV terminal renderers.
///
/// [TerminalRenderer] defines the interface that both the ANSI terminal
/// renderer ([UvTerminalRenderer]) and the canvas renderer
/// ([CanvasTerminalRenderer]) implement.
abstract class TerminalRenderer {
  int width();
  int height();

  void resize(int width, int height);
  void render(Buffer newbuf);
  void flush();

  // --- Terminal-control methods (no-ops in canvas renderer) ---

  void moveTo(int x, int y) {}
  int writeString(String s) => 0;
  void prependString(Buffer newbuf, String str) {}

  void hideCursor() {}
  void showCursor() {}

  void enableMouseAllEvents() {}
  void disableMouseAllEvents() {}

  void enableBracketedPaste() {}
  void disableBracketedPaste() {}

  void enableFocusReporting() {}
  void disableFocusReporting() {}

  void pushKeyboardEnhancements(int flags) {}
  void popKeyboardEnhancements() {}

  void queryKeyboardEnhancements() {}
  void queryPrimaryDeviceAttributes() {}
  void querySecondaryDeviceAttributes() {}
  void queryTertiaryDeviceAttributes() {}
  void queryTerminalVersion() {}
  void queryKittyGraphics() {}
  void queryBackgroundColor() {}
  void queryForegroundColor() {}
  void queryCursorColor() {}
  void queryColorScheme() {}

  void erase() {}

  void setBackspace(bool v) {}
  void setHasTab(bool v) {}
  void setTabStops(int width) {}
  void setColorProfile(cp.Profile profile) {}

  void setFullscreen(bool v) {}
  void setRelativeCursor(bool v) {}
  void setScrollOptim(bool v) {}
  void setSynchronizedOutput(bool v) {}

  void enterAltScreen() {}
  void exitAltScreen() {}

  void setLogger(void Function(String message)? logger) {}

  String get lastFlushedOutput => '';
}
