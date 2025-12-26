import 'package:ormed/migrations.dart';

class CreatePostTagsTable extends Migration {
  const CreatePostTagsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('post_tags', (table) {
      table.integer('post_id');
      table.integer('tag_id');
      table.integer('sort_order').nullable();
      table.string('note').nullable();
      table.primary(['post_id', 'tag_id']);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('post_tags', ifExists: true);
  }
}
