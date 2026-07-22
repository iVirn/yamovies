import 'package:flutter/material.dart';

import 'expandable_overview.dart';
import 'movie.dart';
import 'movie_card.dart';
import 'movie_formatters.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({
    required this.movie,
    required this.genreNames,
    required this.posterAssetPath,
    required this.isFavorite,
    required this.onFavoriteTap,
    super.key,
  });

  final Movie movie;
  final List<String> genreNames;
  final String? posterAssetPath;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  void _toggleFavorite() {
    widget.onFavoriteTap();
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            actions: <Widget>[
              IconButton.filledTonal(
                tooltip: _isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.redAccent : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _DetailsPoster(
                    movie: widget.movie,
                    posterAssetPath: widget.posterAssetPath,
                  ),
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
                    widget.movie.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _MetaPill(
                        icon: Icons.star,
                        label: widget.movie.voteAverage.toStringAsFixed(1),
                        iconColor: Colors.amber,
                      ),
                      _MetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: releaseYear(widget.movie),
                      ),
                      _MetaPill(
                        icon: Icons.how_to_vote_outlined,
                        label: '${widget.movie.voteCount} votes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String genreName in widget.genreNames)
                        Chip(label: Text(genreName)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ExpandableOverview(text: detailsOverview(widget.movie)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    label: Text(
                      _isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                    ),
                  ),
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

class _DetailsPoster extends StatelessWidget {
  const _DetailsPoster({required this.movie, required this.posterAssetPath});

  final Movie movie;
  final String? posterAssetPath;

  @override
  Widget build(BuildContext context) {
    final String? assetPath = posterAssetPath;
    if (assetPath == null) {
      return const PosterFallback();
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      semanticLabel: '${movie.title} poster',
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) =>
              const PosterFallback(),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
