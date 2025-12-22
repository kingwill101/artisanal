import 'dart:convert';
import 'dart:io';

import 'package:contextual/contextual.dart';
import 'package:ormed/ormed.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import '../config/paths.dart';
import '../database/database.dart';
import '../models/genre.dart';
import '../models/movie.dart';
import '../storage/storage.dart';
import '../templates/template_renderer.dart';

class MovieCatalogApp {
  MovieCatalogApp({
    required this.database,
    required this.storage,
    required this.templates,
    required this.logger,
  }) : _uploadsHandler = createStaticHandler(
         AppPaths.uploadsDir,
         serveFilesOutsidePath: true,
       );

  final AppDatabase database;
  final StorageService storage;
  final TemplateRenderer templates;
  final Logger logger;
  final Handler _uploadsHandler;

  Handler buildHandler() {
    // #region router-setup
    final router = Router()
      // #region router-web
      ..get('/', _index)
      ..get('/genres', _genresIndex)
      ..get('/genres/<id|[0-9]+>', _showGenre)
      ..get('/movies/new', _newMovie)
      ..post('/movies', _createMovie)
      ..get('/movies/<id|[0-9]+>', _showMovie)
      ..get('/movies/<id|[0-9]+>/edit', _editMovie)
      ..post('/movies/<id|[0-9]+>/edit', _updateMovie)
      ..get('/movies/<id|[0-9]+>/delete', _confirmDeleteMovie)
      ..post('/movies/<id|[0-9]+>/delete', _deleteMovie)
      // #endregion router-web
      // #region router-api
      ..get('/api/genres', _apiListGenres)
      ..get('/api/genres/<id|[0-9]+>', _apiShowGenre)
      ..get('/api/movies', _apiListMovies)
      ..get('/api/movies/<id|[0-9]+>', _apiShowMovie)
      ..post('/api/movies', _apiCreateMovie)
      ..patch('/api/movies/<id|[0-9]+>', _apiUpdateMovie)
      ..delete('/api/movies/<id|[0-9]+>', _apiDeleteMovie)
      // #endregion router-api
      ..mount('/uploads/', _uploadsHandler);

    return router.call;
    // #endregion router-setup
  }

  Future<Response> _index(Request request) async {
    // #region handler-index
    final movies = await database.dataSource
        .query<$Movie>()
        .withRelation('genre')
        .orderBy('createdAt', descending: true)
        .get();

    final viewModels = movies.map(_movieViewModel).toList();

    final html = await templates.render('movies/index.liquid', {
      'movies': viewModels,
    });

    return _html(html);
    // #endregion handler-index
  }

  Future<Response> _newMovie(Request request) async {
    final genres = await database.dataSource.query<$Genre>().orderBy('name').get();

    final html = await templates.render('movies/new.liquid', {
      'genres': genres.map(_genreViewModel).toList(),
      'errors': <String>[],
      'values': <String, String>{},
    });

    return _html(html);
  }

  Future<Response> _genresIndex(Request request) async {
    // #region handler-genres
    final genres = await database.dataSource.query<$Genre>().orderBy('name').get();

    final html = await templates.render('genres/index.liquid', {
      'genres': genres.map(_genreViewModel).toList(),
    });

    return _html(html);
    // #endregion handler-genres
  }

  Future<Response> _showGenre(Request request, String id) async {
    // #region handler-genre-show
    final genreId = int.tryParse(id);
    if (genreId == null) {
      return Response(HttpStatus.badRequest, body: 'Invalid id');
    }

    final genre = await database.dataSource.query<$Genre>().find(genreId);
    if (genre == null) {
      return Response.notFound('Genre not found');
    }

    final movies = await database.dataSource
        .query<$Movie>()
        .withRelation('genre')
        .where('genreId', genreId)
        .orderBy('createdAt', descending: true)
        .get();

    final html = await templates.render('genres/show.liquid', {
      'genre': _genreViewModel(genre),
      'movies': movies.map(_movieViewModel).toList(),
    });

    return _html(html);
    // #endregion handler-genre-show
  }

