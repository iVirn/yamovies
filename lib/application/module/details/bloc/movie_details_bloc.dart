// ignore_for_file: prefer_initializing_formals

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/movie_repository.dart';
import '../../../../domain/movie.dart';
import '../../../../domain/movie_details.dart';
import '../../../../utils/error_messages.dart';
import '../../../demo_settings.dart';

part 'movie_details_event.dart';
part 'movie_details_state.dart';

class MovieDetailsBloc extends Bloc<MovieDetailsEvent, MovieDetailsState> {
  MovieDetailsBloc({
    required MovieRepository repository,
    required DemoSettings demoSettings,
    required int movieId,
  }) : _repository = repository,
       _demoSettings = demoSettings,
       _movieId = movieId,
       super(const MovieDetailsLoadingState()) {
    on<MovieDetailsStarted>(_onStarted);
    on<MovieDetailsReloaded>(_onStarted);
  }

  final MovieRepository _repository;
  final DemoSettings _demoSettings;
  final int _movieId;

  /// Заведомо несуществующий фильм для демо «один запрос падает».
  int get _castMovieId => _demoSettings.breakCastRequest ? -1 : _movieId;

  Future<void> _onStarted(
    MovieDetailsEvent event,
    Emitter<MovieDetailsState> emit,
  ) async {
    emit(const MovieDetailsLoadingState());

    final bool parallel = _demoSettings.parallelDetailsLoad;
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final MovieDetailsBundle bundle = parallel
          ? await _loadInParallel()
          : await _loadSequentially();
      stopwatch.stop();

      // Пока летели три запроса, пользователь мог уйти с экрана. Закрытый
      // bloc эмит просто проглотит, но проверять `isDone` после каждого
      // ожидания — то, что предписывает сам bloc: иначе легко не заметить,
      // как обработчик доделывает работу для экрана, которого уже нет.
      if (emit.isDone) {
        return;
      }

      emit(
        MovieDetailsSuccessState(
          bundle: MovieDetailsBundle(
            details: bundle.details,
            cast: bundle.cast,
            similar: bundle.similar,
            loadDuration: stopwatch.elapsed,
            loadedInParallel: parallel,
            partialErrors: bundle.partialErrors,
          ),
        ),
      );
    } catch (error) {
      stopwatch.stop();

      if (emit.isDone) {
        return;
      }

      emit(
        MovieDetailsFailureState(
          message: describeLoadError(error),
          canRetry: isRetryable(error),
        ),
      );
    }
  }

  /// ❌ Три ожидания подряд: время экрана — сумма всех трёх.
  Future<MovieDetailsBundle> _loadSequentially() async {
    final MovieDetails details = await _repository.getMovieDetails(_movieId);
    final List<CastMember> cast = await _repository.getMovieCast(_castMovieId);
    final List<Movie> similar = await _repository.getSimilarMovies(_movieId);

    return MovieDetailsBundle(
      details: details,
      cast: cast,
      similar: similar,
      loadDuration: Duration.zero,
      loadedInParallel: false,
    );
  }

  /// ✅ Те же три запроса разом: время экрана — самый долгий из них.
  Future<MovieDetailsBundle> _loadInParallel() async {
    if (_demoSettings.eagerErrorOnDetails) {
      // Типы теряются (List<dynamic>) — зато видно классический вызов.
      // Records сохранили бы их: `final (d, c, s) = await (f1, f2, f3).wait;`
      final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
        _repository.getMovieDetails(_movieId),
        _repository.getMovieCast(_castMovieId),
        _repository.getSimilarMovies(_movieId),
      ], eagerError: true);

      return MovieDetailsBundle(
        details: results[0]! as MovieDetails,
        cast: results[1]! as List<CastMember>,
        similar: results[2]! as List<Movie>,
        loadDuration: Duration.zero,
        loadedInParallel: true,
      );
    }

    // Без eagerError `Future.wait` дожидается всех, но всё равно бросает первую
    // ошибку и теряет то, что доехало. Чтобы собрать частичный результат,
    // ошибку каждого запроса ловим на его собственном future.
    final List<({Object? value, Object? error})> settled = await Future.wait(
      <Future<({Object? value, Object? error})>>[
        _settle<MovieDetails>(_repository.getMovieDetails(_movieId)),
        _settle<List<CastMember>>(_repository.getMovieCast(_castMovieId)),
        _settle<List<Movie>>(_repository.getSimilarMovies(_movieId)),
      ],
    );

    final Object? detailsError = settled[0].error;
    if (detailsError != null) {
      // Без деталей экрана нет — эта ошибка фатальна, остальные нет.
      throw detailsError;
    }

    return MovieDetailsBundle(
      details: settled[0].value! as MovieDetails,
      cast: settled[1].value as List<CastMember>? ?? const <CastMember>[],
      similar: settled[2].value as List<Movie>? ?? const <Movie>[],
      loadDuration: Duration.zero,
      loadedInParallel: true,
      partialErrors: <String>[
        for (final ({Object? value, Object? error}) result in settled)
          if (result.error != null) describeLoadError(result.error!),
      ],
    );
  }

  Future<({Object? value, Object? error})> _settle<T>(Future<T> future) async {
    try {
      return (value: await future, error: null);
    } catch (error) {
      return (value: null, error: error);
    }
  }
}
