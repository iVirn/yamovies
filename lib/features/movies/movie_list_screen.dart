import 'package:flutter/material.dart';

import '../../tmdb_attribution.dart';
import 'mock_tmdb_data.dart';
import 'movie.dart';
import 'movie_card.dart';
import 'movie_poster_assets.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({this.assetPackage, super.key});

  final String? assetPackage;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final Set<int> _favoriteMovieIds = <int>{};

  void _toggleFavorite(int movieId) {
    setState(() {
      if (!_favoriteMovieIds.add(movieId)) {
        _favoriteMovieIds.remove(movieId);
      }
    });
  }

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
        actions: <Widget>[
          TmdbAttributionButton(assetPackage: widget.assetPackage),
        ],
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
            assetPackage: widget.assetPackage,
            isFavorite: _favoriteMovieIds.contains(movie.id),
            onFavoriteTap: () => _toggleFavorite(movie.id),
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
