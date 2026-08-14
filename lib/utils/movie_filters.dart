import '../domain/movie.dart';

List<Movie> filterMoviesByGenres(
  List<Movie> movies,
  Set<int> selectedGenreIds,
) {
  if (selectedGenreIds.isEmpty) {
    return movies;
  }

  return <Movie>[
    for (final Movie movie in movies)
      if (movie.genreIds.any(selectedGenreIds.contains)) movie,
  ];
}

List<String> resolveMovieGenres(Movie movie, Map<int, String> genreNamesById) {
  if (movie.genreIds.isEmpty) {
    return const <String>['Unknown'];
  }

  return <String>[
    for (final int genreId in movie.genreIds)
      genreNamesById[genreId] ?? 'Unknown',
  ];
}
