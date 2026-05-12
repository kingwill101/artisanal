import 'dart:io';

import 'package:ultraviolet/src/colorprofile/detect.dart' as uv_detect;
import 'package:ultraviolet/src/colorprofile/profile.dart' show Profile;

export 'package:ultraviolet/src/colorprofile/detect.dart' show detect;

/// Detect the terminal color profile for an [IOSink] (e.g. `stdout`).
Profile detectForSink(
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
