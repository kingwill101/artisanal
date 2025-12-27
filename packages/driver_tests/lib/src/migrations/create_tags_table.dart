import 'package:ormed/migrations.dart';

class CreateTagsTable extends Migration {
  const CreateTagsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('tags', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('label');
      table.timestamps();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('tags', ifExists: true);
  }
}
