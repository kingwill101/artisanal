import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// JavaScript bridge object for nocterm host-guest communication.
/// This is stored on `window.noctermBridge` and shared between
/// separately compiled Dart applications.
@JS()
@staticInterop
class NoctermBridge {}

/// Create a new empty JS object that can be used as a NoctermBridge.
NoctermBridge createNoctermBridge() {
  // Create a plain JS object: {}
  return _createEmptyObject() as NoctermBridge;
}

/// Helper to create an empty JS object via JS interop.
@JS('Object')
external JSFunction get _objectConstructor;

JSObject _createEmptyObject() {
  return _objectConstructor.callAsConstructor<JSObject>();
}

/// Extension to add properties to NoctermBridge.
extension NoctermBridgeExtension on NoctermBridge {
  // ─────────────────────────────────────────────────────────────────
  // Guest → Host: Output from the nocterm app
  // ─────────────────────────────────────────────────────────────────

  /// Callback for output data from guest app.
  /// Host sets this, guest calls it via writeOutput().
  external JSFunction? get onOutput;
  external set onOutput(JSFunction? value);

  // ─────────────────────────────────────────────────────────────────
  // Host → Guest: Input, resize, shutdown
  // ─────────────────────────────────────────────────────────────────

  /// Callback for keyboard/mouse input.
  /// Guest sets this, host calls it via sendInput().
  external JSFunction? get onInput;
  external set onInput(JSFunction? value);

  /// Callback for terminal resize.
  /// Guest sets this, host calls it via setSize().
  external JSFunction? get onResize;
  external set onResize(JSFunction? value);

  /// Callback for shutdown signal.
  /// Guest sets this, host calls it via requestShutdown().
  external JSFunction? get onShutdown;
  external set onShutdown(JSFunction? value);

  // ─────────────────────────────────────────────────────────────────
  // Synchronous size data (host writes, guest reads)
  // ─────────────────────────────────────────────────────────────────

  /// Current terminal width in columns.
  external JSNumber? get width;
  external set width(JSNumber? value);

  /// Current terminal height in rows.
  external JSNumber? get height;
  external set height(JSNumber? value);
}

/// Global accessor for the bridge object.
@JS('noctermBridge')
external NoctermBridge? get noctermBridge;

/// Global setter for the bridge object.
@JS('noctermBridge')
external set noctermBridge(NoctermBridge? value);

/// Check if the bridge has been initialized (by host).
bool get isBridgeInitialized => noctermBridge != null;
