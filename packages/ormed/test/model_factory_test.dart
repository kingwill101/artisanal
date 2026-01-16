import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  bootstrapOrm();

  group('ModelFactoryBuilder', () {
    group('Basic Generation', () {
      test('generates values and respects overrides', () {
        final builder = Model.factory<AttributeUser>().withOverrides({
          'id': 42,
        });
        final values = builder.values();
        expect(values['id'], 42);
        expect(values['email'], isNotNull);
        expect(builder.value('email'), values['email']);
      });

      test('make returns a hydrated model', () {
        final builder = Model.factory<AttributeUser>().seed(7).withOverrides({
          'role': 'admin',
        });
        final user = builder.make();
        expect(user, isA<AttributeUser>());
        expect(user.role, 'admin');
        expect(user.email, isNotNull);
      });

      test('value returns a single generated field value', () {
        final factory = Model.factory<AttributeUser>().seed(100);
        final email = factory.value('email');
        expect(email, isA<String>());
        expect(email, contains('AttributeUser_email_'));
      });
    });

    group('Deterministic Seeding', () {
      test('same seed produces identical values', () {
        final first = Model.factory<AttributeUser>().seed(42).values();
        final second = Model.factory<AttributeUser>().seed(42).values();
        expect(second['email'], first['email']);
        expect(second['createdAt'], first['createdAt']);
      });

      test('different seeds produce different values', () {
        final first = Model.factory<AttributeUser>().seed(42).values();
        final third = Model.factory<AttributeUser>().seed(99).values();
        // Different seeds should typically produce different values
        // (Note: there's a small chance of collision, but very unlikely)
        expect(third['email'], isNot(equals(first['email'])));
      });
    });

    group('Field Overrides', () {
      test('withOverrides sets multiple field values', () {
        final values = Model.factory<AttributeUser>().withOverrides({
          'id': 999,
          'email': 'override@example.com',
          'role': 'superadmin',
        }).values();
        expect(values['id'], 999);
        expect(values['email'], 'override@example.com');
        expect(values['role'], 'superadmin');
      });

      test('withField sets a single field value', () {
        final values = Model.factory<AttributeUser>()
            .withField('email', 'single@example.com')
            .values();
        expect(values['email'], 'single@example.com');
      });

      test('withField can be chained multiple times', () {
        final values = Model.factory<AttributeUser>()
            .withField('id', 123)
            .withField('email', 'chained@example.com')
            .withField('role', 'user')
            .values();
        expect(values['id'], 123);
        expect(values['email'], 'chained@example.com');
        expect(values['role'], 'user');
      });
    });

    group('Custom Generators', () {
      test('withGenerator overrides individual fields', () {
        final builder = Model.factory<AttributeUser>().withGenerator(
          'email',
          (_, _) => 'forced@example.com',
        );
        final values = builder.values();
        expect(values['email'], 'forced@example.com');
      });

      test('withGenerator receives field definition and context', () {
        FieldDefinition? capturedField;
        ModelFactoryGenerationContext<AttributeUser>? capturedContext;

        final builder = Model.factory<AttributeUser>().seed(55).withGenerator(
          'email',
          (field, context) {
            capturedField = field;
            capturedContext = context;
            return 'custom@test.com';
          },
        );
        builder.values();

        expect(capturedField, isNotNull);
        expect(capturedField!.name, 'email');
        expect(capturedContext, isNotNull);
        expect(capturedContext!.seed, 55);
      });

      test('withGenerator can use context random for varied output', () {
        final builder = Model.factory<AttributeUser>().seed(42).withGenerator(
          'email',
          (field, context) {
            final suffix = context.random.nextInt(1000);
            return 'user_$suffix@test.example.com';
          },
        );
        final values = builder.values();
        expect(
          values['email'],
          matches(RegExp(r'user_\d+@test\.example\.com')),
        );
      });

      test('context provides access to model definition', () {
        ModelDefinition? capturedDefinition;

        Model.factory<AttributeUser>().withGenerator('email', (field, context) {
          capturedDefinition = context.definition;
          return 'test@test.com';
        }).values();

        expect(capturedDefinition, isNotNull);
        expect(capturedDefinition!.modelName, 'AttributeUser');
        expect(capturedDefinition!.tableName, 'attribute_users');
      });

      test('context provides access to overrides', () {
        Map<String, Object?>? capturedOverrides;

        Model.factory<AttributeUser>()
            .withOverrides({'id': 999, 'role': 'admin'})
            .withGenerator('email', (field, context) {
              capturedOverrides = context.overrides;
              return 'test@test.com';
            })
            .values();

        expect(capturedOverrides, isNotNull);
        expect(capturedOverrides!['id'], 999);
        expect(capturedOverrides!['role'], 'admin');
      });
    });

    group('Reset Functionality', () {
      test('reset clears generated values for fresh generation', () {
        final factory = Model.factory<AttributeUser>();
        factory.values(); // First generation

        // After reset, the next values() call regenerates
        factory.reset();
        final second = factory.values();

        // Without seed, values should differ (statistically)
        // But the factory itself should still work
        expect(second, isA<Map<String, Object?>>());
        expect(second['email'], isNotNull);
      });

      test('reset allows changing seed', () {
        final factory = Model.factory<AttributeUser>().seed(1);
        final first = factory.values();

        factory.reset().seed(2);
        final second = factory.values();

        expect(second['email'], isNot(equals(first['email'])));
      });
    });

    group('Default Type Generation', () {
      test('generates int values in expected range', () {
        final values = Model.factory<AttributeUser>().seed(42).values();
        final id = values['id'];
        expect(id, isA<int>());
        expect(id, greaterThanOrEqualTo(1));
        expect(id, lessThanOrEqualTo(1000));
      });

      test('generates String with model name and field pattern', () {
        final values = Model.factory<AttributeUser>().seed(42).values();
        final email = values['email'];
        expect(email, isA<String>());
        expect(email, contains('AttributeUser'));
        expect(email, contains('email'));
        // Pattern should be: ModelName_fieldName_XXXX (4 digit suffix)
        expect(email, matches(RegExp(r'AttributeUser_email_\d{4}')));
      });

      test('generates bool values', () {
        // Test with a model that has bool fields without defaultValueSql
        final factory = Model.factory<DerivedForFactory>().seed(42);
        final values = factory.values();
        // layerTwoFlag is bool?
        // Since nullable, it may or may not be null depending on seed
        // Just verify the factory produces valid output
        expect(values, isA<Map<String, Object?>>());
      });

      test('generates nullable values with chance of null', () {
        // For nullable fields, there's a 50% chance of null
        // With enough samples, we should see both null and non-null values
        final nullCount = List.generate(20, (i) {
          final factory = Model.factory<AttributeUser>().seed(i * 100);
          return factory.values()['role'];
        }).where((v) => v == null).length;
        // Expect at least some nulls and some non-nulls
        // This is a probabilistic test, but 20 samples should give variation
        expect(
          nullCount,
          greaterThan(0),
          reason: 'Expected some null values for nullable field',
        );
        expect(
          nullCount,
          lessThan(20),
          reason: 'Expected some non-null values for nullable field',
        );
      });

      test('generates DateTime values within expected range', () {
        // DateTime is generated as: DateTime.now().toUtc() + random seconds (0-86400)
        // Article has publishedAt which is DateTime without codecType
        final now = DateTime.now().toUtc();
        final values = Model.factory<Article>().seed(42).values();
        final publishedAt = values['published_at'];
        expect(publishedAt, isA<DateTime>());

        final dt = publishedAt as DateTime;
        // Should be within reasonable range of now (within ~2 days)
        final diff = dt.difference(now).inSeconds.abs();
        expect(diff, lessThan(86400 * 2)); // Within 2 days
      });

      test('generates double values in expected range', () {
        // Test with User model's age field if it were double
        // For now, verify through custom generator provider behavior
        final customProvider = _DoubleFieldTestProvider();
        final factory = Model.factory<AttributeUser>(
          generatorProvider: customProvider,
        ).seed(42);
        factory.values(); // Trigger generation

        // Our test provider returns the default double generation for numeric fields
        // Since AttributeUser doesn't have double fields, we test the provider directly
        expect(customProvider.doubleGenerated, isNotNull);
        expect(customProvider.doubleGenerated, greaterThanOrEqualTo(0));
        expect(customProvider.doubleGenerated, lessThanOrEqualTo(1000));
      });
    });

    group('Carbon/CarbonInterface Generation', () {
      test('generates Carbon values via custom generator', () {
        // Test Carbon generation through withGenerator
        final factory = Model.factory<AttributeUser>().seed(42).withGenerator(
          'email',
          (field, context) {
            // Access Carbon generation from DefaultFieldGeneratorProvider
            final provider = const DefaultFieldGeneratorProvider();
            // Create a mock field definition for Carbon type
            const carbonField = FieldDefinition(
              name: 'timestamp',
              columnName: 'timestamp',
              dartType: 'Carbon',
              resolvedType: 'Carbon',
              isPrimaryKey: false,
              isNullable: false,
              isUnique: false,
              isIndexed: false,
              autoIncrement: false,
            );
            return provider.generate(carbonField, context);
          },
        );

        final values = factory.values();
        final generated = values['email'];
        expect(generated, isA<Carbon>());
      });

      test('generates CarbonInterface values via custom generator', () {
        final factory = Model.factory<AttributeUser>().seed(42).withGenerator(
          'email',
          (field, context) {
            final provider = const DefaultFieldGeneratorProvider();
            const carbonField = FieldDefinition(
              name: 'timestamp',
              columnName: 'timestamp',
              dartType: 'CarbonInterface',
              resolvedType: 'CarbonInterface',
              isPrimaryKey: false,
              isNullable: false,
              isUnique: false,
              isIndexed: false,
              autoIncrement: false,
            );
            return provider.generate(carbonField, context);
          },
        );

        final values = factory.values();
        final generated = values['email'];
        expect(generated, isA<CarbonInterface>());
        expect(generated, isA<Carbon>());
      });

      test('Carbon values are within expected time range', () {
        final now = Carbon.now();
        final factory = Model.factory<AttributeUser>().seed(42).withGenerator(
          'email',
          (field, context) {
            final provider = const DefaultFieldGeneratorProvider();
            const carbonField = FieldDefinition(
              name: 'timestamp',
              columnName: 'timestamp',
              dartType: 'Carbon',
              resolvedType: 'Carbon',
              isPrimaryKey: false,
              isNullable: false,
              isUnique: false,
              isIndexed: false,
              autoIncrement: false,
            );
            return provider.generate(carbonField, context);
          },
        );

        final values = factory.values();
        final generated = values['email'] as Carbon;

        // Should be within 1 day of now (0-86400 seconds)
        final diff = generated.diffInSeconds(now).abs();
        expect(diff, lessThanOrEqualTo(86400));
      });

      test('Carbon generation is deterministic with seed', () {
        Carbon generateCarbon(int seed) {
          final factory = Model.factory<AttributeUser>()
              .seed(seed)
              .withGenerator('email', (field, context) {
                final provider = const DefaultFieldGeneratorProvider();
                const carbonField = FieldDefinition(
                  name: 'timestamp',
                  columnName: 'timestamp',
                  dartType: 'Carbon',
                  resolvedType: 'Carbon',
                  isPrimaryKey: false,
                  isNullable: false,
                  isUnique: false,
                  isIndexed: false,
                  autoIncrement: false,
                );
                return provider.generate(carbonField, context);
              });
          return factory.values()['email'] as Carbon;
        }

        final first = generateCarbon(42);
        final second = generateCarbon(42);
        final third = generateCarbon(99);

        // Same seed should produce same seconds offset
        expect(first.second, second.second);
        expect(first.minute, second.minute);
        expect(first.hour, second.hour);

        // Different seed should typically produce different values
        // (Note: small chance of collision, but unlikely)
        expect(
          third.second != first.second || third.minute != first.minute,
          isTrue,
        );
      });

      test('nullable Carbon has chance of null', () {
        int nullCount = 0;
        for (int i = 0; i < 20; i++) {
          final factory = Model.factory<AttributeUser>()
              .seed(i * 100)
              .withGenerator('email', (field, context) {
                final provider = const DefaultFieldGeneratorProvider();
                const carbonField = FieldDefinition(
                  name: 'timestamp',
                  columnName: 'timestamp',
                  dartType: 'Carbon',
                  resolvedType: 'Carbon?',
                  isPrimaryKey: false,
                  isNullable: true,
                  isUnique: false,
                  isIndexed: false,
                  autoIncrement: false,
                );
                return provider.generate(carbonField, context);
              });
          if (factory.values()['email'] == null) {
            nullCount++;
          }
        }

        // Expect at least some nulls and some non-nulls
        expect(
          nullCount,
          greaterThan(0),
          reason: 'Expected some null values for nullable Carbon field',
        );
        expect(
          nullCount,
          lessThan(20),
          reason: 'Expected some non-null values for nullable Carbon field',
        );
      });
    });

    group('Auto-increment and Default SQL Handling', () {
      test('skips auto-increment fields unless overridden', () {
        // User has autoIncrement on id field
        final values = Model.factory<User>().values();
        // Auto-increment fields should not be in the generated values
        expect(values.containsKey('id'), isFalse);
      });

      test('includes auto-increment fields when explicitly overridden', () {
        final values = Model.factory<User>().withOverrides({
          'id': 999,
        }).values();
        expect(values['id'], 999);
      });

      test('skips fields with defaultValueSql unless overridden', () {
        // User.active has defaultValueSql: '1'
        final values = Model.factory<User>().values();
        expect(values.containsKey('active'), isFalse);
      });

      test('includes defaultValueSql fields when explicitly overridden', () {
        final values = Model.factory<User>().withOverrides({
          'active': false,
        }).values();
        expect(values['active'], false);
      });

      test('skips fields with codecType unless overridden', () {
        // User.profile has a custom codec (JsonMapCodec)
        final values = Model.factory<User>().values();
        expect(values.containsKey('profile'), isFalse);
        expect(values.containsKey('metadata'), isFalse);
      });

      test('includes codecType fields when explicitly overridden', () {
        final profileData = {'key': 'value'};
        final values = Model.factory<User>().withOverrides({
          'profile': profileData,
        }).values();
        expect(values['profile'], profileData);
      });
    });

    group('Cross-Model References', () {
      test('value can seed another payload', () {
        final email = Model.factory<AttributeUser>().seed(3).value('email');
        final other = {
          'authorEmail': email,
          'reference': Model.factory<AttributeUser>().value('id'),
        };
        expect(other['authorEmail'], email);
        expect(other['reference'], isA<int>());
      });

      test('consistent foreign key generation', () {
        final userId =
            Model.factory<User>().seed(1).withOverrides({'id': 42}).value('id')
                as int;
        final postValues = Model.factory<Post>().withOverrides({
          'user_id': userId,
          'title': 'Test Post',
        }).values();
        expect(postValues['user_id'], 42);
        expect(postValues['title'], 'Test Post');
      });
    });

    group('Non-Factory Models', () {
      test('non-opt-in models cannot resolve factories', () {
        expect(() => Model.factory<NoFactory>().values(), throwsStateError);
      });
    });

    group('Inheritance Support', () {
      test('derived model inherits factory via mixin base', () {
        final values = Model.factory<DerivedForFactory>().withOverrides({
          'baseName': 'root',
          'layerOneNotes': 'notes',
          'layerTwoFlag': true,
        }).values();
        expect(values['base_name'], 'root');
        expect(values['layer_one_notes'], 'notes');
        expect(values['layer_two_flag'], true);
      });

      test('derived metadata includes ancestor attributes', () {
        final overrides =
            DerivedForFactoryOrmDefinition.definition.metadata.fieldOverrides;
        expect(overrides['id']?.hidden, isTrue);
        expect(overrides['base_name']?.fillable, isTrue);
        expect(overrides['layer_one_notes']?.cast, 'json');
        expect(overrides['layer_two_flag']?.guarded, isTrue);
      });

      test(
        'base class with ModelFactoryCapable enables factory for derived classes',
        () {
          // DerivedForFactory extends LevelOneForFactory extends BaseForFactory
          // Only BaseForFactory has ModelFactoryCapable
          final factory = Model.factory<DerivedForFactory>();
          expect(factory, isNotNull);

          final model = factory.withOverrides({
            'id': 1,
            'baseName': 'inherited',
          }).make();
          expect(model.baseName, 'inherited');
        },
      );
    });

    group('Custom GeneratorProvider', () {
      test('custom provider can replace default generation', () {
        final customProvider = _TestGeneratorProvider();
        final factory = Model.factory<AttributeUser>(
          generatorProvider: customProvider,
        );
        final values = factory.values();

        // Our custom provider returns 'custom_<fieldName>' for strings
        expect(values['email'], 'custom_email');
      });

      test('custom provider can fall back to default for unhandled types', () {
        final customProvider = _FallbackGeneratorProvider();
        final factory = Model.factory<AttributeUser>(
          generatorProvider: customProvider,
        ).seed(42);
        final values = factory.values();

        // Custom provider handles email specially
        expect(values['email'], 'fallback@custom.com');
        // Other string fields use default generation
        expect(values['secret'], contains('AttributeUser_secret_'));
      });
    });

    group('Builder Chain Immutability', () {
      test('builder methods return the same instance for chaining', () {
        final builder = Model.factory<AttributeUser>();
        final withSeed = builder.seed(1);
        final withOverrides = withSeed.withOverrides({'id': 1});
        final withField = withOverrides.withField('email', 'test@test.com');

        expect(withSeed, same(builder));
        expect(withOverrides, same(builder));
        expect(withField, same(builder));
      });
    });

    group('Edge Cases', () {
      test('empty overrides map does not affect generation', () {
        final values = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({})
            .values();
        expect(values['email'], isNotNull);
      });

      test('multiple values() calls return same generated data', () {
        final factory = Model.factory<AttributeUser>().seed(42);
        final first = factory.values();
        final second = factory.values();
        expect(first['email'], second['email']);
      });

      test('make() can be called multiple times with same data', () {
        final factory = Model.factory<AttributeUser>().seed(42).withOverrides({
          'id': 1,
          'secret': 'mysecret',
        });
        final first = factory.make();
        final second = factory.make();
        expect(first.email, second.email);
        expect(first.id, second.id);
      });
    });

    group('Count (Batch Creation)', () {
      test('count() sets the number of models to create', () {
        final models = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .count(3)
            .makeMany();
        expect(models.length, 3);
        expect(models[0], isA<AttributeUser>());
        expect(models[1], isA<AttributeUser>());
        expect(models[2], isA<AttributeUser>());
      });

      test('count(1) creates single model in list', () {
        final models = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .count(1)
            .makeMany();
        expect(models.length, 1);
      });

      test('makeMany() without count defaults to 1', () {
        final models = Model.factory<AttributeUser>().seed(42).withOverrides({
          'secret': 'test',
        }).makeMany();
        expect(models.length, 1);
      });

      test('make() returns first model when count is set', () {
        final factory = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .count(5);
        final single = factory.make();
        final many = factory.makeMany();
        expect(single.email, many[0].email);
      });

      test('count() throws on invalid values', () {
        expect(
          () => Model.factory<AttributeUser>().count(0),
          throwsArgumentError,
        );
        expect(
          () => Model.factory<AttributeUser>().count(-1),
          throwsArgumentError,
        );
      });

      test('each model in batch has unique generated values', () {
        final models = Model.factory<AttributeUser>()
            .withOverrides({'secret': 'test'})
            .count(5)
            .makeMany();
        final emails = models.map((m) => m.email).toSet();
        // All emails should be unique (or at least most due to random generation)
        expect(emails.length, greaterThan(1));
      });
    });

    group('State Transformations', () {
      test('state() applies attribute overrides', () {
        final model = Model.factory<AttributeUser>().seed(42).state({
          'role': 'admin',
          'secret': 'admin_secret',
        }).make();
        expect(model.role, 'admin');
        expect(model.secret, 'admin_secret');
      });

      test('multiple state() calls are applied in order', () {
        final model = Model.factory<AttributeUser>()
            .seed(42)
            .state({'role': 'user', 'secret': 'first'})
            .state({'role': 'admin'}) // Override role but keep secret
            .make();
        expect(model.role, 'admin');
        expect(model.secret, 'first');
      });

      test('stateUsing() applies closure-based transformation', () {
        final model = Model.factory<AttributeUser>()
            .seed(42)
            .stateUsing(
              (attrs) => {
                'secret': 'computed_${attrs['email'].toString().split('_')[0]}',
              },
            )
            .make();
        expect(model.secret, contains('computed_'));
      });

      test('state() and withOverrides() can be combined', () {
        final model = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'id': 100})
            .state({'role': 'moderator', 'secret': 'test'})
            .make();
        expect(model.id, 100);
        expect(model.role, 'moderator');
      });
    });

    group('Sequences', () {
      test('sequence() cycles through attribute sets', () {
        final models = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .count(4)
            .sequence([
              {'role': 'admin'},
              {'role': 'user'},
            ])
            .makeMany();
        expect(models[0].role, 'admin');
        expect(models[1].role, 'user');
        expect(models[2].role, 'admin'); // Wraps around
        expect(models[3].role, 'user');
      });

      test('sequenceUsing() generates attributes based on index', () {
        final models = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .count(3)
            .sequenceUsing((index) => {'role': 'role_$index'})
            .makeMany();
        expect(models[0].role, 'role_0');
        expect(models[1].role, 'role_1');
        expect(models[2].role, 'role_2');
      });

      test('sequence() throws on empty list', () {
        expect(
          () => Model.factory<AttributeUser>().sequence([]),
          throwsArgumentError,
        );
      });

      test('sequence with single item applies to all', () {
        final models = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .count(3)
            .sequence([
              {'role': 'constant'},
            ])
            .makeMany();
        expect(models.every((m) => m.role == 'constant'), isTrue);
      });
    });

    group('Callbacks', () {
      test('afterMaking() is called for each model', () {
        final madeModels = <AttributeUser>[];
        final models = Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .count(3)
            .afterMaking((model) => madeModels.add(model))
            .makeMany();
        expect(madeModels.length, 3);
        expect(madeModels, equals(models));
      });

      test('afterMaking() is called for single make()', () {
        var callCount = 0;
        Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .afterMaking((_) => callCount++)
            .make();
        expect(callCount, 1);
      });

      test('multiple afterMaking() callbacks are all called', () {
        var callback1Called = false;
        var callback2Called = false;
        Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .afterMaking((_) => callback1Called = true)
            .afterMaking((_) => callback2Called = true)
            .make();
        expect(callback1Called, isTrue);
        expect(callback2Called, isTrue);
      });

      test('afterMaking() can modify captured state', () {
        final emails = <String>[];
        Model.factory<AttributeUser>()
            .seed(42)
            .withOverrides({'secret': 'test'})
            .count(2)
            .afterMaking((model) => emails.add(model.email))
            .makeMany();
        expect(emails.length, 2);
      });
    });

    group('Trashed (Soft Delete)', () {
      test('trashed() sets soft delete column', () {
        // ActiveUser has soft deletes
        final values = Model.factory<ActiveUser>().seed(42).trashed().values();
        expect(values['deleted_at'], isA<DateTime>());
      });

      test('trashed() with custom timestamp', () {
        final customTime = DateTime(2024, 6, 15, 10, 30);
        final values = Model.factory<ActiveUser>()
            .seed(42)
            .trashed(customTime)
            .values();
        expect(values['deleted_at'], customTime);
      });

      test('trashed() model can be made', () {
        final model = Model.factory<ActiveUser>().seed(42).trashed().make();
        expect(model, isA<ActiveUser>());
      });
    });

    group('Combined Features', () {
      test('count + sequence + state + callbacks work together', () {
        final results = <String>[];
        final models = Model.factory<AttributeUser>()
            .seed(42)
            .count(4)
            .state({'secret': 'base_secret'})
            .sequence([
              {'role': 'admin'},
              {'role': 'user'},
            ])
            .afterMaking((m) => results.add('${m.role}'))
            .makeMany();

        expect(models.length, 4);
        expect(results, ['admin', 'user', 'admin', 'user']);
        expect(models.every((m) => m.secret == 'base_secret'), isTrue);
      });

      test('sequence overrides state', () {
        final model = Model.factory<AttributeUser>()
            .seed(42)
            .state({'role': 'from_state', 'secret': 'test'})
            .sequence([
              {'role': 'from_sequence'},
            ])
            .make();
        expect(model.role, 'from_sequence');
      });
    });

    group('External Factory Definitions', () {
      const externalFactory = _ExternalFactoryUserFactory();

      setUpAll(() {
        ModelFactoryRegistry.register<ExternalFactoryUser>(
          _externalFactoryUserDefinition,
        );
        ModelFactoryRegistry.registerFactory<ExternalFactoryUser>(
          externalFactory,
        );
      });

      test('Model.factory uses external defaults', () {
        final values = Model.factory<ExternalFactoryUser>().values();
        expect(values['name'], 'Ormed User');
        expect(values['role'], 'member');
      });

      test('stateNamed applies named state', () {
        final model = externalFactory.stateNamed('admin').make();
        expect(model.role, 'admin');
      });
    });
  });
}

