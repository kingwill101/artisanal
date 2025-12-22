import 'package:ormed/ormed.dart';

import 'genre_seeder.dart';
import 'movie_seeder.dart';

/// Root seeder executed by `orm seed` and `orm migrate --seed`.
class AppDatabaseSeeder extends DatabaseSeeder {
  AppDatabaseSeeder(super.connection);

  @override
  Future<void> run() async {
    // #region seed-root
    await call([
      GenreSeeder.new,
      MovieSeeder.new,
    ]);
    // #endregion seed-root
  }
}
