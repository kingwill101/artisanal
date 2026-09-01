/// Browser-only hosting APIs for Artisanal programs.
///
/// Import this entrypoint from Dart web applications that render a [Model]
/// into an HTML canvas.
library;

import 'src/tui/model.dart' show Model;

export 'src/web/run_program_web.dart' show BrowserRunOptions, runBrowserProgram;
