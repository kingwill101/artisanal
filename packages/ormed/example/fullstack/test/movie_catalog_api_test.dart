import 'dart:convert';
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/src/models/genre.dart';
import 'package:server_testing/server_testing.dart';

import 'support/movie_catalog_harness.dart';

Future<void> withClient(
  MovieCatalogTestHarness harness,
  Future<void> Function(TestClient client) run, {
  TransportMode mode = TransportMode.inMemory,
}) async {
  final client = mode == TransportMode.inMemory
      ? TestClient.inMemory(harness.requestHandler)
      : TestClient.ephemeralServer(harness.requestHandler);
  try {
    await run(client);
  } finally {
    await client.close();
  }
}

void main() {
  final config = createMovieCatalogConfig();

  // #region testing-api
  ormedGroup('Movie catalog JSON APIs', (ds) {
    late MovieCatalogTestHarness harness;

    setUpAll(() async {
      harness = await createMovieCatalogHarness(ds);
    });

    tearDownAll(() async {
      await harness.dispose();
    });

    // #region testing-api-list
    test('GET /api/movies returns JSON list', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/api/movies');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertJson((json) {
            json
              ..has('movies')
              ..countBetween('movies', 1, 10)
              ..scope('movies', (movies) {
                movies.each((movie) {
                  movie
                    ..hasAll([
                      'id',
                      'title',
                      'release_year',
                      'summary',
                      'poster_url',
                      'genre',
                    ])
                    ..whereType<int>('id')
                    ..whereType<int>('release_year')
                    ..when(movie.get('genre') != null, (movie) {
                      movie.scope('genre', (genre) {
                        genre
                          ..hasAll(['id', 'name'])
                          ..whereType<int>('id')
                          ..whereType<String>('name')
                          ..etc();
                      });
                    })
                    ..etc();
                });
              })
              ..etc();
          });
      });
    });

    test('GET /api/genres returns JSON list', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/api/genres');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertJson((json) {
            json
              ..has('genres')
              ..countBetween('genres', 1, 10)
              ..scope('genres', (genres) {
                genres.each((genre) {
                  genre
                    ..hasAll(['id', 'name', 'description'])
                    ..whereType<String>('id')
                    ..whereType<String>('name')
                    ..etc();
                });
              })
              ..etc();
          });
      });
    });
    // #endregion testing-api-list

    // #region testing-api-genre-show
    test('GET /api/genres/:id returns genre detail', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/api/genres/1');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertJson((json) {
            json
              ..hasAll(['genre', 'movies'])
              ..scope('genre', (genre) {
                genre
                  ..where('id', '1')
                  ..where('name', 'Drama')
                  ..etc();
              })
              ..scope('movies', (movies) {
                movies.each((movie) {
                  movie
                    ..hasAll(['id', 'title', 'release_year', 'genre'])
                    ..whereType<int>('id')
                    ..whereType<int>('release_year')
                    ..etc();
                });
              })
              ..etc();
          });
      });
    });
    // #endregion testing-api-genre-show

    // #region testing-api-show
    test('GET /api/movies/:id returns movie', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/api/movies/1');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertJson((json) {
            json.has('movie', (movie) {
              movie
                ..where('id', 1)
                ..whereType<String>('title')
                ..whereType<int>('release_year')
                ..has('genre')
                ..etc();
            });
          });
      });
    });
    // #endregion testing-api-show

    // #region testing-api-create
    test('POST /api/movies creates via DTOs', () async {
      await withClient(harness, (client) async {
        final genre = await GenreModelFactory.factory()
            .state({'name': 'API Genre', 'description': 'API factory'})
            .create(context: ds.context);

        final response = await client.postJson('/api/movies', {
          'title': 'Signal Fire',
          'releaseYear': 2021,
          'summary': 'A coastal community reunites after decades.',
          'genreId': genre.id,
        });

        response
          ..assertStatus(HttpStatus.created)
          ..assertJson((json) {
            json
              ..has('movie', (movie) {
                movie
                  ..where('title', 'Signal Fire')
                  ..whereType<int>('id')
                  ..whereType<int>('release_year')
                  ..has('genre')
                  ..etc();
              })
              ..etc();
          });
      });
    });
    // #endregion testing-api-create

    // #region testing-api-update
    test('PATCH /api/movies updates a movie', () async {
      await withClient(harness, (client) async {
        final genre = await GenreModelFactory.factory()
            .state({'name': 'Patch Genre', 'description': 'Patch factory'})
            .create(context: ds.context);

        final created = await client.postJson('/api/movies', {
          'title': 'Paper Horizon',
          'releaseYear': 2020,
          'genreId': genre.id,
        });

        created
          ..assertStatus(HttpStatus.created)
          ..assertJson((json) {
            json.has('movie', (movie) {
              movie
                ..whereType<int>('id')
                ..whereType<String>('title')
                ..etc();
            });
          });

        final createdJson = created.json() as Map<String, dynamic>;
        final movieId = createdJson['movie']['id'] as int;

        final response = await client.patch(
          '/api/movies/$movieId',
          jsonEncode({'summary': 'A traveller reconsiders the journey.'}),
          headers: {
            'content-type': ['application/json'],
          },
        );

        response
          ..assertStatus(HttpStatus.ok)
          ..assertJson((json) {
            json.has('movie', (movie) {
              movie
                ..where('summary', 'A traveller reconsiders the journey.')
                ..etc();
            });
          });
      });
    });
    // #endregion testing-api-update

    // #region testing-api-validation
    test('POST /api/movies validates payloads', () async {
      await withClient(harness, (client) async {
        final response = await client.postJson('/api/movies', {
          'title': '',
          'releaseYear': 1200,
        });

        response
          ..assertStatus(HttpStatus.badRequest)
          ..assertJsonContains({
            'errors': [
              'Title is required.',
              'Release year must be a valid year (1888+).',
            ],
          })
          ..assertJson((json) {
            json
              ..has('errors')
              ..whereType<List>('errors')
              ..scope('errors', (errors) {
                errors
                  ..count(2)
                  ..each((error) {
                    error.whereType<String>();
                  });
              })
              ..etc();
          });
      });
    });
    // #endregion testing-api-validation

    // #region testing-api-missing
    test('GET /api/movies/:id returns 404', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/api/movies/9999');
        response
          ..assertStatus(HttpStatus.notFound)
          ..assertJson((json) {
            json
              ..where('error', 'Movie not found')
              ..etc();
          });
      });
    });

    test('GET /api/genres/:id returns 404', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/api/genres/9999');
        response
          ..assertStatus(HttpStatus.notFound)
          ..assertJson((json) {
            json
              ..where('error', 'Genre not found')
              ..etc();
          });
      });
    });
    // #endregion testing-api-missing

    // #region testing-api-delete
    test('DELETE /api/movies/:id removes a movie', () async {
      await withClient(harness, (client) async {
        final genre = await GenreModelFactory.factory()
            .state({'name': 'Delete API Genre', 'description': 'Delete factory'})
            .create(context: ds.context);
        final created = await client.postJson('/api/movies', {
          'title': 'Marrow Lines',
          'releaseYear': 2023,
          'genreId': genre.id,
        });
        created
          ..assertStatus(HttpStatus.created)
          ..assertJson((json) {
            json.has('movie', (movie) {
              movie
                ..whereType<int>('id')
                ..where('title', 'Marrow Lines')
                ..etc();
            });
          });

        final createdJson = created.json() as Map<String, dynamic>;
        final movieId = createdJson['movie']['id'] as int;

        final response = await client.delete('/api/movies/$movieId');
        response
          ..assertStatus(HttpStatus.ok)
          ..assertJson((json) {
            json
              ..where('deleted', true)
              ..where('id', movieId)
              ..etc();
          });

        final show = await client.get('/api/movies/$movieId');
        show
          ..assertStatus(HttpStatus.notFound)
          ..assertJson((json) {
            json
              ..where('error', 'Movie not found')
              ..etc();
          });
      });
    });

    test('DELETE /api/movies/:id returns 404', () async {
      await withClient(harness, (client) async {
        final response = await client.delete('/api/movies/9999');
        response
          ..assertStatus(HttpStatus.notFound)
          ..assertJson((json) {
            json
              ..where('error', 'Movie not found')
              ..etc();
          });
      });
    });
    // #endregion testing-api-delete
  }, config: config);
  // #endregion testing-api
}
