import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:movie_database/movie_database.dart';
import 'package:movie_network/movie_network.dart';
import 'package:yamovies/application/demo_settings.dart';
import 'package:yamovies/data/cached_movie_repository.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/domain/movie.dart';
import 'package:yamovies/domain/movie_details.dart';
import 'package:yamovies/domain/tmdb_responses.dart';

/// Сеть, которую можно выключить одной строкой.
class _SwitchableRemote implements MovieRepository {
  _SwitchableRemote();

  bool isOffline = false;

  @override
  Stream<List<Movie>> watchMovies() => Stream<List<Movie>>.fromFuture(
    getMovies().then((MoviesPageResponse page) => page.results),
  );

  @override
  Stream<List<Genre>> watchGenres() => Stream<List<Genre>>.fromFuture(
    getGenres().then((MovieGenresResponse response) => response.genres),
  );

  @override
  Stream<Object> get backgroundErrors => const Stream<Object>.empty();

  @override
  Future<MoviesPageResponse> getMovies() async {
    if (isOffline) {
      throw const SocketException('нет сети');
    }

    return const MoviesPageResponse(
      page: 1,
      results: <Movie>[_movie],
      totalPages: 1,
      totalResults: 1,
    );
  }

  @override
  Future<MovieGenresResponse> getGenres() async {
    if (isOffline) {
      throw const SocketException('нет сети');
    }

    return const MovieGenresResponse(
      genres: <Genre>[Genre(id: 18, name: 'Drama')],
    );
  }

  @override
  Future<MovieDetails> getMovieDetails(int id) async =>
      throw UnimplementedError();

  @override
  Future<List<CastMember>> getMovieCast(int id) async =>
      throw UnimplementedError();

  @override
  Future<List<Movie>> getSimilarMovies(int id) async =>
      throw UnimplementedError();

  @override
  Future<List<Movie>> searchMovies(String query, {CancelToken? cancelToken}) =>
      throw UnimplementedError();
}

const Movie _movie = Movie(
  adult: false,
  backdropPath: null,
  genreIds: <int>[18, 80],
  id: 278,
  originalLanguage: 'en',
  originalTitle: 'The Shawshank Redemption',
  overview: 'Hope is a good thing.',
  popularity: 73.8,
  posterPath: '/poster.jpg',
  releaseDate: '1994-09-23',
  title: 'The Shawshank Redemption',
  video: false,
  voteAverage: 8.7,
  voteCount: 30412,
);

void main() {
  late AppDatabase database;
  late _SwitchableRemote remote;
  late CachedMovieRepository repository;

  setUp(() {
    // Настоящая БД в памяти: полноценный SQL и ноль файлов на диске.
    database = AppDatabase(NativeDatabase.memory());
    remote = _SwitchableRemote();
    repository = CachedMovieRepository(
      remote: remote,
      database: database,
      demoSettings: DemoSettings(),
    );
  });

  tearDown(() => database.close());

  test('ответ сети складывается в кэш', () async {
    await repository.getMovies();

    expect(await database.countMovies(), 1);
    expect(await database.lastSyncAt('movies'), isNotNull);
  });

  test('при обрыве сети лента приходит из кэша', () async {
    await repository.getMovies();
    remote.isOffline = true;

    final MoviesPageResponse response = await repository.getMovies();

    expect(response.results.single.title, _movie.title);
    expect(response.results.single.genreIds, <int>[18, 80]);
  });

  test('пустой кэш и нет сети — ошибка, а не пустой экран', () async {
    remote.isOffline = true;

    expect(repository.getMovies(), throwsA(isA<SocketException>()));
  });

  test('watchMovies отдаёт обновление после записи', () async {
    // Первый снимок может прийти уже с данными: запись успевает раньше
    // первой эмиссии, поэтому ждём «когда-нибудь дойдёт до одной строки».
    final Future<void> expectation = expectLater(
      database.watchMovies().map((List<CachedMovie> rows) => rows.length),
      emitsThrough(1),
    );

    await repository.getMovies();
    await expectation;
  });
}
