/// Conditional export hub for widget app entrypoints.
///
/// - IO  → [run_app_io] (local terminal / network serving)
/// - Web → [run_app_web] (canvas / DOM)
/// - else → [run_app_stub] (throws [UnsupportedError])
library;

export 'run_app_stub.dart'
    if (dart.library.io) 'run_app_io.dart'
    if (dart.library.html) 'run_app_web.dart';
