part of 'movie_list_screen.dart';

class _MovieCard extends StatelessWidget {
  const _MovieCard({
    required this.movie,
    required this.genreNames,
    required this.posterAssetPath,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final Movie movie;
  final List<String> genreNames;
  final String? posterAssetPath;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  posterAssetPath == null
                      ? const PosterFallback()
                      : Image.asset(
                          posterAssetPath!,
                          fit: BoxFit.cover,
                          semanticLabel: '${movie.title} poster',
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) => const PosterFallback(),
                        ),
                  const _PosterGradient(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      tooltip: isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      onPressed: onFavoriteTap,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : null,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: _RatingBadge(rating: movie.voteAverage),
                  ),
                ],
              ),
            ),
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
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        releaseYear(movie),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatGenreNames(genreNames),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
