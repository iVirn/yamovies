import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_network/movie_network.dart';
import 'package:yamovies/application/demo_settings.dart';
import 'package:yamovies/application/module/details/bloc/movie_details_bloc.dart';
import 'package:yamovies/data/movie_repository.dart';
import 'package:yamovies/domain/movie.dart';
import 'package:yamovies/domain/movie_details.dart';
import 'package:yamovies/domain/tmdb_responses.dart';

/// Репозиторий с управляемой задержкой: так видно и время загрузки,
/// и то, что происходит, если экран закрыть посреди запросов.
class _SlowRepository implements MovieRepository {
  const _SlowRepository({this.delay = const Duration(milliseconds: 100)});

  final Duration delay;

  @override
  Future<MoviesPageResponse> getMovies() async => throw UnimplementedError();

  @override
  Future<MovieGenresResponse> getGenres() async => throw UnimplementedError();

  @override
  Future<MovieDetails> getMovieDetails(int id) =>
      Future<MovieDetails>.delayed(delay, () => _details);

  @override
  Future<List<CastMember>> getMovieCast(int id) =>
      Future<List<CastMember>>.delayed(delay, () => const <CastMember>[]);

  @override
  Future<List<Movie>> getSimilarMovies(int id) =>
      Future<List<Movie>>.delayed(delay, () => const <Movie>[]);
}

const MovieDetails _details = MovieDetails(
  id: 278,
  title: 'The Shawshank Redemption',
  overview: 'Hope is a good thing.',
  tagline: '',
  runtimeMinutes: 142,
  status: 'Released',
  genres: <Genre>[],
  voteAverage: 8.7,
  voteCount: 30412,
  releaseDate: '1994-09-23',
  posterPath: null,
);

/// Ловит то, что bloc обычно проглатывает молча.
class _RecordingObserver implements BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {}

  @override
  void onClose(BlocBase<dynamic> bloc) {}

  @override
  void onCreate(BlocBase<dynamic> bloc) {}

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {}

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {}

  @override
  void onDone(
    Bloc<dynamic, dynamic> bloc,
    Object? event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {}

  final List<Object> errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) =>
      errors.add(error);
}

void main() {
  late _RecordingObserver observer;

  setUp(() {
    observer = _RecordingObserver();
    Bloc.observer = observer;
  });

  tearDown(() => Bloc.observer = _RecordingObserver());

  test('последовательная загрузка складывает три ожидания', () async {
    final MovieDetailsBloc bloc = MovieDetailsBloc(
      repository: const _SlowRepository(),
      demoSettings: DemoSettings(),
      movieId: 278,
    )..add(const MovieDetailsStarted());
    addTearDown(bloc.close);

    final MovieDetailsSuccessState state = await bloc.stream.firstWhere(
      (MovieDetailsState state) => state is MovieDetailsSuccessState,
    ) as MovieDetailsSuccessState;

    expect(state.bundle.loadedInParallel, isFalse);
    // Три запроса по 100 мс подряд — не меньше 300 мс на всё.
    expect(state.bundle.loadDuration.inMilliseconds, greaterThanOrEqualTo(300));
  });

  test('Future.wait ждёт самый долгий запрос, а не сумму', () async {
    final DemoSettings demoSettings = DemoSettings()
      ..parallelDetailsLoad = true;
    final MovieDetailsBloc bloc = MovieDetailsBloc(
      repository: const _SlowRepository(),
      demoSettings: demoSettings,
      movieId: 278,
    )..add(const MovieDetailsStarted());
    addTearDown(bloc.close);

    final MovieDetailsSuccessState state = await bloc.stream.firstWhere(
      (MovieDetailsState state) => state is MovieDetailsSuccessState,
    ) as MovieDetailsSuccessState;

    expect(state.bundle.loadedInParallel, isTrue);
    expect(state.bundle.loadDuration.inMilliseconds, lessThan(300));
  });

  test('уход с экрана посреди загрузки не роняет bloc', () async {
    final MovieDetailsBloc bloc = MovieDetailsBloc(
      repository: const _SlowRepository(delay: Duration(milliseconds: 50)),
      demoSettings: DemoSettings(),
      movieId: 278,
    )..add(const MovieDetailsStarted());

    // Закрываем экран, пока три запроса ещё в полёте.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await bloc.close();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Регрессионная страховка: закрытие экрана посреди загрузки не должно
    // давать ни ошибок, ни состояний. В bloc 9 эмит в закрытый bloc молча
    // игнорируется, в 8.x он бросал StateError — тест переживёт обновление.
    expect(observer.errors, isEmpty);
    expect(bloc.state, isA<MovieDetailsLoadingState>());
  });

  test('ошибка запроса превращается в состояние с сообщением', () async {
    final MovieDetailsBloc bloc = MovieDetailsBloc(
      repository: const _FailingRepository(),
      demoSettings: DemoSettings(),
      movieId: 278,
    )..add(const MovieDetailsStarted());
    addTearDown(bloc.close);

    final MovieDetailsFailureState state = await bloc.stream.firstWhere(
      (MovieDetailsState state) => state is MovieDetailsFailureState,
    ) as MovieDetailsFailureState;

    expect(state.message, contains('TMDB'));
    expect(state.canRetry, isFalse);
  });
}

class _FailingRepository extends _SlowRepository {
  const _FailingRepository();

  @override
  Future<MovieDetails> getMovieDetails(int id) async =>
      throw const ApiException(statusCode: 404, path: 'movie/278');
}
