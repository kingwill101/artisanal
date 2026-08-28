import 'dart:async';
import 'dart:io';

import 'terminal_windows_io.dart';
import 'terminal_windows_native.dart'
    show NativeWindowsInputStream, sharedWindowsInputStream;
import 'stdin_stream_io.dart';

// On Windows, holds the only strong reference to the shared native CONIN$
// reader so its worker isolate and FFI handle can be torn down on
// [shutdownInput]. The reader is process-singleton, so this is the one
// and only handle the process should ever hold.
Stream<List<int>>? _defaultInput;
NativeWindowsInputStream? _nativeInputStream;
bool _usingNativeInput = false;

Stream<List<int>> get defaultInput {
  if (_defaultInput != null) return _defaultInput!;
  if (!Platform.isWindows) {
    _defaultInput = stdin;
    return _defaultInput!;
  }
  // On Windows, the shared native CONIN$ reader bypasses Dart's stdin
  // (which latches into EOF on Ctrl+Z when ENABLE_VIRTUAL_TERMINAL_INPUT
  // is active). The reader is shared process-wide, so two callers
  // (defaultInput and sharedStdinStream) cannot each open CONIN$ and
  // split the input record stream.
  final stream = sharedWindowsInputStream;
  _nativeInputStream = stream;
  _defaultInput = stream.start();
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
    Platform.environment.entries.map((e) => '${e.key}=${e.value}').toList();

bool get defaultIsWindows => Platform.isWindows;

bool get defaultIsTty => stdout.hasTerminal;

StreamSubscription<Object?>? watchSigint(void Function() handler) =>
    ProcessSignal.sigint.watch().listen((_) => handler());

void exitProcess() => exit(0);

bool isStdin(Stream<List<int>> input) =>
    input == stdin || _usingNativeInput;

bool get stdinHasTerminal => stdin.hasTerminal;

void enterRawMode() {
  stdin.echoMode = false;
  stdin.lineMode = false;
  enableWindowsVtInput();
}

void exitRawMode() {
  restoreWindowsVtInput();
  stdin.echoMode = true;
  stdin.lineMode = true;
}
