import 'dart:io';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('ReloadFileWatcher', () {
    test('reloads on matching file changes', () async {
      final tempDir = await Directory.systemTemp.createTemp('reload-watch-');
      final controller = ReloadController();
      final watcher = await ReloadFileWatcher.watch(
        controller: controller,
        roots: [tempDir.path],
        debounce: const Duration(milliseconds: 20),
        extensions: const ['.dart'],
      );

      addTearDown(() async {
        await watcher.dispose();
        await controller.dispose();
        await tempDir.delete(recursive: true);
      });

      final signalFuture = controller.stream.first;
      await File('${tempDir.path}/main.dart').writeAsString('void main() {}\n');

      final signal = await signalFuture.timeout(const Duration(seconds: 5));
      expect(signal.mode, ReloadMode.reload);
    });

    test('ignores non-matching extensions', () async {
      final tempDir = await Directory.systemTemp.createTemp('reload-watch-');
      final controller = ReloadController();
      final watcher = await ReloadFileWatcher.watch(
        controller: controller,
        roots: [tempDir.path],
        debounce: const Duration(milliseconds: 20),
        extensions: const ['.dart'],
      );

      addTearDown(() async {
        await watcher.dispose();
        await controller.dispose();
        await tempDir.delete(recursive: true);
      });

      var triggered = false;
      final subscription = controller.stream.listen((_) {
        triggered = true;
      });
      addTearDown(subscription.cancel);

      await File('${tempDir.path}/notes.txt').writeAsString('ignored\n');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(triggered, isFalse);
    });

    test('can emit restart signals', () async {
      final tempDir = await Directory.systemTemp.createTemp('reload-watch-');
      final controller = ReloadController();
      final watcher = await ReloadFileWatcher.watch(
        controller: controller,
        roots: [tempDir.path],
        debounce: const Duration(milliseconds: 20),
        mode: ReloadMode.restart,
      );

      addTearDown(() async {
        await watcher.dispose();
        await controller.dispose();
        await tempDir.delete(recursive: true);
      });

      final signalFuture = controller.stream.first;
      await File(
        '${tempDir.path}/widget.dart',
      ).writeAsString('class Demo {}\n');

      final signal = await signalFuture.timeout(const Duration(seconds: 5));
      expect(signal.mode, ReloadMode.restart);
    });
  });
}
