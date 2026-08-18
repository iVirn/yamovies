part of 'movie_details_screen.dart';

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
