/// UV + TUI System Integration Demo - Artisanal Nexus
///
/// A high-density interactive demo showcasing UV rendering, TUI widgets,
/// dynamic layout, and a command console.
///
/// Run:
///   dart run pkgs/artisanal/example/uv_tui_demo/uv_tui_demo.dart
library;

import 'package:artisanal/tui.dart' as tui;

import 'model.dart';

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
