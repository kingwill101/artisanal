import 'package:ormed/migrations.dart';

class CreateTaggablesTable extends Migration {
  const CreateTaggablesTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('taggables', (table) {
      table.integer('tag_id');
      table.integer('taggable_id');
      table.string('taggable_type');
      table.primary(['tag_id', 'taggable_id', 'taggable_type']);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('taggables', ifExists: true);
  }
}
