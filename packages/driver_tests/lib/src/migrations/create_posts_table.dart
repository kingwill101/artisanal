import 'package:ormed/migrations.dart';

class CreatePostsTable extends Migration {
  const CreatePostsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('posts', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.integer('author_id');
      table.string('title');
      table.text('content').nullable();
      table.integer('views').nullable();
      table.dateTime('published_at');
      table.fullText(['title', 'content']);
      table.nullableTimestampsTz(
        precision: 6,
      ); // Adds created_at and updated_at (UTC, nullable, microsecond precision)
      table.softDeletesTz(precision: 6);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('posts', ifExists: true);
  }
}
