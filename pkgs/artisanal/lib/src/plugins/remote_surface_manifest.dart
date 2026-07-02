import 'dart:convert';
import 'dart:io' as io;

import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:path/path.dart' as p;

import 'remote_surface_layers.dart';

typedef JsonObject = Map<String, Object?>;

/// Manifest-backed host placement for a remote plugin surface.
final class RemotePluginManifestPlacement {
  const RemotePluginManifestPlacement({
    required this.surfaceId,
    required this.x,
    required this.y,
    this.z = 0,
  });

  final String surfaceId;
  final int x;
  final int y;
  final int z;

  factory RemotePluginManifestPlacement.fromJson(JsonObject json) {
    return RemotePluginManifestPlacement(
      surfaceId: _requireString(json, 'surfaceId'),
      x: _requireInt(json, 'x'),
      y: _requireInt(json, 'y'),
      z: _readInt(json, 'z', fallback: 0),
    );
  }

  JsonObject toJson() {
    return <String, Object?>{
      'surfaceId': surfaceId,
      'x': x,
      'y': y,
      if (z != 0) 'z': z,
    };
  }

  RemotePluginSurfacePlacement toSurfacePlacement() {
    return RemotePluginSurfacePlacement(surfaceId: surfaceId, x: x, y: y, z: z);
  }
}

/// File-backed manifest describing one launchable remote plugin.
final class RemotePluginManifest {
  const RemotePluginManifest({
    required this.id,
    required this.entrypoint,
    required this.primarySurfaceId,
    required this.surfaceIds,
    required this.placement,
    this.displayName,
    this.capabilities = const <String>[],
    this.manifestPath,
  });

  final String id;
  final String entrypoint;
  final String primarySurfaceId;
  final List<String> surfaceIds;
  final RemotePluginManifestPlacement placement;
  final String? displayName;
  final List<String> capabilities;
  final String? manifestPath;

  factory RemotePluginManifest.fromJson(
    JsonObject json, {
    String? manifestPath,
  }) {
    return RemotePluginManifest(
      id: _requireString(json, 'id'),
      entrypoint: _requireString(json, 'entrypoint'),
      primarySurfaceId: _requireString(json, 'primarySurfaceId'),
      surfaceIds: _readStringList(json, 'surfaceIds'),
      placement: RemotePluginManifestPlacement.fromJson(
        _requireObject(json, 'placement'),
      ),
      displayName: _readStringOrNull(json, 'displayName'),
      capabilities: _readStringList(json, 'capabilities'),
      manifestPath: manifestPath,
    );
  }

  JsonObject toJson() {
    return <String, Object?>{
      'id': id,
      'entrypoint': entrypoint,
      'primarySurfaceId': primarySurfaceId,
      'surfaceIds': surfaceIds,
      'placement': placement.toJson(),
      if (displayName != null) 'displayName': displayName,
      if (capabilities.isNotEmpty) 'capabilities': capabilities,
    };
  }

  String encodeJson() => jsonEncode(toJson());

  /// Resolves [entrypoint] relative to the manifest file when needed.
  String resolveEntrypoint({String? currentWorkingDirectory}) {
    final manifestPath = this.manifestPath;
    if (p.isAbsolute(entrypoint)) {
      return p.normalize(entrypoint);
    }
    if (manifestPath == null) {
      return io.Directory(
        currentWorkingDirectory ?? io.Directory.current.path,
      ).uri.resolve(entrypoint).toFilePath();
    }

    return io.File(manifestPath).parent.uri.resolve(entrypoint).toFilePath();
  }
}

final class RemotePluginManifestSchemas {
  RemotePluginManifestSchemas._();

  static final Schema placement = S.object(
    required: const ['surfaceId', 'x', 'y'],
    properties: <String, Schema>{
      'surfaceId': S.string(minLength: 1),
      'x': S.integer(),
      'y': S.integer(),
      'z': S.integer(),
    },
    additionalProperties: false,
  );

  static final Schema manifest = S.object(
    title: 'Artisanal Remote Surface Plugin Manifest',
    description:
        'Schema for manifest-backed out-of-process Artisanal remote plugins.',
    required: const [
      'id',
      'entrypoint',
      'primarySurfaceId',
      'surfaceIds',
      'placement',
    ],
    properties: <String, Schema>{
      'id': S.string(minLength: 1),
      'entrypoint': S.string(minLength: 1),
      'primarySurfaceId': S.string(minLength: 1),
      'surfaceIds': S.list(items: S.string(minLength: 1), minItems: 1),
      'placement': placement,
      'displayName': S.string(minLength: 1),
      'capabilities': S.list(items: S.string(minLength: 1)),
    },
    additionalProperties: false,
  );
}

