import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Реляционный кэш приложения.
///
/// `NativeDatabase.memory()` в тестах даёт настоящую БД без единого файла:
/// запросы, миграции и реактивность проверяются по-настоящему.
@DriftDatabase(tables: <Type>[CachedMovies, CachedGenres, SyncMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'yamovies_cache'));

  @override
  int get schemaVersion => 1;

  /// Реактивное чтение: любая запись в таблицу сама толкнёт этот поток.
  Stream<List<CachedMovie>> watchMovies() => (select(
    cachedMovies,
  )..orderBy(<OrderClauseGenerator<$CachedMoviesTable>>[
    ($CachedMoviesTable t) =>
        OrderingTerm(expression: t.voteAverage, mode: OrderingMode.desc),
  ])).watch();

  Future<List<CachedMovie>> readMovies() => (select(
    cachedMovies,
  )..orderBy(<OrderClauseGenerator<$CachedMoviesTable>>[
    ($CachedMoviesTable t) =>
        OrderingTerm(expression: t.voteAverage, mode: OrderingMode.desc),
  ])).get();

  Future<List<CachedGenre>> readGenres() => select(cachedGenres).get();

  Stream<List<CachedGenre>> watchGenres() => select(cachedGenres).watch();

  /// Одна транзакция на всю страницу: подписчики увидят её целиком,
  /// а не по одному фильму.
  Future<void> upsertMovies(List<CachedMoviesCompanion> movies) =>
      transaction(() async {
        for (final CachedMoviesCompanion movie in movies) {
          await into(cachedMovies).insertOnConflictUpdate(movie);
        }

        await _touch('movies');
      });

  Future<void> upsertGenres(List<CachedGenresCompanion> genres) =>
      transaction(() async {
        for (final CachedGenresCompanion genre in genres) {
          await into(cachedGenres).insertOnConflictUpdate(genre);
        }

        await _touch('genres');
      });

  Future<DateTime?> lastSyncAt(String key) async {
    final SyncMetaData? row = await (select(
      syncMeta,
    )..where(($SyncMetaTable t) => t.key.equals(key))).getSingleOrNull();

    return row?.updatedAt;
  }

  Future<int> countMovies() async {
    final Expression<int> count = cachedMovies.id.count();
    final TypedResult row = await (selectOnly(
      cachedMovies,
    )..addColumns(<Expression<Object>>[count])).getSingle();

    return row.read(count) ?? 0;
  }

  Future<void> clearCache() => transaction(() async {
    await delete(cachedMovies).go();
    await delete(cachedGenres).go();
    await delete(syncMeta).go();
  });

  Future<void> _touch(String key) => into(syncMeta).insertOnConflictUpdate(
    SyncMetaCompanion.insert(key: key, updatedAt: DateTime.now()),
  );
}
