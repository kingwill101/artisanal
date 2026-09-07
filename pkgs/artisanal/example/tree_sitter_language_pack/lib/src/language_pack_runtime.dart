// RustLib is not exported by the dependency's public barrel. Keep the
// implementation import isolated at this runtime boundary.
// ignore: implementation_imports
import 'package:tree_sitter_language_pack/src/tree_sitter_language_pack_bridge_generated/frb_generated.dart'
    show RustLib;

/// Owns the native flutter_rust_bridge runtime used by the optional adapter.
///
/// The implementation-detail import is intentionally isolated in this file.
final class LanguagePackRuntime {
  LanguagePackRuntime._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await RustLib.init();
    _initialized = true;
  }

  static void dispose() {
    if (!_initialized) return;
    RustLib.dispose();
    _initialized = false;
  }
}
