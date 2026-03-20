import 'dart:convert';
import 'dart:io' as io;

import 'package:test/test.dart';

import '_path_utils.dart';

void main() {
  test('remote plugin schema dump prints the top-level protocol schema', () async {
    final result = await io.Process.run(
      io.Platform.resolvedExecutable,
      <String>[
        'run',
        resolveArtisanalPath(<String>[
          'example',
          'tui',
          'remote_plugin_schema_dump.dart',
        ]),
      ],
      workingDirectory: io.Directory.current.path,
    );

    expect(result.exitCode, 0, reason: '${result.stderr}');

    final json = jsonDecode(result.stdout as String) as Map<String, Object?>;
    expect(
      json[r'$id'],
      'https://artisanal.dev/schemas/remote-surface-plugin-message.json',
    );
    expect(json['title'], 'Artisanal Remote Surface Plugin Message');
    expect(json['oneOf'], isA<List<Object?>>());
  });

  test('remote plugin schema dump prints service descriptors with schemas', () async {
    final result = await io.Process.run(
      io.Platform.resolvedExecutable,
      <String>[
        'run',
        resolveArtisanalPath(<String>[
          'example',
          'tui',
          'remote_plugin_schema_dump.dart',
        ]),
        '--built-in-services',
      ],
      workingDirectory: io.Directory.current.path,
    );

    expect(result.exitCode, 0, reason: '${result.stderr}');

    final json = jsonDecode(result.stdout as String) as Map<String, Object?>;
    final services = json['services'] as List<Object?>;
    expect(
      services,
      contains(
        allOf(
          isA<Map<Object?, Object?>>(),
          containsPair('service', 'clipboard'),
          containsPair('method', 'read'),
          contains('paramsSchema'),
          contains('resultSchema'),
        ),
      ),
    );
    expect(
      services,
      contains(
        allOf(
          isA<Map<Object?, Object?>>(),
          containsPair('service', 'filePicker'),
          containsPair('method', 'open'),
        ),
      ),
    );
  });
}
