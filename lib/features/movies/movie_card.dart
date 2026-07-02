import 'package:flutter/material.dart';

import 'movie.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    required this.movie,
    required this.genreNames,
    required this.posterAssetPath,
    super.key,
  });

  final Movie movie;
  final List<String> genreNames;
  final String? posterAssetPath;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AspectRatio(aspectRatio: 2 / 3, child: _buildPoster()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(child: Text(_releaseYear)),
                    const Icon(Icons.star, size: 16),
                    const SizedBox(width: 4),
                    Text(movie.voteAverage.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  genreNames.isEmpty ? 'Unknown' : genreNames.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoster() {
    final String? assetPath = posterAssetPath;
    if (assetPath == null) {
      return const _PosterFallback();
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      semanticLabel: '${movie.title} poster',
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) =>
              const _PosterFallback(),
    );
  }

  String get _releaseYear {
    final String? releaseDate = movie.releaseDate;
    if (releaseDate == null) {
      return '—';
    }

    return DateTime.tryParse(releaseDate)?.year.toString() ?? '—';
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.movie_outlined, size: 48),
    );
  }
}