  Future<Response> _createMovie(Request request) async {
    // #region handler-create
    // #region handler-create-form
    final form = request.formData();
    if (form == null) {
      return Response(HttpStatus.badRequest, body: 'Expected form data');
    }

    final fields = <String, String>{};
    List<int>? posterBytes;
    String? posterName;

    await for (final formData in form.formData) {
      if (formData.name == 'poster' && formData.filename != null) {
        posterName = formData.filename;
        posterBytes = await formData.part.readBytes();
      } else {
        fields[formData.name] = await formData.part.readString();
      }
    }
    // #endregion handler-create-form

    // #region handler-create-validation
    final errors = _validateMovieForm(fields);
    if (errors.isNotEmpty) {
      final genres = await database.dataSource.query<$Genre>().orderBy('name').get();
      final html = await templates.render('movies/new.liquid', {
        'genres': genres.map(_genreViewModel).toList(),
        'errors': errors,
        'values': fields,
      });
      return _html(html, status: HttpStatus.badRequest);
    }
    // #endregion handler-create-validation

    // #region handler-create-storage
    final posterPath = await storage.savePoster(
      originalName: posterName,
      bytes: posterBytes,
    );
    // #endregion handler-create-storage

    // #region handler-create-db
    final repo = database.dataSource.repo<$Movie>();
    final movie = await repo.insert(MovieInsertDto(
      title: fields['title']!.trim(),
      releaseYear: int.parse(fields['releaseYear']!),
      summary: _nullIfEmpty(fields['summary']),
      posterPath: posterPath,
      genreId: _parseOptionalInt(fields['genreId']),
    ));
    // #endregion handler-create-db

    // #region handler-create-logging
    logger.info(
      'Movie created',
      Context({
        'movie_id': movie.id,
        'title': movie.title,
        'request_id': request.context['requestId'],
      }),
    );
    // #endregion handler-create-logging

    return Response.found('/movies/${movie.id}');
    // #endregion handler-create
  }


  Future<Response> _showMovie(Request request, String id) async {
    // #region handler-show
    final movieId = int.tryParse(id);
    if (movieId == null) {
      return Response(HttpStatus.badRequest, body: 'Invalid id');
    }

    final movie = await database.dataSource
        .query<$Movie>()
        .withRelation('genre')
        .find(movieId);

    if (movie == null) {
      return Response.notFound('Movie not found');
    }

    final html = await templates.render('movies/show.liquid', {
      'movie': _movieViewModel(movie),
    });

    return _html(html);
    // #endregion handler-show
  }

  Future<Response> _editMovie(Request request, String id) async {
    // #region handler-edit
    final movieId = int.tryParse(id);
    if (movieId == null) {
      return Response(HttpStatus.badRequest, body: 'Invalid id');
    }

    final movie = await database.dataSource
        .query<$Movie>()
        .withRelation('genre')
        .find(movieId);

    if (movie == null) {
      return Response.notFound('Movie not found');
    }

    final genres = await database.dataSource.query<$Genre>().orderBy('name').get();

    final html = await templates.render('movies/edit.liquid', {
      'movie': _movieViewModel(movie),
      'genres': genres.map(_genreViewModel).toList(),
      'errors': <String>[],
      'values': {
        'title': movie.title,
        'releaseYear': movie.releaseYear.toString(),
        'summary': movie.summary ?? '',
        'genreId': movie.genreId?.toString() ?? '',
      },
    });

    return _html(html);
    // #endregion handler-edit
  }

  Future<Response> _updateMovie(Request request, String id) async {
    // #region handler-update
    final movieId = int.tryParse(id);
    if (movieId == null) {
      return Response(HttpStatus.badRequest, body: 'Invalid id');
    }

    // #region handler-update-form
    final form = request.formData();
    if (form == null) {
      return Response(HttpStatus.badRequest, body: 'Expected form data');
    }

    final fields = <String, String>{};
    await for (final formData in form.formData) {
      fields[formData.name] = await formData.part.readString();
    }
    // #endregion handler-update-form

    // #region handler-update-validation
    final errors = _validateMovieForm(fields);
    if (errors.isNotEmpty) {
      final genres = await database.dataSource.query<$Genre>().orderBy('name').get();
      final html = await templates.render('movies/edit.liquid', {
        'movie': {'id': movieId},
        'genres': genres.map(_genreViewModel).toList(),
        'errors': errors,
        'values': fields,
      });
      return _html(html, status: HttpStatus.badRequest);
    }
    // #endregion handler-update-validation

    // #region handler-update-db
    final repo = database.dataSource.repo<$Movie>();
    final movie = await repo.update(
      MovieUpdateDto(
        title: fields['title']!.trim(),
        releaseYear: int.parse(fields['releaseYear']!),
        summary: _nullIfEmpty(fields['summary']),
        genreId: _parseOptionalInt(fields['genreId']),
      ),
      where: {'id': movieId},
    );
    // #endregion handler-update-db

    // #region handler-update-logging
    logger.info(
      'Movie updated',
      Context({
        'movie_id': movie.id,
        'title': movie.title,
        'request_id': request.context['requestId'],
      }),
    );
    // #endregion handler-update-logging

    return Response.found('/movies/${movie.id}');
    // #endregion handler-update
  }


