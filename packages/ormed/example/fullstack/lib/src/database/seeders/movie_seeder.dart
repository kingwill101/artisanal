import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/src/models/genre.dart';
import 'package:ormed_fullstack_example/src/models/movie.dart';

class MovieSeeder extends DatabaseSeeder {
  MovieSeeder(super.connection);

  @override
  Future<void> run() async {
    // #region seed-movies
    final genres = await connection.query<Genre>().get();
    final drama = genres.firstWhere((g) => g.name == 'Drama').id;
    final sciFi = genres.firstWhere((g) => g.name == 'Science Fiction').id;
    final mystery = genres.firstWhere((g) => g.name == 'Mystery').id;

    final repo = connection.context.repository<Movie>();
    await repo.insertMany([
      MovieInsertDto(
        title: 'City of Amber',
        releaseYear: 2006,
        summary: 'Two teens uncover the secrets of an underground city.',
        genreId: sciFi,
      ),
      MovieInsertDto(
        title: 'Glass Letters',
        releaseYear: 2019,
        summary: 'A detective pieces together a locked-room mystery.',
        genreId: mystery,
      ),
      MovieInsertDto(
        title: 'Ashes in Winter',
        releaseYear: 2014,
        summary: 'A family confronts loss and renewal after a storm.',
        genreId: drama,
      ),
    ]);

    // Demonstrate update DTOs (fix a typo in a summary).
    await repo.update(
      const MovieUpdateDto(
        summary: 'A detective reconstructs a locked-room mystery.',
      ),
      where: {'title': 'Glass Letters'},
    );
    // #endregion seed-movies
  }
}
