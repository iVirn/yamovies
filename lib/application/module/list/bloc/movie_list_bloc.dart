import 'package:bloc/bloc.dart';

import '../../../../data/movie_repository.dart';
import '../../../../domain/movie.dart';
import '../../../../domain/tmdb_responses.dart';

part 'movie_list_event.dart';
part 'movie_list_state.dart';

class MovieListBloc extends Bloc<MovieListEvent, MovieListState> {
  MovieListBloc({required MovieRepository repository})
    : _repository = repository, // ignore: prefer_initializing_formals
      super(const MovieListLoadingState()) {
    on<MovieListStarted>(_onStarted);
  }

  final MovieRepository _repository;

  Future<void> _onStarted(
    MovieListStarted event,
    Emitter<MovieListState> emit,
  ) async {
    emit(const MovieListLoadingState());

    final MoviesPageResponse moviesResponse = await _repository.getMovies();
    final MovieGenresResponse genresResponse = await _repository.getGenres();

    emit(
      MovieListSuccessState(
        movies: moviesResponse.results,
        genres: <Genre>[
          ...genresResponse.genres,
          const Genre(id: 878, name: 'Science Fiction'),
        ],
      ),
    );
  }
}
