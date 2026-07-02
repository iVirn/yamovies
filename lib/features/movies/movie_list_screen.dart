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
    final List<Movie> movies = mockTopRatedMoviesResponse.results;
    final Map<int, String> genreNamesById = <int, String>{
      for (final Genre genre in mockMovieGenresResponse.genres)
        genre.id: genre.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Movies'),
        actions: const <Widget>[TmdbAttributionButton()],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.40,
        ),
        itemCount: movies.length,
        itemBuilder: (BuildContext context, int index) {
          final Movie movie = movies[index];

          return MovieCard(
            movie: movie,
            genreNames: resolveMovieGenres(movie, genreNamesById),
            posterAssetPath: moviePosterAssets[movie.id],
          );
        },
      ),
    );
  }
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
