import 'package:ormed/ormed.dart';

part 'mixed_constructor.orm.dart';

@OrmModel(table: 'mixed_constructors')
class MixedConstructorModel extends Model<MixedConstructorModel> {
  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String name;

  final String? description;

  MixedConstructorModel(this.id, this.name, {this.description});
}