  Future<Response> _confirmDeleteMovie(Request request, String id) async {
    // #region handler-delete-confirm
    final movieId = int.tryParse(id);
    if (movieId == null) {
      return Response(HttpStatus.badRequest, body: 'Invalid id');
    }

    final movie = await database.dataSource
        .query<$Movie>()
        .withRelation('genre')
        .find(movieId);

    if (movie == null) {
      return Response.notFound('Movie not found');
    }

    final html = await templates.render('movies/delete.liquid', {
      'movie': _movieViewModel(movie),
    });

    return _html(html);
    // #endregion handler-delete-confirm
  }

  Future<Response> _deleteMovie(Request request, String id) async {
    // #region handler-delete
    final movieId = int.tryParse(id);
    if (movieId == null) {
      return Response(HttpStatus.badRequest, body: 'Invalid id');
    }

    final repo = database.dataSource.repo<$Movie>();
    final deleted = await repo.deleteById(movieId);
    if (deleted == 0) {
      return Response.notFound('Movie not found');
    }

    logger.info(
      'Movie deleted',
      Context({
        'movie_id': movieId,
        'request_id': request.context['requestId'],
      }),
    );

    return Response.found('/');
    // #endregion handler-delete
  }

  Future<Response> _apiListMovies(Request request) async {
    // #region api-list-movies
    final movies = await database.dataSource
        .query<$Movie>()
        .withRelation('genre')
        .orderBy('createdAt', descending: true)
        .get();

    return _json({
      'movies': movies.map(_movieViewModel).toList(),
    });
    // #endregion api-list-movies
  }

  Future<Response> _apiListGenres(Request request) async {
    // #region api-list-genres
    final genres = await database.dataSource.query<$Genre>().orderBy('name').get();
    return _json({
      'genres': genres.map(_genreViewModel).toList(),
    });
    // #endregion api-list-genres
  }

  Future<Response> _apiShowGenre(Request request, String id) async {
    // #region api-show-genre
    final genreId = int.tryParse(id);
    if (genreId == null) {
      return _json({'error': 'Invalid id'}, status: HttpStatus.badRequest);
    }

    final genre = await database.dataSource.query<$Genre>().find(genreId);
    if (genre == null) {
      return _json({'error': 'Genre not found'}, status: HttpStatus.notFound);
    }

    final movies = await database.dataSource
        .query<$Movie>()
        .withRelation('genre')
        .where('genreId', genreId)
        .orderBy('createdAt', descending: true)
        .get();

    return _json({
      'genre': _genreViewModel(genre),
      'movies': movies.map(_movieViewModel).toList(),
    });
    // #endregion api-show-genre
  }

  Future<Response> _apiShowMovie(Request request, String id) async {
    // #region api-show-movie
    final movieId = int.tryParse(id);
    if (movieId == null) {
      return _json({'error': 'Invalid id'}, status: HttpStatus.badRequest);
    }

    final movie = await database.dataSource
        .query<$Movie>()
        .withRelation('genre')
        .find(movieId);

    if (movie == null) {
      return _json({'error': 'Movie not found'}, status: HttpStatus.notFound);
    }

    return _json({'movie': _movieViewModel(movie)});
    // #endregion api-show-movie
  }

