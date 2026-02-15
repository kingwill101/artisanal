/// Color profile detection with I/O support.
///
/// Re-exports the pure [detect] function from ultraviolet and adds the
/// `dart:io`-dependent [detectForSink] for detecting profiles from an [IOSink].
library;

import 'dart:io';

import 'package:ultraviolet/ultraviolet.dart' as uv_detect;

export 'package:ultraviolet/ultraviolet.dart' show detect;

/// Detect the terminal color profile for an [IOSink] (e.g. `stdout`).
///
/// This is a convenience wrapper around [detect] that extracts the TTY status
/// and platform environment automatically.
uv_detect.Profile detectForSink(
  IOSink sink, {
  Map<String, String>? env,
  bool? forceIsTty,
}) {
  final environment = env ?? Platform.environment;

  final isTty = forceIsTty ?? (sink is Stdout ? sink.hasTerminal : false);

  return uv_detect.detect(
    isTty: isTty,
    env: environment,
    isWindows: Platform.isWindows,
  );
}
