// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import 'network_events.dart';
import 'token_refresher.dart';
import 'token_storage.dart';

/// Первое звено цепочки: подставить токен и отметить время старта.
///
/// TMDB принимает короткий v3-ключ параметром `api_key`, а длинный v4 —
/// заголовком `Authorization: Bearer`. Токен всегда берётся из хранилища,
/// а не из конфигурации: иначе его нельзя было бы подменить на протухший.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required TokenStorage storage}) : _storage = storage;

  final TokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      if (token.length > 40) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.queryParameters['api_key'] = token;
      }
    }

    options.extra['startedAt'] = DateTime.now();

    return handler.next(options);
  }
}

/// Второе звено: логи и метрики.
///
/// `onRequest`-обработчики идут по порядку регистрации, `onResponse` —
/// в обратном, а `onError` живёт отдельной веткой: сюда попадают
/// и таймауты, и 4xx, и 5xx.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required NetworkEventBus eventBus}) : _eventBus = eventBus;

  final NetworkEventBus _eventBus;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _eventBus.add(
      NetworkEvent(
        kind: NetworkEventKind.request,
        message: '→ ${options.method} ${options.path}',
        at: DateTime.now(),
      ),
    );

    return handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _eventBus.add(
      NetworkEvent(
        kind: NetworkEventKind.response,
        message: '← ${response.requestOptions.path}',
        at: DateTime.now(),
        statusCode: response.statusCode,
        duration: _elapsed(response.requestOptions),
      ),
    );

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _eventBus.add(
      NetworkEvent(
        kind: NetworkEventKind.failure,
        message: '× ${err.requestOptions.path}: ${err.type.name}',
        at: DateTime.now(),
        statusCode: err.response?.statusCode,
        duration: _elapsed(err.requestOptions),
      ),
    );

    return handler.next(err);
  }

  Duration? _elapsed(RequestOptions options) {
    final Object? startedAt = options.extra['startedAt'];

    return startedAt is DateTime ? DateTime.now().difference(startedAt) : null;
  }
}

/// Третье звено: 401 → refresh → повтор.
///
/// Три ловушки, от которых защищаемся здесь:
/// 1. рекурсия — помечаем повтор `extra['retried']`;
/// 2. стадо 401 — очередь живёт в [TokenRefresher];
/// 3. тот же самый Dio — повтор уходит через отдельный «голый» клиент,
///    у которого этого интерсептора нет.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required TokenRefresher refresher,
    required TokenStorage storage,
    required Dio retryClient,
    required NetworkEventBus eventBus,
  }) : _refresher = refresher,
       _storage = storage,
       _retryClient = retryClient,
       _eventBus = eventBus;

  final TokenRefresher _refresher;
  final TokenStorage _storage;
  final Dio _retryClient;
  final NetworkEventBus _eventBus;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final RequestOptions request = err.requestOptions;
    if (request.extra['retried'] == true) {
      // Повтор снова получил 401 — дальше только разлогинивать.
      await _storage.clear();

      return handler.reject(err);
    }

    final bool refreshed = await _refresher.refresh();
    if (!refreshed) {
      return handler.reject(err);
    }

    final String? token = await _storage.readAccessToken();
    request.extra['retried'] = true;
    if (token != null) {
      if (token.length > 40) {
        request.headers['Authorization'] = 'Bearer $token';
      } else {
        request.queryParameters['api_key'] = token;
      }
    }

    _eventBus.add(
      NetworkEvent(
        kind: NetworkEventKind.retry,
        message: '↻ повтор ${request.path} со свежим токеном',
        at: DateTime.now(),
      ),
    );

    try {
      final Response<dynamic> retried = await _retryClient.fetch<dynamic>(
        request,
      );

      // Закорачиваем цепочку: ответ есть, вызывающий код ничего не заметил.
      return handler.resolve(retried);
    } on DioException catch (retryError) {
      // Свежий токен тоже не подошёл — дальше только разлогинивать.
      // Проверять это нужно здесь: повтор уходит через «голый» клиент,
      // у которого нет этого интерсептора, и второй 401 сюда не вернётся.
      if (retryError.response?.statusCode == 401) {
        await _storage.clear();
      }

      return handler.reject(retryError);
    }
  }
}
