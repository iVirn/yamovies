class Movie {
  const Movie({
    required this.adult,
    required this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.releaseDate,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
  });

  /// Разбор руками — ровно как на слайде «Из JSON в модель»: каждое поле
  /// приводится к типу и получает значение по умолчанию, иначе `null`
  /// из ответа уронит экран.
  factory Movie.fromJson(Map<String, Object?> json) => Movie(
    adult: json['adult'] as bool? ?? false,
    backdropPath: json['backdrop_path'] as String?,
    genreIds: <int>[
      for (final Object? id in json['genre_ids'] as List<Object?>? ?? const [])
        if (id is int) id,
    ],
    id: json['id'] as int,
    originalLanguage: json['original_language'] as String? ?? '',
    originalTitle: json['original_title'] as String? ?? '',
    overview: json['overview'] as String? ?? '',
    popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
    posterPath: json['poster_path'] as String?,
    releaseDate: json['release_date'] as String?,
    title: json['title'] as String? ?? '',
    video: json['video'] as bool? ?? false,
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
    voteCount: json['vote_count'] as int? ?? 0,
  );

  final bool adult;
  final String? backdropPath;
  final List<int> genreIds;
  final int id;
  final String originalLanguage;
  final String originalTitle;
  final String overview;
  final double popularity;
  final String? posterPath;
  final String? releaseDate;
  final String title;
  final bool video;
  final double voteAverage;
  final int voteCount;
}

class Genre {
  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, Object?> json) => Genre(
    id: json['id'] as int,
    name: json['name'] as String? ?? 'Unknown',
  );

  final int id;
  final String name;
}
