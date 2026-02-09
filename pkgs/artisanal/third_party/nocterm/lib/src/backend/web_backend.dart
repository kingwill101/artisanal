import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:nocterm/src/size.dart';

import 'terminal_backend.dart';
import 'web_bridge.dart';

/// Backend for web platform - uses JavaScript bridge for communication.
///
/// This enables compiled nocterm apps (WASM/JS) to communicate with
/// a host application (nocterm_web) that renders to xterm.js.
///
/// The communication happens through `window.noctermBridge`, a JavaScript
/// object that is shared between the host and guest because they run
/// in the same browser context (even though they're separately compiled).
///
/// ## Host Side (nocterm_web)
///
/// The host must initialize the bridge before loading the guest app:
/// ```dart
/// // Initialize the bridge
/// WebBackend.initializeHost();
///
/// // Listen for output from the guest
/// WebBackend.outputStream.listen((data) {
///   xterminal.write(data);
/// });
///
/// // Send input to the guest
/// terminal.onOutput = (data) {
///   WebBackend.sendInput(utf8.encode(data));
/// };
///
/// // Send resize to the guest
/// terminal.onResize = (w, h, _, _) {
///   WebBackend.setSize(Size(w.toDouble(), h.toDouble()));
/// };
/// ```
///
/// ## Guest Side (nocterm app compiled to JS)
///
/// The guest just uses WebBackend normally:
/// ```dart
/// final backend = WebBackend();
/// final terminal = Terminal(backend);
/// // runApp will use this backend on web
/// ```
class WebBackend implements TerminalBackend {
  // ===========================================================================
  // HOST-SIDE STATIC METHODS
  // These are called by nocterm_web to set up and control the bridge.
  // ===========================================================================

  static final _outputController = StreamController<String>.broadcast();
  static final _inputController = StreamController<List<int>>.broadcast();
  static final _resizeController = StreamController<Size>.broadcast();
  static final _shutdownController = StreamController<void>.broadcast();

  /// Initialize the bridge (host side).
  /// Must be called before loading any guest app.
  /// After calling this, you MUST call setSize() before loading the guest.
  static void initializeHost() {
    // Create the bridge object on window
    final bridge = createNoctermBridge();
    noctermBridge = bridge;

    // Don't set default size - host MUST call setSize() with actual terminal size

    // Set up the output callback - guest calls this to send output to host
    bridge.onOutput = _handleGuestOutput.toJS;
  }

  /// Handle output from guest app.
  static void _handleGuestOutput(JSString data) {
    _outputController.add(data.toDart);
  }

  /// Stream of output data from the guest app.
  /// Host listens to this and writes to xterm.js.
  static Stream<String> get outputStream => _outputController.stream;

  /// Send input bytes to the guest app.
  /// Called by host when xterm.js receives keyboard/mouse input.
  static void sendInput(List<int> bytes) {
    final bridge = noctermBridge;
    if (bridge != null) {
      final onInput = bridge.onInput;
      if (onInput != null) {
        // Convert bytes to string for transport
        final str = utf8.decode(bytes, allowMalformed: true);
        onInput.callAsFunction(null, str.toJS);
      }
    }
    // Also emit on local controller for any local listeners
    _inputController.add(bytes);
  }

  /// Convenience method to send input as a string.
  static void sendInputString(String text) {
    sendInput(utf8.encode(text));
  }

  /// Get the current terminal size.
  /// Throws if the bridge is not initialized or size is not set.
  static Size get currentSize {
    final bridge = noctermBridge;
    if (bridge == null) {
      throw StateError(
        'noctermBridge not initialized. '
        'The host must call WebBackend.initializeHost() first.',
      );
    }

    final w = bridge.width?.toDartDouble;
    final h = bridge.height?.toDartDouble;

    if (w == null || h == null) {
      throw StateError(
        'Terminal size not set on bridge. '
        'The host must call WebBackend.setSize() before loading the guest app.',
      );
    }

    return Size(w, h);
  }

  /// Set the terminal size.
  /// Called by host when xterm.js resizes.
  static void setSize(Size size) {
    final bridge = noctermBridge;
    if (bridge != null) {
      bridge.width = size.width.toJS;
      bridge.height = size.height.toJS;

      // Notify the guest
      final onResize = bridge.onResize;
      if (onResize != null) {
        onResize.callAsFunction(null, size.width.toJS, size.height.toJS);
      }
    }
    // Also emit on local controller
    _resizeController.add(size);
  }

