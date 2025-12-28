import 'package:ormed/ormed.dart';

part 'genre.orm.dart';

// #region model-genre
@OrmModel(table: 'genres')
class Genre extends Model<Genre> {
  const Genre({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

// #endregion model-genre
