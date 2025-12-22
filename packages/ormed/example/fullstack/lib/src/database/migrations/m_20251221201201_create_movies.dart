import 'package:ormed/migrations.dart';

class CreateMovies extends Migration {
  const CreateMovies();

  @override
  void up(SchemaBuilder schema) {
    // #region migration-movies
    schema.create('movies', (table) {
      table.id();
      table.string('title');
      table.integer('release_year');
      table.text('summary').nullable();
      table.string('poster_path').nullable();
      table.integer('genre_id').nullable();
      table.foreign(
        ['genre_id'],
        references: 'genres',
        referencedColumns: ['id'],
        onDelete: ReferenceAction.setNull,
      );
      table.timestamps();
    });
    // #endregion migration-movies
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('movies');
  }
}
