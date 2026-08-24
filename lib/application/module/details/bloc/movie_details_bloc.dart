// ignore_for_file: prefer_initializing_formals

import 'package:bloc/bloc.dart';

import '../../../../data/movie_repository.dart';
import '../../../../domain/movie.dart';

part 'movie_details_event.dart';
part 'movie_details_state.dart';

class MovieDetailsBloc extends Bloc<MovieDetailsEvent, MovieDetailsState> {
  MovieDetailsBloc({required MovieRepository repository, required int movieId})
    : _repository = repository,
      _movieId = movieId,
      super(const MovieDetailsLoadingState()) {
    on<MovieDetailsStarted>(_onStarted);
  }

  final MovieRepository _repository;
  final int _movieId;

  Future<void> _onStarted(
    MovieDetailsStarted event,
    Emitter<MovieDetailsState> emit,
  ) async {
    emit(const MovieDetailsLoadingState());

    final Movie movie = await _repository.getMovieById(_movieId);

    emit(MovieDetailsSuccessState(movie: movie));
  }
}
