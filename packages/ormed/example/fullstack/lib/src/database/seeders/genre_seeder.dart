import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/src/models/genre.dart';

class GenreSeeder extends DatabaseSeeder {
  GenreSeeder(super.connection);

  @override
  Future<void> run() async {
    // #region seed-genres
    final repo = connection.context.repository<Genre>();
    await repo.insertMany([
      GenreInsertDto(
        name: 'Drama',
        description: 'Character-driven storytelling with emotional stakes.',
      ),
      GenreInsertDto(
        name: 'Science Fiction',
        description: 'Speculative worlds, future tech, and big ideas.',
      ),
      GenreInsertDto(
        name: 'Mystery',
        description: 'Twists, clues, and investigative tension.',
      ),
    ]);
    // #endregion seed-genres
  }
}
