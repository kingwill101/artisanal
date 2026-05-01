import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' as io;

import 'package:hotreloader/hotreloader.dart';

import 'msg.dart' show HotReloadStatus;

mixin HotReloadMixin {
  HotReloader? _reloader;

  bool get _enableHotReload => !const bool.fromEnvironment('dart.vm.product');

  /// Called when the hot reload system transitions to a new status.
  ///
  /// Override in the host to dispatch status updates through the
  /// application's message system (e.g. [Program] sends a
  /// [HotReloadStatusMsg] via [send]).
  void onHotReloadStatus(HotReloadStatus status, {String? detail}) {}

  /// Finds the nearest ancestor directory containing `pubspec.yaml`,
  /// starting from [io.Directory.current].
  ///
  /// Returns `null` if no `pubspec.yaml` is found before hitting the
  /// filesystem root. [HotReloader.create] requires `pubspec.yaml` in the
  /// CWD — this helper lets us `chdir` to the project root when the app
  /// is launched from a subdirectory (e.g. `example/`).
  static io.Directory? _findProjectRoot() {
    var dir = io.Directory.current;
    while (true) {
      if (io.File('${dir.path}/pubspec.yaml').existsSync()) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) return null; // filesystem root
      dir = parent;
    }
  }

  Future<void> initializeHotReload({
    Duration debounceInterval = const Duration(milliseconds: 500),
  }) async {
    if (_reloader != null) return;
    if (!_enableHotReload) return;

    onHotReloadStatus(HotReloadStatus.initializing);

    try {
      // Check whether the VM service is actually reachable before attempting
      // to create the file-watcher. This avoids a confusing exception from
      // HotReloader.create() when the service URI is absent.
      try {
        final info = await dev.Service.getInfo();
        if (info.serverUri == null) {
          const message = 'VM service URI not available. Hot reload disabled.';
          dev.log(message, name: 'HotReload');
          onHotReloadStatus(HotReloadStatus.unavailable, detail: message);
          return;
        }
        if (info.serverWebSocketUri != null) {
          dev.log(
            'DevTools URL: ${info.serverUri}devtools/?uri=${info.serverWebSocketUri}',
            name: 'HotReload',
          );
        }
      } catch (e) {
        final message = 'Could not retrieve VM service URL: $e';
        dev.log(message, name: 'HotReload');
        onHotReloadStatus(HotReloadStatus.unavailable, detail: message);
        return;
      }

      // HotReloader.create() requires pubspec.yaml in the CWD.
      // When the app is launched from a subdirectory (e.g. example/),
      // we temporarily chdir to the project root.
      final projectRoot = _findProjectRoot();
      if (projectRoot == null) {
        const message =
            'Could not find pubspec.yaml in any ancestor directory. '
            'Hot reload disabled.';
        dev.log(message, name: 'HotReload');
        onHotReloadStatus(HotReloadStatus.unavailable, detail: message);
        return;
      }

      final originalDir = io.Directory.current;
      final needsChdir = originalDir.path != projectRoot.path;
      if (needsChdir) {
        dev.log(
          'Changing CWD from ${originalDir.path} to ${projectRoot.path} '
          'for HotReloader',
          name: 'HotReload',
        );
        io.Directory.current = projectRoot;
      }

      try {
        _reloader = await HotReloader.create(
          automaticReload: true,
          debounceInterval: debounceInterval,
          onBeforeReload: (ctx) {
            if (ctx.event case final event?) {
              final message = 'Change detected: ${event.path}';
              dev.log(message, name: 'HotReload');
              onHotReloadStatus(
                HotReloadStatus.changeDetected,
                detail: event.path,
              );
            }
            return true;
          },
          onAfterReload: (ctx) {
            switch (ctx.result) {
              case HotReloadResult.Failed:
                const message = 'Compilation error during hot reload';
                dev.log(message, name: 'HotReload', level: 1000);
                onHotReloadStatus(HotReloadStatus.failed, detail: message);
              case HotReloadResult.Succeeded:
                _performReassembleAfterReload();
              case HotReloadResult.PartiallySucceeded:
                const message = 'Hot reload partially succeeded';
                dev.log(message, name: 'HotReload', level: 900);
                onHotReloadStatus(HotReloadStatus.failed, detail: message);
              case HotReloadResult.Skipped:
                dev.log('Hot reload skipped', name: 'HotReload');
            }
          },
        );
      } finally {
        if (needsChdir) {
          io.Directory.current = originalDir;
        }
      }

      dev.log(
        'Hot reload active – watching for file changes',
        name: 'HotReload',
      );
      onHotReloadStatus(HotReloadStatus.ready);
    } catch (e, stack) {
      final message = 'Failed to initialize hot reload: $e';
      dev.log(message, name: 'HotReload', level: 1000, stackTrace: stack);
      onHotReloadStatus(HotReloadStatus.failed, detail: message);
    }
  }

  void _performReassembleAfterReload() {
    scheduleMicrotask(() async {
      try {
        dev.log('Reassembling application...', name: 'HotReload');
        onHotReloadStatus(HotReloadStatus.reassembling);
        await performReassemble();
        dev.log('Application reassembled successfully', name: 'HotReload');
        onHotReloadStatus(HotReloadStatus.succeeded);
      } catch (e, stack) {
        final message = 'Error during reassemble: $e';
        dev.log(message, name: 'HotReload', level: 1000, stackTrace: stack);
        onHotReloadStatus(HotReloadStatus.failed, detail: message);
      }
    });
  }

  void stopHotReload() {
    _reloader?.stop();
    _reloader = null;
  }

  Future<void> performReassemble();
}
