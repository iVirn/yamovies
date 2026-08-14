import 'package:dio/dio.dart';

part 'network_http_client.dart';

abstract interface class HttpClient {
  const HttpClient();

  static HttpClient create(HttpClientType type, {Dio? dio}) => switch (type) {
    HttpClientType.network => _NetworkHttpClient(dio: dio),
  };
}

enum HttpClientType { network }
