library;

import 'package:artisanal_widgets/app.dart' as app;
import 'package:artisanal_widgets/widgets.dart' as w;

import 'src/app.dart';
import 'src/cli/cli.dart';
import 'src/model.dart';
import 'src/theme.dart';

export 'src/app.dart';
export 'src/cli/cli.dart';
export 'src/model.dart';
export 'src/theme.dart';
export 'src/views/build_view.dart';
export 'src/views/device_picker.dart';
export 'src/views/test_view.dart';

Future<void> runFlutterCliPort({FlutterCliState? initialState}) {
  return app.runWidgetApp(
    w.WidgetApp(
      FlutterCliDashboard(initialState: initialState),
      backgroundColor: FlutterCliTheme.tokyoNight.bg,
    ),
    options: flutterCliInlineOptions(height: 16),
  );
}
