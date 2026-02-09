/// UV + TUI System Integration Demo - Artisanal Nexus
///
/// A technically intense interactive demo showcasing:
/// - UV renderer performance (diffed frame output)
/// - TUI widgets (List, Viewport, Progress, TextInput, Spinner, Help)
/// - Dynamic layouts + live telemetry + command console
///
/// Run:
///   dart run pkgs/artisanal/example/uv_tui_demo.dart
library;

import 'package:artisanal/tui.dart' as tui;

import 'uv_tui_demo/model.dart';

Future<void> main() async {
  await tui.runProgram(
    NexusModel.initial(),
    options: const tui.ProgramOptions(
      useUltravioletRenderer: true,
      useUltravioletInputDecoder: true,
      mouse: true,
      fps: 60,
      altScreen: true,
      startupTitle: 'Artisanal Nexus · UV + TUI',
    ),
  );
}
