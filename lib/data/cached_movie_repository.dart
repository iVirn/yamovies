// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';

import 'package:movie_database/movie_database.dart';
import 'package:movie_network/movie_network.dart';

import '../application/demo_settings.dart';
import '../domain/movie.dart';
import '../domain/movie_details.dart';
import '../domain/tmdb_responses.dart';
import 'movie_repository.dart';

/// Что лежит в кэше прямо сейчас — для экрана-инспектора.
///
/// Экран не должен знать ни про drift, ни про строки таблиц: класс
/// `CachedMovie` сгенерировал drift, и дальше репозитория он не уезжает.
class CacheSnapshot {
  const CacheSnapshot({
    required this.movies,
    required this.cachedAt,
    required this.lastSyncAt,
  });

  final List<Movie> movies;

  /// Когда попал в кэш каждый фильм: id → время записи.
  final Map<int, DateTime> cachedAt;
  final DateTime? lastSyncAt;
}

/// Репозиторий, который знает про кэш.
///
/// Две стратегии в одном классе: `watchMovies()` — **stale-while-revalidate**
/// (сразу отдаём кэш и параллельно идём в сеть), а разовый `getMovies()` —
/// **network-first** с откатом на кэш, когда сеть недоступна.
final class CachedMovieRepository implements MovieRepository {
  CachedMovieRepository({
    required this.remote,
    required this.database,
    required DemoSettings demoSettings,
  }) : _demoSettings = demoSettings;

  final MovieRepository remote;
  final AppDatabase database;
  final DemoSettings _demoSettings;

  /// Ошибки фонового обновления: экран показывает их баннером, но кэш
  /// при этом не трогает.
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  @override
  Stream<Object> get backgroundErrors => _errors.stream;

  @override
  /// Кэш, потом сеть — stale-while-revalidate.
  ///
  /// Первым приходит то, что уже лежит в базе: экран открывается мгновенно
  /// и без спиннера. Дальше фоновый запрос пишет свежие данные в ту же
  /// таблицу, и они приезжают этим же потоком — второй эмиссией.
  Stream<List<Movie>> watchMovies() async* {
    bool refreshed = false;

    await for (final List<CachedMovie> cached in database.watchMovies()) {
      yield <Movie>[for (final CachedMovie row in cached) _toDomain(row)];

      if (!refreshed) {
        refreshed = true;
        unawaited(_refreshMovies());
      }
    }
  }

  @override
  Stream<List<Genre>> watchGenres() async* {
    bool refreshed = false;

    await for (final List<CachedGenre> cached in database.watchGenres()) {
      yield <Genre>[
        for (final CachedGenre row in cached) Genre(id: row.id, name: row.name),
      ];

      if (!refreshed) {
        refreshed = true;
        unawaited(_refreshGenres());
      }
    }
  }

  Future<void> _refreshMovies() async {
    try {
      await getMovies();
    } catch (error) {
      // Кэш остаётся на месте: пользователь видит данные, а не пустой экран.
      _errors.add(error);
    }
  }

  Future<void> _refreshGenres() async {
    try {
      await getGenres();
    } catch (error) {
      _errors.add(error);
    }
  }

  /// Демо «режим полёта»: гасим сеть внутри приложения, чтобы не выключать
  /// Wi-Fi на лекции. Для остального кода это обычный `SocketException`.
  void _checkAirplaneMode() {
    if (_demoSettings.airplaneMode) {
      throw const SocketException('Режим полёта: сети нет');
    }
  }

  @override
  Future<MoviesPageResponse> getMovies() async {
    try {
      _checkAirplaneMode();
      final MoviesPageResponse response = await remote.getMovies();
      await database.upsertMovies(
        <CachedMoviesCompanion>[
          for (final Movie movie in response.results) _toCompanion(movie),
        ],
      );

      return response;
    } on SocketException {
      return _moviesFromCacheOr(rethrowIfEmpty: true);
    } on TimeoutException {
      return _moviesFromCacheOr(rethrowIfEmpty: true);
    }
  }

