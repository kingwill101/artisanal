import 'package:flutter/widgets.dart';
import 'package:artisanal/runtime.dart'
    show Model, ProgramOptions, TuiRendererOptions;
import 'package:flutter_artisanal/src/tui_controller.dart' show TuiController;

Future<void> runFlutterApp(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(app);
}

Future<TuiController<M>> runFlutterProgram<M extends Model>({
  required M model,
  ProgramOptions options = const ProgramOptions(hotReload: false),
  TuiRendererOptions? rendererOptions,
}) async {
  final controller = TuiController<M>(
    model: model,
    options: options,
    rendererOptions: rendererOptions,
  );
  await controller.start();
  return controller;
}
