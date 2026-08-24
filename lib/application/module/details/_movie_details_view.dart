part of 'movie_details_screen.dart';

class _MovieDetailsView extends StatelessWidget {
  const _MovieDetailsView({required this.genreNames});

  final List<String> genreNames;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
      builder: (BuildContext context, MovieDetailsState state) {
        return switch (state) {
          MovieDetailsLoadingState() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          MovieDetailsSuccessState(:final MovieDetailsBundle bundle) =>
            _MovieDetailsContent(bundle: bundle, genreNames: genreNames),
          MovieDetailsFailureState failure => _MovieDetailsError(
            state: failure,
          ),
        };
      },
    );
  }
}

class _MovieDetailsError extends StatelessWidget {
  const _MovieDetailsError({required this.state});

  final MovieDetailsFailureState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
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
          Center(
            child: FilledButton.icon(
              onPressed: () => context.read<MovieDetailsBloc>().add(
                const MovieDetailsReloaded(),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(state.canRetry ? 'Retry' : 'Reload'),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          // Переключатели демо нужны именно здесь: сломанный запрос уносит
          // экран в ошибку, и выключить поломку было бы уже негде.
          const _DetailsDemoPanel(),
        ],
      ),
    );
  }
}
