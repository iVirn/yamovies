import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamovies/features/movies/mock_tmdb_data.dart';
import 'package:yamovies/features/movies/movie.dart';
import 'package:yamovies/features/movies/movie_poster_assets.dart';

const Set<String> _movieWireKeys = <String>{
  'adult',
  'backdrop_path',
  'genre_ids',
  'id',
  'original_language',
  'original_title',
  'overview',
  'popularity',
  'poster_path',
  'release_date',
  'title',
  'video',
  'vote_average',
  'vote_count',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('typed movie fixture matches the API-shaped JSON fixture', () async {
    final Map<String, Object?> json = await _readJsonObject(
      'test/fixtures/tmdb_top_rated.en-US.json',
    );
    final List<Object?> results = json['results']! as List<Object?>;

    expect(json.keys.toSet(), <String>{
      'page',
      'results',
      'total_pages',
      'total_results',
    });
    expect(json['page'], 1);
    expect(json['total_pages'], 1);
    expect(json['total_results'], 6);
    expect(results, hasLength(6));
    expect(
      results.map((Object? item) => (item! as Map<String, Object?>)['id']),
      <int>[278, 238, 240, 424, 389, 129],
    );

    for (final Object? item in results) {
      expect((item! as Map<String, Object?>).keys.toSet(), _movieWireKeys);
    }

    expect(<String, Object?>{
      'page': mockTopRatedMoviesResponse.page,
      'results': mockTopRatedMoviesResponse.results
          .map(_movieToWireJson)
          .toList(),
      'total_pages': mockTopRatedMoviesResponse.totalPages,
      'total_results': mockTopRatedMoviesResponse.totalResults,
    }, json);
  });

  test('typed genre fixture matches the API-shaped JSON fixture', () async {
    final Map<String, Object?> json = await _readJsonObject(
      'test/fixtures/movie_genres.en.json',
    );

    expect(<String, Object?>{
      'genres': mockMovieGenresResponse.genres
          .map(
            (Genre genre) => <String, Object?>{
              'id': genre.id,
              'name': genre.name,
            },
          )
          .toList(),
    }, json);
  });

  test('poster manifest matches movies and bundled assets', () async {
    final Map<String, Object?> manifest = await _readJsonObject(
      'test/fixtures/poster_manifest.json',
    );
    final List<Object?> posters = manifest['posters']! as List<Object?>;

    expect(posters, hasLength(mockTopRatedMoviesResponse.results.length));

    for (final Object? item in posters) {
      final Map<String, Object?> poster = item! as Map<String, Object?>;
      final int movieId = poster['movie_id']! as int;
      final Movie movie = mockTopRatedMoviesResponse.results.singleWhere(
        (Movie movie) => movie.id == movieId,
      );
      final String expectedAsset = 'assets/${poster['local_asset']! as String}';

      expect(movie.posterPath, poster['poster_path']);
      expect(moviePosterAssets[movieId], expectedAsset);
      expect(await File(expectedAsset).length(), greaterThan(0));
    }
  });

  test('the approved TMDB logo is bundled', () async {
    expect(
      await File('assets/branding/tmdb-logo.png').length(),
      greaterThan(0),
    );
  });
}

Future<Map<String, Object?>> _readJsonObject(String path) async {
  final Object? value = jsonDecode(await File(path).readAsString());
  return (value! as Map<Object?, Object?>).cast<String, Object?>();
}

Map<String, Object?> _movieToWireJson(Movie movie) => <String, Object?>{
  'adult': movie.adult,
  'backdrop_path': movie.backdropPath,
  'genre_ids': movie.genreIds,
  'id': movie.id,
  'original_language': movie.originalLanguage,
  'original_title': movie.originalTitle,
  'overview': movie.overview,
  'popularity': movie.popularity,
  'poster_path': movie.posterPath,
  'release_date': movie.releaseDate,
  'title': movie.title,
  'video': movie.video,
  'vote_average': movie.voteAverage,
  'vote_count': movie.voteCount,
};
