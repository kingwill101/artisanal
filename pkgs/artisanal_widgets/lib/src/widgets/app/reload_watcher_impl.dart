import 'dart:async';
import 'dart:io';

import 'reload.dart';

final class ReloadFileWatcher {
  ReloadFileWatcher._({
    required this.controller,
    required this.mode,
    required this.debounce,
    required this.recursive,
    required this.ignoreHidden,
    required Set<String> extensions,
    required List<String> roots,
    required List<StreamSubscription<FileSystemEvent>> subscriptions,
  }) : _extensions = extensions,
       roots = List<String>.unmodifiable(roots),
       _subscriptions = subscriptions;

  static Future<ReloadFileWatcher> watch({
    required ReloadController controller,
    required Iterable<String> roots,
    ReloadMode mode = ReloadMode.reload,
    Duration debounce = const Duration(milliseconds: 150),
    bool recursive = true,
    bool ignoreHidden = true,
    Iterable<String> extensions = const <String>[],
  }) async {
    final normalizedRoots =
        roots.map((root) => Directory(root).absolute.path).toSet().toList()
          ..sort();

    if (normalizedRoots.isEmpty) {
      throw ArgumentError.value(
        roots,
        'roots',
        'At least one watch root is required.',
      );
    }

    final normalizedExtensions = extensions
        .map((extension) => extension.trim().toLowerCase())
        .where((extension) => extension.isNotEmpty)
        .map(
          (extension) => extension.startsWith('.') ? extension : '.$extension',
        )
        .toSet();

    final subscriptions = <StreamSubscription<FileSystemEvent>>[];
    final watcher = ReloadFileWatcher._(
      controller: controller,
      mode: mode,
      debounce: debounce,
      recursive: recursive,
      ignoreHidden: ignoreHidden,
      extensions: normalizedExtensions,
      roots: normalizedRoots,
      subscriptions: subscriptions,
    );

    for (final root in normalizedRoots) {
      final directory = Directory(root);
      if (!await directory.exists()) {
        throw ArgumentError.value(root, 'roots', 'Watch root does not exist.');
      }
      subscriptions.add(
        directory
            .watch(recursive: recursive)
            .listen(watcher._handleEvent, cancelOnError: false),
      );
    }

    return watcher;
  }

  final ReloadController controller;
  final ReloadMode mode;
  final Duration debounce;
  final bool recursive;
  final bool ignoreHidden;
  final List<String> roots;

  final Set<String> _extensions;
  final List<StreamSubscription<FileSystemEvent>> _subscriptions;
  final Set<String> _pendingPaths = <String>{};
  Timer? _debounceTimer;
  bool _disposed = false;

  List<String> get pendingPaths => List<String>.unmodifiable(_pendingPaths);

  void _handleEvent(FileSystemEvent event) {
    if (_disposed) return;
    final path = event.path;
    if (!_matches(path)) return;

    _pendingPaths.add(path);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _flushPending);
  }

  bool _matches(String path) {
    if (ignoreHidden) {
      final segments = path.split(Platform.pathSeparator);
      if (segments.any(
        (segment) => segment.startsWith('.') && segment.length > 1,
      )) {
        return false;
      }
    }

    if (_extensions.isEmpty) return true;
    final lowerPath = path.toLowerCase();
    return _extensions.any(lowerPath.endsWith);
  }

  void _flushPending() {
    if (_disposed || _pendingPaths.isEmpty) return;
    _pendingPaths.clear();
    switch (mode) {
      case ReloadMode.reload:
        controller.reload();
      case ReloadMode.restart:
        controller.restart();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _debounceTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _pendingPaths.clear();
  }
}
