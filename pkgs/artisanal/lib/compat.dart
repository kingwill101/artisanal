/// Platform compatibility shims for `dart:io` / `dart:isolate` parity.
///
/// Re-exports the native `dart:io` / `dart:isolate` types on VM platforms and
/// web-safe stubs on the web/WASM, so consumers can reference [File],
/// [Platform], [HttpClient], [HttpHeaders], and [Isolate] without branching on
/// `dart.library.io` themselves.
///
/// This is a low-level helper consumed by `package:artisanal_widgets`; it is
/// intentionally NOT re-exported from the main `package:artisanal` barrel so its
/// stub types do not shadow `dart:io` symbols in dependent packages.
library;

export 'src/compat/compat.dart';
