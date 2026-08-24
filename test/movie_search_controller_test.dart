import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_network/movie_network.dart';
import 'package:yamovies/application/module/search/movie_search_controller.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/domain/movie.dart';
import 'package:yamovies/domain/movie_details.dart';
import 'package:yamovies/domain/tmdb_responses.dart';

/// Репозиторий, который считает запросы и отвечает с задержкой.
class _CountingRepository implements MovieRepository {
  _CountingRepository({this.delay = const Duration(milliseconds: 200)});

  final Duration delay;
  final List<String> queries = <String>[];
  final List<String> cancelled = <String>[];

  @override
  Future<List<Movie>> searchMovies(String query, {CancelToken? cancelToken}) {
    queries.add(query);
    cancelToken?.whenCancel.then((_) => cancelled.add(query));

    return Future<List<Movie>>.delayed(delay, () => <Movie>[_movie(query)]);
  }

  @override
  Future<MoviesPageResponse> getMovies() async => throw UnimplementedError();

  @override
  Future<MovieGenresResponse> getGenres() async => throw UnimplementedError();

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
  Stream<List<Movie>> watchMovies() => Stream<List<Movie>>.fromFuture(
    getMovies().then((MoviesPageResponse page) => page.results),
  );

  @override
  Stream<List<Genre>> watchGenres() => Stream<List<Genre>>.fromFuture(
    getGenres().then((MovieGenresResponse response) => response.genres),
  );

  @override
  Stream<Object> get backgroundErrors => const Stream<Object>.empty();
}

Movie _movie(String title) => Movie(
  adult: false,
  backdropPath: null,
  genreIds: const <int>[],
  id: title.hashCode,
  originalLanguage: 'en',
  originalTitle: title,
  overview: '',
  popularity: 0,
  posterPath: null,
  releaseDate: null,
  title: title,
  video: false,
  voteAverage: 0,
  voteCount: 0,
);

void main() {
  test('без debounce уходит запрос на каждую букву', () {
    // Управляем временем: тест на паузу в 300 мс выполняется мгновенно.
    fakeAsync((FakeAsync async) {
      final _CountingRepository repository = _CountingRepository();
      final MovieSearchController controller = MovieSearchController(
        repository: repository,
      );

      for (final String query in <String>['ma', 'mat', 'matr', 'matri']) {
        controller.onQueryChanged(query);
        async.elapse(const Duration(milliseconds: 50));
      }
      async.elapse(const Duration(seconds: 1));

      expect(repository.queries, <String>['ma', 'mat', 'matr', 'matri']);
      controller.dispose();
      async.elapse(const Duration(seconds: 1));
    });
  });

  test('debounce схлопывает набор в один запрос', () {
    fakeAsync((FakeAsync async) {
      final _CountingRepository repository = _CountingRepository();
      final MovieSearchController controller = MovieSearchController(
        repository: repository,
      )..setMode(SearchMode.debounce);

      for (final String query in <String>['ma', 'mat', 'matr', 'matri']) {
        controller.onQueryChanged(query);
        async.elapse(const Duration(milliseconds: 100));
      }
      expect(repository.queries, isEmpty, reason: 'пауза ещё не выдержана');

      async.elapse(const Duration(seconds: 1));
      expect(repository.queries, <String>['matri']);

      controller.dispose();
      async.elapse(const Duration(seconds: 1));
    });
  });

  // Этот тест идёт в реальном времени, а не в `fakeAsync`: связка rxdart
  // с фиктивными часами не доводит до конца внутренние потоки `switchMap`,
  // и проверка получилась бы про поведение библиотеки в тесте, а не про наш код.
  test('switchMap отменяет незавершённый запрос', () async {
    final _CountingRepository repository = _CountingRepository(
      delay: const Duration(milliseconds: 600),
    );
    final MovieSearchController controller = MovieSearchController(
      repository: repository,
    )..setMode(SearchMode.debounceAndSwitchMap);
    addTearDown(controller.dispose);

    controller.onQueryChanged('matrix');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(repository.queries, <String>['matrix']);

    // Новый ввод приходит, пока первый запрос ещё в полёте.
    controller.onQueryChanged('matrix reloaded');
    await Future<void>.delayed(const Duration(milliseconds: 2000));

    expect(repository.cancelled, contains('matrix'));
    expect(repository.queries.last, 'matrix reloaded');

    final MovieSearchState state = controller.currentState;
    expect(state, isA<SearchResultsState>());
    expect((state as SearchResultsState).query, 'matrix reloaded');
  });

  test('закрытие контроллера посреди запроса проходит без ошибок', () async {
    final _CountingRepository repository = _CountingRepository();
    final MovieSearchController controller = MovieSearchController(
      repository: repository,
    );

    final List<Object> zoneErrors = <Object>[];
    await runZonedGuarded(() async {
      controller.onQueryChanged('matrix');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }, (Object error, StackTrace stackTrace) => zoneErrors.add(error));

    expect(zoneErrors, isEmpty);
  });
}
