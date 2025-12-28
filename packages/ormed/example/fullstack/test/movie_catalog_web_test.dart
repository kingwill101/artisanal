import 'dart:io';
import 'dart:typed_data';

import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/src/models/genre.dart';
import 'package:ormed_fullstack_example/src/models/movie.dart';
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

  // #region testing-web
  ormedGroup('Movie catalog web routes', (ds) {
    late MovieCatalogTestHarness harness;

    setUpAll(() async {
      harness = await createMovieCatalogHarness(ds);
    });

    tearDownAll(() async {
      await harness.dispose();
    });

    // #region testing-web-index
    test('GET / renders the catalog', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertBodyContains('Movie Catalog')
          ..assertBodyContains('City of Amber')
          ..assertBodyContains('Science Fiction');
      });
    });
    // #endregion testing-web-index

    // #region testing-web-genres
    test('GET /genres renders genre list', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/genres');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertBodyContains('Genres')
          ..assertBodyContains('Drama');
      });
    });

    test('GET /genres/:id renders genre detail', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/genres/1');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertBodyContains('Drama')
          ..assertBodyContains('Ashes in Winter');
      });
    });

    test('GET /genres/:id returns 404 for missing genre', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/genres/9999');
        response.assertStatus(HttpStatus.notFound);
      });
    });
    // #endregion testing-web-genres

    // #region testing-web-create
    test('POST /movies creates a movie', () async {
      await withClient(harness, (client) async {
        final genre = await GenreModelFactory.factory()
            .state({'name': 'Test Drama', 'description': 'Factory seed.'})
            .create(context: ds.context);

        final response = await client.multipart('/movies', (builder) {
          builder.addField('title', 'North Star');
          builder.addField('releaseYear', '2022');
          builder.addField('genreId', genre.id.toString());
          builder.addField('summary', 'A drifting crew returns home.');
          builder.addFileFromBytes(
            name: 'poster',
            bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
            filename: 'poster.jpg',
            contentType: MediaType('image', 'jpeg'),
          );
        });

        response.assertStatus(HttpStatus.found);
        final location = response.headers['location']?.first ?? '';
        expect(location, startsWith('/movies/'));

        final index = await client.get('/');
        index
          ..assertStatus(HttpStatus.ok)
          ..assertBodyContains('North Star')
          ..assertBodyContains(genre.name);
      }, mode: TransportMode.ephemeralServer);
    });
    // #endregion testing-web-create

    // #region testing-web-show
    test('GET /movies/:id renders detail page', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/movies/1');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertBodyContains('City of Amber')
          ..assertBodyContains('underground city');
      });
    });

    test('GET /movies/:id returns 404 for missing movie', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/movies/9999');
        response.assertStatus(HttpStatus.notFound);
      });
    });
    // #endregion testing-web-show

    // #region testing-web-edit
    test('GET /movies/:id/edit renders edit form', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/movies/1/edit');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertBodyContains('Edit movie')
          ..assertBodyContains('City of Amber');
      });
    });

    test('POST /movies/:id/edit updates a movie', () async {
      await withClient(harness, (client) async {
        final response = await client.multipart('/movies/1/edit', (builder) {
          builder.addField('title', 'City of Amber');
          builder.addField('releaseYear', '2006');
          builder.addField('genreId', '');
          builder.addField(
            'summary',
            'A renewed edit of the underground tale.',
          );
        });

        response.assertStatus(HttpStatus.found);
        final show = await client.get('/movies/1');
        show
          ..assertStatus(HttpStatus.ok)
          ..assertBodyContains('A renewed edit of the underground tale.');
      }, mode: TransportMode.ephemeralServer);
    });
    // #endregion testing-web-edit

    // #region testing-web-delete
    test('GET /movies/:id/delete renders delete confirmation', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/movies/1/delete');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertBodyContains('Delete City of Amber')
          ..assertBodyContains('Yes, delete');
      });
    });

    test('POST /movies/:id/delete removes a movie', () async {
      await withClient(harness, (client) async {
        final genre = await GenreModelFactory.factory()
            .state({'name': 'Delete Genre', 'description': 'For delete tests.'})
            .create(context: ds.context);
        final movie = await MovieModelFactory.factory()
            .state({
              'title': 'Shadow Atlas',
              'releaseYear': 2016,
              'genreId': genre.id,
            })
            .create(context: ds.context);

        final response = await client.post('/movies/${movie.id}/delete', '');
        response.assertStatus(HttpStatus.found);

        final show = await client.get('/movies/${movie.id}');
        show.assertStatus(HttpStatus.notFound);
      });
    });
    // #endregion testing-web-delete

    // #region testing-web-api-link
    test('GET /api/genres/:id returns JSON for web links', () async {
      await withClient(harness, (client) async {
        final response = await client.get('/api/genres/1');

        response
          ..assertStatus(HttpStatus.ok)
          ..assertJson((json) {
            json
              ..has('genre')
              ..has('movies')
              ..etc();
          });
      });
    });
    // #endregion testing-web-api-link
  }, config: config);
  // #endregion testing-web
}
