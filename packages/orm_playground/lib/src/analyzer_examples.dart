// ignore_for_file: unused_element

import 'package:ormed/ormed.dart';

import 'models/post.dart';

/// Intentionally invalid patterns for the Ormed analyzer plugin.
///
/// Open this file in the IDE to verify diagnostics are reported.
void _ormedAnalyzerWarningSamples() {
  final query = Model.query<Post>();
  const title = 'Hello';

  // Unknown field/column names.
  query.where('missing_field', true);
  query.whereColumn('title', 'missing_column');
  query.orderBy('not_a_real_field');

  // Unknown relation names.
  query.withRelation('missingRelation');
  query.whereHas('missingRelation');

  // Typed predicate field that does not exist on the model.
  query.whereTyped((q) => q.legacy.eq('oops'));

  // Raw SQL interpolation without bindings.
  query.whereRaw('title = $title');
}

extension _PostPredicateExtras on PredicateBuilder<Post> {
  PredicateField<Post, String> get legacy =>
      PredicateField<Post, String>(this, 'legacy');
}
