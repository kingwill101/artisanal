/// Helpers used by the CLI to resolve ORM project files.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

export 'package:ormed/ormed.dart'
    show
        MigrationFormat,
        OrmProjectConfig,
        DriverConfig,
        MigrationSection,
        SeedSection,
        DriverAdapterRegistry,
        findOrmConfigFile,
        loadOrmConfig,
        loadOrmProjectConfig;

String resolvePath(Directory root, String relativePath) =>
    p.normalize(p.join(root.path, relativePath));
