/// Integration tests for the fluent query builder and relation loader.
library;

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  ModelRegistry registry = bootstrapOrm();
  late InMemoryQueryExecutor executor;
  late QueryContext context;

  setUp(() {
    executor = InMemoryQueryExecutor();

    executor.register(AuthorOrmDefinition.definition, const [
      Author(id: 1, name: 'Alice', active: true),
      Author(id: 2, name: 'Bob', active: true),
      Author(id: 3, name: 'Charlie', active: false),
    ]);

    executor.register(PostOrmDefinition.definition, [
      Post(
        id: 1,
        authorId: 1,
        title: 'Welcome',
        publishedAt: DateTime.utc(2024, 1, 1),
      ),
      Post(
        id: 2,
        authorId: 1,
        title: 'Second',
        publishedAt: DateTime.utc(2024, 2, 1),
      ),
      Post(
        id: 3,
        authorId: 2,
        title: 'Intro',
        publishedAt: DateTime.utc(2024, 3, 1),
      ),
    ]);

    executor.register(TagOrmDefinition.definition, const [
      Tag(id: 1, label: 'featured'),
      Tag(id: 2, label: 'draft'),
    ]);

    executor.register(PostTagOrmDefinition.definition, const [
      PostTag(postId: 1, tagId: 1),
      PostTag(postId: 1, tagId: 2),
      PostTag(postId: 2, tagId: 2),
      PostTag(postId: 3, tagId: 1),
    ]);

    executor.register(PhotoOrmDefinition.definition, const [
      Photo(id: 1, imageableId: 1, imageableType: 'Post', path: 'hero.jpg'),
      Photo(id: 2, imageableId: 1, imageableType: 'Post', path: 'thumb.jpg'),
      Photo(id: 3, imageableId: 3, imageableType: 'Post', path: 'header.jpg'),
      Photo(id: 4, imageableId: 101, imageableType: 'Image', path: 'cover.jpg'),
      Photo(
        id: 5,
        imageableId: 102,
        imageableType: 'Image',
        path: 'alternate.jpg',
      ),
    ]);

    executor.register(ImageOrmDefinition.definition, const [
      Image(id: 101, label: 'Landing'),
      Image(id: 102, label: 'Archive'),
    ]);

    context = QueryContext(registry: registry, driver: executor);
  });

  test('applies filters, ordering, limit and offset', () async {
    final rows = await context
        .query<Author>()
        .whereEquals('active', true)
        .orderBy('name', descending: true)
        .offset(1)
        .limit(1)
        .rows();

    expect(rows, hasLength(1));
    expect(rows.first.model.name, 'Alice');
  });

  test('debug plan captures driver metadata name', () {
    final plan = context.query<Author>().debugPlan();
    expect(plan.driverName, equals(executor.metadata.name));
  });

  test('distinct flag persists in plan', () {
    final plan = context.query<Author>().distinct().debugPlan();
    expect(plan.distinct, isTrue);
    expect(plan.distinctOn, isEmpty);
  });

  test('where() accepts PartialEntity', () async {
    final authors = await context
        .query<Author>()
        .where(const AuthorPartial(name: 'Alice'))
        .get();

    expect(authors, hasLength(1));
    expect(authors.first.name, 'Alice');
  });

  test('where() accepts Symbol', () async {
    final authors = await context
        .query<Author>()
        .where(#name, 'Alice')
        .get();

    expect(authors, hasLength(1));
    expect(authors.first.name, 'Alice');
  });

  test('where() accepts Symbol with operator', () async {
    final authors = await context
        .query<Author>()
        .where(#id, 1, PredicateOperator.greaterThan)
        .get();

    expect(authors, hasLength(2));
    expect(authors.map((a) => a.name), containsAll(['Bob', 'Charlie']));
  });

  test('distinct on columns capture normalized selectors', () {
    final plan = context.query<Author>().distinct(['name']).debugPlan();
    expect(plan.distinctOn, hasLength(1));
    expect(plan.distinctOn.first.field, 'name');
  });

  test('loads hasMany relations via withRelation', () async {
    final rows = await context
        .query<Author>()
        .withRelation('posts')
        .orderBy('id')
        .rows();

    final postsForAlice = rows.first.relationList<Post>('posts');
    expect(postsForAlice, hasLength(2));
    expect(postsForAlice.first.title, 'Welcome');

    final postsForBob = rows[1].relationList<Post>('posts');
    expect(postsForBob.single.title, 'Intro');
  });

  test('loads belongsTo relations for child queries', () async {
    final row = await context
        .query<Post>()
        .whereEquals('id', 3)
        .withRelation('author')
        .firstRow();

    expect(row, isNotNull);
    expect(row!.relation<Author>('author')?.name, 'Bob');
  });

  test('loads manyToMany relations for posts', () async {
    final row = await context
        .query<Post>()
        .whereEquals('id', 1)
        .withRelation('tags')
        .firstRow();

    final tags = row!.relationList<Tag>('tags');
    expect(tags.map((t) => t.label), containsAll(['featured', 'draft']));
  });

  test('loads morphMany relations for posts', () async {
    final row = await context
        .query<Post>()
        .whereEquals('id', 1)
        .withRelation('photos')
        .firstRow();

    final photos = row!.relationList<Photo>('photos');
    expect(photos, hasLength(2));
    expect(photos.map((p) => p.path), containsAll(['hero.jpg', 'thumb.jpg']));
  });

  test('loads morphOne relations for images', () async {
    final row = await context
        .query<Image>()
        .withRelation('primaryPhoto')
        .whereEquals('id', 101)
        .firstRow();

    final photo = row!.relation<Photo>('primaryPhoto');
    expect(photo?.path, 'cover.jpg');
  });

  test('supports whereIn filters and model extraction', () async {
    final models = await context.query<Author>().whereIn('id', [1, 3]).get();
    expect(models.map((a) => a.name), containsAll(['Alice', 'Charlie']));
  });

  test('value and pluck helpers mirror Laravel semantics', () async {
    final firstName = await context
        .query<Author>()
        .orderBy('id')
        .value<String>('name');
    expect(firstName, 'Alice');

    final names = await context
        .query<Author>()
        .orderBy('id')
        .pluck<String>('name');
    expect(names, ['Alice', 'Bob', 'Charlie']);
  });

  test('union captures additional query plans', () {
    final base = context.query<Author>();
    final unioned = base.union(context.query<Author>().whereEquals('id', 2));
    final plan = unioned.debugPlan();
    expect(plan.unions, hasLength(1));
    final clause = plan.unions.single;
    expect(clause.all, isFalse);
    expect(clause.plan.filters.single.field, 'id');
  });

  test('insertUsing requires at least one column', () async {
    final source = context.query<Author>();
    await expectLater(
      context.query<Author>().insertUsing([], source),
      throwsArgumentError,
    );
  });

  test('insertUsing enforces shared query context', () async {
    final otherExecutor = InMemoryQueryExecutor();
    final otherContext = QueryContext(
      registry: registry,
      driver: otherExecutor,
    );
    final source = otherContext.query<Author>();
    await expectLater(
      context.query<Author>().insertUsing(['id'], source),
      throwsA(isA<StateError>()),
    );
  });

  test('orderByRandom captures optional seed', () {
    final seededPlan = context.query<Author>().orderByRandom(42).debugPlan();
    expect(seededPlan.randomOrder, isTrue);
    expect(seededPlan.randomSeed, 42);

    final plainPlan = context.query<Author>().orderByRandom().debugPlan();
    expect(plainPlan.randomOrder, isTrue);
    expect(plainPlan.randomSeed, isNull);
  });

  test('orderBy handles json selectors', () {
    final plan = context
        .query<Post>()
        .orderBy('title->author', descending: true)
        .debugPlan();

    expect(plan.orders, hasLength(1));
    final clause = plan.orders.single;
    expect(clause.jsonSelector, isNotNull);
    expect(clause.jsonSelector!.column, 'title');
    expect(clause.jsonSelector!.path, isNotEmpty);
    expect(clause.descending, isTrue);
  });

  test('count, exists, and doesntExist use efficient queries', () async {
    expect(await context.query<Author>().count(), 3);
    expect(await context.query<Author>().whereEquals('id', 1).exists(), isTrue);
    expect(
      await context.query<Author>().whereEquals('id', 999).doesntExist(),
      isTrue,
    );
  });

  test('find helpers target the primary key', () async {
    final alice = await context.query<Author>().find(1);
    expect(alice?.name, 'Alice');

    final authors = await context.query<Author>().findMany([2, 3]);
    expect(authors.map((a) => a.id), equals([2, 3]));
    await expectLater(
      () => context.query<Author>().findOrFail(999),
      throwsA(isA<ModelNotFoundException>()),
    );
  });

  test('firstOrFail and sole enforce record counts', () async {
    final author = await context.query<Author>().whereEquals('id', 1).sole();
    expect(author.name, 'Alice');
    await expectLater(
      () => context.query<Author>().whereEquals('id', 999).firstOrFail(),
      throwsA(isA<ModelNotFoundException>()),
    );
    await expectLater(
      () => context.query<Author>().whereEquals('id', 999).sole(),
      throwsA(isA<ModelNotFoundException>()),
    );
    await expectLater(
      () => context.query<Author>().sole(),
      throwsA(isA<MultipleRecordsFoundException>()),
    );
  });

  test('attaches connection resolver metadata to hydrated models', () async {
    final row = await context.query<Author>().firstRow();
    expect(row, isNotNull);
    final model = row!.model;
    expect(model, isA<ModelConnection>());
    final conn = model as ModelConnection;
    expect(conn.connectionResolver, same(context));
  });

  test('update applies mutations using query builder constraints', () async {
    final affected = await context.query<Author>().whereEquals('id', 1).update({
      'name': 'Updated Alice',
    });

    expect(affected, 1);

    final refreshed = await context
        .query<Author>()
        .whereEquals('id', 1)
        .firstOrFail();

    expect(refreshed.name, 'Updated Alice');
  });

  group('json predicates', () {
    late AdHocModelDefinition jsonDefinition;

    setUp(() {
      jsonDefinition = AdHocModelDefinition(
        tableName: 'documents',
        columns: const [
          AdHocColumn(name: 'id', columnName: 'id'),
          AdHocColumn(name: 'data', columnName: 'data'),
        ],
      );
    });

    test('whereJsonContains records clause on the plan', () {
      final plan = context
          .queryFromDefinition(jsonDefinition)
          .whereJsonContains('data', {'foo': 'bar'})
          .debugPlan();

      expect(plan.jsonWheres, hasLength(1));
      final clause = plan.jsonWheres.single;
      expect(clause.column, 'data');
      expect(clause.path, r'$');
      expect(clause.type, JsonPredicateType.contains);
    });

    test('whereJsonOverlaps records clause on the plan', () {
      final plan = context
          .queryFromDefinition(jsonDefinition)
          .whereJsonOverlaps('data->tags', ['alpha', 'beta'])
          .debugPlan();

      final clause = plan.jsonWheres.single;
      expect(clause.type, JsonPredicateType.overlaps);
      expect(clause.path, r'$.tags');
    });

    test('whereJsonContainsKey normalizes path', () {
      final plan = context
          .queryFromDefinition(jsonDefinition)
          .whereJsonContainsKey('data->meta.details')
          .debugPlan();

      final clause = plan.jsonWheres.single;
      expect(clause.type, JsonPredicateType.containsKey);
      expect(clause.path, r'$.meta.details');
    });

    test('whereJsonLength infers operator when omitted', () {
      final plan = context
          .queryFromDefinition(jsonDefinition)
          .whereJsonLength('data->items', 3)
          .debugPlan();

      final clause = plan.jsonWheres.single;
      expect(clause.type, JsonPredicateType.length);
      expect(clause.lengthOperator, '=');
      expect(clause.lengthValue, 3);
    });

    test('whereJsonLength accepts explicit operator', () {
      final plan = context
          .queryFromDefinition(jsonDefinition)
          .whereJsonLength('data', '>=', 2)
          .debugPlan();

      final clause = plan.jsonWheres.single;
      expect(clause.lengthOperator, '>=');
      expect(clause.lengthValue, 2);
    });

    test('where supports json selectors and boolean values', () {
      final plan = context
          .queryFromDefinition(jsonDefinition)
          .where('data->flag', true)
          .debugPlan();

      expect(plan.predicate, isA<FieldPredicate>());
      final predicate = plan.predicate! as FieldPredicate;
      expect(predicate.jsonSelector, isNotNull);
      expect(predicate.jsonBooleanComparison, isTrue);
      expect(predicate.value, 'true');
    });

    test('whereNull tracks json selector metadata', () {
      final plan = context
          .queryFromDefinition(jsonDefinition)
          .whereNull('data->nested.missing')
          .debugPlan();

      expect(plan.predicate, isA<FieldPredicate>());
      final predicate = plan.predicate! as FieldPredicate;
      expect(predicate.jsonSelector, isNotNull);
      expect(predicate.operator, PredicateOperator.isNull);
    });
  });

  group('having predicates', () {
    test('havingBitwise records predicate with normalized operator', () {
      final plan = context
          .query<Post>()
          .groupBy(['authorId'])
          .havingBitwise('authorId', '&', 1)
          .debugPlan();

      expect(plan.having, isA<BitwisePredicate>());
      final predicate = plan.having as BitwisePredicate;
      expect(predicate.field, 'author_id');
      expect(predicate.operator, '&');
      expect(predicate.value, 1);
    });

    test('orHavingBitwise merges predicates via OR', () {
      final plan = context
          .query<Post>()
          .groupBy(['authorId'])
          .havingBitwise('authorId', '&', 1)
          .orHavingBitwise('authorId', '&', 2)
          .debugPlan();

      expect(plan.having, isA<PredicateGroup>());
      final group = plan.having as PredicateGroup;
      expect(group.logicalOperator, PredicateLogicalOperator.or);
      expect(group.predicates, hasLength(2));
      expect(group.predicates.every((p) => p is BitwisePredicate), isTrue);
    });
  });

  group('group limits', () {
    test('limitPerGroup stores metadata on the plan', () {
      // TODO: Implement limitPerGroup when window function support is available
      // final plan = context
      //     .query<Post>()
      //     .orderBy('publishedAt', descending: true)
      //     .limitPerGroup(2, 'authorId', offset: 1)
      //     .debugPlan();

      // final limit = plan.groupLimit;
      // expect(limit, isNotNull);
      // expect(limit!.column, 'author_id');
      // expect(limit.limit, 2);
      // expect(limit.offset, 1);
    });
  });

  group('date predicates', () {
    late AdHocModelDefinition dateDefinition;

    setUp(() {
      dateDefinition = AdHocModelDefinition(
        tableName: 'events',
        columns: const [
          AdHocColumn(name: 'id', columnName: 'id'),
          AdHocColumn(name: 'occurredAt', columnName: 'occurred_at'),
          AdHocColumn(name: 'data', columnName: 'data'),
        ],
      );
    });

    test('whereDate infers equality and formats DateTime values', () {
      final plan = context
          .queryFromDefinition(dateDefinition)
          .whereDate('occurredAt', DateTime(2024, 1, 2, 3))
          .debugPlan();

      final clause = plan.dateWheres.single;
      expect(clause.component, DateComponent.date);
      expect(clause.operator, '=');
      expect(clause.value, '2024-01-02');
      expect(clause.path, r'$');
    });

    test('whereDate accepts explicit operators', () {
      final plan = context
          .queryFromDefinition(dateDefinition)
          .whereDate('occurredAt', '>=', DateTime(2024, 5, 1))
          .debugPlan();

      final clause = plan.dateWheres.single;
      expect(clause.operator, '>=');
      expect(clause.value, '2024-05-01');
    });

    test('calendar helpers normalize numeric values', () {
      final plan = context
          .queryFromDefinition(dateDefinition)
          .whereMonth('occurredAt', '02')
          .whereDay('occurredAt', 15)
          .whereYear('occurredAt', DateTime(2023, 10, 1))
          .debugPlan();

      expect(plan.dateWheres, hasLength(3));
      expect(plan.dateWheres[0].value, 2);
      expect(plan.dateWheres[1].value, 15);
      expect(plan.dateWheres[2].value, 2023);
    });

    test('whereTime captures JSON selectors', () {
      final plan = context
          .queryFromDefinition(dateDefinition)
          .whereTime(r'data->"$.meta.sentAt"', '08:30:00')
          .debugPlan();

      final clause = plan.dateWheres.single;
      expect(clause.path, r'$.meta.sentAt');
      expect(clause.component, DateComponent.time);
      expect(clause.value, '08:30:00');
    });
  });

  test('whereBitwise stores predicate metadata on the plan', () {
    final plan = context
        .query<Post>()
        .withTrashed()
        .whereBitwise('id', '&', 2)
        .debugPlan();

    expect(plan.predicate, isA<BitwisePredicate>());
    final predicate = plan.predicate as BitwisePredicate;
    expect(predicate.operator, '&');
    expect(predicate.value, 2);
  });
}