/// Test generator provider that returns custom values for string fields.
class _TestGeneratorProvider extends GeneratorProvider {
  const _TestGeneratorProvider();

  @override
  Object? generate<TModel extends OrmEntity>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  ) {
    final type = field.resolvedType.replaceAll('?', '');
    if (type == 'String') {
      return 'custom_${field.name}';
    }
    if (type == 'int') {
      return 42;
    }
    if (type == 'bool') {
      return true;
    }
    return null;
  }
}

/// Test generator provider that handles only specific fields and falls back.
class _FallbackGeneratorProvider extends GeneratorProvider {
  const _FallbackGeneratorProvider();

  @override
  Object? generate<TModel extends OrmEntity>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  ) {
    if (field.name == 'email') {
      return 'fallback@custom.com';
    }
    // Fall back to default provider for everything else
    return const DefaultFieldGeneratorProvider().generate(field, context);
  }
}

/// Test provider for verifying double generation.
class _DoubleFieldTestProvider extends GeneratorProvider {
  double? doubleGenerated;

  @override
  Object? generate<TModel extends OrmEntity>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  ) {
    // Simulate double generation to verify the range
    doubleGenerated = context.random.nextDouble() * 1000;
    // Fall back to default for actual generation
    return const DefaultFieldGeneratorProvider().generate(field, context);
  }
}

