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
