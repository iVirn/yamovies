part of 'movie_list_screen.dart';

class _MovieListView extends StatelessWidget {
  const _MovieListView();

  @override
  Widget build(BuildContext context) {
    final MovieListViewModel viewModel = ViewModelScope.of<MovieListViewModel>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Movies'),
        actions: const <Widget>[_TmdbAttributionButton()],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (BuildContext context, Widget? child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Movie> movies = viewModel.movies;
          final Map<int, String> genreNamesById = viewModel.genreNamesById;
          final List<Movie> filteredMovies = viewModel.filteredMovies;
          final List<Genre> selectedGenres = viewModel.selectedGenres;

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
                          viewModel.onTapMovie(context, movie),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _MovieFiltersHeader(
                      moviesCount: filteredMovies.length,
                      selectedGenres: selectedGenres,
                      onOpenFilters: () => viewModel.onTapFilters(context),
                      onClearFilters: viewModel.clearGenres,
                      onRemoveGenre: viewModel.toggleGenre,
                    ),
                  ),
                  if (filteredMovies.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MoviesEmptyState(
                        onClearFilters: viewModel.clearGenres,
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
                            genreNames: resolveMovieGenres(
                              movie,
                              genreNamesById,
                            ),
                            posterAssetPath: moviePosterAssets[movie.id],
                            isFavorite: viewModel.isFavorite(movie.id),
                            onFavoriteTap: () =>
                                viewModel.toggleFavorite(movie.id),
                            onTap: () => viewModel.onTapMovie(context, movie),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
