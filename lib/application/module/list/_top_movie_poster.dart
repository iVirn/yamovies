part of 'movie_list_screen.dart';

class _TopMoviePoster extends StatelessWidget {
  const _TopMoviePoster({required this.movie, required this.posterAssetPath});

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
