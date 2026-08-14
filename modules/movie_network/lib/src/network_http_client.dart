part of 'http_client.dart';

class _NetworkHttpClient implements HttpClient {
  _NetworkHttpClient({Dio? dio}) : dio = dio ?? Dio();

  final Dio dio;
}
