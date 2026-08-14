part of 'movie_list_screen.dart';

class _MovieListContent extends StatelessWidget {
  const _MovieListContent({required this.state});

  final MovieListSuccessState state;

  void _openGenreFilters(BuildContext context) {
    final MovieListBloc bloc = context.read<MovieListBloc>();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return BlocProvider<MovieListBloc>.value(
          value: bloc,
          child: BlocBuilder<MovieListBloc, MovieListState>(
            builder: (BuildContext context, MovieListState state) {
              return switch (state) {
                MovieListLoadingState() => const SizedBox.shrink(),
                MovieListSuccessState success => GenreFilterSheet(
                  genres: success.genres,
                  selectedGenreIds: success.selectedGenreIds,
                  onGenreTap: (int genreId) => context.read<MovieListBloc>().add(
                    MovieListGenreToggled(genreId),
                  ),
                  onClear: () => context.read<MovieListBloc>().add(
                    const MovieListGenresCleared(),
                  ),
                ),
              };
            },
          ),
        );
      },
    );
  }

  void _openMovieDetails(BuildContext context, Movie movie) {
    final MovieListBloc bloc = context.read<MovieListBloc>();
    final List<String> genreNames = resolveMovieGenres(
      movie,
      state.genreNamesById,
    );

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MovieDetailsScreen(
            movie: movie,
            genreNames: genreNames,
            posterAssetPath: moviePosterAssets[movie.id],
            isFavorite: state.isFavorite(movie.id),
            onFavoriteTap: () => bloc.add(MovieListFavoriteToggled(movie.id)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Movie> movies = state.movies;
    final Map<int, String> genreNamesById = state.genreNamesById;
    final List<Movie> filteredMovies = state.filteredMovies;
    final List<Genre> selectedGenres = state.selectedGenres;

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
                onMovieTap: (Movie movie) => _openMovieDetails(context, movie),
              ),
            ),
            SliverToBoxAdapter(
              child: _MovieFiltersHeader(
                moviesCount: filteredMovies.length,
                selectedGenres: selectedGenres,
                onOpenFilters: () => _openGenreFilters(context),
                onClearFilters: () => context.read<MovieListBloc>().add(
                  const MovieListGenresCleared(),
                ),
                onRemoveGenre: (int genreId) => context.read<MovieListBloc>().add(
                  MovieListGenreToggled(genreId),
                ),
              ),
            ),
            if (filteredMovies.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _MoviesEmptyState(
                  onClearFilters: () => context.read<MovieListBloc>().add(
                    const MovieListGenresCleared(),
                  ),
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
                      isFavorite: state.isFavorite(movie.id),
                      onFavoriteTap: () => context.read<MovieListBloc>().add(
                        MovieListFavoriteToggled(movie.id),
                      ),
                      onTap: () => _openMovieDetails(context, movie),
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