  Future<Response> _apiCreateMovie(Request request) async {
    // #region api-create-movie
    final payload = await _readJson(request);
    if (payload == null) {
      return _json({'error': 'Invalid JSON'}, status: HttpStatus.badRequest);
    }

    final errors = _validateMoviePayload(payload);
    if (errors.isNotEmpty) {
      return _json({'errors': errors}, status: HttpStatus.badRequest);
    }

    final repo = database.dataSource.repo<$Movie>();
    final movie = await repo.insert(MovieInsertDto(
      title: payload['title']!.trim(),
      releaseYear: payload['releaseYear']!,
      summary: _nullIfEmpty(payload['summary']),
      posterPath: _nullIfEmpty(payload['posterPath']),
      genreId: _parseOptionalInt(payload['genreId']),
    ));

    return _json({'movie': _movieViewModel(movie)}, status: HttpStatus.created);
    // #endregion api-create-movie
  }

  Future<Response> _apiUpdateMovie(Request request, String id) async {
    // #region api-update-movie
    final movieId = int.tryParse(id);
    if (movieId == null) {
      return _json({'error': 'Invalid id'}, status: HttpStatus.badRequest);
    }

    final payload = await _readJson(request);
    if (payload == null) {
      return _json({'error': 'Invalid JSON'}, status: HttpStatus.badRequest);
    }

    final repo = database.dataSource.repo<$Movie>();
    final update = MovieUpdateDto(
      title: payload['title'],
      releaseYear: payload['releaseYear'],
      summary: _nullIfEmpty(payload['summary']),
      posterPath: _nullIfEmpty(payload['posterPath']),
      genreId: _parseOptionalInt(payload['genreId']),
    );

    final movie = await repo.update(
      update,
      where: {'id': movieId},
    );

    return _json({'movie': _movieViewModel(movie)});
    // #endregion api-update-movie
  }

  Future<Response> _apiDeleteMovie(Request request, String id) async {
    // #region api-delete-movie
    final movieId = int.tryParse(id);
    if (movieId == null) {
      return _json({'error': 'Invalid id'}, status: HttpStatus.badRequest);
    }

    final repo = database.dataSource.repo<$Movie>();
    final deleted = await repo.deleteById(movieId);
    if (deleted == 0) {
      return _json({'error': 'Movie not found'}, status: HttpStatus.notFound);
    }

    return _json({'deleted': true, 'id': movieId});
    // #endregion api-delete-movie
  }

  Map<String, Object?> _movieViewModel(Movie movie) {
    final posterUrl = movie.posterPath == null
        ? null
        : storage.publicUrl(movie.posterPath!);

    return {
      'id': movie.id,
      'title': movie.title,
      'release_year': movie.releaseYear,
      'summary': movie.summary,
      'poster_url': posterUrl,
      'genre': movie.genre == null
          ? null
          : {
              'id': movie.genre!.id,
              'name': movie.genre!.name,
            },
    };
  }

  Map<String, Object?> _genreViewModel(Genre genre) {
    return {
      'id': genre.id.toString(),
      'name': genre.name,
      'description': genre.description,
    };
  }


  List<String> _validateMovieForm(Map<String, String> fields) {
    final errors = <String>[];
    if (fields['title'] == null || fields['title']!.trim().isEmpty) {
      errors.add('Title is required.');
    }

    final year = int.tryParse(fields['releaseYear'] ?? '');
    if (year == null || year < 1888) {
      errors.add('Release year must be a valid year (1888+).');
    }

    return errors;
  }

  int? _parseOptionalInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is String && raw.isNotEmpty) {
      return int.tryParse(raw);
    }
    return null;
  }

  String? _nullIfEmpty(Object? value) {
    if (value == null) return null;
    if (value is! String) return value.toString();
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Response _html(String body, {int status = HttpStatus.ok}) {
    return Response(
      status,
      body: body,
      headers: const {'content-type': 'text/html; charset=utf-8'},
    );
  }

  Response _json(Object body, {int status = HttpStatus.ok}) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Future<Map<String, dynamic>?> _readJson(Request request) async {
    try {
      final raw = await request.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<String> _validateMoviePayload(Map<String, dynamic> payload) {
    final errors = <String>[];
    final title = payload['title'];
    if (title is! String || title.trim().isEmpty) {
      errors.add('Title is required.');
    }
    final releaseYear = payload['releaseYear'];
    if (releaseYear is! int || releaseYear < 1888) {
      errors.add('Release year must be a valid year (1888+).');
    }
    return errors;
  }
}
