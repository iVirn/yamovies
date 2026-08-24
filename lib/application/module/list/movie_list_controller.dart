import 'dart:isolate';

import 'package:flutter/material.dart';

import '../../../domain/catalog_stats.dart';
import '../../../domain/movie.dart';
import '../../../utils/movie_filters.dart';
import '../../controller.dart';
import '../../demo_settings.dart';
import '../details/movie_details_screen.dart';
import '../filters/genre_filter_sheet.dart';

/// Результат одного пересчёта: сами цифры плюс то, как их получили.
class CatalogStatsRun {
  const CatalogStatsRun({
    required this.stats,
    required this.duration,
    required this.inIsolate,
  });

  final CatalogStats stats;
  final Duration duration;
  final bool inIsolate;
}

class MovieListController extends Controller {
  MovieListController({required DemoSettings demoSettings})
    : _demoSettings = demoSettings; // ignore: prefer_initializing_formals

  final DemoSettings _demoSettings;
  final Set<int> _favoriteMovieIds = <int>{};
  final Set<int> _selectedGenreIds = <int>{};

  CatalogStatsRun? _statsRun;
  bool _isComputingStats = false;

  CatalogStatsRun? get statsRun => _statsRun;

  bool get isComputingStats => _isComputingStats;

  /// Пересчитать индекс каталога.
  ///
  /// Одна и та же CPU-работа, разница только в том, кто её выполняет.
  /// Метод `async`, но это ничего не меняет: пока `computeCatalogStats`
  /// считает в UI-изоляте, кадры не рисуются и тапы не доходят —
  /// `async` не спасает от блокировки, спасает другой изолят.
  Future<void> recalculateStats(List<Movie> movies) async {
    if (_isComputingStats) {
      return;
    }

    final bool inIsolate = _demoSettings.computeStatsInIsolate;
    final CatalogStatsRequest request = CatalogStatsRequest(movies: movies);

    _isComputingStats = true;
    notifyListeners();

    final Stopwatch stopwatch = Stopwatch()..start();
    final CatalogStats stats = inIsolate
        // ✅ Тяжёлое — в другой изолят: своя память, свой event loop.
        //    `Isolate.run` сам поднимет изолят, вернёт результат и закроет его.
        ? await Isolate.run(() => computeCatalogStats(request))
        // ❌ Здесь UI-изолят занят целиком: спиннер стоит, тапы копятся.
        : computeCatalogStats(request);
    stopwatch.stop();

    _statsRun = CatalogStatsRun(
      stats: stats,
      duration: stopwatch.elapsed,
      inIsolate: inIsolate,
    );
    _isComputingStats = false;
    notifyListeners();
  }

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

  void openMovieDetails(BuildContext context, Movie movie, List<Genre> genres) {
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
