import 'movie.dart';

class MoviesPageResponse {
  const MoviesPageResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  final int page;
  final List<Movie> results;
  final int totalPages;
  final int totalResults;
}

class MovieGenresResponse {
  const MovieGenresResponse({required this.genres});

  final List<Genre> genres;
}
