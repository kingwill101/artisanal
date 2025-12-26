import 'package:ormed/ormed.dart';

part 'accessor_user.orm.dart';

@OrmModel(
  table: 'accessor_users',
  appends: ['full_name', 'email_domain'],
)
class AccessorUser extends Model<AccessorUser> {
  const AccessorUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  @OrmField(columnName: 'first_name')
  final String firstName;

  @OrmField(columnName: 'last_name')
  final String lastName;

  final String email;

  @OrmAccessor(attribute: 'full_name')
  static String fullName(AccessorUser model, Object? _) =>
      '${model.firstName} ${model.lastName}';

  @OrmAccessor(attribute: 'email_domain')
  static String emailDomain(AccessorUser model, String? value) {
    final emailValue = (value ?? model.email).toLowerCase();
    final parts = emailValue.split('@');
    return parts.length > 1 ? parts.last : '';
  }

  @OrmMutator(attribute: 'email')
  static String normalizeEmail(AccessorUser model, String? value) =>
      value?.trim().toLowerCase() ?? model.email.toLowerCase();
}
