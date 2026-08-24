import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'interceptors.dart';
import 'network_events.dart';
import 'token_refresher.dart';
import 'token_storage.dart';

part 'network_http_client.dart';

/// Настройки одного клиента: базовый адрес и таймауты.
///
/// Ключа здесь больше нет: его подставляет [AuthInterceptor] из хранилища,
/// иначе токен нельзя было бы подменить на протухший.
class HttpClientConfig {
  const HttpClientConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 5),
    this.receiveTimeout = const Duration(seconds: 10),
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}

/// Транспорт: знает про HTTP и ничего — про фильмы.
abstract interface class HttpClient {
  const HttpClient();

  static HttpClient create(
    HttpClientType type, {
    required HttpClientConfig config,
    required TokenStorage tokenStorage,
    required TokenRefresher tokenRefresher,
    required NetworkEventBus eventBus,
    Dio? dio,
    Dio? retryDio,
  }) => switch (type) {
    HttpClientType.network => _NetworkHttpClient(
      config: config,
      tokenStorage: tokenStorage,
      tokenRefresher: tokenRefresher,
      eventBus: eventBus,
      dio: dio,
      // Повторы уходят через отдельный клиент. В тестах его подменяют
      // вместе с основным — иначе повтор ушёл бы в настоящую сеть.
      retryDio: retryDio,
    ),
  };

  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  });
}

enum HttpClientType { network }
