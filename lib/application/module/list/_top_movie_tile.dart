part of 'movie_list_screen.dart';

class _TopMovieTile extends StatelessWidget {
  const _TopMovieTile({
    required this.movie,
    required this.genreNames,
    required this.posterAssetPath,
    required this.onTap,
  });

  final Movie movie;
  final List<String> genreNames;
  final String? posterAssetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 96,
              child: _TopMoviePoster(
                movie: movie,
                posterAssetPath: posterAssetPath,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${releaseYear(movie)} • ${formatGenreNames(genreNames)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(movie.voteAverage.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
