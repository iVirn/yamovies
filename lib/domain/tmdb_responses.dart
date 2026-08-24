import 'movie.dart';

class MoviesPageResponse {
  const MoviesPageResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory MoviesPageResponse.fromJson(Map<String, Object?> json) =>
      MoviesPageResponse(
        page: json['page'] as int? ?? 1,
        results: <Movie>[
          for (final Object? item
              in json['results'] as List<Object?>? ?? const [])
            if (item is Map<String, Object?>) Movie.fromJson(item),
        ],
        totalPages: json['total_pages'] as int? ?? 1,
        totalResults: json['total_results'] as int? ?? 0,
      );

  final int page;
  final List<Movie> results;
  final int totalPages;
  final int totalResults;
}

class MovieGenresResponse {
  const MovieGenresResponse({required this.genres});

  factory MovieGenresResponse.fromJson(Map<String, Object?> json) =>
      MovieGenresResponse(
        genres: <Genre>[
          for (final Object? item
              in json['genres'] as List<Object?>? ?? const [])
            if (item is Map<String, Object?>) Genre.fromJson(item),
        ],
      );

  final List<Genre> genres;
}
