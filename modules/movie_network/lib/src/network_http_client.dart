part of 'http_client.dart';

/// Один `Dio` на приложение: пул соединений, keep-alive и общие интерсепторы
/// живут в нём. Создавать клиент в каждом методе — значит терять всё это разом.
class _NetworkHttpClient implements HttpClient {
  _NetworkHttpClient({
    required HttpClientConfig config,
    required TokenStorage tokenStorage,
    required TokenRefresher tokenRefresher,
    required NetworkEventBus eventBus,
    Dio? dio,
    Dio? retryDio,
  }) : dio = dio ?? Dio() {
    final BaseOptions options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: <String, Object?>{'Accept': 'application/json'},
      // 4xx разбираем сами — но 401 отдаём в ветку ошибок, чтобы до него
      // добрался refresh-интерсептор.
      validateStatus: (int? code) =>
          code != null && code < 500 && code != 401,
    );

    this.dio.options = options;

    // Отдельный «голый» клиент для повторов: у него нет ни логов,
    // ни refresh-интерсептора, поэтому повтор не уйдёт в рекурсию.
    _retryClient = retryDio ?? Dio();
    _retryClient.options = options;

    // Порядок регистрации — это порядок вызова onRequest:
    // сначала токен, потом логи.
    this.dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(storage: tokenStorage),
      LoggingInterceptor(eventBus: eventBus),
      RefreshInterceptor(
        refresher: tokenRefresher,
        storage: tokenStorage,
        retryClient: _retryClient,
        eventBus: eventBus,
      ),
    ]);
    _retryClient.interceptors.add(LoggingInterceptor(eventBus: eventBus));
  }

  final Dio dio;
  late final Dio _retryClient;

  @override
  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<Object?> response = await dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );

      final int statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw ApiException(
          statusCode: statusCode,
          path: path,
          serverMessage: _serverMessage(response.data),
        );
      }

      final Object? data = response.data;
      if (data is! Map<String, Object?>) {
        // Пришёл не JSON: заглушка провайдера, HTML-страница ошибки.
        throw FormatException('Ожидали JSON-объект от $path', data);
      }

      return data;
    } on DioException catch (error) {
      throw _mapDioException(error, path);
    }
  }

  /// Единственное место, где `DioException` превращается в четыре понятных
  /// типа. Выше по слоям про dio уже никто не знает.
  Object _mapDioException(DioException error, String path) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => TimeoutException(
        'Сервер не ответил вовремя: $path',
      ),
      DioExceptionType.connectionError => SocketException(
        error.message ?? 'Нет сети',
      ),
      DioExceptionType.badResponse => ApiException(
        statusCode: error.response?.statusCode ?? 0,
        path: path,
        serverMessage: _serverMessage(error.response?.data),
      ),
      DioExceptionType.cancel => error,
      _ => error.error ?? error,
    };
  }

  String? _serverMessage(Object? data) =>
      data is Map<String, Object?> ? data['status_message'] as String? : null;
}
