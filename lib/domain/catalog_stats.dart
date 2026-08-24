import 'movie.dart';

/// Аргумент тяжёлого расчёта.
///
/// Отдельный класс нужен потому, что в изолят уезжает ровно один аргумент.
/// Внутри — обычные доменные модели: `Isolate.run` выполняется в той же
/// изолят-группе и умеет копировать произвольные объекты.
class CatalogStatsRequest {
  const CatalogStatsRequest({
    required this.movies,
    this.passes = defaultPasses,
  });

  /// Сколько раз пересчитать частоты слов.
  ///
  /// Один проход по шести фильмам занимает доли миллисекунды, поэтому
  /// «дорогой» расчёт имитируется повторами: на среднем ноутбуке
  /// [defaultPasses] проходов — это примерно 0.6–1.5 секунды CPU-работы.
  /// Если на вашей машине лаг незаметен, поднимите значение.
  static const int defaultPasses = 20000;

  final List<Movie> movies;
  final int passes;
}

/// Результат расчёта «индекса каталога».
class CatalogStats {
  const CatalogStats({
    required this.moviesScanned,
    required this.averageRating,
    required this.topKeyword,
    required this.topKeywordHits,
    required this.wordsProcessed,
  });

  final int moviesScanned;
  final double averageRating;
  final String topKeyword;
  final int topKeywordHits;
  final int wordsProcessed;
}

/// Чистая функция без замыканий и ссылок на UI — такую можно отдать
/// в `Isolate.run` или `compute` как есть.
///
/// Считает средний рейтинг каталога и самое частое значимое слово
/// в описаниях фильмов.
CatalogStats computeCatalogStats(CatalogStatsRequest request) {
  final List<Movie> movies = request.movies;

  if (movies.isEmpty) {
    return const CatalogStats(
      moviesScanned: 0,
      averageRating: 0,
      topKeyword: '—',
      topKeywordHits: 0,
      wordsProcessed: 0,
    );
  }

  double ratingSum = 0;
  for (final Movie movie in movies) {
    ratingSum += movie.voteAverage;
  }

  final Map<String, int> frequencies = <String, int>{};
  int wordsProcessed = 0;

  // Ровно тот самый цикл, который не даёт event loop нарисовать кадр:
  // пока он крутится, изолят занят только им.
  for (int pass = 0; pass < request.passes; pass++) {
    frequencies.clear();

    for (final Movie movie in movies) {
      for (final String word in _significantWords(movie.overview)) {
        frequencies[word] = (frequencies[word] ?? 0) + 1;
        wordsProcessed++;
      }
    }
  }

  String topKeyword = '—';
  int topKeywordHits = 0;
  frequencies.forEach((String word, int hits) {
    if (hits > topKeywordHits) {
      topKeyword = word;
      topKeywordHits = hits;
    }
  });

  return CatalogStats(
    moviesScanned: movies.length,
    averageRating: ratingSum / movies.length,
    topKeyword: topKeyword,
    topKeywordHits: topKeywordHits,
    wordsProcessed: wordsProcessed,
  );
}

const Set<String> _stopWords = <String>{
  'a',
  'an',
  'and',
  'as',
  'at',
  'but',
  'by',
  'for',
  'from',
  'he',
  'her',
  'his',
  'in',
  'into',
  'is',
  'it',
  'its',
  'of',
  'on',
  'or',
  'she',
  'that',
  'the',
  'their',
  'they',
  'to',
  'while',
  'who',
  'with',
};

Iterable<String> _significantWords(String text) sync* {
  for (final String raw in text.toLowerCase().split(RegExp(r'[^a-z]+'))) {
    if (raw.length > 3 && !_stopWords.contains(raw)) {
      yield raw;
    }
  }
}
