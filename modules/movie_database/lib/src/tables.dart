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

/// Избранное пользователя — то, что он меняет офлайн.
@DataClassName('FavoriteMovie')
class FavoriteMovies extends Table {
  IntColumn get movieId => integer()();
  DateTimeColumn get changedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{movieId};
}

/// Очередь изменений: то, что пользователь сделал офлайн и что надо
/// отправить позже.
///
/// Ключ идемпотентности генерирует **клиент** и хранит вместе с операцией:
/// сеть могла оборваться после того, как сервер применил операцию,
/// но до того, как ответ дошёл.
@DataClassName('PendingOp')
class PendingOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get movieId => integer()();
  TextColumn get kind => text()(); // 'favorite'
  TextColumn get payload => text()(); // JSON
  TextColumn get idemKey => text().unique()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextTry => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
}
