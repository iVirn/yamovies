part of 'movie_search_screen.dart';

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.controller});

  final MovieSearchController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return StreamBuilder<MovieSearchState>(
      stream: controller.state,
      initialData: controller.currentState,
      builder: (BuildContext context, AsyncSnapshot<MovieSearchState> snapshot) {
        final MovieSearchState state =
            snapshot.data ?? const SearchIdleState();

        return switch (state) {
          SearchIdleState() => Center(
            child: Text(
              'Start typing to search TMDB.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SearchLoadingState(:final String query) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text('Searching «$query»…', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          SearchFailureState(:final String message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
          SearchResultsState(:final String query, :final List<Movie> movies) =>
            movies.isEmpty
                ? Center(child: Text('Nothing found for «$query».'))
                : _SearchResultsList(query: query, movies: movies),
        };
      },
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({required this.query, required this.movies});

  final String query;
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: movies.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              // Заголовок показывает, на какой именно ввод пришёл ответ:
              // в режиме без switchMap он может отставать от строки поиска.
              'Results for «$query»',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
        }

        final Movie movie = movies[index - 1];

        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: MoviePoster(
                movieId: movie.id,
                posterPath: movie.posterPath,
                title: movie.title,
                size: 'w185',
                cacheWidth: 144,
              ),
            ),
          ),
          title: Text(movie.title),
          subtitle: Text(
            '${releaseYear(movie)} · ★ ${movie.voteAverage.toStringAsFixed(1)}',
          ),
          onTap: () => context.go(AppRoutes.movie(movie.id)),
        );
      },
    );
  }
}
