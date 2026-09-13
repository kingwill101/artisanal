import 'dart:convert';
import 'dart:io';

import 'package:artisanal_capture/widgets.dart';
import 'package:artisanal_widgets/widgets.dart';

/// Writes a reusable cell capture; use the CLI to render it with a chosen font.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run example/widget_capture.dart <capture.json>',
    );
    exitCode = 64;
    return;
  }
  final capture = await captureWidget(
    Column(
      children: [
        Text('Artisanal widget capture'),
        Text('Rendered by the real widget layout pipeline.'),
        Text('No browser. No screenshot timing delay.'),
      ],
    ),
    columns: 52,
    rows: 5,
  );
  await File(arguments.single).writeAsString(jsonEncode(capture.toJson()));
}
