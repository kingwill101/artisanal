import 'package:ormed/ormed.dart';

part 'json_value_record.orm.dart';

@OrmModel(table: 'json_value_records')
class JsonValueRecord extends Model<JsonValueRecord> with ModelFactoryCapable {
  const JsonValueRecord({
    required this.id,
    this.objectValue,
    this.stringValue,
    this.mapDynamic,
    this.mapObject,
    this.listDynamic,
    this.listObject,
  });

  @OrmField(isPrimaryKey: true)
  final String id;

  @OrmField(cast: 'json')
  final Object? objectValue;

  @OrmField(cast: 'json')
  final String? stringValue;

  @OrmField(cast: 'json')
  final Map<String, dynamic>? mapDynamic;

  @OrmField(cast: 'json')
  final Map<String, Object?>? mapObject;

  @OrmField(cast: 'json')
  final List<dynamic>? listDynamic;

  @OrmField(cast: 'json')
  final List<Object?>? listObject;
}
