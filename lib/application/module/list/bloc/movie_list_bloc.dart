import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../data/movie_repository.dart';
import '../../../../domain/movie.dart';
import '../../../../utils/error_messages.dart';

part 'movie_list_event.dart';
part 'movie_list_state.dart';

class MovieListBloc extends Bloc<MovieListEvent, MovieListState> {
  MovieListBloc({required MovieRepository repository})
    : _repository = repository, // ignore: prefer_initializing_formals
      super(const MovieListLoadingState()) {
    on<MovieListStarted>(_onStarted);
    on<MovieListRefreshed>(_onRefreshed);
  }

  final MovieRepository _repository;

  /// Экран подписывается на репозиторий один раз и живёт на его потоке:
  /// первым придёт кэш, следом — то, что принесла сеть.
  ///
  /// `combineLatest2` собирает пару из двух независимых источников —
  /// ленты и справочника жанров. Молчит он только до первого значения
  /// каждого, а drift отдаёт даже пустую таблицу, поэтому экран не зависает.
  Future<void> _onStarted(
    MovieListStarted event,
    Emitter<MovieListState> emit,
  ) async {
    emit(const MovieListLoadingState());

    // Версия этой ветки: экран живёт на потоке репозитория, а `emit.forEach`
    // сам следит за тем, что bloc ещё открыт.
    await emit.forEach<({List<Movie> movies, List<Genre> genres})>(
      Rx.combineLatest2(
        _repository.watchMovies(),
        _repository.watchGenres(),
        (List<Movie> movies, List<Genre> genres) =>
            (movies: movies, genres: genres),
      ),
      onData: (({List<Movie> movies, List<Genre> genres}) data) =>
          MovieListSuccessState(movies: data.movies, genres: data.genres),
      onError: (Object error, StackTrace stackTrace) => MovieListFailureState(
        message: describeLoadError(error),
        canRetry: isRetryable(error),
      ),
    );
  }

  /// Ручное обновление: поток остаётся тем же, просто просим свежие данные.
  Future<void> _onRefreshed(
    MovieListRefreshed event,
    Emitter<MovieListState> emit,
  ) async {
    try {
      await _repository.getMovies();
      await _repository.getGenres();
    } catch (error) {
      if (state is! MovieListSuccessState) {
        emit(
          MovieListFailureState(
            message: describeLoadError(error),
            canRetry: isRetryable(error),
          ),
        );
      }
    }
  }
}
