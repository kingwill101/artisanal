import 'dart:async';
import 'dart:io';

import 'terminal_windows_io.dart';
import 'stdin_stream_io.dart';

Stream<List<int>>? _defaultInput;
// On Windows, holds the only strong reference to the native CONIN$ reader
// so its worker isolate and FFI handle can be torn down on [shutdownInput].
NativeWindowsInputStream? _nativeInputStream;
bool _usingNativeInput = false;

Stream<List<int>> get defaultInput {
  if (_defaultInput != null) return _defaultInput!;
  if (!Platform.isWindows) {
    _defaultInput = stdin;
    return _defaultInput!;
  }
  // On Windows, use the native CONIN$ reader to avoid the Ctrl+Z → EOF bug
  // when ENABLE_VIRTUAL_TERMINAL_INPUT is active.
  _nativeInputStream = NativeWindowsInputStream();
  _defaultInput = _nativeInputStream!.start();
  _usingNativeInput = true;
  return _defaultInput!;
}

/// Shuts down all input streams (shared stdin and native Windows).
/// Called from Terminal.stop() to ensure clean process exit.
Future<void> shutdownInput() async {
  if (_nativeInputStream != null) {
    await _nativeInputStream!.close();
    _nativeInputStream = null;
    _defaultInput = null;
    _usingNativeInput = false;
  }
  await shutdownSharedStdinStream();
}

StringSink get defaultOutput => stdout;

List<String> get defaultEnv =>
    Platform.environment.entries
        .map((e) => '${e.key}=${e.value}')
        .toList();

bool get defaultIsWindows => Platform.isWindows;

bool get defaultIsTty => stdout.hasTerminal;

StreamSubscription<Object?>? watchSigint(void Function() handler) =>
    ProcessSignal.sigint.watch().listen((_) => handler());

void exitProcess() => exit(0);

bool isStdin(Stream<List<int>> input) => input == stdin || _usingNativeInput;

bool get stdinHasTerminal => stdin.hasTerminal;

void enterRawMode() {
  if (_usingNativeInput) {
    // Native reader handles input directly; only configure console mode.
    enableWindowsVtInput();
  } else {
    stdin.echoMode = false;
    stdin.lineMode = false;
    enableWindowsVtInput();
  }
}

void exitRawMode() {
  restoreWindowsVtInput();
  if (!_usingNativeInput) {
    stdin.echoMode = true;
    stdin.lineMode = true;
  }
}
