import 'package:flutter/material.dart';

import '../data/tmdb_config.dart';
import '../utils/movie_poster_assets.dart';
import 'poster_fallback.dart';

/// Постер фильма: сначала локальная фикстура, потом сеть.
///
/// Шесть фильмов из офлайн-фикстуры лежат в ассетах, всё остальное приезжает
/// с `image.tmdb.org`. Картинка по сети — это запрос плюс декодирование
/// в память, поэтому размер выбирается под ячейку (`w185`, `w500`),
/// а `cacheWidth` не даёт декодировать больше, чем нужно.
class MoviePoster extends StatelessWidget {
  const MoviePoster({
    required this.movieId,
    required this.posterPath,
    required this.title,
    this.size = 'w500',
    this.cacheWidth,
    super.key,
  });

  final int movieId;
  final String? posterPath;
  final String title;
  final String size;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final String? assetPath = moviePosterAssets[movieId];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        semanticLabel: '$title poster',
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                const PosterFallback(),
      );
    }

    final String? url = TmdbConfig.posterUrl(posterPath, size: size);
    if (url == null) {
      return const PosterFallback();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      semanticLabel: '$title poster',
      loadingBuilder:
          (BuildContext context, Widget child, ImageChunkEvent? progress) =>
              progress == null ? child : const PosterFallback(),
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) =>
              const PosterFallback(),
    );
  }
}
