import 'package:ormed/migrations.dart';

class CreateNullableRelationsTestTable extends Migration {
  const CreateNullableRelationsTestTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('nullable_relations_test', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('name');
      table.dateTime('deleted_at').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('nullable_relations_test', ifExists: true);
  }
}
