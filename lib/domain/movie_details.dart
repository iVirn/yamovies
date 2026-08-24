import 'package:equatable/equatable.dart';

import 'movie.dart';

/// Ответ `/movie/{id}` — то, чего нет в карточке ленты.
class MovieDetails extends Equatable {
  const MovieDetails({
    required this.id,
    required this.title,
    required this.overview,
    required this.tagline,
    required this.runtimeMinutes,
    required this.status,
    required this.genres,
    required this.voteAverage,
    required this.voteCount,
    required this.releaseDate,
    required this.posterPath,
  });

  factory MovieDetails.fromJson(Map<String, Object?> json) => MovieDetails(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '',
    overview: json['overview'] as String? ?? '',
    tagline: json['tagline'] as String? ?? '',
    runtimeMinutes: json['runtime'] as int?,
    status: json['status'] as String? ?? '',
    genres: <Genre>[
      for (final Object? item in json['genres'] as List<Object?>? ?? const [])
        if (item is Map<String, Object?>) Genre.fromJson(item),
    ],
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
    voteCount: json['vote_count'] as int? ?? 0,
    releaseDate: json['release_date'] as String?,
    posterPath: json['poster_path'] as String?,
  );

  /// Фильм из ленты, когда деталей ещё нет: экран рисуется сразу, а не после
  /// ответа сети.
  factory MovieDetails.fromMovie(Movie movie) => MovieDetails(
    id: movie.id,
    title: movie.title,
    overview: movie.overview,
    tagline: '',
    runtimeMinutes: null,
    status: '',
    genres: const <Genre>[],
    voteAverage: movie.voteAverage,
    voteCount: movie.voteCount,
    releaseDate: movie.releaseDate,
    posterPath: movie.posterPath,
  );

  final int id;
  final String title;
  final String overview;
  final String tagline;
  final int? runtimeMinutes;
  final String status;
  final List<Genre> genres;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final String? posterPath;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    overview,
    tagline,
    runtimeMinutes,
    status,
    genres,
    voteAverage,
    voteCount,
    releaseDate,
    posterPath,
  ];
}

/// Один актёр из ответа `/movie/{id}/credits`.
class CastMember extends Equatable {
  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory CastMember.fromJson(Map<String, Object?> json) => CastMember(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    character: json['character'] as String? ?? '',
    profilePath: json['profile_path'] as String?,
  );

  final int id;
  final String name;
  final String character;
  final String? profilePath;

  @override
  List<Object?> get props => <Object?>[id, name, character, profilePath];
}

/// Всё, из чего собран экран фильма: три ответа плюс время загрузки.
class MovieDetailsBundle extends Equatable {
  const MovieDetailsBundle({
    required this.details,
    required this.cast,
    required this.similar,
    required this.loadDuration,
    required this.loadedInParallel,
    this.partialErrors = const <String>[],
  });

  final MovieDetails details;
  final List<CastMember> cast;
  final List<Movie> similar;
  final Duration loadDuration;
  final bool loadedInParallel;

  /// Ошибки запросов, которые не уронили экран целиком
  /// (`Future.wait` без `eagerError`).
  final List<String> partialErrors;

  @override
  List<Object?> get props => <Object?>[
    details,
    cast,
    similar,
    loadDuration,
    loadedInParallel,
    partialErrors,
  ];
}
