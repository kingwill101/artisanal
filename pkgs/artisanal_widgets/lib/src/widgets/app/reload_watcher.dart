import 'dart:async';
import 'dart:io';

import 'reload.dart';

/// Watches one or more filesystem roots and forwards changes into a
/// [ReloadController].
///
/// This is intended for local development loops. It debounces noisy editor or
/// build-tool bursts and can either request a subtree rebuild (`reload`) or a
/// full remount (`restart`).
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

  /// Creates and starts a filesystem-backed watcher.
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

  /// The target controller that receives debounced reload signals.
  final ReloadController controller;

  /// Requested mode when a matching change arrives.
  final ReloadMode mode;

  /// Debounce duration applied across all watched roots.
  final Duration debounce;

  /// Whether subdirectories are watched recursively.
  final bool recursive;

  /// Whether dotfiles and dot-directories are ignored.
  final bool ignoreHidden;

  /// Absolute filesystem roots being watched.
  final List<String> roots;

  final Set<String> _extensions;
  final List<StreamSubscription<FileSystemEvent>> _subscriptions;
  final Set<String> _pendingPaths = <String>{};
  Timer? _debounceTimer;
  bool _disposed = false;

  /// Most recent paths coalesced into the current debounce window.
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

  /// Stops watching and cancels any pending debounce timer.
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
