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
          _CacheInspectorAction(),
          _TokenStorageAction(),
          _NetworkDemoAction(),
          _SearchAction(),
          _FavoritesCounter(),
          _TmdbAttributionButton(),
        ],
      ),
      body: Column(
        children: <Widget>[
          const _BackgroundErrorBanner(),
          Expanded(child: _buildBody(context, controller)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, MovieListController controller) {
    return BlocBuilder<MovieListBloc, MovieListState>(
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
    );
  }
}

/// Фоновое обновление упало — говорим об этом баннером, а кэш на экране
/// оставляем: это ровно та ситуация, ради которой offline-first и делают.
class _BackgroundErrorBanner extends StatelessWidget {
  const _BackgroundErrorBanner();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MovieRepository repository = DependencyScope.of(
      context,
    ).movieRepository;

    return StreamBuilder<Object>(
      stream: repository.backgroundErrors,
      builder: (BuildContext context, AsyncSnapshot<Object> snapshot) {
        final Object? error = snapshot.data;
        if (error == null) {
          return const SizedBox.shrink();
        }

        return Material(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.wifi_off,
                  size: 18,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${describeLoadError(error)} Показываем кэш.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      onPressed: () => context.go(AppRoutes.search),
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
      onPressed: () => context.go(AppRoutes.network),
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
      onPressed: () => context.go(AppRoutes.token),
      icon: const Icon(Icons.key_outlined),
    );
  }
}

class _CacheInspectorAction extends StatelessWidget {
  const _CacheInspectorAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Local cache',
      onPressed: () => context.go(AppRoutes.cache),
      icon: const Icon(Icons.storage_outlined),
    );
  }
}
