/// Настройки TMDB.
///
/// Ключ приходит сборкой, а не лежит в коде:
/// `flutter run --dart-define=TMDB_API_KEY=...`
/// (в Android Studio — конфигурация запуска «YaMovies (TMDB)»).
abstract final class TmdbConfig {
  static const String apiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: String.fromEnvironment('TMDB_TOKEN'),
  );

  static const String baseUrl = 'https://api.themoviedb.org/3/';

  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/';

  /// Язык ответов TMDB.
  static const String language = 'en-US';

  static bool get hasApiKey => apiKey.isNotEmpty;

  /// Готовый URL постера. Размер выбирается под ячейку, а не «original»:
  /// полноразмерный постер в списке — самый быстрый путь к OOM.
  static String? posterUrl(String? posterPath, {String size = 'w500'}) =>
      posterPath == null ? null : '$imageBaseUrl$size$posterPath';
}
