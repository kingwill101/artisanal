// Driver extension snippets for documentation.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import '../orm_registry.g.dart';

// #region postgres-extension-definition
class PostgresCaseInsensitiveExtensions extends DriverExtension {
  const PostgresCaseInsensitiveExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.where,
          key: 'ci_equals',
          compile: _compilePostgresCaseInsensitive,
        ),
      ];
}

DriverExtensionFragment _compilePostgresCaseInsensitive(
  DriverExtensionContext context,
  Object? payload,
) {
  final data = payload as Map<String, Object?>;
  final column = context.grammar.wrapIdentifier(data['column'] as String);
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: '${context.tableIdentifier}.$column ILIKE $placeholder',
    bindings: [data['value']],
  );
}
// #endregion postgres-extension-definition

// #region postgres-extension-usage
Future<List<Map<String, Object?>>> searchDocumentsPostgres(
  DataSource dataSource,
  String query,
) {
  return dataSource.context
      .table('documents')
      .whereExtension('ci_equals', {'column': 'title', 'value': query})
      .rows();
}

Future<DataSource> createPostgresExtensionDataSource() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'docs-postgres-extensions',
      driver: PostgresDriverAdapter.fromUrl(
        'postgresql://postgres:postgres@localhost:5432/app',
      ),
      entities: generatedOrmModelDefinitions,
      driverExtensions: const [PostgresCaseInsensitiveExtensions()],
    ),
  );
  await dataSource.init();
  return dataSource;
}
// #endregion postgres-extension-usage

// #region mysql-extension-definition
class MySqlCaseInsensitiveExtensions extends DriverExtension {
  const MySqlCaseInsensitiveExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.where,
          key: 'ci_equals',
          compile: _compileMySqlCaseInsensitive,
        ),
      ];
}

DriverExtensionFragment _compileMySqlCaseInsensitive(
  DriverExtensionContext context,
  Object? payload,
) {
  final data = payload as Map<String, Object?>;
  final column = context.grammar.wrapIdentifier(data['column'] as String);
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: 'LOWER(${context.tableIdentifier}.$column) = LOWER($placeholder)',
    bindings: [data['value']],
  );
}
// #endregion mysql-extension-definition

// #region mysql-extension-usage
Future<List<Map<String, Object?>>> searchDocumentsMySql(
  DataSource dataSource,
  String query,
) {
  return dataSource.context
      .table('documents')
      .whereExtension('ci_equals', {'column': 'title', 'value': query})
      .rows();
}

Future<DataSource> createMySqlExtensionDataSource() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'docs-mysql-extensions',
      driver: MySqlDriverAdapter.fromUrl(
        'mysql://root:secret@localhost:3306/app',
      ),
      entities: generatedOrmModelDefinitions,
      driverExtensions: const [MySqlCaseInsensitiveExtensions()],
    ),
  );
  await dataSource.init();
  return dataSource;
}
// #endregion mysql-extension-usage

// #region sqlite-extension-definition
class SqliteCaseInsensitiveExtensions extends DriverExtension {
  const SqliteCaseInsensitiveExtensions();

  @override
  List<DriverExtensionHandler> get handlers => const [
        DriverExtensionHandler(
          kind: DriverExtensionKind.where,
          key: 'ci_equals',
          compile: _compileSqliteCaseInsensitive,
        ),
      ];
}

DriverExtensionFragment _compileSqliteCaseInsensitive(
  DriverExtensionContext context,
  Object? payload,
) {
  final data = payload as Map<String, Object?>;
  final column = context.grammar.wrapIdentifier(data['column'] as String);
  final placeholder = context.grammar.parameterPlaceholder();
  return DriverExtensionFragment(
    sql: 'LOWER(${context.tableIdentifier}.$column) = LOWER($placeholder)',
    bindings: [data['value']],
  );
}
// #endregion sqlite-extension-definition

// #region sqlite-extension-usage
Future<List<Map<String, Object?>>> searchDocumentsSqlite(
  DataSource dataSource,
  String query,
) {
  return dataSource.context
      .table('documents')
      .whereExtension('ci_equals', {'column': 'title', 'value': query})
      .rows();
}

Future<DataSource> createSqliteExtensionDataSource() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'docs-sqlite-extensions',
      driver: SqliteDriverAdapter(database: 'database.sqlite'),
      entities: generatedOrmModelDefinitions,
      driverExtensions: const [SqliteCaseInsensitiveExtensions()],
    ),
  );
  await dataSource.init();
  return dataSource;
}
// #endregion sqlite-extension-usage
