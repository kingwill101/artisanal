import 'package:ormed/migrations.dart';

class CreateJsonValueRecordsTable extends Migration {
  const CreateJsonValueRecordsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('json_value_records', (table) {
      table.string('id').primaryKey();
      table.json('object_value').nullable();
      table.json('string_value').nullable();
      table.json('map_dynamic').nullable();
      table.json('map_object').nullable();
      table.json('list_dynamic').nullable();
      table.json('list_object').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('json_value_records', ifExists: true);
  }
}
