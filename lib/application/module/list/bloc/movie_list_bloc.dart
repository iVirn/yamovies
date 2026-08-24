import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/movie_repository.dart';
import '../../../../domain/movie.dart';
import '../../../../domain/tmdb_responses.dart';
import '../../../../utils/error_messages.dart';

part 'movie_list_event.dart';
part 'movie_list_state.dart';

class MovieListBloc extends Bloc<MovieListEvent, MovieListState> {
  MovieListBloc({required MovieRepository repository})
    : _repository = repository, // ignore: prefer_initializing_formals
      super(const MovieListLoadingState()) {
    on<MovieListStarted>(_onStarted);
    on<MovieListRefreshed>(_onStarted);
  }

  final MovieRepository _repository;

  Future<void> _onStarted(
    MovieListEvent event,
    Emitter<MovieListState> emit,
  ) async {
    emit(const MovieListLoadingState());

    try {
      // Лента и справочник жанров независимы — незачем ждать их по очереди.
      final (MoviesPageResponse moviesResponse, MovieGenresResponse genresResponse) =
          await (_repository.getMovies(), _repository.getGenres()).wait;

      if (emit.isDone) {
        return;
      }

      emit(
        MovieListSuccessState(
          movies: moviesResponse.results,
          genres: genresResponse.genres,
        ),
      );
    } catch (error) {
      if (emit.isDone) {
        return;
      }

      emit(
        MovieListFailureState(
          message: describeLoadError(_unwrap(error)),
          canRetry: isRetryable(_unwrap(error)),
        ),
      );
    }
  }

  /// `(f1, f2).wait` заворачивает ошибки в `ParallelWaitError`: достаём первую
  /// настоящую, иначе пользователь увидит служебный текст.
  Object _unwrap(Object error) => switch (error) {
    ParallelWaitError<dynamic, dynamic>(:final Object? errors) =>
      _firstError(errors) ?? error,
    _ => error,
  };

  Object? _firstError(Object? errors) {
    if (errors is (AsyncError?, AsyncError?)) {
      return (errors.$1 ?? errors.$2)?.error;
    }
    if (errors is List<AsyncError?>) {
      for (final AsyncError? error in errors) {
        if (error != null) {
          return error.error;
        }
      }
    }

    return null;
  }
}
