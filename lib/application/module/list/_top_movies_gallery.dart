part of 'movie_list_screen.dart';

class _TopMoviesGallery extends StatefulWidget {
  const _TopMoviesGallery({
    required this.movies,
    required this.genreNamesById,
    required this.posterAssets,
    required this.onMovieTap,
  });

  final List<Movie> movies;
  final Map<int, String> genreNamesById;
  final Map<int, String> posterAssets;
  final ValueChanged<Movie> onMovieTap;

  @override
  State<_TopMoviesGallery> createState() => _TopMoviesGalleryState();
}

class _TopMoviesGalleryState extends State<_TopMoviesGallery> {
  static const int _initialPageMultiplier = 100;
  static const int _maxPageBound = 1200;

  late final PageController _pageController;
  late final int _initialPage;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initialPage = widget.movies.length * _initialPageMultiplier;
    _currentPage = _initialPage;
    _pageController = PageController(
      initialPage: _initialPage,
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
      _currentPage = _pageController.page?.round() ?? _currentPage;
    });
  }

  void _scrollToNextMovie() {
    if (!mounted || !_pageController.hasClients || widget.movies.length < 2) {
      return;
    }

    final int currentPage = (_pageController.page ?? _currentPage).round();

    // Before drifting far enough for float-precision issues, jump back to an
    // equivalent page (same movie thanks to `index % movies.length`). The jump
    // is invisible because the wrapped page renders the identical tile.
    if (currentPage >= _maxPageBound) {
      final int wrappedPage = _initialPage + currentPage % widget.movies.length;
      _pageController.jumpToPage(wrappedPage);
      return;
    }

    _pageController.animateToPage(
      currentPage + 1,
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
                    .clamp(0, 1)
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
