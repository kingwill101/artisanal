import 'dart:convert';
import 'dart:io';

/// Adds DevTools region allocation deltas to a benchmark JSON report.
Future<Map<String, Object?>> addAllocationAccounting({
  required Map<String, Object?> report,
  required Directory sessionDirectory,
}) async {
  final regions = await _readRegions(sessionDirectory);
  final benchmarks = (report['benchmarks'] as List<Object?>)
      .cast<Map<Object?, Object?>>();

  for (final rawBenchmark in benchmarks) {
    final benchmark = rawBenchmark.cast<String, Object?>();
    final name = benchmark['name'] as String;
    final region = regions['ultraviolet.$name'];
    if (region == null) {
      benchmark['allocation'] = <String, Object?>{
        'status': 'unavailable',
        'reason': 'No matching DevTools profiler region was captured.',
      };
      continue;
    }

    benchmark['allocation'] = await _allocationForRegion(region);
  }

  report['schema_version'] = 2;
  final metadata = (report['metadata'] as Map<Object?, Object?>)
      .cast<String, Object?>();
  metadata['allocation_profile_session'] = sessionDirectory.absolute.path;
  metadata['allocation_accounting'] =
      'DevTools VM allocation accumulator delta';
  return report;
}

Future<Map<String, _RegionArtifact>> _readRegions(
  Directory sessionDirectory,
) async {
  final regions = <String, _RegionArtifact>{};
  if (!sessionDirectory.existsSync()) return regions;

  await for (final entity in sessionDirectory.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('/summary.json')) continue;
    final decoded = jsonDecode(await entity.readAsString());
    if (decoded is! Map) continue;
    final summary = decoded.cast<String, Object?>();
    final name = summary['name'];
    if (name is! String || !name.startsWith('ultraviolet.')) continue;
    if (regions.containsKey(name)) {
      throw StateError('Multiple profiler regions named $name were captured.');
    }
    regions[name] = _RegionArtifact(summary: summary, summaryFile: entity);
  }
  return regions;
}

Future<Map<String, Object?>> _allocationForRegion(
  _RegionArtifact region,
) async {
  final attributes = (region.summary['attributes'] as Map<Object?, Object?>?)
      ?.cast<String, Object?>();
  final operations = int.tryParse('${attributes?['operations'] ?? ''}');
  if (operations == null || operations <= 0) {
    return <String, Object?>{
      'status': 'unavailable',
      'reason': 'The profiler region does not record measured operations.',
    };
  }

  final memory = (region.summary['memory'] as Map<Object?, Object?>?)
      ?.cast<String, Object?>();
  final configuredPath = memory?['rawProfilePath'];
  final rawFile = configuredPath is String
      ? File(configuredPath)
      : File('${region.summaryFile.parent.path}/memory_profile.json');
  if (!rawFile.existsSync()) {
    return <String, Object?>{
      'status': 'unavailable',
      'reason': 'The region has no raw memory profile artifact.',
    };
  }

  final raw =
      (jsonDecode(await rawFile.readAsString()) as Map<Object?, Object?>)
          .cast<String, Object?>();
  final start = _classTotals(raw['start']);
  final end = _classTotals(raw['end']);
  final deltas = <_ClassDelta>[];

  for (final key in <String>{...start.keys, ...end.keys}) {
    final before = start[key];
    final after = end[key];
    final bytes = (after?.bytes ?? 0) - (before?.bytes ?? 0);
    final instances = (after?.instances ?? 0) - (before?.instances ?? 0);
    if (bytes <= 0 && instances <= 0) continue;
    deltas.add(
      _ClassDelta(
        className: after?.className ?? before?.className ?? 'unknown',
        libraryUri: after?.libraryUri ?? before?.libraryUri,
        bytes: bytes < 0 ? 0 : bytes,
        instances: instances < 0 ? 0 : instances,
      ),
    );
  }
  deltas.sort((a, b) => b.bytes.compareTo(a.bytes));

  final allocatedBytes = deltas.fold<int>(0, (sum, item) => sum + item.bytes);
  final allocatedInstances = deltas.fold<int>(
    0,
    (sum, item) => sum + item.instances,
  );
  return <String, Object?>{
    'status': 'measured',
    'source': 'devtools_profiler_region',
    'operations': operations,
    'allocated_bytes': allocatedBytes,
    'allocated_instances': allocatedInstances,
    'bytes_per_operation': allocatedBytes / operations,
    'instances_per_operation': allocatedInstances / operations,
    'includes_profiler_control_overhead': true,
    'top_classes': <Map<String, Object?>>[
      for (final delta in deltas.take(10)) delta.toJson(),
    ],
  };
}

Map<String, _ClassTotals> _classTotals(Object? snapshotValue) {
  if (snapshotValue is! Map) return const <String, _ClassTotals>{};
  final snapshot = snapshotValue.cast<String, Object?>();
  final profiles = snapshot['profiles'];
  if (profiles is! List) return const <String, _ClassTotals>{};
  final totals = <String, _ClassTotals>{};

  for (final profileValue in profiles) {
    if (profileValue is! Map) continue;
    final profile = profileValue.cast<String, Object?>();
    final allocationProfile = profile['allocationProfile'];
    if (allocationProfile is! Map) continue;
    final members = allocationProfile['members'];
    if (members is! List) continue;
    for (final memberValue in members) {
      if (memberValue is! Map) continue;
      final member = memberValue.cast<String, Object?>();
      final classValue = member['class'];
      if (classValue is! Map) continue;
      final classRef = classValue.cast<String, Object?>();
      final className = classRef['name'] as String? ?? 'unknown';
      final libraryValue = classRef['library'];
      final libraryUri = libraryValue is Map
          ? libraryValue.cast<String, Object?>()['uri'] as String?
          : null;
      final key = '$libraryUri::$className';
      final current = totals[key];
      totals[key] = _ClassTotals(
        className: className,
        libraryUri: libraryUri,
        bytes: (current?.bytes ?? 0) + (member['accumulatedSize'] as int? ?? 0),
        instances:
            (current?.instances ?? 0) +
            (member['instancesAccumulated'] as int? ?? 0),
      );
    }
  }
  return totals;
}

final class _RegionArtifact {
  const _RegionArtifact({required this.summary, required this.summaryFile});

  final Map<String, Object?> summary;
  final File summaryFile;
}

final class _ClassTotals {
  const _ClassTotals({
    required this.className,
    required this.libraryUri,
    required this.bytes,
    required this.instances,
  });

  final String className;
  final String? libraryUri;
  final int bytes;
  final int instances;
}

final class _ClassDelta {
  const _ClassDelta({
    required this.className,
    required this.libraryUri,
    required this.bytes,
    required this.instances,
  });

  final String className;
  final String? libraryUri;
  final int bytes;
  final int instances;

  Map<String, Object?> toJson() => <String, Object?>{
    'class_name': className,
    'library_uri': libraryUri,
    'allocated_bytes': bytes,
    'allocated_instances': instances,
  };
}
