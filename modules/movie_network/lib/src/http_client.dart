import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exception.dart';

part 'network_http_client.dart';

/// Настройки одного клиента: базовый адрес, ключ и таймауты.
class HttpClientConfig {
  const HttpClientConfig({
    required this.baseUrl,
    required this.apiKey,
    this.connectTimeout = const Duration(seconds: 5),
    this.receiveTimeout = const Duration(seconds: 10),
  });

  final String baseUrl;
  final String apiKey;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// У TMDB два вида ключей: короткий v3 (`api_key` в query) и длинный
  /// v4 read access token (заголовок `Authorization: Bearer`).
  bool get isBearerToken => apiKey.length > 40;

  bool get isEmpty => apiKey.isEmpty;
}

/// Транспорт: знает про HTTP и ничего — про фильмы.
abstract interface class HttpClient {
  const HttpClient();

  static HttpClient create(
    HttpClientType type, {
    required HttpClientConfig config,
    Dio? dio,
  }) => switch (type) {
    HttpClientType.network => _NetworkHttpClient(config: config, dio: dio),
  };

  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  });
}

enum HttpClientType { network }
