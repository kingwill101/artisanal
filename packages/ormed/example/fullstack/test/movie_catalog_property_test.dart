import 'package:ormed/ormed.dart';
import 'package:property_testing/property_testing.dart';
import 'package:server_testing/server_testing.dart';
import 'support/movie_catalog_harness.dart';

void main() {
  final config = createMovieCatalogConfig();

  // #region testing-property
  ormedGroup('Movie catalog property testing', (ds) {
    late MovieCatalogTestHarness harness;

    setUpAll(() async {
      harness = await createMovieCatalogHarness(ds);
    });

    tearDownAll(() async {
      await harness.dispose();
    });

    // #region testing-property-chaos
    test('property: API survives chaotic ids', () async {
      final client = TestClient.inMemory(harness.requestHandler);

      final runner = PropertyTestRunner<String>(
        Chaos.string(minLength: 1, maxLength: 64),
        (value) async {
          final response = await client.get('/api/movies/$value');
          expect(response.statusCode, lessThan(500));
        },
      );

      final report = await runner.run();
      await client.close();
      expect(report.success, isTrue, reason: report.report);
    });

    test('property: genre routes never 500', () async {
      final client = TestClient.inMemory(harness.requestHandler);

      final runner = PropertyTestRunner<String>(
        Chaos.string(minLength: 1, maxLength: 64),
        (value) async {
          final response = await client.get('/api/genres/$value');
          expect(response.statusCode, lessThan(500));
        },
      );

      final report = await runner.run();
      await client.close();
      expect(report.success, isTrue, reason: report.report);
    });
    // #endregion testing-property-chaos

    // #region testing-property-validation
    test('property: create validation never 500', () async {
      final client = TestClient.inMemory(harness.requestHandler);

      // #region testing-property-generators
      final titleGen = Gen.oneOfGen([
        Gen.string(minLength: 1, maxLength: 40),
        Chaos.string(minLength: 0, maxLength: 8),
      ]);
      final yearGen = Gen.oneOfGen([
        Gen.integer(min: 1888, max: 2030),
        Chaos.integer(min: 0, max: 3000),
      ]);
      final summaryGen = Gen.oneOfGen<String?>([
        Gen.constant(null),
        Gen.string(maxLength: 120),
      ]);
      final genreIdGen = Gen.oneOfGen<int?>([
        Gen.constant(null),
        Gen.integer(min: 1, max: 10),
        Chaos.integer(min: -50, max: 50),
      ]);

      final payloadGen = titleGen.flatMap(
        (title) => yearGen.flatMap(
          (year) => summaryGen.flatMap(
            (summary) => genreIdGen.map((genreId) {
              return {
                'title': title,
                'releaseYear': year,
                'summary': summary,
                'genreId': genreId,
              };
            }),
          ),
        ),
      );
      // #endregion testing-property-generators

      // #region testing-property-runner
      final runner = PropertyTestRunner<Map<String, dynamic>>(payloadGen, (
        payload,
      ) async {
        final response = await client.postJson('/api/movies', payload);
        expect(response.statusCode, anyOf([201, 400]));
        expect(response.statusCode, lessThan(500));

        if (response.statusCode == 201) {
          response.assertJson((json) {
            json.has('movie', (movie) {
              movie
                ..whereType<int>('id')
                ..whereType<String>('title')
                ..whereType<int>('release_year')
                ..isGreaterOrEqual('release_year', 1888)
                ..etc();
            });
          });
        } else if (response.statusCode == 400) {
          response.assertJson((json) {
            json
              ..hasAny(['error', 'errors'])
              ..etc();
          });
        }
      }, PropertyConfig(numTests: 250, maxShrinks: 50));
      // #endregion testing-property-runner

      final report = await runner.run();
      await client.close();
      expect(report.success, isTrue, reason: report.report);
    });

    test('property: invalid JSON never 500', () async {
      final client = TestClient.inMemory(harness.requestHandler);

      final runner = PropertyTestRunner<String>(
        Chaos.string(minLength: 0, maxLength: 200),
        (payload) async {
          final response = await client.post(
            '/api/movies',
            payload,
            headers: {
              'content-type': ['application/json'],
            },
          );
          expect(response.statusCode, anyOf([400, 201]));
          expect(response.statusCode, lessThan(500));
          if (response.statusCode == 400) {
            response.assertJson((json) {
              json
                ..hasAny(['error', 'errors'])
                ..etc();
            });
          }
        },
        PropertyConfig(numTests: 150, maxShrinks: 50),
      );

      final report = await runner.run();
      await client.close();
      expect(report.success, isTrue, reason: report.report);
    });

    test('property: patch payloads never 500', () async {
      final client = TestClient.inMemory(harness.requestHandler);

      final payloadGen = Gen.oneOfGen([
        Gen.constant(<String, dynamic>{'summary': 'A short note.'}),
        Gen.constant(<String, dynamic>{'title': 'Edge Title'}),
        Gen.constant(<String, dynamic>{'releaseYear': 2024}),
        Gen.constant(<String, dynamic>{}),
      ]);

      final runner = PropertyTestRunner<Map<String, dynamic>>(payloadGen, (
        payload,
      ) async {
        final response = await client.patchJson('/api/movies/1', payload);
        expect(response.statusCode, anyOf([200, 400, 404]));
        expect(response.statusCode, lessThan(500));
      }, PropertyConfig(numTests: 120, maxShrinks: 30));

      final report = await runner.run();
      await client.close();
      expect(report.success, isTrue, reason: report.report);
    });
    // #endregion testing-property-validation

    // #region testing-property-web
    test('property: web routes tolerate odd ids', () async {
      final client = TestClient.inMemory(harness.requestHandler);

      final runner = PropertyTestRunner<String>(
        Chaos.string(minLength: 1, maxLength: 64),
        (value) async {
          final response = await client.get('/movies/$value');
          expect(response.statusCode, anyOf([200, 404]));
          expect(response.statusCode, lessThan(500));
        },
      );

      final report = await runner.run();
      await client.close();
      expect(report.success, isTrue, reason: report.report);
    });
    // #endregion testing-property-web

    // #region testing-property-upload
    test('property: upload validation never 500', () async {
      final client = TestClient.inMemory(harness.requestHandler);

      final titleGen = Chaos.string(minLength: 0, maxLength: 10);
      final yearGen = Chaos.integer(min: 0, max: 3000);

      final payloadGen = titleGen.flatMap(
        (title) => yearGen.map((year) {
          return {'title': title, 'releaseYear': year, 'genreId': ''};
        }),
      );

      final runner = PropertyTestRunner<Map<String, dynamic>>(payloadGen, (
        payload,
      ) async {
        final response = await client.multipart('/movies', (builder) {
          for (final entry in payload.entries) {
            final value = entry.value;
            if (value == null) {
              continue;
            }
            builder.addField(entry.key, value.toString());
          }
        });
        expect(response.statusCode, anyOf([302, 400]));
        expect(response.statusCode, lessThan(500));
      }, PropertyConfig(numTests: 120, maxShrinks: 30));

      final report = await runner.run();
      await client.close();
      expect(report.success, isTrue, reason: report.report);
    });
    // #endregion testing-property-upload
  }, config: config);
  // #endregion testing-property
}
