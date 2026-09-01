import 'dart:async';

/// Non-native placeholder for the Windows console input reader.
///
/// The real implementation is exported on `dart:io` platforms. Calling
/// [start] elsewhere is unsupported.
final class NativeWindowsInputStream {
  const NativeWindowsInputStream._();

  /// Starts reading Windows console input.
  Stream<List<int>> start() {
    throw UnsupportedError(
      'NativeWindowsInputStream is only available on dart:io platforms.',
    );
  }

  /// Releases native input resources.
  Future<void> close() async {}
}

const NativeWindowsInputStream _sharedWindowsInputStream =
    NativeWindowsInputStream._();

/// Process-wide Windows input reader placeholder.
NativeWindowsInputStream get sharedWindowsInputStream =>
    _sharedWindowsInputStream;
