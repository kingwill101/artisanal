// Attribute metadata examples for documentation.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

part 'attribute_metadata_examples.orm.dart';

// #region attributes-model-level
@OrmModel(
  table: 'accounts',
  fillable: ['email', 'name'],
  guarded: ['is_admin'],
  hidden: ['password_hash'],
  visible: ['password_hash'],
  appends: ['display_name'],
)
class Account extends Model<Account> {
  const Account({
    required this.id,
    required this.email,
    required this.passwordHash,
    this.name,
    this.isAdmin = false,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;

  @OrmField(columnName: 'password_hash')
  final String passwordHash;

  final String? name;

  @OrmField(columnName: 'is_admin', guarded: true)
  final bool isAdmin;

  // #endregion attributes-model-level

  // #region attributes-accessors
  @OrmAccessor(attribute: 'display_name')
  static String displayName(Account model, Object? _) =>
      model.name ?? model.email;

  @OrmMutator(attribute: 'email')
  static String normalizeEmail(Account model, String? value) =>
      value?.trim().toLowerCase() ?? model.email;
  // #endregion attributes-accessors
}

// #region attributes-fill
void massAssignmentExample() {
  final account = $Account(id: 1, email: 'a@example.com', passwordHash: 'hash');

  // Only fillable columns are applied; guarded columns are discarded.
  account.fill({'email': 'new@example.com', 'is_admin': true});

  // Enable strict mode to throw instead of silently discarding.
  try {
    account.fill({'is_admin': true}, strict: true);
  } on MassAssignmentException {
    // Handle mass assignment failures.
  }

  // Bypass guards for trusted code paths.
  account.forceFill({'is_admin': true});
}
// #endregion attributes-fill

// #region attributes-serialize
Map<String, Object?> serializationExample() {
  final account = $Account(id: 1, email: 'a@example.com', passwordHash: 'hash');

  // Hidden columns are excluded.
  final safe = account.toArray();

  // Hidden columns can be included, but only when they're explicitly visible.
  final internal = account.toArray(includeHidden: true);

  return {'safe': safe, 'internal': internal};
}

// #endregion attributes-serialize

// #region attributes-appends
Map<String, Object?> appendsExample() {
  final account = $Account(
    id: 2,
    email: 'User@Example.com',
    passwordHash: 'hash',
    name: 'User Name',
  );

  return account.toArray();
}
// #endregion attributes-appends
