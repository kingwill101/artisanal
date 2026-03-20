import 'dart:io' as io;

import 'package:path/path.dart' as p;

String resolveArtisanalPath(List<String> relativeSegments) {
  final currentDirectory = io.Directory.current.path;
  final candidates = <String>[
    p.joinAll(<String>[currentDirectory, ...relativeSegments]),
    p.joinAll(<String>[
      currentDirectory,
      'pkgs',
      'artisanal',
      ...relativeSegments,
    ]),
  ];
  for (final candidate in candidates) {
    if (io.FileSystemEntity.typeSync(candidate) !=
        io.FileSystemEntityType.notFound) {
      return candidate;
    }
  }
  throw StateError(
    'Could not resolve artisanal path: ${p.joinAll(relativeSegments)}',
  );
}
