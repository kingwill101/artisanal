import 'package:ormed/ormed.dart';

class CreateInsertDefaultsTable extends Migration {
  const CreateInsertDefaultsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('insert_defaults', (table) {
      table.string('id').primaryKey();
      table.timestampsTz();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('insert_defaults', ifExists: true);
  }
}
