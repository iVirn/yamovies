// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'network_events.dart';
import 'token_storage.dart';

/// Как достать свежий токен. В настоящем приложении здесь запрос
/// `/auth/refresh` на «голом» Dio.
typedef FetchFreshToken = Future<String?> Function();

/// Обновление токена, которое переживает стадо 401.
///
/// Экран стартует пятью запросами — прилетает пять 401. Если каждый уйдёт
/// в refresh, сервер ротирует токен на первом и отзовёт остальные:
/// пользователь разлогинен на ровном месте. Лечение — очередь:
/// refresh выполняет первый, остальные ждут его `Future`.
class TokenRefresher {
  TokenRefresher({
    required TokenStorage storage,
    required FetchFreshToken fetchFreshToken,
    required NetworkEventBus eventBus,
  }) : _storage = storage,
       _fetchFreshToken = fetchFreshToken,
       _eventBus = eventBus;

  final TokenStorage _storage;
  final FetchFreshToken _fetchFreshToken;
  final NetworkEventBus _eventBus;

  Future<bool>? _inFlight;

  /// Демо «наивно против очереди»: с `false` каждый 401 идёт обновлять токен
  /// сам по себе.
  bool useQueue = true;

  int refreshCallsSent = 0;

  Future<bool> refresh() {
    if (!useQueue) {
      return _doRefresh();
    }

    // Весь механизм очереди — одна строка: первый создаёт future,
    // остальные получают его же и просто ждут.
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<bool> _doRefresh() async {
    refreshCallsSent++;
    final Stopwatch stopwatch = Stopwatch()..start();
    _eventBus.add(
      NetworkEvent(
        kind: NetworkEventKind.refreshStarted,
        message: 'refresh #$refreshCallsSent пошёл за новым токеном',
        at: DateTime.now(),
      ),
    );

    try {
      final String? token = await _fetchFreshToken();
      if (token == null) {
        await _storage.clear();

        return false;
      }

      await _storage.writeAccessToken(token);

      return true;
    } catch (error) {
      _eventBus.add(
        NetworkEvent(
          kind: NetworkEventKind.failure,
          message: 'refresh не удался: $error',
          at: DateTime.now(),
        ),
      );

      return false;
    } finally {
      stopwatch.stop();
      _eventBus.add(
        NetworkEvent(
          kind: NetworkEventKind.refreshDone,
          message: 'refresh #$refreshCallsSent завершён',
          at: DateTime.now(),
          duration: stopwatch.elapsed,
        ),
      );
    }
  }
}
