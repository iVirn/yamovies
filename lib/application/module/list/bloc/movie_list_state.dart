part of 'movie_list_bloc.dart';

sealed class MovieListState {
  const MovieListState();
}

final class MovieListLoadingState extends MovieListState {
  const MovieListLoadingState();
}

final class MovieListSuccessState extends MovieListState {
  const MovieListSuccessState({required this.movies, required this.genres});

  final List<Movie> movies;
  final List<Genre> genres;
}

final class MovieListFailureState extends MovieListState {
  const MovieListFailureState({required this.message, required this.canRetry});

  final String message;
  final bool canRetry;
}
