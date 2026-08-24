import 'package:movie_network/movie_network.dart';

import '../domain/movie.dart';
import '../domain/movie_details.dart';
import '../domain/tmdb_responses.dart';
import 'tmdb_config.dart';

/// DataSource: знает про endpoint-ы и JSON TMDB, но не про HTTP и не про кэш.
class TmdbApi {
  const TmdbApi({required HttpClient httpClient})
    : _httpClient = httpClient; // ignore: prefer_initializing_formals

  final HttpClient _httpClient;

  Future<MoviesPageResponse> topRated({int page = 1}) async {
    final Map<String, Object?> json = await _httpClient.getJson(
      'movie/top_rated',
      queryParameters: <String, Object?>{
        'page': page,
        'language': TmdbConfig.language,
      },
    );

    return MoviesPageResponse.fromJson(json);
  }

  Future<MovieGenresResponse> genres() async {
    final Map<String, Object?> json = await _httpClient.getJson(
      'genre/movie/list',
      queryParameters: <String, Object?>{'language': TmdbConfig.language},
    );

    return MovieGenresResponse.fromJson(json);
  }

  /// Поиск по названию. `CancelToken` здесь не украшение: строка поиска
  /// отменяет предыдущий запрос при каждом новом вводе.
  Future<List<Movie>> search(String query, {CancelToken? cancelToken}) async {
    final Map<String, Object?> json = await _httpClient.getJson(
      'search/movie',
      queryParameters: <String, Object?>{
        'query': query,
        'language': TmdbConfig.language,
        'include_adult': false,
      },
      cancelToken: cancelToken,
    );

    return MoviesPageResponse.fromJson(json).results;
  }

  Future<MovieDetails> movieDetails(int id, {CancelToken? cancelToken}) async {
    final Map<String, Object?> json = await _httpClient.getJson(
      'movie/$id',
      queryParameters: <String, Object?>{'language': TmdbConfig.language},
      cancelToken: cancelToken,
    );

    return MovieDetails.fromJson(json);
  }

  Future<List<CastMember>> movieCredits(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final Map<String, Object?> json = await _httpClient.getJson(
      'movie/$id/credits',
      queryParameters: <String, Object?>{'language': TmdbConfig.language},
      cancelToken: cancelToken,
    );

    return <CastMember>[
      for (final Object? item in json['cast'] as List<Object?>? ?? const [])
        if (item is Map<String, Object?>) CastMember.fromJson(item),
    ];
  }

  Future<List<Movie>> similarMovies(int id, {CancelToken? cancelToken}) async {
    final Map<String, Object?> json = await _httpClient.getJson(
      'movie/$id/similar',
      queryParameters: <String, Object?>{'language': TmdbConfig.language},
      cancelToken: cancelToken,
    );

    return MoviesPageResponse.fromJson(json).results;
  }
}
