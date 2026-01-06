// ignore_for_file: unused_element

import 'package:ormed/ormed.dart';

import 'models/post.dart';
import 'models/tag.dart';
import 'models/user.dart';

const RelationDefinition _badPivotRelation = RelationDefinition(
  name: 'tags',
  kind: RelationKind.manyToMany,
  targetModel: 'Tag',
  pivotColumns: ['missing_pivot'],
  pivotModel: 'PostTag',
);

/// Intentionally invalid patterns for the Ormed analyzer plugin.
///
/// Open this file in the IDE to verify diagnostics are reported.
void _ormedAnalyzerWarningSamples() {
  final postQuery = Model.query<Post>();
  final userQuery = Model.query<User>();
  final repo = Model.repository<Post>();
  const title = 'Hello';
  const user = User(email: 'test@example.com', name: 'Test User');
  const tag = Tag(id: 1, name: 'ormed');

  // Unknown field/column names.
  postQuery.where('missing_field', true);
  postQuery.whereColumn('title', 'missing_column');

  // Unknown select fields + duplicates.
  postQuery.select(['missing_select']);
  postQuery.select(['title', 'title']);

  // Unknown order/group/having fields.
  postQuery.orderBy('missing_order');
  postQuery.groupBy(['missing_group']);
  postQuery.having('missing_having', PredicateOperator.equals, 1);

  // Type mismatch warnings.
  postQuery.whereEquals('userId', 'not_an_int');
  postQuery.whereIn('userId', ['not_an_int']);
  postQuery.whereBetween('userId', 'a', 'z');

  // Unknown relation names.
  postQuery.withRelation('missingRelation');
  postQuery.whereHas('missingRelation');

  // Unknown nested relation.
  postQuery.withRelation('comments.missingRelation');

  // Relation callback field mismatch.
  postQuery.whereHas('comments', (q) => q.where('email', 'oops'));

  // Typed predicate field that does not exist on the model.
  postQuery.whereTyped((q) => q.legacy.eq('oops'));

  // Soft delete and timestamps warnings.
  userQuery.withTrashed();
  user.withoutTimestamps(() {});
  tag.updatedAt;

  // Query safety warnings.
  postQuery.update({'title': 'updated'});
  postQuery.delete();
  postQuery.offset(10);
  postQuery.limit(10);
  postQuery.get();
  postQuery.rows();
  postQuery.getPartial(PostPartial.fromRow);
  Posts.all();
  Model.all<Post>();
  ModelCompanion<Post>().all();

  // Raw SQL interpolation without bindings.
  postQuery.whereRaw('title = $title');

  // Raw SQL alias missing.
  postQuery.selectRaw('count(*)');

  // DTO warnings.
  repo.insert(PostInsertDto());
  repo.update(PostUpdateDto(title: 'updated'));
}

extension _PostPredicateExtras on PredicateBuilder<Post> {
  PredicateField<Post, String> get legacy =>
      PredicateField<Post, String>(this, 'legacy');
}
