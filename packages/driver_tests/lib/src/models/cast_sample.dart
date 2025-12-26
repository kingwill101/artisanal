import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';

part 'cast_sample.orm.dart';

enum CastStatus { draft, active, archived }

@OrmModel(table: 'cast_samples')
class CastSample extends Model<CastSample> {
  const CastSample({
    required this.id,
    required this.name,
    required this.isActive,
    required this.visits,
    required this.ratio,
    required this.startedOn,
    required this.updatedAt,
    required this.amount,
    required this.status,
    required this.secret,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(cast: 'string')
  final String name;

  @OrmField(columnName: 'is_active', cast: 'boolean')
  final bool isActive;

  @OrmField(cast: 'integer')
  final int visits;

  @OrmField(cast: 'float')
  final double ratio;

  @OrmField(columnName: 'started_on', cast: 'date')
  final DateTime startedOn;

  @OrmField(columnName: 'updated_at', cast: 'datetime')
  final DateTime updatedAt;

  @OrmField(cast: 'decimal:2')
  final Decimal amount;

  @OrmField(cast: 'enum')
  final CastStatus status;

  @OrmField(cast: 'encrypted')
  final String secret;
}