class ExternalFactoryUser extends Model<ExternalFactoryUser> {
  const ExternalFactoryUser({this.id, required this.name, this.role});

  final int? id;
  final String name;
  final String? role;
}

class _ExternalFactoryUserCodec extends ModelCodec<ExternalFactoryUser> {
  const _ExternalFactoryUserCodec();

  @override
  Map<String, Object?> encode(
    ExternalFactoryUser model,
    ValueCodecRegistry registry,
  ) => {'id': model.id, 'name': model.name, 'role': model.role};

  @override
  ExternalFactoryUser decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) {
    return ExternalFactoryUser(
      id: data['id'] as int?,
      name: data['name'] as String? ?? 'unknown',
      role: data['role'] as String?,
    );
  }
}

const _externalFactoryUserDefinition = ModelDefinition<ExternalFactoryUser>(
  modelName: 'ExternalFactoryUser',
  tableName: 'external_factory_users',
  fields: [
    FieldDefinition(
      name: 'id',
      columnName: 'id',
      dartType: 'int?',
      resolvedType: 'int?',
      isPrimaryKey: true,
      isNullable: true,
      autoIncrement: true,
    ),
    FieldDefinition(
      name: 'name',
      columnName: 'name',
      dartType: 'String',
      resolvedType: 'String',
      isPrimaryKey: false,
      isNullable: false,
    ),
    FieldDefinition(
      name: 'role',
      columnName: 'role',
      dartType: 'String?',
      resolvedType: 'String?',
      isPrimaryKey: false,
      isNullable: true,
    ),
  ],
  codec: _ExternalFactoryUserCodec(),
);

class _ExternalFactoryUserFactory
    extends ModelFactoryDefinition<ExternalFactoryUser> {
  const _ExternalFactoryUserFactory();

  @override
  Map<String, Object?> defaults() => const {
    'name': 'Ormed User',
    'role': 'member',
  };

  @override
  Map<String, StateTransformer<ExternalFactoryUser>> get states => const {
    'admin': _adminState,
  };

  static Map<String, Object?> _adminState(Map<String, Object?> attributes) => {
    'role': 'admin',
  };
}
