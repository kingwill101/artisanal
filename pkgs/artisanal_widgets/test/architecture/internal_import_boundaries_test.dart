import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _importDirective = RegExp(
  r'''^\s*import\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

const _blockedPackageImports = {
  'package:artisanal_widgets/widgets.dart',
  'package:artisanal_widgets/artisanal_widgets.dart',
  'package:artisanal_widgets/src/widgets/widgets.dart',
};

final _blockedRelativeTargets = {
  p.normalize('lib/widgets.dart'),
  p.normalize('lib/artisanal_widgets.dart'),
  p.normalize('lib/src/widgets/widgets.dart'),
};

bool _isAllWidgetImport(String sourcePath, String uri) {
  if (_blockedPackageImports.contains(uri)) return true;
  if (uri.startsWith('dart:') || uri.startsWith('package:')) return false;
  final target = p.normalize(p.join(p.dirname(sourcePath), uri));
  return _blockedRelativeTargets.contains(target);
}

void main() {
  test('recognizes package and relative all-widget barrel imports', () {
    const componentPath = 'lib/src/widgets/components/example.dart';

    expect(
      _isAllWidgetImport(
        componentPath,
        'package:artisanal_widgets/widgets.dart',
      ),
      isTrue,
    );
    expect(_isAllWidgetImport(componentPath, '../widgets.dart'), isTrue);
    expect(_isAllWidgetImport(componentPath, '../../../widgets.dart'), isTrue);
    expect(
      _isAllWidgetImport(componentPath, '../../../artisanal_widgets.dart'),
      isTrue,
    );
    expect(
      _isAllWidgetImport(componentPath, '_component_foundation.dart'),
      isFalse,
    );
  });

  test('implementation libraries do not import all-widget barrels', () {
    final packageRoot = Directory('lib/src/widgets').existsSync()
        ? Directory.current
        : Directory('pkgs/artisanal_widgets');
    final sourceRoot = Directory('${packageRoot.path}/lib/src/widgets');

    final offenders =
        sourceRoot
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .expand((file) {
              final sourcePath = p.relative(file.path, from: packageRoot.path);
              return _importDirective
                  .allMatches(file.readAsStringSync())
                  .map((match) => match.group(1)!)
                  .where((uri) => _isAllWidgetImport(sourcePath, uri))
                  .map((uri) => '$sourcePath -> $uri');
            })
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
