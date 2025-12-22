import 'dart:io';

import 'package:liquify/liquify.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/orm_registry.g.dart';
import 'package:ormed_fullstack_example/src/database/database.dart';
import 'package:ormed_fullstack_example/src/database/migrations.dart';
import 'package:ormed_fullstack_example/src/database/seeders/database_seeder.dart';
import 'package:ormed_fullstack_example/src/logging/logging.dart';
import 'package:ormed_fullstack_example/src/server/app.dart';
import 'package:ormed_fullstack_example/src/storage/storage.dart';
import 'package:ormed_fullstack_example/src/templates/template_renderer.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:server_testing_shelf/server_testing_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

// #region testing-setup
OrmedTestConfig createMovieCatalogConfig() {
  final baseDataSource = DataSource(
    DataSourceOptions(
      driver: SqliteDriverAdapter.inMemory(),
      registry: bootstrapOrm(),
      name: 'movie_catalog_test',
    ),
  );

  final config = setUpOrmed(
    dataSource: baseDataSource,
    migrationDescriptors: buildMigrations(),
    seeders: [AppDatabaseSeeder.new],
    adapterFactory: (_) => SqliteDriverAdapter.inMemory(),
    strategy: DatabaseIsolationStrategy.migrateWithTransactions,
  );

  tearDownAll(() async {
    await config.manager.cleanup();
  });

  return config;
}

class MovieCatalogTestHarness {
  MovieCatalogTestHarness({
    required this.dataSource,
    required this.requestHandler,
    required this.storage,
    required this.templates,
    required this.uploadsDir,
  });

  final DataSource dataSource;
  final ShelfRequestHandler requestHandler;
  final StorageService storage;
  final TemplateRenderer templates;
  final Directory uploadsDir;

  Future<void> dispose() async {
    await uploadsDir.delete(recursive: true);
  }
}

Future<MovieCatalogTestHarness> createMovieCatalogHarness(
  DataSource dataSource,
) async {
  final uploadsDir = await Directory.systemTemp.createTemp('movie_uploads_');
  final storage = StorageService(uploadsRoot: uploadsDir.path);
  await storage.init();

  final templates = TemplateRenderer(
    FileSystemRoot('templates', throwOnMissing: true),
    sharedData: {'app_name': 'Movie Catalog', 'year': 2025},
  );

  final logger = buildLogger();
  final httpLogger = buildHttpLogger(logger);
  final app = MovieCatalogApp(
    database: AppDatabase.fromDataSource(dataSource),
    storage: storage,
    templates: templates,
    logger: logger,
  );

  final handler = Pipeline()
      .addMiddleware(requestIdMiddleware())
      .addMiddleware(httpLogger.middleware)
      .addHandler(app.buildHandler());

  return MovieCatalogTestHarness(
    dataSource: dataSource,
    requestHandler: ShelfRequestHandler(handler),
    storage: storage,
    templates: templates,
    uploadsDir: uploadsDir,
  );
}
// #endregion testing-setup
