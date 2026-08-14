import 'package:flutter/material.dart';

import '../../../data/movie_repository.dart';
import '../../../domain/movie.dart';
import '../../../utils/movie_poster_assets.dart';
import '../details/movie_details_screen.dart';
import '../filters/genre_filter_sheet.dart';

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel({required MovieRepository repository})
    : _repository = repository; // ignore: prefer_initializing_formals

  final MovieRepository _repository;

  final Set<int> _favoriteMovieIds = <int>{};
  final Set<int> _selectedGenreIds = <int>{};

  List<Movie> _movies = <Movie>[];
  List<Genre> _genres = <Genre>[];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Movie> get movies => _movies;

  List<Genre> get genres => _genres;

  Set<int> get selectedGenreIds => _selectedGenreIds;

  Map<int, String> get genreNamesById => <int, String>{
    for (final Genre genre in _genres) genre.id: genre.name,
  };

  List<Movie> get filteredMovies =>
      filterMoviesByGenres(_movies, _selectedGenreIds);

  List<Genre> get selectedGenres => <Genre>[
    for (final Genre genre in _genres)
      if (_selectedGenreIds.contains(genre.id)) genre,
  ];

  bool isFavorite(int movieId) => _favoriteMovieIds.contains(movieId);

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final moviesResponse = await _repository.getMovies();
    final genresResponse = await _repository.getGenres();

    _movies = moviesResponse.results;
    _genres = <Genre>[
      ...genresResponse.genres,
      const Genre(id: 878, name: 'Science Fiction'),
    ];
    _isLoading = false;
    notifyListeners();
  }

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

  void onTapFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return GenreFilterSheet(
              genres: _genres,
              selectedGenreIds: _selectedGenreIds,
              onGenreTap: (int genreId) {
                toggleGenre(genreId);
                setSheetState(() {});
              },
              onClear: () {
                clearGenres();
                setSheetState(() {});
              },
            );
          },
        );
      },
    );
  }

  void onTapMovie(BuildContext context, Movie movie) {
    final Map<int, String> genreNames = genreNamesById;
    final List<String> resolvedGenres = resolveMovieGenres(movie, genreNames);

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MovieDetailsScreen(
            movie: movie,
            genreNames: resolvedGenres,
            posterAssetPath: moviePosterAssets[movie.id],
            isFavorite: isFavorite(movie.id),
            onFavoriteTap: () => toggleFavorite(movie.id),
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
