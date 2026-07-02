import 'dart:io' as io;

import 'package:path/path.dart' as p;

final String _artisanalRootDirectory = io.Directory.current.path;

String resolveArtisanalPath(List<String> relativeSegments) {
  final candidates = <String>[
    p.joinAll(<String>[_artisanalRootDirectory, ...relativeSegments]),
    p.joinAll(<String>[
      _artisanalRootDirectory,
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