  /// Signal that the guest app should shut down.
  static void requestShutdown() {
    final bridge = noctermBridge;
    if (bridge != null) {
      final onShutdown = bridge.onShutdown;
      if (onShutdown != null) {
        onShutdown.callAsFunction(null);
      }
    }
    _shutdownController.add(null);
  }

  /// Reset the bridge for loading a new app.
  /// Note: Does NOT reset size - the host should call setSize() with current size.
  static void reset() {
    final bridge = noctermBridge;
    if (bridge != null) {
      // Clear guest callbacks
      bridge.onInput = null;
      bridge.onResize = null;
      bridge.onShutdown = null;
      // Don't clear onOutput - host still needs it
      // Don't clear size - host should set it explicitly
    }
  }

  /// Check if an app is currently connected (has registered callbacks).
  static bool get isAppConnected {
    final bridge = noctermBridge;
    return bridge != null && bridge.onInput != null;
  }

  // ===========================================================================
  // GUEST-SIDE INSTANCE METHODS
  // These are used by the nocterm app (compiled to JS) via Terminal.
  // ===========================================================================

  bool _disposed = false;
  bool _connected = false;

  WebBackend() {
    _connect();
  }

  void _connect() {
    print('WebBackend: _connect() called');
    final bridge = noctermBridge;
    if (bridge == null) {
      print('WebBackend: ERROR - noctermBridge is null!');
      throw StateError(
        'noctermBridge not found. The host (nocterm_web) must call '
        'WebBackend.initializeHost() before loading the guest app.',
      );
    }
    print('WebBackend: bridge found, registering callbacks...');

    // Register callbacks for receiving data from host
    bridge.onInput = _handleHostInput.toJS;
    bridge.onResize = _handleHostResize.toJS;
    bridge.onShutdown = _handleHostShutdown.toJS;

    print('WebBackend: callbacks registered successfully');
    _connected = true;
  }

  /// Handle input from host.
  static void _handleHostInput(JSAny? data) {
    print('WebBackend: received input from host');
    if (data == null) {
      print('WebBackend: input data is null');
      return;
    }
    // Convert JSAny to String - may come as JSString or need conversion
    final String str;
    if (data.isA<JSString>()) {
      str = (data as JSString).toDart;
    } else {
      // Try toString conversion for other types
      str = data.dartify()?.toString() ?? '';
    }
    print('WebBackend: input string: "$str" (length: ${str.length})');
    final bytes = utf8.encode(str);
    print('WebBackend: converted to ${bytes.length} bytes: $bytes');
    _inputController.add(bytes);
  }

  /// Handle resize from host.
  static void _handleHostResize(JSNumber width, JSNumber height) {
    final size = Size(width.toDartDouble, height.toDartDouble);
    _resizeController.add(size);
  }

  /// Handle shutdown from host.
  static void _handleHostShutdown() {
    _shutdownController.add(null);
  }

  @override
  void writeRaw(String data) {
    if (_disposed) return;

    final bridge = noctermBridge;
    if (bridge != null) {
      final onOutput = bridge.onOutput;
      if (onOutput != null) {
        onOutput.callAsFunction(null, data.toJS);
      }
    }
  }

  @override
  Size getSize() => currentSize;

  @override
  bool get supportsSize => true;

  @override
  Stream<List<int>>? get inputStream => _inputController.stream;

  @override
  Stream<Size>? get resizeStream => _resizeController.stream;

  @override
  Stream<void>? get shutdownStream => _shutdownController.stream;

  @override
  void enableRawMode() {
    // No-op on web - browser handles input mode
  }

  @override
  void disableRawMode() {
    // No-op on web
  }

  @override
  bool get isAvailable => !_disposed && _connected && isBridgeInitialized;

  @override
  void notifySizeChanged(Size newSize) {
    // On web, size is managed by the host via setSize()
    // This is just for compatibility with the backend interface
  }

  @override
  void requestExit([int exitCode = 0]) {
    // Can't exit browser tab from Dart
    // Just disconnect
    _connected = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _connected = false;

    // Clear our callbacks from the bridge
    final bridge = noctermBridge;
    if (bridge != null) {
      bridge.onInput = null;
      bridge.onResize = null;
      bridge.onShutdown = null;
    }
  }
}
