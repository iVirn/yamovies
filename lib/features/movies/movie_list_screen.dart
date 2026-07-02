import 'package:flutter/material.dart';

import '../../tmdb_attribution.dart';
import 'mock_tmdb_data.dart';
import 'movie.dart';
import 'movie_card.dart';
import 'movie_poster_assets.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Movie movie = mockTopRatedMoviesResponse.results.first;
    final List<String> genreNames = resolveMovieGenres(
      movie,
      mockMovieGenresResponse.genres,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Movies'),
        actions: const <Widget>[TmdbAttributionButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: MovieCard(
              movie: movie,
              genreNames: genreNames,
              posterAssetPath: moviePosterAssets[movie.id],
            ),
          ),
        ),
      ),
    );
  }
}

List<String> resolveMovieGenres(Movie movie, Iterable<Genre> genres) {
  final Map<int, String> genreNamesById = <int, String>{
    for (final Genre genre in genres) genre.id: genre.name,
  };

  if (movie.genreIds.isEmpty) {
    return const <String>['Unknown'];
  }

  return <String>[
    for (final int genreId in movie.genreIds)
      genreNamesById[genreId] ?? 'Unknown',
  ];
}
