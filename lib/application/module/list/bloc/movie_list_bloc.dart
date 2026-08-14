import 'package:bloc/bloc.dart';

import '../../../../data/movie_repository.dart';
import '../../../../domain/movie.dart';
import '../../../../domain/tmdb_responses.dart';
import '../../../../utils/movie_filters.dart';

part 'movie_list_event.dart';
part 'movie_list_state.dart';

class MovieListBloc extends Bloc<MovieListEvent, MovieListState> {
  MovieListBloc({required MovieRepository repository})
    : _repository = repository, // ignore: prefer_initializing_formals
      super(const MovieListLoadingState()) {
    on<MovieListStarted>(_onStarted);
    on<MovieListFavoriteToggled>(_onFavoriteToggled);
    on<MovieListGenreToggled>(_onGenreToggled);
    on<MovieListGenresCleared>(_onGenresCleared);
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

  void _onFavoriteToggled(
    MovieListFavoriteToggled event,
    Emitter<MovieListState> emit,
  ) {
    emit(switch (state) {
      MovieListLoadingState() => state,
      MovieListSuccessState success => success.copyWith(
        favoriteMovieIds: _toggled(success.favoriteMovieIds, event.movieId),
      ),
    });
  }

  void _onGenreToggled(
    MovieListGenreToggled event,
    Emitter<MovieListState> emit,
  ) {
    emit(switch (state) {
      MovieListLoadingState() => state,
      MovieListSuccessState success => success.copyWith(
        selectedGenreIds: _toggled(success.selectedGenreIds, event.genreId),
      ),
    });
  }

  void _onGenresCleared(
    MovieListGenresCleared event,
    Emitter<MovieListState> emit,
  ) {
    emit(switch (state) {
      MovieListLoadingState() => state,
      MovieListSuccessState success => success.copyWith(
        selectedGenreIds: const <int>{},
      ),
    });
  }

  Set<int> _toggled(Set<int> ids, int id) {
    final Set<int> next = Set<int>.of(ids);
    if (!next.add(id)) {
      next.remove(id);
    }
    return next;
  }
}
