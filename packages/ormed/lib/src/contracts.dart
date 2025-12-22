library;

/// Marker interface for ORM-managed entities and generated tracked models.
///
/// This interface serves as the base type constraint for all ORM operations.
/// Generated tracked models (`$Model`) implement this interface, allowing
/// repositories and query builders to safely accept a wide variety of inputs
/// while maintaining type safety.
///
/// ## Usage
///
/// You typically don't implement this interface directly. Instead, it's
/// automatically implemented by:
/// - Generated tracked models (`$Model`)
/// - Generated DTOs (`$ModelInsertDto`, `$ModelUpdateDto`)
/// - Generated partials (`$ModelPartial`)
/// - Ad-hoc query result types (`AdHocRow`)
///
/// This allows repository methods like `insert()`, `update()`, and `upsert()`
/// to accept various input types (tracked models, DTOs, or raw maps) while
/// maintaining compile-time type safety.
///
/// ## Example
///
/// ```dart
/// // All of these work because they satisfy OrmEntity bounds:
/// await repository.insert($User(name: 'Alice', email: 'alice@example.com'));
/// await repository.insert($UserInsertDto(name: 'Bob', email: 'bob@example.com'));
/// await context.query<$User>().where('active', true).get();
/// ```
///
/// Note: This class intentionally does **not** have the `@immutable` annotation
/// to allow models with non-final relation fields (e.g., for lazy loading patterns).
/// Generated tracked models manage mutable state internally via [Expando].
abstract class OrmEntity {
  const OrmEntity();
}

/// Represents insertable data for an ORM entity.
///
/// Generated `$ModelInsertDto` classes implement this interface. Insert DTOs
/// have the following characteristics:
///
/// - **Nullable/optional fields**: Fields that have database defaults (like
///   auto-increment primary keys) or nullable columns are optional in the DTO.
/// - **Required fields**: Non-nullable columns without defaults must be provided.
/// - **Column-name keys**: The `toMap()` method returns a map with database
///   column names as keys (not Dart field names).
///
/// ## Example
///
/// ```dart
/// // Generated InsertDto - id is optional (auto-increment)
/// final dto = $UserInsertDto(
///   name: 'Alice',
///   email: 'alice@example.com',
///   // id is auto-generated, so not required
/// );
///
/// await repository.insert(dto);
/// ```
///
/// ## When to Use
///
/// Use `InsertDto` when:
/// - You want compile-time validation of insert data
/// - You don't need the overhead of a full tracked model
/// - You want to clearly express insert intent in your API
abstract class InsertDto<T extends OrmEntity> {
  /// Converts this DTO to a map suitable for database insertion.
  ///
  /// Returns a map with column names as keys. Only non-null/provided
  /// fields should be included.
  Map<String, Object?> toMap();
}

/// Represents updatable data for an ORM entity.
///
/// Generated `$ModelUpdateDto` classes implement this interface. Update DTOs
/// have the following characteristics:
///
/// - **All fields optional**: Every field is nullable/optional because updates
///   typically only modify a subset of columns.
/// - **Only provided fields updated**: The `toMap()` method only includes
///   fields that were explicitly set, allowing partial updates.
/// - **Column-name keys**: The `toMap()` method returns a map with database
///   column names as keys.
///
/// ## Example
///
/// ```dart
/// // Generated UpdateDto - only update specific fields
/// final dto = $UserUpdateDto(
///   email: 'newemail@example.com',
///   // Other fields like name remain unchanged
/// );
///
/// await repository.update(dto, where: {'id': 1});
/// ```
///
/// ## When to Use
///
/// Use `UpdateDto` when:
/// - You want to update only specific fields without affecting others
/// - You want compile-time validation of update data
/// - You want to clearly express update intent in your API
abstract class UpdateDto<T extends OrmEntity> {
  /// Converts this DTO to a map suitable for database updates.
  ///
  /// Returns a map with column names as keys. Only fields that were
  /// explicitly set should be included, allowing partial updates.
  Map<String, Object?> toMap();
}

/// Partial projection of an ORM entity where all fields are nullable.
///
/// Generated `$ModelPartial` classes implement this interface. Partials are
/// used when queries select only a subset of columns, ensuring type safety
/// while acknowledging that some fields may be missing.
///
/// ## Characteristics
///
/// - **All fields nullable**: Every field is nullable because the query might
///   not have selected all columns.
/// - **toEntity() validation**: The `toEntity()` method attempts to convert
///   the partial into a full entity, throwing `StateError` if required fields
///   are missing.
/// - **Query result hydration**: Subset selects automatically hydrate into
///   partial types rather than full tracked models.
///
/// ## Example
///
/// ```dart
/// // Select only specific columns - returns partials
/// final partials = await context.query<$User>()
///     .select(['id', 'name'])
///     .get();
///
/// for (final partial in partials) {
///   print(partial.id);    // Available
///   print(partial.name);  // Available
///   print(partial.email); // null - not selected
///
///   // Convert to full entity if all required fields present
///   try {
///     final user = partial.toEntity();
///   } on StateError catch (e) {
///     print('Missing required fields: $e');
///   }
/// }
/// ```
///
/// ## When to Use
///
/// Partials are automatically used when:
/// - You use `.select()` to fetch specific columns
/// - You use aggregate projections that don't include all columns
///
/// Use `toEntity()` when you need to convert a partial back to a full
/// entity, but be prepared to handle `StateError` if required fields
/// were not selected.
abstract class PartialEntity<T extends OrmEntity> {
  const PartialEntity();

  /// Convert this partial into a full entity.
  ///
  /// Validates that all required (non-nullable) fields are present.
  ///
  /// Throws [StateError] if any required field is null/missing. The error
  /// message should indicate which required fields are missing.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final partial = $UserPartial(id: 1, name: 'Alice', email: null);
  ///
  /// try {
  ///   final user = partial.toEntity();
  /// } on StateError catch (e) {
  ///   // "Required field 'email' is null on UserPartial"
  ///   print(e.message);
  /// }
  /// ```
  T toEntity();

  /// Converts this partial to a map with column names as keys.
  ///
  /// Only non-null fields are included in the returned map.
  /// This is useful for building WHERE clauses from partial instances.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final partial = $UserPartial(id: 1, email: 'alice@example.com');
  /// final map = partial.toMap();
  /// // {'id': 1, 'email': 'alice@example.com'}
  /// ```
  Map<String, Object?> toMap();
}
