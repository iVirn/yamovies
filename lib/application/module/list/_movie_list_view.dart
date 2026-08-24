part of 'movie_list_screen.dart';

class _MovieListView extends StatelessWidget {
  const _MovieListView();

  @override
  Widget build(BuildContext context) {
    final MovieListController controller =
        ControllerScope.of<MovieListController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Movies'),
        actions: const <Widget>[
          _TokenStorageAction(),
          _NetworkDemoAction(),
          _SearchAction(),
          _FavoritesCounter(),
          _TmdbAttributionButton(),
        ],
      ),
      body: BlocBuilder<MovieListBloc, MovieListState>(
        buildWhen: (MovieListState previous, MovieListState current) =>
            previous is! MovieListLoadingState ||
            current is! MovieListLoadingState,
        builder: (BuildContext context, MovieListState state) {
          return switch (state) {
            MovieListLoadingState() => const Center(
              child: CircularProgressIndicator(),
            ),
            MovieListSuccessState success => ListenableBuilder(
              listenable: controller,
              builder: (BuildContext context, Widget? child) {
                return _MovieListContent(state: success, controller: controller);
              },
            ),
            MovieListFailureState failure => _MovieListError(state: failure),
          };
        },
      ),
    );
  }
}

class _MovieListError extends StatelessWidget {
  const _MovieListError({required this.state});

  final MovieListFailureState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  context.read<MovieListBloc>().add(const MovieListRefreshed()),
              icon: const Icon(Icons.refresh),
              label: Text(state.canRetry ? 'Retry' : 'Reload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAction extends StatelessWidget {
  const _SearchAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Search movies',
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const MovieSearchScreen(),
        ),
      ),
      icon: const Icon(Icons.search),
    );
  }
}

class _NetworkDemoAction extends StatelessWidget {
  const _NetworkDemoAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Network demo: 401 and refresh',
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const NetworkDemoScreen(),
        ),
      ),
      icon: const Icon(Icons.lan_outlined),
    );
  }
}

class _TokenStorageAction extends StatelessWidget {
  const _TokenStorageAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Where the token lives',
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const TokenStorageScreen(),
        ),
      ),
      icon: const Icon(Icons.key_outlined),
    );
  }
}
