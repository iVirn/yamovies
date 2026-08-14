part of 'movie_list_bloc.dart';

sealed class MovieListEvent {
  const MovieListEvent();
}

final class MovieListStarted extends MovieListEvent {
  const MovieListStarted();
}

final class MovieListFavoriteToggled extends MovieListEvent {
  const MovieListFavoriteToggled(this.movieId);

  final int movieId;
}

final class MovieListGenreToggled extends MovieListEvent {
  const MovieListGenreToggled(this.genreId);

  final int genreId;
}

final class MovieListGenresCleared extends MovieListEvent {
  const MovieListGenresCleared();
}
