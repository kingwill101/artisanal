import 'dart:io';

import 'package:ultraviolet/colorprofile.dart' show Profile, detect;

/// Detect the terminal color profile for an [IOSink] (e.g. `stdout`).
Profile detectForSink(
  IOSink sink, {
  Map<String, String>? env,
  bool? forceIsTty,
}) {
  final environment = env ?? Platform.environment;
  final isTty = forceIsTty ?? (sink is Stdout ? sink.hasTerminal : false);
  return detect(isTty: isTty, env: environment, isWindows: Platform.isWindows);
}
