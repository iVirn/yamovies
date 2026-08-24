part of 'movie_list_screen.dart';

class _MovieListContent extends StatelessWidget {
  const _MovieListContent({required this.state, required this.controller});

  final MovieListSuccessState state;
  final MovieListController controller;

  @override
  Widget build(BuildContext context) {
    final List<Movie> movies = state.movies;
    final List<Genre> genres = state.genres;
    final Map<int, String> genreNamesById = controller.genreNamesById(genres);
    final List<Movie> filteredMovies = controller.filteredMovies(movies);
    final List<Genre> selectedGenres = controller.selectedGenres(genres);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _TopMoviesGallery(
                movies: movies,
                genreNamesById: genreNamesById,
                posterAssets: moviePosterAssets,
                onMovieTap: (Movie movie) =>
                    controller.openMovieDetails(context, movie, genres),
              ),
            ),
            SliverToBoxAdapter(
              child: _CatalogStatsPanel(movies: movies, controller: controller),
            ),
            SliverToBoxAdapter(
              child: _MovieFiltersHeader(
                moviesCount: filteredMovies.length,
                selectedGenres: selectedGenres,
                onOpenFilters: () => controller.openFilters(context, genres),
                onClearFilters: controller.clearGenres,
                onRemoveGenre: controller.toggleGenre,
              ),
            ),
            if (filteredMovies.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _MoviesEmptyState(
                  onClearFilters: controller.clearGenres,
                ),
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

                    return _MovieCard(
                      movie: movie,
                      genreNames: resolveMovieGenres(movie, genreNamesById),
                      posterAssetPath: moviePosterAssets[movie.id],
                      isFavorite: controller.isFavorite(movie.id),
                      onFavoriteTap: () => controller.toggleFavorite(movie.id),
                      onTap: () =>
                          controller.openMovieDetails(context, movie, genres),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
