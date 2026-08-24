part of 'movie_details_screen.dart';

class _MovieDetailsContent extends StatelessWidget {
  const _MovieDetailsContent({required this.movie, required this.genreNames});

  final Movie movie;
  final List<String> genreNames;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String? posterAssetPath = moviePosterAssets[movie.id];

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            actions: const <Widget>[
              _DetailsFavoriteAction(),
              SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _DetailsPoster(movie: movie, posterAssetPath: posterAssetPath),
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
                    movie.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _MetaPill(
                        icon: Icons.star,
                        label: movie.voteAverage.toStringAsFixed(1),
                        iconColor: Colors.amber,
                      ),
                      _MetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: releaseYear(movie),
                      ),
                      _MetaPill(
                        icon: Icons.how_to_vote_outlined,
                        label: '${movie.voteCount} votes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String genreName in genreNames)
                        Chip(label: Text(genreName)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _ExpandableOverview(text: detailsOverview(movie)),
                  const SizedBox(height: 24),
                  const _DetailsFavoriteButton(),
                  const SizedBox(height: 24),
                  Divider(color: colorScheme.outlineVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
