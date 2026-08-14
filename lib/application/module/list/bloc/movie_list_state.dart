part of 'movie_list_bloc.dart';

sealed class MovieListState {
  const MovieListState();
}

final class MovieListLoadingState extends MovieListState {
  const MovieListLoadingState();
}

final class MovieListSuccessState extends MovieListState {
  const MovieListSuccessState({
    required this.movies,
    required this.genres,
    this.favoriteMovieIds = const <int>{},
    this.selectedGenreIds = const <int>{},
  });

  final List<Movie> movies;
  final List<Genre> genres;
  final Set<int> favoriteMovieIds;
  final Set<int> selectedGenreIds;

  Map<int, String> get genreNamesById => <int, String>{
    for (final Genre genre in genres) genre.id: genre.name,
  };

  List<Movie> get filteredMovies =>
      filterMoviesByGenres(movies, selectedGenreIds);

  List<Genre> get selectedGenres => <Genre>[
    for (final Genre genre in genres)
      if (selectedGenreIds.contains(genre.id)) genre,
  ];

  bool isFavorite(int movieId) => favoriteMovieIds.contains(movieId);

  MovieListSuccessState copyWith({
    List<Movie>? movies,
    List<Genre>? genres,
    Set<int>? favoriteMovieIds,
    Set<int>? selectedGenreIds,
  }) => MovieListSuccessState(
    movies: movies ?? this.movies,
    genres: genres ?? this.genres,
    favoriteMovieIds: favoriteMovieIds ?? this.favoriteMovieIds,
    selectedGenreIds: selectedGenreIds ?? this.selectedGenreIds,
  );
}
