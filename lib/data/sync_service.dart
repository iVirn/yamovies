// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:movie_database/movie_database.dart';
import 'package:rxdart/rxdart.dart';

import '../application/demo_settings.dart';
import 'favorites_sync_api.dart';

/// Операция очереди в том виде, в каком её показывает экран.
///
/// Строки таблиц наверх не уезжают: `PendingOp` сгенерировал drift,
/// и дальше слоя данных он не нужен.
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.movieId,
    required this.kind,
    required this.status,
    required this.attempts,
    required this.idempotencyKey,
  });

  final int id;
  final int movieId;
  final String kind;
  final String status;
  final int attempts;
  final String idempotencyKey;

  bool get isPending => status == 'pending';

  bool get isDead => status == 'dead';
}

/// Как прошёл последний проход очереди — для баннера на экране.
class SyncStatus {
  const SyncStatus({
    required this.isRunning,
    required this.pendingCount,
    required this.deadCount,
    this.lastMessage,
  });

  final bool isRunning;
  final int pendingCount;
  final int deadCount;
  final String? lastMessage;
}

/// Разбор очереди изменений.
///
/// Три правила, без которых очередь ломается:
/// 1. **идемпотентность** — ключ генерирует клиент, сервер отсекает дубли;
/// 2. **порядок** — при ошибке останавливаемся, а не перескакиваем операцию;
/// 3. **конечность** — у операции есть предел попыток и статус dead letter.
class SyncService {
  SyncService({required AppDatabase database, required FavoritesSyncApi api})
    : _database = database,
      _api = api;

  static const int maxAttempts = 5;

  final AppDatabase _database;
  final FavoritesSyncApi _api;
  final math.Random _random = math.Random(42);
  final StreamController<SyncStatus> _status =
      StreamController<SyncStatus>.broadcast();

  bool _isDraining = false;

  Stream<SyncStatus> get status => _status.stream;

  /// Очередь для экрана: один общий поток, а не новый на каждую перерисовку.
  late final Stream<List<OutboxEntry>> queue = _database
      .watchPendingOps()
      .map(
        (List<PendingOp> ops) => <OutboxEntry>[
          for (final PendingOp op in ops) _toEntry(op),
        ],
      )
      .shareValue();

  DemoSettings? _connectivitySource;

  /// Толкнуть очередь: после изменения, при возврате сети, по таймеру.
  void kick() => unawaited(drain());

  /// Следить за возвращением сети. В настоящем приложении здесь был бы
  /// `connectivity_plus`; на демо роль сети играет переключатель.
  void listenToConnectivity(DemoSettings demoSettings) {
    _connectivitySource = demoSettings..addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (_connectivitySource?.airplaneMode == false) {
      kick();
    }
  }

  Future<void> drain() async {
    if (_isDraining) {
      return;
    }

    _isDraining = true;
    await _emitStatus('очередь пошла');

    try {
      for (final PendingOp op in await _database.readPendingOps()) {
        if (op.attempts >= maxAttempts) {
          await _database.markOpDead(op.id);
          continue;
        }

        final DateTime? nextTry = op.nextTry;
        if (nextTry != null && nextTry.isAfter(DateTime.now())) {
          // Ещё не пришло время повтора — и порядок нарушать нельзя.
          break;
        }

        try {
          await _api.apply(op, idempotencyKey: op.idemKey);
          await _database.markOpDone(op.id);
          await _emitStatus('операция ${op.id} ушла на сервер');
        } on ConflictException catch (conflict) {
          // 409: приводим локальное состояние к серверному — server wins.
          await _database.applyServerFavorite(
            conflict.movieId,
            isFavorite: conflict.serverIsFavorite,
          );
          await _database.markOpDone(op.id);
          await _emitStatus('конфликт по фильму ${conflict.movieId}: '
              'приняли версию сервера');
        } on SocketException {
          await _database.rescheduleOp(op.id, delay: _backoff(op.attempts));
          await _emitStatus('нет сети, повтор через '
              '${_backoff(op.attempts).inSeconds} с');
          // Останавливаемся: следующая операция может зависеть от этой.
          break;
        } catch (error) {
          debugPrint('[sync] операция ${op.id} упала: $error');
          await _database.markOpDead(op.id);
          await _emitStatus('операция ${op.id} в dead letter');
        }
      }
    } finally {
      _isDraining = false;
      await _emitStatus(null);
    }
  }

  /// Граница слоя данных: строка таблицы превращается в модель для экрана.
  OutboxEntry _toEntry(PendingOp op) => OutboxEntry(
    id: op.id,
    movieId: op.movieId,
    kind: op.kind,
    status: op.status,
    attempts: op.attempts,
    idempotencyKey: op.idemKey,
  );

  /// Backoff с джиттером: без него все клиенты вернутся одновременно.
  Duration _backoff(int attempts) {
    final int seconds = math.min(1 << attempts, 300);
    final double jitter = 0.8 + _random.nextDouble() * 0.4;

    return Duration(milliseconds: (seconds * 1000 * jitter).round());
  }

  Future<void> _emitStatus(String? message) async {
    if (_status.isClosed) {
      return;
    }

    final List<PendingOp> ops = await _database.readAllOps();

    _status.add(
      SyncStatus(
        isRunning: _isDraining,
        pendingCount: ops
            .where((PendingOp op) => op.status == 'pending')
            .length,
        deadCount: ops.where((PendingOp op) => op.status == 'dead').length,
        lastMessage: message,
      ),
    );
  }

  Future<void> dispose() {
    _connectivitySource?.removeListener(_onConnectivityChanged);
    _connectivitySource = null;

    return _status.close();
  }
}
