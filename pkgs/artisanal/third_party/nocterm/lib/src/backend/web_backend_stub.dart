// Stub file for non-web platforms.
// The actual implementation is in web_backend.dart (web only).

import 'dart:async';

import 'package:nocterm/src/size.dart';

import 'terminal_backend.dart';

/// Stub WebBackend for non-web platforms.
/// This class exists so that code can reference WebBackend without
/// conditional imports, but it will throw if actually used on non-web.
class WebBackend implements TerminalBackend {
  // Static host-side methods (stubs)

  static void initializeHost() {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  static Stream<String> get outputStream {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  static void sendInput(List<int> bytes) {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  static void sendInputString(String text) {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  static Size get currentSize {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  static void setSize(Size size) {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  static void requestShutdown() {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  static void reset() {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  static bool get isAppConnected {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  // Instance methods (stubs)

  WebBackend() {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  @override
  void writeRaw(String data) {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  @override
  Size getSize() {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  @override
  bool get supportsSize =>
      throw UnsupportedError('WebBackend is only available on web platforms');

  @override
  Stream<List<int>>? get inputStream =>
      throw UnsupportedError('WebBackend is only available on web platforms');

  @override
  Stream<Size>? get resizeStream =>
      throw UnsupportedError('WebBackend is only available on web platforms');

  @override
  Stream<void>? get shutdownStream =>
      throw UnsupportedError('WebBackend is only available on web platforms');

  @override
  void enableRawMode() {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  @override
  void disableRawMode() {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  @override
  bool get isAvailable =>
      throw UnsupportedError('WebBackend is only available on web platforms');

  @override
  void notifySizeChanged(Size newSize) {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  @override
  void requestExit([int exitCode = 0]) {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }

  @override
  void dispose() {
    throw UnsupportedError('WebBackend is only available on web platforms');
  }
}
