import 'dart:io';

import 'package:contextual/contextual.dart';
import 'package:liquify/liquify.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import '../config/paths.dart';
import '../database/database.dart';
import '../logging/logging.dart';
import '../storage/storage.dart';
import '../templates/template_renderer.dart';
import 'app.dart';

// #region server-bootstrap
Future<HttpServer> runServer({String host = '0.0.0.0', int port = 8080}) async {
  final logger = buildLogger();
  final httpLogger = buildHttpLogger(logger);

  final storage = StorageService();
  await storage.init();

  final database = AppDatabase();
  await database.init();

  final templates = TemplateRenderer(
    FileSystemRoot(AppPaths.templatesDir, throwOnMissing: true),
    sharedData: {'app_name': 'Movie Catalog', 'year': DateTime.now().year},
  );

  final app = MovieCatalogApp(
    database: database,
    storage: storage,
    templates: templates,
    logger: logger,
  );

  final handler = Pipeline()
      .addMiddleware(requestIdMiddleware())
      .addMiddleware(httpLogger.middleware)
      .addHandler(app.buildHandler());

  final server = await serve(handler, host, port);
  logger.info('Server running', Context({'host': host, 'port': port}));
  return server;
}

// #endregion server-bootstrap
