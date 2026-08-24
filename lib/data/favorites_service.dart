// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movie_database/movie_database.dart';
import 'package:rxdart/rxdart.dart';

import 'sync_service.dart';

/// Избранное: локальная запись сразу, отправка на сервер — когда получится.
///
/// Источник правды теперь база, а не множество в памяти: переключение
/// переживает перезапуск приложения и работает офлайн. Экранам сервис
/// по-прежнему отдаёт `Stream` — это тот самый источник, который живёт
/// дольше одного ответа.
class FavoritesService {
  FavoritesService({required AppDatabase database, required SyncService syncService})
    : _database = database,
      _syncService = syncService {
    // Ресурсы поднимаем на первой подписке и отпускаем, когда слушать некому:
    // одна подписка на базу на всё приложение, и та живёт не дольше экранов.
    _controller = StreamController<Set<int>>.broadcast(
      onListen: () {
        debugPrint('[favorites] появился первый слушатель');
        _databaseSubscription = _database.watchFavoriteIds().listen((
          Set<int> ids,
        ) {
          _current = ids;
          _controller.add(ids);
        });
      },
      onCancel: () {
        debugPrint('[favorites] слушателей не осталось');
        unawaited(_databaseSubscription?.cancel());
        _databaseSubscription = null;
      },
    );
  }

  final AppDatabase _database;
  final SyncService _syncService;

  late final StreamController<Set<int>> _controller;
  StreamSubscription<Set<int>>? _databaseSubscription;
  Set<int> _current = <int>{};

  /// Текущее состояние — синхронно и без подписки (для `initialData`).
  Set<int> get current => _current;

  Stream<Set<int>> get changes => _controller.stream;

  Stream<bool> watchIsFavorite(int movieId) =>
      changes.map((Set<int> ids) => ids.contains(movieId)).distinct();

  /// Операции, которые ещё не доехали до сервера, — для бейджа на карточке.
  ///
  /// Поток собран **один раз**: если строить его в `build`, каждая перерисовка
  /// создаст новый стрим, `StreamBuilder` переподпишется, отдаст значение —
  /// и вызовет следующую перерисовку. Экран уйдёт в бесконечный цикл.
  late final Stream<Set<int>> unsyncedIds = _database
      .watchPendingOps()
      .map(
        (List<PendingOp> ops) => <int>{
          for (final PendingOp op in ops)
            if (op.status == 'pending') op.movieId,
        },
      )
      .shareValue();

  /// Пара «избранное + неотправленное» для ленты — тоже собрана один раз.
  late final Stream<({Set<int> favorites, Set<int> unsynced})> board =
      Rx.combineLatest2(
        changes,
        unsyncedIds,
        (Set<int> ids, Set<int> unsynced) =>
            (favorites: ids, unsynced: unsynced),
      ).shareValue();

  bool isFavorite(int movieId) => _current.contains(movieId);

  /// Меняем локально, кладём операцию в очередь и толкаем синхронизацию.
  /// Если сети нет, изменение никуда не денется — оно уже в базе.
  Future<void> toggle(int movieId) async {
    await _database.toggleFavoriteWithOutbox(movieId);
    _syncService.kick();
  }

  Future<void> dispose() async {
    await _databaseSubscription?.cancel();
    await _controller.close();
  }
}