  @override
  Future<MovieGenresResponse> getGenres() async {
    try {
      _checkAirplaneMode();
      final MovieGenresResponse response = await remote.getGenres();
      await database.upsertGenres(
        <CachedGenresCompanion>[
          for (final Genre genre in response.genres)
            CachedGenresCompanion.insert(id: Value<int>(genre.id), name: genre.name),
        ],
      );

      return response;
    } on SocketException {
      return _genresFromCache();
    } on TimeoutException {
      return _genresFromCache();
    }
  }

  // Детали, актёры и похожие пока не кэшируются: их экран открывается
  // по одному фильму, и кэш ему даёт меньше, чем ленте.
  @override
  Future<MovieDetails> getMovieDetails(int id) {
    _checkAirplaneMode();

    return remote.getMovieDetails(id);
  }

  @override
  Future<List<CastMember>> getMovieCast(int id) {
    _checkAirplaneMode();

    return remote.getMovieCast(id);
  }

  @override
  Future<List<Movie>> getSimilarMovies(int id) {
    _checkAirplaneMode();

    return remote.getSimilarMovies(id);
  }

  @override
  Future<List<Movie>> searchMovies(String query, {CancelToken? cancelToken}) {
    _checkAirplaneMode();

    return remote.searchMovies(query, cancelToken: cancelToken);
  }

  Future<void> dispose() => _errors.close();

  /// Снимок кэша для экрана-инспектора: доменные модели плюс время записи.
  Stream<CacheSnapshot> watchCacheSnapshot() async* {
    await for (final List<CachedMovie> rows in database.watchMovies()) {
      yield CacheSnapshot(
        movies: <Movie>[for (final CachedMovie row in rows) _toDomain(row)],
        cachedAt: <int, DateTime>{
          for (final CachedMovie row in rows) row.id: row.cachedAt,
        },
        lastSyncAt: await database.lastSyncAt('movies'),
      );
    }
  }

  /// Очистить кэш — тоже через репозиторий, а не в обход него.
  Future<void> clearCache() => database.clearCache();

  Future<MoviesPageResponse> _moviesFromCacheOr({
    required bool rethrowIfEmpty,
  }) async {
    final List<CachedMovie> cached = await database.readMovies();
    if (cached.isEmpty && rethrowIfEmpty) {
      throw const SocketException('Нет сети и пустой кэш');
    }

    final List<Movie> movies = <Movie>[
      for (final CachedMovie row in cached) _toDomain(row),
    ];

    return MoviesPageResponse(
      page: 1,
      results: movies,
      totalPages: 1,
      totalResults: movies.length,
    );
  }

  Future<MovieGenresResponse> _genresFromCache() async {
    final List<CachedGenre> cached = await database.readGenres();

    return MovieGenresResponse(
      genres: <Genre>[
        for (final CachedGenre row in cached)
          Genre(id: row.id, name: row.name),
      ],
    );
  }
}

/// Граница репозитория: доменная модель превращается в строку таблицы.
CachedMoviesCompanion _toCompanion(Movie movie) => CachedMoviesCompanion.insert(
  id: Value<int>(movie.id),
  title: movie.title,
  overview: Value<String>(movie.overview),
  posterPath: Value<String?>(movie.posterPath),
  releaseDate: Value<String?>(movie.releaseDate),
  voteAverage: Value<double>(movie.voteAverage),
  voteCount: Value<int>(movie.voteCount),
  popularity: Value<double>(movie.popularity),
  genreIds: Value<String>(movie.genreIds.join(',')),
  cachedAt: DateTime.now(),
);

/// И обратно: строка таблицы — в доменную модель. Класс `CachedMovie`
/// сгенерировал drift, дальше репозитория он не уезжает.
Movie _toDomain(CachedMovie row) => Movie(
  adult: false,
  backdropPath: null,
  genreIds: <int>[
    for (final String raw in row.genreIds.split(','))
      if (int.tryParse(raw) case final int id) id,
  ],
  id: row.id,
  originalLanguage: '',
  originalTitle: row.title,
  overview: row.overview,
  popularity: row.popularity,
  posterPath: row.posterPath,
  releaseDate: row.releaseDate,
  title: row.title,
  video: false,
  voteAverage: row.voteAverage,
  voteCount: row.voteCount,
);