final class RemotePluginManifestValidator {
  const RemotePluginManifestValidator();

  Future<List<ValidationError>> validateJson(JsonObject json) {
    return RemotePluginManifestSchemas.manifest.validate(json);
  }

  Future<List<ValidationError>> validateManifest(
    RemotePluginManifest manifest,
  ) async {
    final json = manifest.toJson();
    final errors = await validateJson(json);
    if (errors.isEmpty) {
      _validateRelationships(json);
    }
    return errors;
  }

  Future<void> validateJsonOrThrow(JsonObject json) async {
    final errors = await validateJson(json);
    if (errors.isEmpty) {
      _validateRelationships(json);
      return;
    }
    throw RemotePluginManifestValidationException(errors);
  }

  void _validateRelationships(JsonObject json) {
    final primarySurfaceId = _requireString(json, 'primarySurfaceId');
    final placement = RemotePluginManifestPlacement.fromJson(
      _requireObject(json, 'placement'),
    );
    final surfaceIds = _readStringList(json, 'surfaceIds');
    if (!surfaceIds.contains(primarySurfaceId)) {
      throw FormatException(
        'primarySurfaceId "$primarySurfaceId" must be present in surfaceIds.',
      );
    }
    if (!surfaceIds.contains(placement.surfaceId)) {
      throw FormatException(
        'placement.surfaceId "${placement.surfaceId}" must be present in '
        'surfaceIds.',
      );
    }
  }
}

final class RemotePluginManifestValidationException implements Exception {
  RemotePluginManifestValidationException(this.errors);

  final List<ValidationError> errors;

  @override
  String toString() {
    final buffer = StringBuffer(
      'Remote plugin manifest validation failed with ${errors.length} error(s):',
    );
    for (final error in errors) {
      buffer
        ..write('\n- ')
        ..write(error.toErrorString());
    }
    return buffer.toString();
  }
}

/// Loads all `*.plugin.json` manifests from `directoryPath`.
Future<RemotePluginManifest> loadRemotePluginManifest(
  String manifestPath, {
  RemotePluginManifestValidator validator =
      const RemotePluginManifestValidator(),
}) async {
  final file = io.File(manifestPath);
  if (!await file.exists()) {
    throw io.FileSystemException(
      'Remote plugin manifest file does not exist.',
      manifestPath,
    );
  }

  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<Object?, Object?>) {
    throw FormatException(
      'Remote plugin manifest $manifestPath must decode to a JSON object.',
    );
  }
  final json = decoded.cast<String, Object?>();
  await validator.validateJsonOrThrow(json);
  return RemotePluginManifest.fromJson(json, manifestPath: manifestPath);
}

/// Loads all `*.plugin.json` manifests from [directoryPath].
Future<List<RemotePluginManifest>> loadRemotePluginManifests(
  String directoryPath, {
  RemotePluginManifestValidator validator =
      const RemotePluginManifestValidator(),
}) async {
  final directory = io.Directory(directoryPath);
  if (!await directory.exists()) {
    throw io.FileSystemException(
      'Remote plugin manifest directory does not exist.',
      directoryPath,
    );
  }

  final manifests = <RemotePluginManifest>[];
  await for (final entity in directory.list()) {
    if (entity is! io.File || !entity.path.endsWith('.plugin.json')) {
      continue;
    }

    manifests.add(
      await loadRemotePluginManifest(entity.path, validator: validator),
    );
  }

  manifests.sort((a, b) => a.id.compareTo(b.id));
  return manifests;
}

JsonObject _requireObject(JsonObject json, String key) {
  final value = json[key];
  if (value is Map<Object?, Object?>) {
    return value.cast<String, Object?>();
  }
  throw FormatException('Expected "$key" to be a JSON object');
}

String _requireString(JsonObject json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Expected "$key" to be a non-empty string');
}

String? _readStringOrNull(JsonObject json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}

int _requireInt(JsonObject json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('Expected "$key" to be an integer');
}

int _readInt(JsonObject json, String key, {required int fallback}) {
  final value = json[key];
  return value is int ? value : fallback;
}

List<String> _readStringList(JsonObject json, String key) {
  final value = json[key];
  if (value is! List) {
    return const <String>[];
  }
  return value.whereType<String>().toList(growable: false);
}
