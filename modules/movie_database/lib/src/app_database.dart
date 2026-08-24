import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Реляционный кэш приложения.
///
/// `NativeDatabase.memory()` в тестах даёт настоящую БД без единого файла:
/// запросы, миграции и реактивность проверяются по-настоящему.
@DriftDatabase(
  tables: <Type>[
    CachedMovies,
    CachedGenres,
    SyncMeta,
    FavoriteMovies,
    PendingOps,
  ],
)
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

  // --- Избранное и очередь изменений -------------------------------------

  Stream<Set<int>> watchFavoriteIds() => select(favoriteMovies).watch().map(
    (List<FavoriteMovie> rows) => <int>{
      for (final FavoriteMovie row in rows) row.movieId,
    },
  );

  Future<Set<int>> readFavoriteIds() async {
    final List<FavoriteMovie> rows = await select(favoriteMovies).get();

    return <int>{for (final FavoriteMovie row in rows) row.movieId};
  }

  /// Меняем локально и кладём операцию в очередь — **одной транзакцией**.
  ///
  /// Иначе возможен разрыв: избранное переключилось, а операция потерялась,
  /// и сервер о ней никогда не узнает.
  Future<void> toggleFavoriteWithOutbox(int movieId) => transaction(() async {
    final bool isFavorite = await (select(
      favoriteMovies,
    )..where(($FavoriteMoviesTable t) => t.movieId.equals(movieId))).getSingleOrNull() != null;

    if (isFavorite) {
      await (delete(
        favoriteMovies,
      )..where(($FavoriteMoviesTable t) => t.movieId.equals(movieId))).go();
    } else {
      await into(favoriteMovies).insertOnConflictUpdate(
        FavoriteMoviesCompanion.insert(
          movieId: Value<int>(movieId),
          changedAt: DateTime.now(),
        ),
      );
    }

    final DateTime now = DateTime.now();
    await into(pendingOps).insert(
      PendingOpsCompanion.insert(
        movieId: movieId,
        kind: 'favorite',
        payload: jsonEncode(<String, Object?>{
          'movieId': movieId,
          'isFavorite': !isFavorite,
        }),
        // Ключ идемпотентности: повтор той же операции сервер отсечёт сам.
        idemKey: 'fav-$movieId-${now.microsecondsSinceEpoch}',
        createdAt: now,
      ),
    );
  });

  Stream<List<PendingOp>> watchPendingOps() => (select(
    pendingOps,
  )..orderBy(<OrderClauseGenerator<$PendingOpsTable>>[
    ($PendingOpsTable t) => OrderingTerm(expression: t.id),
  ])).watch();

  /// Очередь — это очередь: берём операции по порядку и не перескакиваем.
  Future<List<PendingOp>> readPendingOps() => (select(
    pendingOps,
  )..where(($PendingOpsTable t) => t.status.equals('pending'))
   ..orderBy(<OrderClauseGenerator<$PendingOpsTable>>[
     ($PendingOpsTable t) => OrderingTerm(expression: t.id),
   ])).get();

  /// Разовое чтение всей очереди — для статуса синхронизации.
  Future<List<PendingOp>> readAllOps() => select(pendingOps).get();

  Future<void> markOpDone(int id) =>
      (delete(pendingOps)..where(($PendingOpsTable t) => t.id.equals(id))).go();

  /// 4xx повторять бессмысленно: операция уходит в dead letter.
  Future<void> markOpDead(int id) =>
      (update(pendingOps)..where(($PendingOpsTable t) => t.id.equals(id))).write(
        const PendingOpsCompanion(status: Value<String>('dead')),
      );

  Future<void> rescheduleOp(int id, {required Duration delay}) async {
    final PendingOp op = await (select(
      pendingOps,
    )..where(($PendingOpsTable t) => t.id.equals(id))).getSingle();

    await (update(pendingOps)..where(($PendingOpsTable t) => t.id.equals(id)))
        .write(
          PendingOpsCompanion(
            attempts: Value<int>(op.attempts + 1),
            nextTry: Value<DateTime>(DateTime.now().add(delay)),
          ),
        );
  }

  /// Разрешение конфликта: приводим локальное состояние к серверному.
  Future<void> applyServerFavorite(int movieId, {required bool isFavorite}) =>
      transaction(() async {
        if (isFavorite) {
          await into(favoriteMovies).insertOnConflictUpdate(
            FavoriteMoviesCompanion.insert(
              movieId: Value<int>(movieId),
              changedAt: DateTime.now(),
            ),
          );
        } else {
          await (delete(
            favoriteMovies,
          )..where(($FavoriteMoviesTable t) => t.movieId.equals(movieId))).go();
        }
      });

  Future<void> clearOutbox() => delete(pendingOps).go();

  Future<void> clearCache() => transaction(() async {
    await delete(cachedMovies).go();
    await delete(cachedGenres).go();
    await delete(syncMeta).go();
  });

  Future<void> _touch(String key) => into(syncMeta).insertOnConflictUpdate(
    SyncMetaCompanion.insert(key: key, updatedAt: DateTime.now()),
  );
}
