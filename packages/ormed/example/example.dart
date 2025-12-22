import 'package:ormed/ormed.dart';
import 'package:driver_tests/src/in_memory_query_driver.dart';
import 'models/todo.dart';

Future<void> main() async {
  final dataSource = DataSource(
    DataSourceOptions(
      entities: [TodoOrmDefinition.definition],
      driver: InMemoryQueryExecutor(),
    ),
  );

  await dataSource.init();

  final context = dataSource.connection;

  // Seed a few todos using the repository helpers.
  await context.repository<Todo>().insertMany(const [
    Todo(id: 1, title: 'Write specs'),
    Todo(id: 2, title: 'Implement features'),
  ]);

  final pending = await context
      .query<Todo>()
      .whereEquals('completed', false)
      .orderBy('id')
      .get();
  print('Typed query -> ${pending.map((todo) => todo.title).join(', ')}');

  // Attach the global resolver so models can save/refresh themselves.
  Model.bindConnectionResolver(resolveConnection: (_) => context);
  await const Todo(id: 1, title: 'Write docs', completed: false).save();
  final refreshed = await pending.first.refresh();
  print('Refreshed title: ${refreshed.title}');
  final viaHelpers = await Model.query<Todo>().orderBy('id').get();
  print('Model helper query -> ${viaHelpers.length} rows');
  Model.unbindConnectionResolver();

  // Ad-hoc table queries return plain maps when you need arbitrary SQL access.
  final adHocRows = await context
      .table('todos')
      .select(['id', 'title'])
      .whereEquals('completed', false)
      .get();
  print('Ad-hoc rows -> $adHocRows');

  // Manual encode/decode flows still work via ModelDefinition.
  final row = TodoOrmDefinition.definition.toMap(pending.first.toTracked());
  print('Encoded row -> $row');
  final decoded = TodoOrmDefinition.definition.fromMap(row);
  print('Decoded back -> ${decoded.title}');
}
