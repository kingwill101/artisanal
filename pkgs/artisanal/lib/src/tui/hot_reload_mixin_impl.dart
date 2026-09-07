import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' as io;

import 'package:hotreloader/hotreloader.dart';
import 'package:path/path.dart' as p;

import 'msg.dart' show HotReloadStatus;

/// Integrates the Dart VM hot-reload lifecycle with a running TUI host.
mixin HotReloadMixin {
  HotReloader? _reloader;
  Future<void>? _initialization;
  StreamSubscription<io.FileSystemEvent>? _entrypointSubscription;
  Timer? _entrypointDebounce;
  bool _stopRequested = false;

  bool get _enableHotReload => !const bool.fromEnvironment('dart.vm.product');

  void onHotReloadStatus(HotReloadStatus status, {String? detail}) {}

  /// Whether this process has a VM service that can support hot reload.
  Future<bool> canInitializeHotReload() async {
    if (!_enableHotReload) return false;
    try {
      return (await dev.Service.getInfo()).serverUri != null;
    } catch (_) {
      return false;
    }
  }

  /// Starts automatic hot reload once.
  ///
  /// Concurrent callers share the same initialization attempt. A stopped
  /// instance may be initialized again by a later program run.
  Future<void> initializeHotReload({
    Duration debounceInterval = const Duration(milliseconds: 500),
  }) {
    if (_reloader != null) return Future.value();
    return _initialization ??= _initializeHotReload(
      debounceInterval,
    ).whenComplete(() => _initialization = null);
  }

  Future<void> _initializeHotReload(Duration debounceInterval) async {
    if (!_enableHotReload) return;
    _stopRequested = false;
    onHotReloadStatus(HotReloadStatus.initializing);

    try {
      final reloader = await HotReloader.create(
        automaticReload: true,
        debounceInterval: debounceInterval,
        onBeforeReload: (context) {
          final path = context.event?.path;
          if (path != null) {
            dev.log('Change detected: $path', name: 'HotReload');
            onHotReloadStatus(HotReloadStatus.changeDetected, detail: path);
          }
          return true;
        },
        onAfterReload: _handleReload,
      );

      if (_stopRequested) {
        await reloader.stop();
        return;
      }
      _reloader = reloader;
      _watchEntrypointIfNeeded(debounceInterval);
      dev.log(
        'Hot reload active – watching for file changes',
        name: 'HotReload',
      );
      onHotReloadStatus(HotReloadStatus.ready);
    } catch (error, stack) {
      final message = 'Hot reload unavailable: $error';
      dev.log(message, name: 'HotReload', stackTrace: stack);
      onHotReloadStatus(HotReloadStatus.unavailable, detail: message);
    }
  }

  Future<void> _handleReload(AfterReloadContext context) async {
    switch (context.result) {
      case HotReloadResult.Succeeded:
        try {
          dev.log('Reassembling application...', name: 'HotReload');
          onHotReloadStatus(HotReloadStatus.reassembling);
          await performReassemble();
          dev.log('Application reassembled successfully', name: 'HotReload');
          onHotReloadStatus(HotReloadStatus.succeeded);
        } catch (error, stack) {
          final message = 'Error during reassemble: $error';
          dev.log(message, name: 'HotReload', level: 1000, stackTrace: stack);
          onHotReloadStatus(HotReloadStatus.failed, detail: message);
        }
      case HotReloadResult.Failed:
        const message = 'Compilation error during hot reload';
        dev.log(message, name: 'HotReload', level: 1000);
        onHotReloadStatus(HotReloadStatus.failed, detail: message);
      case HotReloadResult.PartiallySucceeded:
        const message = 'Hot reload partially succeeded';
        dev.log(message, name: 'HotReload', level: 900);
        onHotReloadStatus(HotReloadStatus.failed, detail: message);
      case HotReloadResult.Skipped:
        dev.log('Hot reload skipped', name: 'HotReload');
    }
  }

  void _watchEntrypointIfNeeded(Duration debounceInterval) {
    final script = io.Platform.script;
    if (script.scheme != 'file') return;

    final scriptPath = p.normalize(script.toFilePath());
    final packageRoot = _findPackageRoot(io.File(scriptPath).parent);
    if (packageRoot == null) return;

    final relativePath = p.relative(scriptPath, from: packageRoot.path);
    final firstSegment = p.split(relativePath).firstOrNull;
    if (const {'bin', 'lib', 'test'}.contains(firstSegment)) return;

    final scriptDirectory = io.File(scriptPath).parent;
    _entrypointSubscription = scriptDirectory.watch().listen((event) {
      // Watching the directory rather than the file also handles editors that
      // save by renaming the original and creating a replacement.
      if (p.normalize(event.path) != scriptPath) return;
      _entrypointDebounce?.cancel();
      _entrypointDebounce = Timer(
        debounceInterval,
        () => _reloadEntrypoint(scriptPath),
      );
    });
    dev.log('Watching entrypoint: $scriptPath', name: 'HotReload');
  }

  Future<void> _reloadEntrypoint(String scriptPath) async {
    if (_stopRequested || _reloader == null) return;
    dev.log('Change detected: $scriptPath', name: 'HotReload');
    onHotReloadStatus(HotReloadStatus.changeDetected, detail: scriptPath);
    try {
      await _reloader?.reloadCode();
    } catch (error, stack) {
      final message = 'Hot reload failed: $error';
      dev.log(message, name: 'HotReload', level: 1000, stackTrace: stack);
      onHotReloadStatus(HotReloadStatus.failed, detail: message);
    }
  }

  io.Directory? _findPackageRoot(io.Directory start) {
    var directory = start;
    while (true) {
      if (io.File(p.join(directory.path, 'pubspec.yaml')).existsSync()) {
        return directory;
      }
      final parent = directory.parent;
      if (parent.path == directory.path) return null;
      directory = parent;
    }
  }

  /// Stops file watching and closes the VM service connection.
  Future<void> stopHotReload() async {
    _stopRequested = true;
    await _initialization;
    _entrypointDebounce?.cancel();
    _entrypointDebounce = null;
    await _entrypointSubscription?.cancel();
    _entrypointSubscription = null;
    final reloader = _reloader;
    _reloader = null;
    await reloader?.stop();
  }

  Future<void> performReassemble();
}
