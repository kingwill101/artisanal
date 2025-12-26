/// Repository APIs for querying and mutating Ormed models.
///
/// The [Repository] type provides a model-centric façade over Ormed's [Query]
/// builder and mutation planning APIs.
library;

import 'package:ormed/src/model/model.dart';

import '../contracts.dart';
import '../driver/driver.dart';
import '../events/event_bus.dart';
import '../mutation/json_update.dart';
import '../mutation/mutation_input_helper.dart';
import '../query/query.dart';
import '../value_codec.dart';

part 'repository_delete_mixin.dart';
part 'repository_helpers_mixin.dart';
part 'repository_input_handler.dart';
// Part files for repository mixins
part 'repository_insert_mixin.dart';
part 'repository_preview_mixin.dart';
part 'repository_read_mixin.dart';
part 'repository_update_mixin.dart';
part 'repository_upsert_mixin.dart';

/// Base class for repositories.
///
/// This abstract class provides the core dependencies and accessors that all
/// repository mixins require.
abstract class RepositoryBase<T extends OrmEntity> {
  ModelDefinition<T> get definition;

  String get driverName;

  ValueCodecRegistry get codecs;

  Future<MutationResult> Function(MutationPlan plan) get runMutation;

  StatementPreview Function(MutationPlan plan) get describeMutation;

  void Function(Object? model) get attachRuntimeMetadata;

  QueryContext? get queryContext;
}

/// A repository for a model of type [T].
///
/// {@template ormed.repository}
/// CRUD helpers for a single model type.
///
/// Reads delegate to the [Query] builder. Writes build [MutationPlan] objects
/// that are executed by the active driver.
///
/// Obtain a repository from `DataSource.repo<T>()`,
/// `QueryContext.repository<T>()`, or `Model.repository<T>()`.
///
/// ```dart
/// final repo = dataSource.repo<$User>();
///
/// final inserted = await repo.insert(
///   $UserInsertDto(email: 'john@example.com'),
/// );
///
/// final updated = await repo.update(
///   $UserUpdateDto(name: 'John'),
///   where: {'id': inserted.id},
/// );
///
/// final exists = await repo.exists(where: {'email': 'john@example.com'});
/// ```
/// {@endtemplate}
///
/// {@macro ormed.repository}
///
/// Provides methods for inserting, updating, upserting and deleting models.
/// The repository is composed of several mixins, each providing a specific
/// set of operations:
///
/// - [RepositoryInsertMixin] - Insert operations
/// - [RepositoryUpdateMixin] - Update operations
/// - [RepositoryUpsertMixin] - Upsert operations
/// - [RepositoryDeleteMixin] - Delete operations
/// - [RepositoryPreviewMixin] - Preview methods for all operations
/// - [RepositoryHelpersMixin] - Internal helper methods
class Repository<T extends OrmEntity> extends RepositoryBase<T>
    with
        RepositoryInputHandlerMixin<T>,
        RepositoryHelpersMixin<T>,
        RepositoryInsertMixin<T>,
        RepositoryUpdateMixin<T>,
        RepositoryUpsertMixin<T>,
        RepositoryDeleteMixin<T>,
        RepositoryPreviewMixin<T>,
        RepositoryReadMixin<T> {
  Repository({
    required ModelDefinition<T> definition,
    required String driverName,
    required Future<MutationResult> Function(MutationPlan plan) runMutation,
    required StatementPreview Function(MutationPlan plan) describeMutation,
    required void Function(Object? model) attachRuntimeMetadata,
    QueryContext? context,
  }) : assert(
         context != null,
         'Repository now delegates entirely to the query builder and requires a QueryContext. '
         'Construct via QueryContext.repository() or Model.repository(connection: ...).',
       ),
       _definition = definition,
       _driverName = driverName,
       _runMutation = runMutation,
       _describeMutation = describeMutation,
       _attachRuntimeMetadata = attachRuntimeMetadata,
       _queryContext = context;

  final ModelDefinition<T> _definition;
  final String _driverName;
  final Future<MutationResult> Function(MutationPlan plan) _runMutation;
  final StatementPreview Function(MutationPlan plan) _describeMutation;
  final void Function(Object? model) _attachRuntimeMetadata;
  final QueryContext? _queryContext;

  @override
  ModelDefinition<T> get definition => _definition;

  @override
  String get driverName => _driverName;

  @override
  ValueCodecRegistry get codecs =>
      _queryContext?.codecRegistry ??
      ValueCodecRegistry.instance.forDriver(_driverName);

  @override
  Future<MutationResult> Function(MutationPlan plan) get runMutation =>
      _runMutation;

  @override
  StatementPreview Function(MutationPlan plan) get describeMutation =>
      _describeMutation;

  @override
  void Function(Object? model) get attachRuntimeMetadata =>
      _attachRuntimeMetadata;

  @override
  QueryContext? get queryContext => _queryContext;
}
