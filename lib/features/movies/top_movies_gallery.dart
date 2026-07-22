import 'dart:async';

import 'package:flutter/material.dart';

import 'movie.dart';
import 'movie_card.dart';
import 'movie_formatters.dart';

class TopMoviesGallery extends StatefulWidget {
  const TopMoviesGallery({
    required this.movies,
    required this.genreNamesById,
    required this.posterAssets,
    required this.onMovieTap,
    super.key,
  });

  final List<Movie> movies;
  final Map<int, String> genreNamesById;
  final Map<int, String> posterAssets;
  final ValueChanged<Movie> onMovieTap;

  @override
  State<TopMoviesGallery> createState() => _TopMoviesGalleryState();
}

class _TopMoviesGalleryState extends State<TopMoviesGallery> {
  static const int _initialPageMultiplier = 1000;

  late final PageController _pageController;
  Timer? _autoScrollTimer;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final int initialPage = widget.movies.length * _initialPageMultiplier;
    _currentPage = initialPage.toDouble();
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.72,
    )..addListener(_handlePageChanged);
    _autoScrollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _scrollToNextMovie(),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController
      ..removeListener(_handlePageChanged)
      ..dispose();
    super.dispose();
  }

  void _handlePageChanged() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  void _scrollToNextMovie() {
    if (!mounted || !_pageController.hasClients || widget.movies.length < 2) {
      return;
    }

    final int nextPage = (_pageController.page ?? _currentPage).round() + 1;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Best of all time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemBuilder: (BuildContext context, int index) {
                final Movie movie = widget.movies[index % widget.movies.length];
                final double distance = (_currentPage - index)
                    .abs()
                    .clamp(0.0, 1.0)
                    .toDouble();
                final double scale = 1 - distance * 0.08;
                final double opacity = 1 - distance * 0.24;

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: _TopMovieTile(
                        movie: movie,
                        genreNames: _resolveGenreNames(movie),
                        posterAssetPath: widget.posterAssets[movie.id],
                        onTap: () => widget.onMovieTap(movie),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _resolveGenreNames(Movie movie) {
    return <String>[
      for (final int genreId in movie.genreIds)
        widget.genreNamesById[genreId] ?? 'Unknown',
    ];
  }
}

class _TopMovieTile extends StatelessWidget {
  const _TopMovieTile({
    required this.movie,
    required this.genreNames,
    required this.posterAssetPath,
    required this.onTap,
  });

  final Movie movie;
  final List<String> genreNames;
  final String? posterAssetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 96,
              child: _Poster(movie: movie, posterAssetPath: posterAssetPath),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${releaseYear(movie)} • ${formatGenreNames(genreNames)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(movie.voteAverage.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.movie, required this.posterAssetPath});

  final Movie movie;
  final String? posterAssetPath;

  @override
  Widget build(BuildContext context) {
    final String? assetPath = posterAssetPath;
    if (assetPath == null) {
      return const PosterFallback();
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      semanticLabel: '${movie.title} poster',
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) =>
              const PosterFallback(),
    );
  }
}
