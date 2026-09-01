import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('implementation libraries do not import all-widget barrels', () {
    final packageRoot = Directory('lib/src/widgets').existsSync()
        ? Directory.current
        : Directory('pkgs/artisanal_widgets');
    final sourceRoot = Directory('${packageRoot.path}/lib/src/widgets');
    final allWidgetImport = RegExp(
      r'''^\s*import\s+['"]package:artisanal_widgets/'''
      r'(?:widgets\.dart|artisanal_widgets\.dart|src/widgets/widgets\.dart)'
      r'''['"]''',
      multiLine: true,
    );

    final offenders =
        sourceRoot
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => allWidgetImport.hasMatch(file.readAsStringSync()))
            .map((file) => file.path.substring(packageRoot.path.length + 1))
            .toList()
          ..sort();

    expect(
      offenders,
      isEmpty,
      reason:
          'Implementation libraries must import lower-layer or peer libraries '
          'directly. Importing an all-widget barrel creates a cycle because '
          'that barrel re-exports the importing implementation.',
    );
  });
}
