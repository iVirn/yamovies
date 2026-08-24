import 'package:equatable/equatable.dart';

/// Доменная модель фильма.
///
/// Сравнение по значению — не украшение: состояния BLoC и оператор `distinct`
/// сравнивают именно модели, и без `==` каждая перерисовка считалась бы
/// новым значением.
class Movie extends Equatable {
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
    // Единственное поле без запасного значения — идентификатор:
    // фильм без id бессмыслен, и молча подставлять ноль тут хуже, чем упасть.
    id: (json['id'] as num).toInt(),
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

  @override
  List<Object?> get props => <Object?>[
    adult,
    backdropPath,
    genreIds,
    id,
    originalLanguage,
    originalTitle,
    overview,
    popularity,
    posterPath,
    releaseDate,
    title,
    video,
    voteAverage,
    voteCount,
  ];
}

class Genre extends Equatable {
  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, Object?> json) => Genre(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? 'Unknown',
  );

  final int id;
  final String name;

  @override
  List<Object?> get props => <Object?>[id, name];
}
