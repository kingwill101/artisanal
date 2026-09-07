import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Builtin language behavior lives here — never in the minimal core barrel.
const _extensionFiles = {
  'code_edit_policy.dart',
  'code_editing.dart',
  'code_language_profile.dart',
  'code_extensions.dart',
};

final _platformImport = RegExp(
  '^\\s*(import|export)\\s+[\'"]dart:(io|ffi)',
  multiLine: true,
);

Directory _packageRoot() => Directory('lib/src').existsSync()
    ? Directory.current
    : Directory('pkgs/artisanal');

List<File> _editorCoreFiles(Directory packageRoot) => Directory(
  p.join(packageRoot.path, 'lib', 'src', 'tui', 'editor_core'),
).listSync().whereType<File>().where(
  (file) => file.path.endsWith('.dart'),
).toList();

void main() {
  test('editor core never touches dart:io or dart:ffi', () {
    final offenders = _editorCoreFiles(
      _packageRoot(),
    ).where((file) {
      // Doc comments may name the forbidden libraries; only directives
      // create a real platform dependency.
      return _platformImport.hasMatch(file.readAsStringSync());
    }).map((file) => p.basename(file.path)).toList()..sort();

    expect(
      offenders,
      isEmpty,
      reason:
          'Editor core must stay portable (VM, web, tests). Platform I/O '
          'belongs in terminal backends and app code, never in editing logic.',
    );
  });

  test('core modules never import builtin language extensions', () {
    final offenders = <String>[];
    for (final file in _editorCoreFiles(_packageRoot())) {
      final name = p.basename(file.path);
      if (_extensionFiles.contains(name)) continue;
      final source = file.readAsStringSync();
      for (final extension in _extensionFiles) {
        if (extension == 'code_extensions.dart') continue;
        if (source.contains("'$extension'")) {
          offenders.add('$name imports $extension');
        }
      }
    }
    offenders.sort();

    expect(
      offenders,
      isEmpty,
      reason:
          'Builtin language behavior (comment tables, indent policy, '
          'auto-pairs) is opt-in via code_extensions.dart. Core modules '
          'depend on the EditorLanguageAdapter seam instead.',
    );
  });

  test('minimal core barrel excludes builtin extensions', () {
    final packageRoot = _packageRoot();
    final barrel = File(
      p.join(
        packageRoot.path,
        'lib',
        'src',
        'tui',
        'editor_core',
        'editor_core.dart',
      ),
    ).readAsStringSync();
    final leaked = _extensionFiles
        .where((name) => name != 'code_extensions.dart')
        .where((name) => barrel.contains("'$name'"))
        .toList()
      ..sort();

    expect(
      leaked,
      isEmpty,
      reason:
          'editor_core.dart is the minimal versatile core. Builtins stay in '
          'code_extensions.dart, re-exported for compatibility by '
          'package:artisanal/editor_core.dart.',
    );
  });

  test('builtin extensions ship in their own barrel', () {
    final packageRoot = _packageRoot();
    final barrel = File(
      p.join(
        packageRoot.path,
        'lib',
        'src',
        'tui',
        'editor_core',
        'code_extensions.dart',
      ),
    );
    expect(barrel.existsSync(), isTrue);
    final source = barrel.readAsStringSync();
    for (final name in const [
      'code_edit_policy.dart',
      'code_editing.dart',
      'code_language_profile.dart',
    ]) {
      expect(source, contains("'$name'"), reason: '$name must stay opt-in');
    }
  });
}
