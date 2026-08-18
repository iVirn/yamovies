import 'package:flutter/material.dart';

import '../../../domain/movie.dart';
import '../../../utils/movie_filters.dart';
import '../../controller.dart';
import '../details/movie_details_screen.dart';
import '../filters/genre_filter_sheet.dart';

class MovieListController extends Controller {
  final Set<int> _favoriteMovieIds = <int>{};
  final Set<int> _selectedGenreIds = <int>{};

  bool isFavorite(int movieId) => _favoriteMovieIds.contains(movieId);

  Map<int, String> genreNamesById(List<Genre> genres) => <int, String>{
    for (final Genre genre in genres) genre.id: genre.name,
  };

  List<Movie> filteredMovies(List<Movie> movies) =>
      filterMoviesByGenres(movies, _selectedGenreIds);

  List<Genre> selectedGenres(List<Genre> genres) => <Genre>[
    for (final Genre genre in genres)
      if (_selectedGenreIds.contains(genre.id)) genre,
  ];

  void toggleFavorite(int movieId) {
    if (!_favoriteMovieIds.add(movieId)) {
      _favoriteMovieIds.remove(movieId);
    }
    notifyListeners();
  }

  void toggleGenre(int genreId) {
    if (!_selectedGenreIds.add(genreId)) {
      _selectedGenreIds.remove(genreId);
    }
    notifyListeners();
  }

  void clearGenres() {
    _selectedGenreIds.clear();
    notifyListeners();
  }

  void openFilters(BuildContext context, List<Genre> genres) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return ListenableBuilder(
          listenable: this,
          builder: (BuildContext context, Widget? child) {
            return GenreFilterSheet(
              genres: genres,
              selectedGenreIds: _selectedGenreIds,
              onGenreTap: toggleGenre,
              onClear: clearGenres,
            );
          },
        );
      },
    );
  }

  void openMovieDetails(
    BuildContext context,
    Movie movie,
    List<Genre> genres,
  ) {
    final List<String> genreNames = resolveMovieGenres(
      movie,
      genreNamesById(genres),
    );

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MovieDetailsScreen(
            movieId: movie.id,
            genreNames: genreNames,
            isFavorite: isFavorite(movie.id),
            onFavoriteTap: () => toggleFavorite(movie.id),
          );
        },
      ),
    );
  }
}
