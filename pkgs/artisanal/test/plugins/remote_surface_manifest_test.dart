import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:test/test.dart';

void main() {
  const validator = plugins.RemotePluginManifestValidator();

  test('manifest round-trips and validates', () async {
    const manifest = plugins.RemotePluginManifest(
      id: 'overview',
      entrypoint: 'overview_plugin.dart',
      primarySurfaceId: 'overview.panel',
      surfaceIds: <String>['overview.panel'],
      placement: plugins.RemotePluginManifestPlacement(
        surfaceId: 'overview.panel',
        x: 3,
        y: 5,
        z: 10,
      ),
      displayName: 'Overview',
      capabilities: <String>['surfaces'],
    );

    final roundTrip = plugins.RemotePluginManifest.fromJson(manifest.toJson());
    final errors = await validator.validateManifest(manifest);

    expect(roundTrip.id, manifest.id);
    expect(roundTrip.entrypoint, manifest.entrypoint);
    expect(roundTrip.primarySurfaceId, manifest.primarySurfaceId);
    expect(roundTrip.surfaceIds, manifest.surfaceIds);
    expect(roundTrip.placement.surfaceId, manifest.placement.surfaceId);
    expect(roundTrip.placement.x, manifest.placement.x);
    expect(roundTrip.placement.y, manifest.placement.y);
    expect(roundTrip.placement.z, manifest.placement.z);
    expect(roundTrip.displayName, manifest.displayName);
    expect(roundTrip.capabilities, manifest.capabilities);
    expect(errors, isEmpty);
  });

  test('resolveEntrypoint resolves relative to manifest path', () async {
    final directory = await io.Directory.systemTemp.createTemp(
      'remote-plugin-manifest-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final manifestFile = io.File('${directory.path}/overview.plugin.json');
    await manifestFile.writeAsString('{}');

    final manifest = plugins.RemotePluginManifest(
      id: 'overview',
      entrypoint: 'overview_plugin.dart',
      primarySurfaceId: 'overview.panel',
      surfaceIds: const <String>['overview.panel'],
      placement: const plugins.RemotePluginManifestPlacement(
        surfaceId: 'overview.panel',
        x: 1,
        y: 2,
      ),
      manifestPath: manifestFile.path,
    );

    expect(
      manifest.resolveEntrypoint(),
      io.File(
        manifestFile.path,
      ).parent.uri.resolve('overview_plugin.dart').toFilePath(),
    );
  });

  test(
    'loadRemotePluginManifests loads sorted manifests and ignores other files',
    () async {
      final directory = await io.Directory.systemTemp.createTemp(
        'remote-plugin-loader-',
      );
      addTearDown(() => directory.delete(recursive: true));

      await io.File('${directory.path}/zeta.plugin.json').writeAsString('''
{
  "id": "zeta",
  "entrypoint": "zeta.dart",
  "primarySurfaceId": "zeta.panel",
  "surfaceIds": ["zeta.panel"],
  "placement": {"surfaceId": "zeta.panel", "x": 12, "y": 8}
}
''');
      await io.File('${directory.path}/alpha.plugin.json').writeAsString('''
{
  "id": "alpha",
  "entrypoint": "alpha.dart",
  "primarySurfaceId": "alpha.panel",
  "surfaceIds": ["alpha.panel", "alpha.popup"],
  "placement": {"surfaceId": "alpha.panel", "x": 1, "y": 2, "z": 3}
}
''');
      await io.File('${directory.path}/README.txt').writeAsString('ignored');

      final manifests = await plugins.loadRemotePluginManifests(directory.path);

      expect(manifests.map((manifest) => manifest.id).toList(), <String>[
        'alpha',
        'zeta',
      ]);
      expect(
        manifests.first.resolveEntrypoint(),
        io.File('${directory.path}/alpha.dart').path,
      );
      expect(
        manifests.first.placement.toSurfacePlacement().surfaceId,
        'alpha.panel',
      );
      expect(
        manifests.last.resolveEntrypoint(),
        io.File('${directory.path}/zeta.dart').path,
      );
    },
  );

  test(
    'loadRemotePluginManifest loads and validates one manifest file',
    () async {
      final directory = await io.Directory.systemTemp.createTemp(
        'remote-plugin-single-loader-',
      );
      addTearDown(() => directory.delete(recursive: true));

      final manifestFile = io.File('${directory.path}/solo.plugin.json');
      await manifestFile.writeAsString('''
{
  "id": "solo",
  "entrypoint": "solo.dart",
  "primarySurfaceId": "solo.panel",
  "surfaceIds": ["solo.panel"],
  "placement": {"surfaceId": "solo.panel", "x": 4, "y": 6}
}
''');

      final manifest = await plugins.loadRemotePluginManifest(
        manifestFile.path,
      );

      expect(manifest.id, 'solo');
      expect(manifest.manifestPath, manifestFile.path);
      expect(
        manifest.resolveEntrypoint(),
        io.File('${directory.path}/solo.dart').path,
      );
    },
  );

  test(
    'validator rejects manifests whose primary surface is undeclared',
    () async {
      await expectLater(
        () => validator.validateJsonOrThrow(<String, Object?>{
          'id': 'broken',
          'entrypoint': 'broken.dart',
          'primarySurfaceId': 'broken.panel',
          'surfaceIds': <Object?>['broken.popup'],
          'placement': <String, Object?>{
            'surfaceId': 'broken.popup',
            'x': 1,
            'y': 1,
          },
        }),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('stable plugins entrypoint exposes manifest schemas', () async {
    final errors = await plugins.RemotePluginManifestSchemas.manifest.validate(
      <String, Object?>{
        'id': 'demo',
        'entrypoint': 'demo.dart',
        'primarySurfaceId': 'demo.panel',
        'surfaceIds': <Object?>['demo.panel'],
        'placement': <String, Object?>{
          'surfaceId': 'demo.panel',
          'x': 0,
          'y': 0,
        },
      },
    );

    expect(plugins.RemotePluginManifestSchemas.manifest, isA<plugins.Schema>());
    expect(errors, isEmpty);
  });
}
