import 'dart:async';
import 'dart:io';

import 'terminal_windows_io.dart';
import 'stdin_stream_io.dart';

Stream<List<int>>? _defaultInput;
NativeWindowsInputStream? _nativeInputStream;
bool _usingNativeInput = false;

void _logTerminalIo(String msg) {
  // Mirror the same TEMP/C:\Temp fallback as the native reader so we get
  // main-isolate visibility even when the worker isolate never logs.
  final tempDir =
      Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? 'C:\\Temp';
  for (final p in ['$tempDir\\uv_native_reader.log', 'C:\\Temp\\uv_native_reader.log']) {
    try {
      File(p).writeAsStringSync('[$msg]\n', mode: FileMode.append);
    } catch (_) {}
  }
}

Stream<List<int>> get defaultInput {
  if (_defaultInput != null) {
    _logTerminalIo('defaultInput: returning cached stream (usingNative=$_usingNativeInput)');
    return _defaultInput!;
  }
  if (!Platform.isWindows) {
    _logTerminalIo('defaultInput: not Windows, using stdin');
    _defaultInput = stdin;
    return _defaultInput!;
  }
  _logTerminalIo('defaultInput: Windows, creating NativeWindowsInputStream');
  // On Windows, use the native CONIN$ reader to avoid the Ctrl+Z → EOF bug
  // when ENABLE_VIRTUAL_TERMINAL_INPUT is active.
  try {
    _nativeInputStream = NativeWindowsInputStream();
    _defaultInput = _nativeInputStream!.start();
    _usingNativeInput = true;
    _logTerminalIo('defaultInput: native stream created, usingNative=true');
  } catch (e, st) {
    _logTerminalIo('defaultInput: native stream creation FAILED: $e\n$st');
    rethrow;
  }
  return _defaultInput!;
}

/// Shuts down the native Windows input stream if it was created.
/// Should be called during terminal shutdown on Windows.
Future<void> shutdownNativeInputStream() async {
  if (_nativeInputStream != null) {
    await _nativeInputStream!.close();
    _nativeInputStream = null;
    _defaultInput = null;
    _usingNativeInput = false;
  }
}

/// Shuts down all input streams (shared stdin and native Windows).
/// Called from Terminal.stop() to ensure clean process exit.
Future<void> shutdownInput() async {
  await shutdownNativeInputStream();
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
