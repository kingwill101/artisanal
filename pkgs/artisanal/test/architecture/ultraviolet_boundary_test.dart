import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _allowedUvImplementationFiles = {'tui_adapter.dart'};

void main() {
  final packageRoot = Directory('lib/src').existsSync()
      ? Directory.current
      : Directory('pkgs/artisanal');

  test('implementation code uses public ultraviolet entrypoints', () {
    final sourceRoot = Directory(p.join(packageRoot.path, 'lib'));
    final offenders =
        sourceRoot
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where(
              (file) =>
                  file.readAsStringSync().contains('package:ultraviolet/src/'),
            )
            .map((file) => p.relative(file.path, from: packageRoot.path))
            .toList()
          ..sort();

    expect(
      offenders,
      isEmpty,
      reason:
          'Artisanal must consume stable Ultraviolet package entrypoints, '
          'not another package\'s private lib/src implementation.',
    );
  });

  test('UV integration directory contains the Artisanal adapter only', () {
    final uvRoot = Directory(p.join(packageRoot.path, 'lib', 'src', 'uv'));
    final unexpected =
        uvRoot
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .map((file) => p.basename(file.path))
            .where((name) => !_allowedUvImplementationFiles.contains(name))
            .toList()
          ..sort();

    expect(
      unexpected,
      isEmpty,
      reason:
          'Ultraviolet primitives belong in package:ultraviolet. Keep only '
          'the Artisanal-owned input adapter here.',
    );
  });
}
