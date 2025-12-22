import 'package:ormed/migrations.dart';

class CreateCommentsTable extends Migration {
  const CreateCommentsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('comments', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('body');
      table.dateTime('deleted_at').nullable(); // nullable field
      // Foreign keys for nullable relations test
      table.integer('parent_id').nullable();
      table.integer('other_parent_id').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('comments', ifExists: true);
  }
}
