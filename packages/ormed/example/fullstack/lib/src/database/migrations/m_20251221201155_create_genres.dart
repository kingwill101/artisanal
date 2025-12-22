import 'package:ormed/migrations.dart';

class CreateGenres extends Migration {
  const CreateGenres();

  @override
  void up(SchemaBuilder schema) {
    // #region migration-genres
    schema.create('genres', (table) {
      table.id();
      table.string('name');
      table.text('description').nullable();
      table.timestamps();
    });
    // #endregion migration-genres
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('genres');
  }
}
