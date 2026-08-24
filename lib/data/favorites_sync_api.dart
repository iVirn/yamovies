// ignore_for_file: prefer_initializing_formals

import 'dart:io';

import 'package:movie_database/movie_database.dart';

import '../application/demo_settings.dart';

/// Конфликт версий: на сервере состояние уже другое.
class ConflictException implements Exception {
  const ConflictException({required this.movieId, required this.serverIsFavorite});

  final int movieId;

  /// Что сервер считает правдой прямо сейчас.
  final bool serverIsFavorite;

  @override
  String toString() =>
      'ConflictException(movie $movieId, server says '
      '${serverIsFavorite ? 'в избранном' : 'не в избранном'})';
}

/// Сервер синхронизации избранного.
///
/// TMDB v3 умеет отдавать данные, но не принимать наше избранное без
/// пользовательской сессии, поэтому «приёмная сторона» здесь заглушка.
/// Всё, ради чего она существует, — настоящее: задержка, обрыв связи,
/// идемпотентность и ответ 409.
class FavoritesSyncApi {
  FavoritesSyncApi({
    required DemoSettings demoSettings,
    this.latency = const Duration(milliseconds: 600),
  }) : _demoSettings = demoSettings;

  final DemoSettings _demoSettings;
  final Duration latency;

  /// Ключи идемпотентности, которые сервер уже видел: повтор той же операции
  /// не создаёт вторую запись.
  final Set<String> _appliedIdempotencyKeys = <String>{};

  int appliedCount = 0;

  Future<void> apply(PendingOp op, {required String idempotencyKey}) async {
    if (_demoSettings.airplaneMode) {
      throw const SocketException('Режим полёта: сети нет');
    }

    await Future<void>.delayed(latency);

    if (_appliedIdempotencyKeys.contains(idempotencyKey)) {
      // Сервер уже применил эту операцию — повтор просто подтверждаем.
      return;
    }

    if (_demoSettings.simulateConflict && op.movieId.isEven) {
      // «Пока вы были офлайн, с другого устройства этот фильм убрали».
      throw ConflictException(movieId: op.movieId, serverIsFavorite: false);
    }

    _appliedIdempotencyKeys.add(idempotencyKey);
    appliedCount++;
  }
}
