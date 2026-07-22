import 'package:flutter/material.dart';

import '../../tmdb_attribution.dart';
import 'mock_tmdb_data.dart';
import 'movie.dart';
import 'movie_card.dart';
import 'movie_details_screen.dart';
import 'movie_filters.dart';
import 'movie_poster_assets.dart';
import 'top_movies_gallery.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final Set<int> _favoriteMovieIds = <int>{};
  final Set<int> _selectedGenreIds = <int>{};

  void _toggleFavorite(int movieId) {
    setState(() {
      if (!_favoriteMovieIds.add(movieId)) {
        _favoriteMovieIds.remove(movieId);
      }
    });
  }

  void _toggleGenre(int genreId) {
    setState(() {
      if (!_selectedGenreIds.add(genreId)) {
        _selectedGenreIds.remove(genreId);
      }
    });
  }

  void _clearGenres() {
    setState(_selectedGenreIds.clear);
  }

  void _openGenreFilters(List<Genre> genres) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return GenreFilterSheet(
              genres: genres,
              selectedGenreIds: _selectedGenreIds,
              onGenreTap: (int genreId) {
                _toggleGenre(genreId);
                setSheetState(() {});
              },
              onClear: () {
                _clearGenres();
                setSheetState(() {});
              },
            );
          },
        );
      },
    );
  }

  void _openMovieDetails(Movie movie, Map<int, String> genreNamesById) {
    final List<String> genreNames = resolveMovieGenres(movie, genreNamesById);

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MovieDetailsScreen(
            movie: movie,
            genreNames: genreNames,
            posterAssetPath: moviePosterAssets[movie.id],
            isFavorite: _favoriteMovieIds.contains(movie.id),
            onFavoriteTap: () => _toggleFavorite(movie.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Movie> movies = mockTopRatedMoviesResponse.results;
    final List<Genre> genres = <Genre>[
      ...mockMovieGenresResponse.genres,
      const Genre(id: 878, name: 'Science Fiction'),
    ];
    final Map<int, String> genreNamesById = <int, String>{
      for (final Genre genre in genres) genre.id: genre.name,
    };
    final List<Movie> filteredMovies = filterMoviesByGenres(
      movies,
      _selectedGenreIds,
    );
    final List<Genre> selectedGenres = <Genre>[
      for (final Genre genre in genres)
        if (_selectedGenreIds.contains(genre.id)) genre,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Movies'),
        actions: const <Widget>[TmdbAttributionButton()],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;

          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: TopMoviesGallery(
                  movies: movies,
                  genreNamesById: genreNamesById,
                  posterAssets: moviePosterAssets,
                  onMovieTap: (Movie movie) =>
                      _openMovieDetails(movie, genreNamesById),
                ),
              ),
              SliverToBoxAdapter(
                child: MovieFiltersHeader(
                  moviesCount: filteredMovies.length,
                  selectedGenres: selectedGenres,
                  onOpenFilters: () => _openGenreFilters(genres),
                  onClearFilters: _clearGenres,
                  onRemoveGenre: _toggleGenre,
                ),
              ),
              if (filteredMovies.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: MoviesEmptyState(onClearFilters: _clearGenres),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.50,
                    ),
                    itemCount: filteredMovies.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Movie movie = filteredMovies[index];

                      return MovieCard(
                        movie: movie,
                        genreNames: resolveMovieGenres(movie, genreNamesById),
                        posterAssetPath: moviePosterAssets[movie.id],
                        isFavorite: _favoriteMovieIds.contains(movie.id),
                        onFavoriteTap: () => _toggleFavorite(movie.id),
                        onTap: () => _openMovieDetails(movie, genreNamesById),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

List<Movie> filterMoviesByGenres(
  List<Movie> movies,
  Set<int> selectedGenreIds,
) {
  if (selectedGenreIds.isEmpty) {
    return movies;
  }

  return <Movie>[
    for (final Movie movie in movies)
      if (movie.genreIds.any(selectedGenreIds.contains)) movie,
  ];
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
