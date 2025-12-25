import 'package:ormed/ormed.dart';

import 'genre.dart';

part 'movie.orm.dart';

// #region model-movie
@OrmModel(table: 'movies')
class Movie extends Model<Movie> {
  const Movie({
    required this.id,
    required this.title,
    required this.releaseYear,
    this.summary,
    this.posterPath,
    this.genreId,
    this.createdAt,
    this.updatedAt,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String title;
  final int releaseYear;
  final String? summary;
  final String? posterPath;
  final int? genreId;

  @OrmField(ignore: true)
  @OrmRelation.belongsTo(target: Genre, foreignKey: 'genre_id')
  final Genre? genre = null;

  final DateTime? createdAt;
  final DateTime? updatedAt;
}
// #endregion model-movie
