part of 'http_client.dart';

/// Один `Dio` на приложение: пул соединений, keep-alive и общие интерсепторы
/// живут в нём. Создавать клиент в каждом методе — значит терять всё это разом.
class _NetworkHttpClient implements HttpClient {
  _NetworkHttpClient({required HttpClientConfig config, Dio? dio})
    : _config = config,
      dio = dio ?? Dio() {
    this.dio.options = this.dio.options.copyWith(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: <String, Object?>{
        'Accept': 'application/json',
        if (config.isBearerToken) 'Authorization': 'Bearer ${config.apiKey}',
      },
      // 4xx разбираем сами: без этого dio бросает DioException и на 401,
      // и на 404, а нам нужен единый ApiException.
      validateStatus: (int? code) => code != null && code < 500,
    );
  }

  final HttpClientConfig _config;
  final Dio dio;

  @override
  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<Object?> response = await dio.get<Object?>(
        path,
        queryParameters: <String, Object?>{
          if (!_config.isBearerToken) 'api_key': _config.apiKey,
          ...?queryParameters,
        },
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
