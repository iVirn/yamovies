import 'package:drift/drift.dart';

/// Кэш ленты.
///
/// Осторожно: по таблице `CachedMovies` drift сгенерирует свой класс
/// `CachedMovie`. Это **не** доменная модель приложения — конвертировать
/// их нужно на границе репозитория.
@DataClassName('CachedMovie')
class CachedMovies extends Table {
  IntColumn get id => integer()(); // id из TMDB
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get overview => text().withDefault(const Constant(''))();
  TextColumn get posterPath => text().nullable()();
  TextColumn get releaseDate => text().nullable()();
  RealColumn get voteAverage => real().withDefault(const Constant(0))();
  IntColumn get voteCount => integer().withDefault(const Constant(0))();
  RealColumn get popularity => real().withDefault(const Constant(0))();

  /// Список жанров хранится строкой «18,80»: отдельная таблица связей нужна
  /// только тогда, когда по жанрам собираются запросы.
  TextColumn get genreIds => text().withDefault(const Constant(''))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Справочник жанров — тот случай, когда cache-first оправдан: меняется он
/// раз в год.
@DataClassName('CachedGenre')
class CachedGenres extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Когда кэш обновляли в последний раз.
class SyncMeta extends Table {
  TextColumn get key => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}
