import 'reload.dart';

final class ReloadFileWatcher {
  static Future<ReloadFileWatcher> watch({
    required ReloadController controller,
    required Iterable<String> roots,
    ReloadMode mode = ReloadMode.reload,
    Duration debounce = const Duration(milliseconds: 150),
    bool recursive = true,
    bool ignoreHidden = true,
    Iterable<String> extensions = const <String>[],
  }) async {
    throw UnsupportedError(
      'ReloadFileWatcher is not supported on this platform',
    );
  }

  ReloadFileWatcher._();

  ReloadController get controller => throw UnsupportedError('Not supported');

  ReloadMode get mode => ReloadMode.reload;

  Duration get debounce => Duration.zero;

  bool get recursive => false;

  bool get ignoreHidden => false;

  List<String> get roots => <String>[];

  List<String> get pendingPaths => <String>[];

  Future<void> dispose() async {}
}
