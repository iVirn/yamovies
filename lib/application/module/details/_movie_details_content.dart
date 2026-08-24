part of 'movie_details_screen.dart';

class _MovieDetailsContent extends StatelessWidget {
  const _MovieDetailsContent({required this.bundle, required this.genreNames});

  final MovieDetailsBundle bundle;
  final List<String> genreNames;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MovieDetails details = bundle.details;
    final List<String> genres = details.genres.isEmpty
        ? genreNames
        : <String>[for (final Genre genre in details.genres) genre.name];

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            // Шапка живёт поверх постера: белый текст и иконки читаются
            // на любом кадре, а тёмный фон подхватывает их же, когда шапка
            // схлопывается при прокрутке.
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: const <Widget>[
              _DetailsReloadAction(),
              _DetailsFavoriteAction(),
              SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                details.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  // Тень нужна там, где под подписью светлый кадр постера.
                  shadows: <Shadow>[
                    Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _DetailsPoster(details: details),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    details.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (details.tagline.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      details.tagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _MetaPill(
                        icon: Icons.star,
                        label: details.voteAverage.toStringAsFixed(1),
                        iconColor: Colors.amber,
                      ),
                      _MetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: releaseYearOf(details.releaseDate),
                      ),
                      if (details.runtimeMinutes != null)
                        _MetaPill(
                          icon: Icons.schedule,
                          label: '${details.runtimeMinutes} min',
                        ),
                      _MetaPill(
                        icon: Icons.how_to_vote_outlined,
                        label: '${details.voteCount} votes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String genreName in genres)
                        Chip(label: Text(genreName)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailsLoadTiming(bundle: bundle),
                  const SizedBox(height: 24),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _ExpandableOverview(text: detailsOverviewText(details)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _CastRow(cast: bundle.cast)),
          SliverToBoxAdapter(child: _SimilarMoviesRow(movies: bundle.similar)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _DetailsFavoriteButton(),
                  const SizedBox(height: 20),
                  const _FavoriteActivityLog(),
                  const SizedBox(height: 24),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  const _DetailsDemoPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
