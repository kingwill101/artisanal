// JSON query + update snippets.
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

part 'json.orm.dart';

// #region json-model-field
@OrmModel(table: 'users')
class User extends Model<User> {
  const User({required this.id, required this.email, this.metadata});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;

  // Use the built-in `json` cast key for JSON objects.
  @OrmField(cast: 'json')
  final Map<String, Object?>? metadata;
}
// #endregion json-model-field

// #region json-where-json-helpers
Future<List<User>> jsonWhereHelpers(DataSource dataSource) {
  return dataSource
      .query<$User>()
      .whereJsonContains('metadata', 'Dart', path: r'$.skills')
      .whereJsonContainsKey('metadata', r'$.flags')
      .whereJsonLength('metadata->tags', '>=', 2)
      .whereJsonOverlaps('metadata->skills', ['Dart', 'Go'])
      .get();
}
// #endregion json-where-json-helpers

// #region json-where-selector-syntax
Future<List<User>> jsonWhereSelectorSyntax(DataSource dataSource) {
  return dataSource
      .query<$User>()
      // `->` extracts JSON, `->>` extracts text for comparisons/sorting.
      // If you include `$.path` in a Dart string, prefer raw strings `r'...'`.
      .where(r'metadata->>$.mode', 'dark')
      // You can also omit the `$` prefix (`mode` normalizes to `$.mode`).
      .where('metadata->>mode', 'dark')
      .where(r'metadata->$.featured', true)
      .orderBy('metadata->>createdBy')
      .get();
}
// #endregion json-where-selector-syntax

// #region json-where-indexing
Future<List<User>> jsonWhereIndexing(DataSource dataSource) {
  return dataSource
      .query<$User>()
      // Array index addressing: `items[1]` and `items.1` are equivalent.
      .where(r'metadata->>$.meta.profile.items[1].label', 'b')
      .where(r'metadata->>$.meta.profile.items.1.label', 'b')
      // Numeric object keys are different: use bracket quoting.
      .whereJsonContainsKey('metadata', r'$.items["0"]')
      .get();
}
// #endregion json-where-indexing

// #region json-update-query
Future<void> jsonUpdateQuery(DataSource dataSource) async {
  await dataSource.query<$User>().whereEquals('id', 1).update(
    {'email': 'updated@example.com'},
    jsonUpdates: (_) => [
      JsonUpdateDefinition.path('metadata', r'$.meta.count', 5),
      JsonUpdateDefinition.selector('metadata->mode', 'light'),
      // Update JSON array elements (both forms normalize the same way).
      JsonUpdateDefinition.path(
        'metadata',
        r'$.meta.profile.items[1].label',
        'b2',
      ),
      JsonUpdateDefinition.path(
        'metadata',
        r'$.meta.profile.items.0.label',
        'a2',
      ),
      JsonUpdateDefinition.patch('metadata', {
        'flags': {'beta': true},
      }),
    ],
  );
}
// #endregion json-update-query

// #region json-update-model
Future<void> jsonUpdateModel($User user) async {
  // Queue JSON updates on the tracked model, then save.
  user.jsonSetPath('metadata', r'$.meta.count', 5);
  user.jsonSet('metadata->mode', 'light');
  user.jsonSetPath('metadata', r'$.meta.profile.items.0.label', 'a2');
  user.jsonPatch('metadata', {
    'flags': {'beta': true},
  });
  await user.save();
}

// #endregion json-update-model
